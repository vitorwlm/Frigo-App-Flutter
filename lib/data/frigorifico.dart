import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/compra.dart';
import '../models/evento.dart';
import '../models/item.dart';
import '../models/receita.dart';
import '../widgets/tag_chip.dart';
import '../services/nuvem.dart';
import 'dados_exemplo.dart';

// Os 4 estados do cartão de cima do Início (ecrãs 01, 02, 13 e 19 do Figma)
enum EstadoFrigu { ok, temperaturaAlta, semLigacao, portaAberta }

// 2.0 -> "2", 2.5 -> "2,5"
String numeroPt(double v) => v == v.roundToDouble()
    ? v.toInt().toString()
    : v.toStringAsFixed(1).replaceAll('.', ',');

// 4.2 -> "4,2 °C"
String graus(double v) => '${v.toStringAsFixed(1).replaceAll('.', ',')} °C';

// Os dados da app num só sítio, partilhados por todos os ecrãs.
// ChangeNotifier: quando algo muda, chama notifyListeners() e os ecrãs
// que estão a ouvir (ListenableBuilder ou addListener) redesenham-se.
// Mais tarde, estes métodos passam a ler e escrever no Supabase.
class Frigorifico extends ChangeNotifier {
  final List<Item> itens = itensExemplo();
  final List<Receita> receitas = receitasExemplo();
  final List<Evento> eventos = _eventosExemplo();
  final List<AlertaSensor> alertas = _alertasExemplo();
  final List<Compra> compras = [
    Compra(nome: 'Manteiga', motivo: 'Acabou no frigorífico'),
    Compra(nome: 'Farinha', motivo: 'Para as panquecas', tom: TagTom.marca),
    Compra(
      nome: 'Iogurte natural ×2',
      motivo: 'Pack mais pequeno',
      tom: TagTom.aviso,
    ),
    Compra(nome: 'Tomates', motivo: 'Acabou no frigorífico', noCarrinho: true),
  ];
  int _proximoId = 100;

  // ---- sensores (falsos até a ESP32 enviar leituras para o Supabase) ----
  double temperatura = 4.2;
  int humidade = 62;
  bool ligado = true;
  // null = porta fechada
  DateTime? portaAbertaDesde;
  DateTime ultimaLeitura = DateTime.now().subtract(const Duration(minutes: 2));
  final List<AberturaPorta> aberturas = _aberturasExemplo();

  EstadoFrigu get estado {
    if (!ligado) return EstadoFrigu.semLigacao;
    if (portaAbertaDesde != null) return EstadoFrigu.portaAberta;
    if (temperatura > alvoMax) return EstadoFrigu.temperaturaAlta;
    return EstadoFrigu.ok;
  }

  // ---- definições (ecrã 14) ----
  // avisar quantos dias antes de expirar (1, 2 ou 3)
  int diasAviso = 2;
  bool resumoDiario = true;
  // temperatura-alvo em °C
  double alvoMin = 2;
  double alvoMax = 5;

  Frigorifico() {
    _sincronizarReceitas();
  }

  // sempre que algo muda, as receitas passam a saber o que há em casa
  @override
  void notifyListeners() {
    _sincronizarReceitas();
    super.notifyListeners();
  }

  // copia do inventário para cada ingrediente: quanto há e quando expira
  void _sincronizarReceitas() {
    for (final r in receitas) {
      for (final ing in r.ingredientes) {
        if (ing.despensa) continue;
        final iguais = noFrigorifico
            .where((i) => i.quantidade > 0 && ingredienteCorresponde(ing, i))
            .toList();
        ing.stock = iguais.fold(0.0, (soma, i) => soma + i.quantidade);
        ing.dias = iguais.isEmpty
            ? null
            : iguais.map((i) => i.dias).reduce((a, b) => a < b ? a : b);
      }
    }
  }

  // chama-se depois de mudar um item à mão (ex.: no ecrã de detalhe)
  void atualizar([Item? item]) {
    if (item != null) _guardar(item);
    notifyListeners();
  }

  // ---- leituras ----

  List<Item> get noFrigorifico =>
      itens.where((i) => i.local == Local.frigorifico).toList();

  // o que expira em 4 dias ou menos, do mais urgente para o menos
  List<Item> get aExpirar =>
      noFrigorifico.where((i) => i.dias <= 4).toList()
        ..sort((a, b) => a.dias.compareTo(b.dias));

  int get totalEmCasa => itens.where((i) => i.local != Local.acabou).length;

  // a melhor receita para hoje: tens tudo e salva mais alimentos a expirar
  Receita get receitaDoDia {
    final candidatas = receitas.where((r) => r.tensTudo(r.pessoasBase)).toList()
      ..sort((a, b) => b.salva.compareTo(a.salva));
    return candidatas.isNotEmpty ? candidatas.first : receitas.first;
  }

  // ---- ações sobre os alimentos ----

  void usar(Item item, {int? quantidade}) {
    // por defeito: 1 unidade, ou tudo se for em gramas/litros
    int q = quantidade ?? (item.porUnidade ? 1 : item.quantidade);
    if (q > item.quantidade) q = item.quantidade;
    item.quantidade -= q;
    if (item.quantidade <= 0) {
      item.quantidade = 0;
      item.local = Local.acabou;
      item.motivoSaida = 'consumido';
    }
    _guardar(item);
    eventos.add(Evento(
      itemId: item.id,
      nome: item.nome,
      tipo: TipoEvento.usado,
      data: DateTime.now(),
      pesoKg: item.pesoDe(q),
    ));
    notifyListeners();
  }

  void usarTudo(Item item) => usar(item, quantidade: item.quantidade);

  void deitarFora(Item item, {String? motivo}) {
    eventos.add(Evento(
      itemId: item.id,
      nome: item.nome,
      tipo: TipoEvento.deitadoFora,
      data: DateTime.now(),
      pesoKg: item.pesoDe(item.quantidade),
      motivo: motivo ??
          (item.dias <= 0 ? 'Passou a validade' : 'Estragou-se antes'),
    ));
    item.quantidade = 0;
    item.local = Local.acabou;
    item.motivoSaida = 'desperdicado';
    _guardar(item);
    notifyListeners();
  }

  // botão Anular: volta ao que estava e apaga o último registo deste item
  void repor(Item item, int quantidade, Local local) {
    item.quantidade = quantidade;
    item.local = local;
    item.motivoSaida = null;
    _guardar(item);
    final int i = eventos.lastIndexWhere((e) => e.itemId == item.id);
    if (i != -1) eventos.removeAt(i);
    notifyListeners();
  }

  Future<void> adicionar({
    required String nome,
    required int quantidade,
    required String unidade,
    required int dias,
    required String categoria,
  }) async {
    final hoje = DateUtils.dateOnly(DateTime.now());
    if (naNuvem) {
      // insert(...).select().single() devolve a linha criada, com o id
      final rascunho = Item(
        id: '0',
        nome: nome,
        quantidade: quantidade,
        unidade: unidade,
        validade: hoje.add(Duration(days: dias)),
        entrada: hoje,
        categoria: categoria,
      );
      try {
        final linha = await supabase
            .from('itens')
            .insert({...linhaDoItem(rascunho), 'origem': 'manual'})
            .select()
            .single();
        final novo = itemDaLinha(linha);
        // o Realtime pode já o ter trazido
        if (!itens.any((i) => i.id == novo.id)) itens.add(novo);
      } catch (e) {
        _erro(e);
      }
      notifyListeners();
      return;
    }
    itens.add(Item(
      id: '${_proximoId++}',
      nome: nome,
      quantidade: quantidade,
      unidade: unidade,
      validade: hoje.add(Duration(days: dias)),
      entrada: hoje,
      categoria: categoria,
    ));
    notifyListeners();
  }

  // tira do inventário o que a receita usa (procura pelo início do nome)
  void cozinhar(Receita r, int pessoas) {
    for (final ing in r.ingredientes) {
      if (ing.despensa) continue;
      final candidatos = noFrigorifico
          .where((i) => ingredienteCorresponde(ing, i))
          .toList()
        ..sort((a, b) => a.dias.compareTo(b.dias));
      if (candidatos.isEmpty) continue;
      usar(candidatos.first, quantidade: ing.necessario(pessoas).round());
    }
  }

  // ---- confirmar o que a câmara viu (ecrã 12) ----

  void confirmar(Item item, String nome) {
    item.nome = nome;
    item.certeza = 100;
    _guardar(item);
    notifyListeners();
  }

  // "Não está no frigorífico": tira o item e devolve a posição, para o Anular
  int remover(Item item) {
    final int i = itens.indexOf(item);
    itens.remove(item);
    if (naNuvem) {
      // na base de dados fica com quantidade 0, sem motivo (não foi usado)
      supabase
          .from('itens')
          .update({
            'quantidade': 0,
            'removido_em': DateTime.now().toUtc().toIso8601String(),
            'motivo_saida': null,
          })
          .eq('id', int.parse(item.id))
          .then((_) {}, onError: (Object e) => _erro(e));
    }
    notifyListeners();
    return i;
  }

  void inserir(int i, Item item) {
    itens.insert(i, item);
    _guardar(item);
    notifyListeners();
  }

  // ---- estados do Início ----

  // Muda os sensores para mostrar um estado (secção Demonstração das Definições)
  void simular(EstadoFrigu e) {
    ligado = e != EstadoFrigu.semLigacao;
    portaAbertaDesde = e == EstadoFrigu.portaAberta
        ? DateTime.now().subtract(const Duration(minutes: 2))
        : null;
    temperatura = switch (e) {
      EstadoFrigu.temperaturaAlta => 7.4,
      EstadoFrigu.portaAberta => 4.6,
      _ => 4.2,
    };
    ultimaLeitura = e == EstadoFrigu.semLigacao
        ? DateTime.now().subtract(const Duration(hours: 3))
        : DateTime.now().subtract(const Duration(minutes: 2));
    notifyListeners();
  }

  // "Já fechei a porta": a temperatura volta a descer
  void fecharPorta() {
    portaAbertaDesde = null;
    temperatura = 4.8;
    ultimaLeitura = DateTime.now();
    notifyListeners();
  }

  // "Tentar ligar de novo": espera pela placa (aqui, 2 s a fingir)
  Future<void> reconectar() async {
    await Future.delayed(const Duration(seconds: 2));
    ligado = true;
    ultimaLeitura = DateTime.now();
    notifyListeners();
  }

  // Temperatura num momento: base que sobe e desce um pouco ao longo do dia
  // + o pico de cada abertura da porta, que desce ao longo de ~1 h
  double temperaturaEm(DateTime t) {
    double v = 3.9 + 0.3 * sin(t.hour / 24 * 2 * pi);
    for (final a in aberturas) {
      final double min = t.difference(a.inicio).inMinutes.toDouble();
      if (min >= 0 && min <= 60) v += (a.maxTemp - 3.9) * exp(-min / 12);
    }
    return v;
  }

  // Leituras de [horas] para trás até agora, uma a cada [passo] minutos
  List<(DateTime, double)> leituras(int horas, int passo) {
    final reais = _resumos['$horas/$passo'];
    if (temLeiturasReais && reais != null && reais.isNotEmpty) {
      // médias do Supabase + o valor de agora no fim
      return [...reais, (DateTime.now(), temperatura)];
    }
    final agora = DateTime.now();
    final lista = <(DateTime, double)>[];
    for (int m = horas * 60; m > 0; m -= passo) {
      final t = agora.subtract(Duration(minutes: m));
      lista.add((t, temperaturaEm(t)));
    }
    // a última é o valor de agora
    lista.add((agora, temperatura));
    return lista;
  }

  // ---- editar um alimento (detalhe) ----

  void editar(Item item, {
    required String nome,
    required DateTime validade,
    required String categoria,
  }) {
    item.nome = nome;
    item.validade = validade;
    item.categoria = categoria;
    _guardar(item);
    notifyListeners();
  }

  // ---- Supabase ----

  String nomeUtilizador = '';
  String email = '';
  bool eAdmin = false;
  // true depois de carregar o inventário do Supabase: só então se escreve lá
  bool naNuvem = false;
  bool temLeiturasReais = false;
  String? erroNuvem;
  // mostra as Boas-vindas a seguir a criar conta
  bool verBoasVindas = false;
  final Map<String, List<(DateTime, double)>> _resumos = {};
  RealtimeChannel? _canal;

  void _erro(Object e) {
    erroNuvem = e.toString();
    debugPrint('Supabase: $e');
  }

  // grava as colunas do item; sem esperar pela resposta (a app não fica parada)
  void _guardar(Item item) {
    if (!naNuvem) return;
    supabase
        .from('itens')
        .update(linhaDoItem(item))
        .eq('id', int.parse(item.id))
        .then((_) {}, onError: (Object e) => _erro(e));
  }

  // Lê tudo do Supabase a seguir ao login
  Future<void> carregar() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    email = user.email ?? '';
    try {
      // perfil (criado pelo trigger ao registar)
      final perfil = await supabase
          .from('perfis')
          .select('nome, role')
          .eq('id', user.id)
          .maybeSingle();
      nomeUtilizador = (perfil?['nome'] as String?) ??
          (user.userMetadata?['nome'] as String?) ??
          email.split('@').first;
      eAdmin = perfil?['role'] == 'admin';

      // inventário: o que está em casa + o que acabou nos últimos 30 dias
      final mes = DateTime.now().subtract(const Duration(days: 30)).toUtc();
      final linhas = await supabase
          .from('itens')
          .select()
          .or('quantidade.gt.0,removido_em.gte.${mes.toIso8601String()}')
          .order('validade');
      itens
        ..clear()
        ..addAll(linhas.map(itemDaLinha));
      naNuvem = true;

      final conf = await supabase
          .from('configuracao')
          .select('valor')
          .eq('chave', 'temp_alvo')
          .maybeSingle();
      if (conf != null) {
        alvoMax = double.tryParse(conf['valor'] as String) ?? alvoMax;
      }

      await _carregarSensores();
      _ouvir();
      erroNuvem = null;
    } catch (e) {
      _erro(e);
    }
    notifyListeners();
  }

  Future<void> _carregarSensores() async {
    final ultima = await supabase
        .from('leituras')
        .select()
        .order('medido_em', ascending: false)
        .limit(1)
        .maybeSingle();
    // sem leituras (placa ainda não ligada): ficam os sensores falsos
    if (ultima == null) return;
    temLeiturasReais = true;
    _aplicarLeitura(ultima);

    await carregarLeituras(24, 30);
    await carregarLeituras(24 * 7, 60);

    final semana = DateTime.now().subtract(const Duration(days: 7)).toUtc();
    final evs = await supabase
        .from('eventos')
        .select()
        .gte('ocorreu_em', semana.toIso8601String())
        .order('ocorreu_em');
    aberturas.clear();
    alertas.clear();
    portaAbertaDesde = null;
    for (final e in evs) {
      _aplicarEvento(e);
    }
  }

  // médias por intervalo (função leituras_resumo do esquema_app.sql)
  Future<void> carregarLeituras(int horas, int passo) async {
    final desde = DateTime.now().subtract(Duration(hours: horas)).toUtc();
    try {
      final r = await supabase.rpc(
        'leituras_resumo',
        params: {'desde': desde.toIso8601String(), 'passo_min': passo},
      );
      _resumos['$horas/$passo'] = [
        for (final l in r as List)
          (
            DateTime.parse(l['momento'] as String).toLocal(),
            (l['temperatura'] as num).toDouble(),
          ),
      ];
    } catch (e) {
      _erro(e);
    }
  }

  void _aplicarLeitura(Map<String, dynamic> l) {
    temperatura = (l['temperatura'] as num).toDouble();
    humidade = (l['humidade'] as num).round();
    ultimaLeitura = DateTime.parse(l['medido_em'] as String).toLocal();
    // a placa manda a cada 30 s: 10 min sem nada = sem ligação
    ligado = DateTime.now().difference(ultimaLeitura).inMinutes < 10;
  }

  void _aplicarEvento(Map<String, dynamic> e) {
    final t = DateTime.parse(e['ocorreu_em'] as String).toLocal();
    if (e['tipo'] == 'porta_aberta') {
      portaAbertaDesde = t;
      return;
    }
    portaAbertaDesde = null;
    final dur = Duration(seconds: (e['duracao_s'] as int?) ?? 0);
    final inicio = t.subtract(dur);
    // temperatura mais alta na hora seguinte (das médias de 30 min)
    double maxT = temperatura;
    final dia = _resumos['24/30'] ?? [];
    final perto = dia.where((l) =>
        !l.$1.isBefore(inicio.subtract(const Duration(minutes: 30))) &&
        l.$1.isBefore(inicio.add(const Duration(hours: 1))));
    if (perto.isNotEmpty) {
      maxT = perto.map((l) => l.$2).reduce((a, b) => a > b ? a : b);
    }
    aberturas.add(AberturaPorta(inicio: inicio, duracao: dur, maxTemp: maxT));
    if (dur.inSeconds > 60) {
      alertas.add(AlertaSensor(
        titulo: 'Porta aberta muito tempo',
        detalhe: 'Esteve aberta ${dur.inMinutes} min',
        data: inicio,
      ));
    }
  }

  // Realtime: a app atualiza-se sozinha quando a placa ou outro telemóvel
  // mudam alguma coisa
  void _ouvir() {
    _canal?.unsubscribe();
    _canal = supabase
        .channel('frigu')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'leituras',
          callback: (p) {
            temLeiturasReais = true;
            _aplicarLeitura(p.newRecord);
            notifyListeners();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'eventos',
          callback: (p) {
            _aplicarEvento(p.newRecord);
            notifyListeners();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'itens',
          callback: _aplicarItem,
        )
        .subscribe();
  }

  void _aplicarItem(PostgresChangePayload p) {
    if (p.eventType == PostgresChangeEvent.delete) {
      itens.removeWhere((i) => i.id == '${p.oldRecord['id']}');
    } else {
      final novo = itemDaLinha(p.newRecord);
      final i = itens.indexWhere((x) => x.id == novo.id);
      if (i == -1) {
        itens.add(novo);
      } else {
        // muda o objeto que já existe: os ecrãs abertos continuam a apontar
        // para ele
        final velho = itens[i]
          ..nome = novo.nome
          ..quantidade = novo.quantidade
          ..local = novo.local
          ..aberto = novo.aberto
          ..validade = novo.validade
          ..categoria = novo.categoria
          ..certeza = novo.certeza
          ..motivoSaida = novo.motivoSaida;
        itens[i] = velho;
      }
    }
    notifyListeners();
  }

  // Põe os alimentos de exemplo no Supabase (Demonstração nas Definições)
  Future<String> enviarExemplos() async {
    if (!naNuvem) return 'Entra primeiro na tua conta.';
    try {
      await supabase.from('itens').insert([
        for (final i in itensExemplo()) {...linhaDoItem(i), 'origem': 'manual'},
      ]);
      await carregar();
      return 'Alimentos de exemplo adicionados';
    } catch (e) {
      _erro(e);
      return 'Erro: ${erroEmPortugues(e)}';
    }
  }

  Future<void> sair() async {
    await _canal?.unsubscribe();
    _canal = null;
    await supabase.auth.signOut();
    // volta aos dados falsos até alguém entrar de novo
    naNuvem = false;
    temLeiturasReais = false;
    _resumos.clear();
    itens
      ..clear()
      ..addAll(itensExemplo());
    nomeUtilizador = '';
    eAdmin = false;
    notifyListeners();
  }

  // ---- definições ----

  void mudarDiasAviso(int dias) {
    diasAviso = dias;
    notifyListeners();
  }

  void mudarResumoDiario(bool ligado) {
    resumoDiario = ligado;
    notifyListeners();
  }

  // Devolve uma mensagem de erro, ou null se correu bem
  Future<String?> mudarAlvo(double min, double max) async {
    alvoMin = min;
    alvoMax = max;
    notifyListeners();
    if (!naNuvem) return null;
    try {
      // a placa só lê o máximo (temp_alvo), o termóstato liga acima dele
      final mudadas = await supabase
          .from('configuracao')
          .update({'valor': numeroPt(max).replaceAll(',', '.')})
          .eq('chave', 'temp_alvo')
          .select();
      // o RLS não dá erro: simplesmente não muda nenhuma linha
      if (mudadas.isEmpty) {
        return 'Só o administrador pode mudar a temperatura da placa.';
      }
      return null;
    } catch (e) {
      _erro(e);
      return 'Não foi possível guardar no Supabase.';
    }
  }

  // ---- compras ----

  void adicionarCompra(String nome, String motivo, {TagTom tom = TagTom.neutro}) {
    // não repete o que já está por comprar
    final existe = compras.any(
      (c) => !c.noCarrinho && c.nome.toLowerCase() == nome.toLowerCase(),
    );
    if (existe) return;
    compras.add(Compra(nome: nome, motivo: motivo, tom: tom));
    notifyListeners();
  }

  void alternarCarrinho(Compra c) {
    c.noCarrinho = !c.noCarrinho;
    notifyListeners();
  }

  void limparCarrinho() {
    compras.removeWhere((c) => c.noCarrinho);
    notifyListeners();
  }
}

// O ingrediente corresponde ao item se partilharem uma palavra com 4+ letras
// ("caixa de sobras de arroz" ↔ "Sobras de arroz"); palavras curtas
// ("ovo") comparam com o início do nome ("Ovos").
bool ingredienteCorresponde(Ingrediente ing, Item item) {
  final nomeItem = item.nome.toLowerCase();
  final palavras =
      ing.nome.toLowerCase().split(' ').where((p) => p.length >= 4).toList();
  if (palavras.isEmpty) return nomeItem.startsWith(ing.nome.toLowerCase());
  return palavras.any((p) => nomeItem.contains(p));
}

// uma só instância para a app toda
final Frigorifico frigorifico = Frigorifico();

// Aberturas da porta falsas (relativas a agora, para caberem nas 24 h)
List<AberturaPorta> _aberturasExemplo() {
  final agora = DateTime.now();
  AberturaPorta a(int minAtras, int seg, double max) => AberturaPorta(
    inicio: agora.subtract(Duration(minutes: minAtras)),
    duracao: Duration(seconds: seg),
    maxTemp: max,
  );
  return [
    a(160, 240, 7.4),
    a(330, 40, 4.3),
    a(640, 60, 5.3),
    // dias anteriores (só aparecem em 7 dias)
    a(60 * 30, 90, 5.0),
    a(60 * 52, 30, 4.2),
    a(60 * 100, 300, 6.8),
  ];
}

// Avisos falsos dos sensores
List<AlertaSensor> _alertasExemplo() {
  // a mesma abertura de 4 min das _aberturasExemplo
  return [
    AlertaSensor(
      titulo: 'Porta mal fechada',
      detalhe: 'Chegou a 7,4 °C durante 4 min',
      data: DateTime.now().subtract(const Duration(minutes: 160)),
    ),
  ];
}

// Histórico falso para o ecrã Impacto não começar vazio
List<Evento> _eventosExemplo() {
  final agora = DateTime.now();
  final lista = <Evento>[];

  void usados(int n, int mesAtras) {
    for (int i = 0; i < n; i++) {
      lista.add(Evento(
        itemId: 'h$mesAtras-$i',
        nome: 'Exemplo',
        tipo: TipoEvento.usado,
        // DateTime corrige sozinho o mês 0 para dezembro do ano anterior
        // no mês atual, só até hoje (nada no futuro)
        data: DateTime(
          agora.year,
          agora.month - mesAtras,
          1 + i % (mesAtras == 0 ? agora.day : 28),
        ),
        pesoKg: 0.125,
      ));
    }
  }

  void fora(String nome, String motivo, int mesAtras, int n) {
    lista.add(Evento(
      itemId: 'f$mesAtras-$n',
      nome: nome,
      tipo: TipoEvento.deitadoFora,
      data: DateTime(
        agora.year,
        agora.month - mesAtras,
        mesAtras == 0 ? 1 + n % agora.day : 1 + n,
      ),
      pesoKg: 0.25,
      motivo: motivo,
    ));
  }

  // ontem: fiambre usado a tempo (aparece nos Avisos)
  lista.add(Evento(
    itemId: '7',
    nome: 'Fiambre',
    tipo: TipoEvento.usado,
    data: DateUtils.dateOnly(agora).subtract(const Duration(hours: 4)),
    pesoKg: 0.05,
  ));

  // este mês: 37 usados, 5 deitados fora (88 %)
  usados(37, 0);
  fora('Iogurte natural', 'Passou a validade', 0, 0);
  fora('Iogurte natural', 'Passou a validade', 0, 1);
  fora('Iogurte natural', 'Comprei a mais', 0, 2);
  fora('Fiambre', 'Passou a validade', 0, 3);
  fora('Alface', 'Estragou-se antes', 0, 4);
  // mês passado: 30 usados, 5 deitados fora (86 %)
  usados(30, 1);
  for (int n = 0; n < 5; n++) {
    fora('Iogurte natural', 'Passou a validade', 1, n);
  }
  return lista;
}
