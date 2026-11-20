// * O CÉREBRO DA APP: todos os dados e todas as ações num só sítio.
// * Fluxo: o main.dart chama carregar() depois do login → lê tudo do Supabase
// * → liga o Realtime (_ouvir) → os ecrãs leem daqui e chamam os métodos
// * (usar, deitarFora, adicionar…) → cada método muda a lista, grava no
// * Supabase e chama notifyListeners() para os ecrãs se redesenharem.
// * Os ecrãs nunca falam diretamente com o Supabase: passam sempre por aqui.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/compra.dart';
import '../models/evento.dart';
import '../models/item.dart';
import '../models/receita.dart';
import '../widgets/tag_chip.dart';
import '../services/nuvem.dart';

// ? Os 4 estados do cartão de cima do Início (ecrãs 01, 02, 13 e 19 do Figma).
// ? enum em vez de vários bool porque só pode haver um estado de cada vez.
enum EstadoFrigu { ok, temperaturaAlta, semLigacao, portaAberta }

// ? 2.0 -> "2", 2.5 -> "2,5": números à portuguesa (vírgula e sem ,0)
String numeroPt(double v) => v == v.roundToDouble()
    ? v.toInt().toString()
    : v.toStringAsFixed(1).replaceAll('.', ',');

// ? 4.2 -> "4,2 °C"
String graus(double v) => '${v.toStringAsFixed(1).replaceAll('.', ',')} °C';

// ? "há 2 min", "há 3 h": tempo desde a última leitura, para a pessoa saber
// ? se o que vê é recente (usado no Início e no Inventário)
String ha(DateTime t) {
  final int min = DateTime.now().difference(t).inMinutes;
  if (min < 1) return 'agora';
  if (min < 60) return 'há $min min';
  return 'há ${min ~/ 60} h';
}

// ? hora do resumo diário (notificação com o que expira e uma receita)
const String horaResumo = '18:00';

// ? Usei ChangeNotifier (e não setState em cada ecrã) porque vários ecrãs
// ? mostram os mesmos dados: quando algo muda, notifyListeners() avisa todos
// ? os que estão a ouvir (ListenableBuilder ou addListener) e redesenham-se.
class Frigorifico extends ChangeNotifier {
  // ? começam vazios: enchem-se com o Supabase no carregar()
  // ? (final = a lista é sempre a mesma, só muda o conteúdo)
  final List<Item> itens = [];
  final List<Receita> receitas = [];
  // ? dias até expirar por categoria (tabela validades): 'ovos' → 21
  final Map<String, int> validades = {};
  // ? eventos, alertas e compras começam com exemplos para os ecrãs Impacto,
  // ? Avisos e Compras não aparecerem vazios antes de haver dados reais
  final List<Evento> eventos = _eventosExemplo();
  final List<AlertaSensor> alertas = _alertasExemplo();
  final List<Compra> compras = _comprasExemplo();
  // ? ids para itens criados sem Supabase (modo de exemplo)
  int _proximoId = 100;

  // * ---- sensores (falsos até a ESP32 enviar leituras para o Supabase) ----
  double temperatura = 4.2;
  int humidade = 62;
  bool ligado = true;
  // ? DateTime? e não bool: null = porta fechada; com data, sabe-se há
  // ? quanto tempo está aberta (o Início mostra os minutos)
  DateTime? portaAbertaDesde;
  DateTime ultimaLeitura = DateTime.now().subtract(const Duration(minutes: 2));
  final List<AberturaPorta> aberturas = _aberturasExemplo();

  // ? get porque o estado é calculado a partir dos sensores, não se guarda.
  // ? A ordem dos if é a prioridade: sem ligação > porta > temperatura
  EstadoFrigu get estado {
    if (!ligado) return EstadoFrigu.semLigacao;
    if (portaAbertaDesde != null) return EstadoFrigu.portaAberta;
    if (temperatura > alvoMax) return EstadoFrigu.temperaturaAlta;
    return EstadoFrigu.ok;
  }

  // * ---- definições (ecrã 14) ----
  // * avisar quantos dias antes de expirar (1, 2 ou 3)
  int diasAviso = 2;
  bool resumoDiario = true;
  // ? temperatura-alvo em °C
  double alvoMin = 2;
  double alvoMax = 5;

  Frigorifico() {
    _sincronizarReceitas();
  }

  // ? Faço override do notifyListeners para que, antes de qualquer ecrã se
  // ? redesenhar, as receitas fiquem a saber o que há em casa
  @override
  void notifyListeners() {
    _sincronizarReceitas();
    super.notifyListeners();
  }

  // ? copia do inventário para cada ingrediente: quanto há e quando expira
  // ? (assim a Receita consegue dizer "tens tudo" sem conhecer o inventário)
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

  // ? chama-se depois de mudar um item à mão (ex.: no ecrã de detalhe):
  // ? grava-o e avisa os ecrãs
  void atualizar([Item? item]) {
    if (item != null) _guardar(item);
    notifyListeners();
  }

  // * ---- leituras (listas que os ecrãs mostram) ----

  List<Item> get noFrigorifico =>
      itens.where((i) => i.local == Local.frigorifico).toList();

  // ? o que expira em 4 dias ou menos, do mais urgente para o menos
  // ? (cartão "A expirar" do Início)
  List<Item> get aExpirar =>
      noFrigorifico.where((i) => i.dias <= 4).toList()
        ..sort((a, b) => a.dias.compareTo(b.dias));

  int get totalEmCasa => itens.where((i) => i.local != Local.acabou).length;

  // ? A melhor receita para hoje (ODS 12.3): tens tudo e aproveita mais
  // ? alimentos a expirar. null quando ainda não há receitas na base de dados
  // ? Permite devolver null ?
  Receita? get receitaDoDia {
    if (receitas.isEmpty) return null;
    final candidatas = receitas.where((r) => r.tensTudo(r.pessoasBase)).toList()
      ..sort((a, b) => b.salva.compareTo(a.salva));
    return candidatas.isNotEmpty ? candidatas.first : receitas.first;
  }

  // * ---- ações sobre os alimentos ----
  // * Todas seguem o mesmo fluxo: muda o item → _guardar (Supabase) →
  // * regista um Evento (para o Impacto) → notifyListeners (ecrãs)

  void usar(Item item, {int? quantidade}) {
    // ? por defeito: 1 unidade, ou tudo se for em gramas/litros
    // ? (ninguém conta 200 g de espinafres um a um)
    int q = quantidade ?? (item.porUnidade ? 1 : item.quantidade);
    if (q > item.quantidade) q = item.quantidade;
    item.quantidade -= q;
    if (item.quantidade <= 0) {
      item.quantidade = 0;
      item.local = Local.acabou;
      item.motivoSaida = 'consumido';
    }
    _guardar(item);
    _registar(
      Evento(
        itemId: item.id,
        nome: item.nome,
        tipo: TipoEvento.usado,
        data: DateTime.now(),
        pesoKg: item.pesoDe(q),
      ),
    );
    notifyListeners();
  }

  void usarTudo(Item item) => usar(item, quantidade: item.quantidade);

  void deitarFora(Item item, {String? motivo}) {
    _registar(
      Evento(
        itemId: item.id,
        nome: item.nome,
        tipo: TipoEvento.deitadoFora,
        data: DateTime.now(),
        pesoKg: item.pesoDe(item.quantidade),
        motivo:
            motivo ??
            (item.dias <= 0 ? 'Passou a validade' : 'Estragou-se antes'),
      ),
    );
    item.quantidade = 0;
    item.local = Local.acabou;
    item.motivoSaida = 'desperdicado';
    _guardar(item);
    notifyListeners();
  }

  // ? botão Anular da snackbar: volta ao que estava e apaga o último registo
  // ? deste item, para o Impacto não contar uma ação que foi desfeita
  void repor(Item item, int quantidade, Local local) {
    item.quantidade = quantidade;
    item.local = local;
    item.motivoSaida = null;
    _guardar(item);
    final int i = eventos.lastIndexWhere((e) => e.itemId == item.id);
    if (i != -1) _anular(eventos.removeAt(i));
    notifyListeners();
  }

  // ? Junta o evento à lista (o Impacto muda já) e grava-o na tabela
  // ? historico por trás, sem await, como o _guardar dos itens
  void _registar(Evento e) {
    eventos.add(e);
    if (!naNuvem) return;
    supabase
        .from('historico')
        .insert(linhaDoEvento(e))
        .then((_) {}, onError: (Object erro) => _erro(erro));
  }

  // ? Anular: apaga a linha do historico. Procuro-a pelo nome e pela hora
  // ? exata (com microssegundos), que é a app que envia no _registar, por
  // ? isso não preciso de esperar pelo id que o Supabase dá.
  // ! Se carregarem Anular antes de o insert chegar ao Supabase (menos de
  // ! 1 s), o delete não encontra nada e a linha fica. Aceitei isto para o
  // ! código ficar simples.
  void _anular(Evento e) {
    if (!naNuvem) return;
    supabase
        .from('historico')
        .delete()
        .eq('nome', e.nome)
        .eq('criado_em', e.data.toUtc().toIso8601String())
        .then((_) {}, onError: (Object erro) => _erro(erro));
  }

  // ? Chamado pelo ecrã Adicionar. Future porque espera pelo Supabase para
  // ? ter o id verdadeiro do item novo
  Future<void> adicionar({
    required String nome,
    required int quantidade,
    required String unidade,
    required int dias,
    required String categoria,
  }) async {
    final hoje = DateUtils.dateOnly(DateTime.now());
    if (naNuvem) {
      // ? insert(...).select().single() porque preciso da linha criada, com o
      // ? id que o Supabase lhe deu (sem o id não dava para a mudar depois)
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
        // ? o Realtime pode já o ter trazido: assim não fica repetido
        if (!itens.any((i) => i.id == novo.id)) itens.add(novo);
      } catch (e) {
        _erro(e);
      }
      notifyListeners();
      return;
    }
    // ? sem Supabase (exemplo): só fica na memória do telemóvel
    itens.add(
      Item(
        id: '${_proximoId++}',
        nome: nome,
        quantidade: quantidade,
        unidade: unidade,
        validade: hoje.add(Duration(days: dias)),
        entrada: hoje,
        categoria: categoria,
      ),
    );
    notifyListeners();
  }

  // ? Botão "Cozinhei" das Receitas: tira do inventário o que a receita usa.
  // ? Ordena por dias para gastar primeiro o que expira mais cedo (ODS 12.3)
  // ? Gasta de vários itens se for preciso: 2 iogurtes da receita podem
  // ? estar em 2 itens com 1 cada (antes só gastava do primeiro)
  void cozinhar(Receita r, int pessoas) {
    for (final ing in r.ingredientes) {
      if (ing.despensa) continue;
      final candidatos =
          noFrigorifico
              .where((i) => i.quantidade > 0 && ingredienteCorresponde(ing, i))
              .toList()
            ..sort((a, b) => a.dias.compareTo(b.dias));
      int falta = ing.necessario(pessoas).round();
      for (final item in candidatos) {
        if (falta <= 0) break;
        // ? usar() já corta no que há, por isso guardo o antes para saber
        // ? quanto saiu mesmo deste item
        final int antes = item.quantidade;
        usar(item, quantidade: falta);
        falta -= antes - item.quantidade;
      }
    }
  }

  // * ---- confirmar o que a câmara viu (ecrã 12) ----
  // * O Gemini pode enganar-se: a certeza passa a 100 quando a pessoa confirma

  void confirmar(Item item, String nome) {
    item.nome = nome;
    item.certeza = 100;
    _guardar(item);
    notifyListeners();
  }

  // ? "Não está no frigorífico": tira o item e devolve a posição, para o
  // ? Anular o conseguir pôr outra vez no mesmo sítio da lista
  int remover(Item item) {
    final int i = itens.indexOf(item);
    itens.remove(item);
    if (naNuvem) {
      // ! Não apago a linha: fica com quantidade 0 e sem motivo, porque não
      // ! foi usado nem deitado fora (a câmara enganou-se) e não conta no Impacto
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

  // * ---- estados do Início ----
  // * Enquanto a placa não envia dados, estes métodos fingem os sensores
  // * para dar para mostrar e testar os 4 estados do cartão do Início

  // ? Muda os sensores para mostrar um estado (secção Demonstração das
  // ? Definições), útil para a apresentação sem o frigorífico ligado
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

  // ? "Já fechei a porta": a temperatura volta a descer
  void fecharPorta() {
    portaAbertaDesde = null;
    temperatura = 4.8;
    ultimaLeitura = DateTime.now();
    notifyListeners();
  }

  // ? "Tentar ligar de novo": espera pela placa (por agora, 2 s a fingir)
  Future<void> reconectar() async {
    await Future.delayed(const Duration(seconds: 2));
    ligado = true;
    ultimaLeitura = DateTime.now();
    notifyListeners();
  }

  // ? Temperatura falsa, só usada sem leituras reais: uma base que sobe e
  // ? desce ao longo do dia (sin) + o pico de cada abertura da porta, que
  // ? desce ao longo de ~1 h (exp), para o gráfico parecer verdadeiro
  double temperaturaEm(DateTime t) {
    double v = 3.9 + 0.3 * sin(t.hour / 24 * 2 * pi);
    for (final a in aberturas) {
      final double min = t.difference(a.inicio).inMinutes.toDouble();
      if (min >= 0 && min <= 60) v += (a.maxTemp - 3.9) * exp(-min / 12);
    }
    return v;
  }

  // ? Leituras de [horas] para trás até agora, uma a cada [passo] minutos.
  // ? Usado pelo gráfico do Histórico da temperatura
  List<Leitura> leituras(int horas, int passo) {
    final reais = _resumos['$horas/$passo'];
    if (temLeiturasReais && reais != null && reais.isNotEmpty) {
      // ? médias do Supabase + o valor de agora no fim, para a linha do
      // ? gráfico acabar no mesmo número que aparece no cartão
      return [...reais, Leitura(DateTime.now(), temperatura)];
    }
    final agora = DateTime.now();
    final lista = <Leitura>[];
    for (int m = horas * 60; m > 0; m -= passo) {
      final t = agora.subtract(Duration(minutes: m));
      lista.add(Leitura(t, temperaturaEm(t)));
    }
    // ? a última é o valor de agora (igual ao cartão do Início)
    lista.add(Leitura(agora, temperatura));
    return lista;
  }

  // * ---- editar um alimento (botão Editar do detalhe) ----

  void editar(
    Item item, {
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

  // * ---- Supabase ----
  // * Estado da ligação e do utilizador; preenchidos no carregar()

  String nomeUtilizador = '';
  String email = '';
  bool eAdmin = false;
  // ! true depois de carregar o inventário do Supabase: só então se escreve
  // ! lá, para os dados de exemplo nunca irem parar à base de dados
  bool naNuvem = false;
  // ? false enquanto a placa não enviou nenhuma leitura: ficam os sensores
  // ? falsos
  bool temLeiturasReais = false;
  String? erroNuvem;
  // ? mostra as Boas-vindas a seguir a criar conta (o main.dart ouve isto)
  bool verBoasVindas = false;
  // ? médias do gráfico guardadas por "horas/passo" ('24/30', '168/60')
  // ? para não as pedir outra vez ao trocar entre 24 h e 7 dias
  final Map<String, List<Leitura>> _resumos = {};
  RealtimeChannel? _canal;

  // ? Um só sítio para os erros: guarda o último (as Definições mostram-no)
  // ? e escreve-o na consola para eu ver ao testar
  void _erro(Object e) {
    erroNuvem = e.toString();
    debugPrint('Supabase: $e');
  }

  // ! Grava as colunas do item sem await, de propósito: a app muda logo e
  // ! não fica parada à espera da internet; se falhar, só regista o erro
  void _guardar(Item item) {
    if (!naNuvem) return;
    supabase
        .from('itens')
        .update(linhaDoItem(item))
        .eq('id', int.parse(item.id))
        .then((_) {}, onError: (Object e) => _erro(e));
  }

  // * 1.º passo depois do login (chamado pelo _Arranque do main.dart):
  // * perfil → inventário → temperatura-alvo → receitas → validades →
  // * compras → sensores → liga o Realtime
  Future<void> carregar() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    email = user.email ?? '';
    try {
      // ! perfil (criado pelo trigger ao registar); maybeSingle porque
      // ! pode ainda não existir e assim não dá erro
      final perfil = await supabase
          .from('perfis')
          .select('nome, role')
          .eq('id', user.id)
          .maybeSingle();
      nomeUtilizador =
          (perfil?['nome'] as String?) ??
          (user.userMetadata?['nome'] as String?) ??
          email.split('@').first;
      eAdmin = perfil?['role'] == 'admin';

      // ? inventário: o que está em casa + o que acabou nos últimos 30 dias
      // ? (os que acabaram servem para os Avisos e o separador Acabou)
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

      // ? temperatura-alvo da placa (a mesma que o termóstato da ESP32 usa)
      final conf = await supabase
          .from('configuracao')
          .select('valor')
          .eq('chave', 'temp_alvo')
          .maybeSingle();
      if (conf != null) {
        alvoMax = double.tryParse(conf['valor'] as String) ?? alvoMax;
      }

      await _carregarReceitas();
      await _carregarValidades();
      await _carregarCompras();
      await _carregarHistorico();
      await _carregarSensores();
      _ouvir();
      erroNuvem = null;
    } catch (e) {
      _erro(e);
    }
    notifyListeners();
  }

  // ? receitas (tabela receitas, esquema_receitas.sql)
  // ? try próprio: se esta tabela falhar, o resto da app continua a carregar
  Future<void> _carregarReceitas() async {
    try {
      final linhas = await supabase.from('receitas').select().order('titulo');
      receitas
        ..clear()
        ..addAll(linhas.map(receitaDaLinha));
    } catch (e) {
      _erro(e);
    }
  }

  // ? dias por categoria (tabela validades, esquema_fase4.sql)
  Future<void> _carregarValidades() async {
    try {
      final linhas = await supabase
          .from('validades')
          .select()
          .order('categoria');
      validades.clear();
      for (final l in linhas) {
        validades[l['categoria'] as String] = l['dias'] as int;
      }
    } catch (e) {
      _erro(e);
    }
  }

  // ? lista de compras partilhada (tabela compras, esquema_compras.sql)
  Future<void> _carregarCompras() async {
    try {
      final linhas = await supabase.from('compras').select().order('criada_em');
      compras
        ..clear()
        ..addAll(linhas.map(compraDaLinha));
    } catch (e) {
      // ? sem a tabela (SQL ainda não corrido): fica a lista de exemplo
      // ? em vez de a app deixar de abrir
      _erro(e);
    }
  }

  // ? Histórico do Impacto desde 1 de janeiro do ano passado (o Impacto
  // ? compara com o mês e o ano anteriores; mais para trás não se usa)
  Future<void> _carregarHistorico() async {
    try {
      final desde = DateTime(DateTime.now().year - 1).toUtc();
      final linhas = await supabase
          .from('historico')
          .select()
          .gte('criado_em', desde.toIso8601String())
          .order('criado_em');
      // ? troca os exemplos pelos dados reais (mesmo que venha vazio: assim o
      // ? Impacto mostra "sem dados" em vez de números inventados)
      eventos
        ..clear()
        ..addAll(linhas.map(eventoDaLinha));
    } catch (e) {
      // ? sem a tabela (SQL ainda não corrido): ficam os exemplos
      _erro(e);
    }
  }

  // ? Última leitura + médias do gráfico + eventos da porta da última semana.
  // ! try próprio (como as outras): se falhar, o carregar() continua e liga
  // ! o Realtime na mesma (antes saltava o _ouvir() e a app deixava de se
  // ! atualizar sozinha)
  Future<void> _carregarSensores() async {
    try {
      final ultima = await supabase
          .from('leituras')
          .select()
          .order('medido_em', ascending: false)
          .limit(1)
          .maybeSingle();
      // ? sem leituras (placa ainda não ligada): ficam os sensores falsos
      // ? para os ecrãs terem o que mostrar
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
    } catch (e) {
      _erro(e);
    }
  }

  // ? Médias por intervalo (função leituras_resumo do esquema_app.sql).
  // ? Uso rpc em vez de ler a tabela toda porque são 2880 leituras por dia:
  // ? o Supabase faz as médias e só manda ~48 pontos para o gráfico
  Future<void> carregarLeituras(int horas, int passo) async {
    final desde = DateTime.now().subtract(Duration(hours: horas)).toUtc();
    try {
      final r = await supabase.rpc(
        'leituras_resumo',
        params: {'desde': desde.toIso8601String(), 'passo_min': passo},
      );
      _resumos['$horas/$passo'] = [
        for (final l in r as List)
          Leitura(
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
    // ? a placa manda a cada 30 s: 10 min sem nada = sem ligação
    // ? (dá margem para falhas curtas do Wi-Fi sem assustar a pessoa)
    ligado = DateTime.now().difference(ultimaLeitura).inMinutes < 10;
  }

  // ? Um evento da porta muda o cartão do Início (porta aberta) ou entra no
  // ? gráfico como abertura; acima de 60 s também vira um aviso
  void _aplicarEvento(Map<String, dynamic> e) {
    final t = DateTime.parse(e['ocorreu_em'] as String).toLocal();
    if (e['tipo'] == 'porta_aberta') {
      portaAbertaDesde = t;
      return;
    }
    portaAbertaDesde = null;
    final dur = Duration(seconds: (e['duracao_s'] as int?) ?? 0);
    final inicio = t.subtract(dur);
    // ? temperatura mais alta na hora seguinte (das médias de 30 min),
    // ? para o gráfico mostrar quanto aqueceu com aquela abertura
    double maxT = temperatura;
    final dia = _resumos['24/30'] ?? [];
    final perto = dia.where(
      (l) =>
          !l.hora.isBefore(inicio.subtract(const Duration(minutes: 30))) &&
          l.hora.isBefore(inicio.add(const Duration(hours: 1))),
    );
    if (perto.isNotEmpty) {
      maxT = perto.map((l) => l.temperatura).reduce((a, b) => a > b ? a : b);
    }
    aberturas.add(AberturaPorta(inicio: inicio, duracao: dur, maxTemp: maxT));
    if (dur.inSeconds > 60) {
      alertas.add(
        AlertaSensor(
          titulo: 'Porta aberta muito tempo',
          detalhe: 'Esteve aberta ${dur.inMinutes} min',
          data: inicio,
        ),
      );
    }
  }

  // ? Realtime: a app atualiza-se sozinha quando a placa ou outro telemóvel
  // ? mudam alguma coisa. Um só canal para as 6 tabelas, em vez de um por
  // ? tabela, para ter uma só ligação aberta
  void _ouvir() {
    // ! fecha o canal antigo para não receber tudo a dobrar
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
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'compras',
          callback: _aplicarCompra,
        )
        // ? o admin mudou receitas ou validades: volta a ler tudo (são poucas
        // ? linhas, é mais simples do que atualizar uma a uma)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'receitas',
          callback: (_) => _carregarReceitas().then((_) => notifyListeners()),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'validades',
          callback: (_) => _carregarValidades().then((_) => notifyListeners()),
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
        // ? Muda o objeto que já existe em vez de o trocar, porque os ecrãs
        // ? abertos (ex.: o detalhe) continuam a apontar para ele
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

  // ? outro telemóvel mudou a lista de compras (lista partilhada)
  void _aplicarCompra(PostgresChangePayload p) {
    if (p.eventType == PostgresChangeEvent.delete) {
      compras.removeWhere((c) => c.id == '${p.oldRecord['id']}');
    } else {
      final nova = compraDaLinha(p.newRecord);
      final i = compras.indexWhere((c) => c.id == nova.id);
      if (i == -1) {
        compras.add(nova);
      } else {
        compras[i].noCarrinho = nova.noCarrinho;
      }
    }
    notifyListeners();
  }

  // * ---- Demonstração (Definições, só o admin) ----
  // * As duas chamam uma função SQL (dados_demo.sql) porque a app não tem
  // * permissão para apagar itens nem para escrever leituras da placa.
  // * Devolvem a mensagem para a snackbar.

  // ? Inventário, histórico do Impacto, compras, 7 dias de temperatura e
  // ? aberturas da porta, tudo de uma vez
  Future<String> porDadosFalsos() async {
    if (!naNuvem) return 'Entra primeiro na tua conta.';
    try {
      await supabase.rpc('por_dados_falsos');
      await carregar();
      return 'Dados falsos adicionados';
    } catch (e) {
      _erro(e);
      return 'Erro: ${erroEmPortugues(e)}';
    }
  }

  // ! Apaga itens, histórico, fotos, compras, leituras e eventos de TODAS as
  // ! contas (o frigorífico é partilhado). Ficam as contas, as receitas, as
  // ! validades e a temperatura-alvo. O ecrã pede confirmação antes.
  Future<String> apagarDados() async {
    if (!naNuvem) return 'Entra primeiro na tua conta.';
    try {
      await supabase.rpc('apagar_dados');
      // ? sem leituras, o carregar() não mexe nos sensores: volto eu aos
      // ? falsos, senão ficava a última temperatura real no ecrã
      _sensoresDeExemplo();
      await carregar();
      return 'Dados apagados';
    } catch (e) {
      _erro(e);
      return 'Erro: ${erroEmPortugues(e)}';
    }
  }

  void _sensoresDeExemplo() {
    temLeiturasReais = false;
    _resumos.clear();
    temperatura = 4.2;
    humidade = 62;
    ligado = true;
    portaAbertaDesde = null;
    ultimaLeitura = DateTime.now().subtract(const Duration(minutes: 2));
    aberturas
      ..clear()
      ..addAll(_aberturasExemplo());
    alertas
      ..clear()
      ..addAll(_alertasExemplo());
  }

  // ? Botão Sair das Definições. Depois do signOut, o _PortaoLogin do
  // ? main.dart vê que não há sessão e volta ao Login sozinho
  Future<void> sair() async {
    await _canal?.unsubscribe();
    _canal = null;
    await supabase.auth.signOut();
    // ? limpa tudo para a próxima conta não ver os dados desta
    naNuvem = false;
    temLeiturasReais = false;
    _resumos.clear();
    itens.clear();
    receitas.clear();
    validades.clear();
    compras
      ..clear()
      ..addAll(_comprasExemplo());
    eventos
      ..clear()
      ..addAll(_eventosExemplo());
    nomeUtilizador = '';
    eAdmin = false;
    notifyListeners();
  }

  // * ---- definições ----

  // ? Estas 2 definições são do telemóvel (não da conta), por isso ficam no
  // ? SharedPreferences e não no Supabase. O main.dart chama isto antes do
  // ? 1.º ecrã para não se ver o valor padrão a piscar.
  Future<void> carregarDefinicoes() async {
    final prefs = await SharedPreferences.getInstance();
    diasAviso = prefs.getInt('diasAviso') ?? diasAviso;
    resumoDiario = prefs.getBool('resumoDiario') ?? resumoDiario;
    notifyListeners();
  }

  // ? muda já na memória (ecrã responde logo) e grava em segundo plano
  void mudarDiasAviso(int dias) {
    diasAviso = dias;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setInt('diasAviso', dias));
  }

  void mudarResumoDiario(bool ligado) {
    resumoDiario = ligado;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (p) => p.setBool('resumoDiario', ligado),
    );
  }

  // ? Devolve uma mensagem de erro, ou null se correu bem (o ecrã das
  // ? Definições mostra-a numa snackbar)
  Future<String?> mudarAlvo(double min, double max) async {
    alvoMin = min;
    alvoMax = max;
    notifyListeners();
    if (!naNuvem) return null;
    try {
      // ? só envio o máximo (temp_alvo) porque é o único valor que a placa
      // ? lê: o termóstato liga a ventoinha acima dele
      final mudadas = await supabase
          .from('configuracao')
          .update({'valor': numeroPt(max).replaceAll(',', '.')})
          .eq('chave', 'temp_alvo')
          .select();
      // ! .select() porque o RLS não dá erro: simplesmente não muda nenhuma
      // ! linha; uma lista vazia quer dizer que não és admin
      if (mudadas.isEmpty) {
        return 'Só o administrador pode mudar a temperatura da placa.';
      }
      return null;
    } catch (e) {
      _erro(e);
      return 'Não foi possível guardar no Supabase.';
    }
  }

  // ? Botão "Tirar foto agora" (Adicionar e Última foto). A app não chama a
  // ? Edge Function analisar-foto diretamente porque ela precisa da foto, e
  // ? quem a tira é a câmara da placa. Por isso grava a hora do pedido em
  // ? configuracao.pedir_foto; a ESP32 vê que mudou (de 10 em 10 s), tira a
  // ? foto e manda-a à analisar-foto (pedido_foto.sql e rede.cpp).
  // ? Devolve null se o pedido foi gravado, ou a mensagem de erro.
  Future<String?> pedirFoto() async {
    if (!naNuvem) return 'Só funciona com o frigorífico ligado à conta.';
    try {
      final mudadas = await supabase
          .from('configuracao')
          .update({'valor': DateTime.now().toUtc().toIso8601String()})
          .eq('chave', 'pedir_foto')
          .select();
      // ! lista vazia = a linha não existe ou falta a política "app pede foto"
      if (mudadas.isEmpty) return 'A câmara ainda não aceita pedidos da app.';
      return null;
    } catch (e) {
      _erro(e);
      return 'Não foi possível falar com o frigorífico.';
    }
  }

  // * ---- administração (ecrã Admin) ----
  // * Devolvem null se correu bem, ou a mensagem de erro para mostrar.
  // * Só o admin escreve em receitas e validades (RLS do esquema_fase4.sql):
  // * a segurança está no Supabase, não só em esconder o ecrã.

  // ? id vazio = receita nova (insert); senão muda a que existe (update).
  // ? Um só método para os dois casos porque o ecrã Editar receita é o mesmo
  Future<String?> guardarReceita(Receita r) async {
    try {
      if (r.id.isEmpty) {
        await supabase.from('receitas').insert(linhaDaReceita(r));
      } else {
        // ! .select() devolve as linhas mudadas: vazio = o RLS não deixou
        // ! (o update sozinho não dava erro e eu não saberia)
        final mudadas = await supabase
            .from('receitas')
            .update(linhaDaReceita(r))
            .eq('id', int.parse(r.id))
            .select('id');
        if (mudadas.isEmpty) return 'Só o administrador pode mudar receitas.';
      }
      await _carregarReceitas();
      notifyListeners();
      return null;
    } catch (e) {
      _erro(e);
      return 'Não foi possível guardar: ${erroEmPortugues(e)}';
    }
  }

  // ! .select('id') pela mesma razão: saber se o RLS deixou apagar
  Future<String?> apagarReceita(Receita r) async {
    try {
      final apagadas = await supabase
          .from('receitas')
          .delete()
          .eq('id', int.parse(r.id))
          .select('id');
      if (apagadas.isEmpty) return 'Só o administrador pode apagar receitas.';
      receitas.removeWhere((x) => x.id == r.id);
      notifyListeners();
      return null;
    } catch (e) {
      _erro(e);
      return 'Não foi possível apagar: ${erroEmPortugues(e)}';
    }
  }

  // ? upsert = insert, ou update se a categoria já existir: o mesmo botão
  // ? Guardar serve para criar e para mudar
  Future<String?> guardarValidade(String categoria, int dias) async {
    try {
      await supabase.from('validades').upsert({
        'categoria': categoria,
        'dias': dias,
      });
      validades[categoria] = dias;
      notifyListeners();
      return null;
    } catch (e) {
      _erro(e);
      return 'Não foi possível guardar: ${erroEmPortugues(e)}';
    }
  }

  // ? Os itens desta categoria ficam sem categoria (on delete set null na
  // ? base de dados), por isso apagar não apaga alimentos
  Future<String?> apagarValidade(String categoria) async {
    try {
      final apagadas = await supabase
          .from('validades')
          .delete()
          .eq('categoria', categoria)
          .select('categoria');
      if (apagadas.isEmpty) return 'Só o administrador pode apagar categorias.';
      validades.remove(categoria);
      notifyListeners();
      return null;
    } catch (e) {
      _erro(e);
      return 'Não foi possível apagar: ${erroEmPortugues(e)}';
    }
  }

  // * ---- compras ----
  // * A app muda a lista logo (não fica à espera) e grava no Supabase por trás,
  // * porque no supermercado a internet pode ser fraca e a lista tem de reagir.

  void adicionarCompra(
    String nome,
    String motivo, {
    TagTom tom = TagTom.neutro,
  }) {
    // ? não repete o que já está por comprar (o mesmo item pode ser pedido
    // ? pelo Inventário e pelas Receitas)
    final existe = compras.any(
      (c) => !c.noCarrinho && c.nome.toLowerCase() == nome.toLowerCase(),
    );
    if (existe) return;
    final nova = Compra(nome: nome, motivo: motivo, tom: tom);
    compras.add(nova);
    notifyListeners();
    if (!naNuvem) return;
    supabase
        .from('compras')
        .insert(linhaDaCompra(nova))
        .select('id')
        .single()
        .then((l) {
          nova.id = '${l['id']}';
          // ? o Realtime pode já a ter trazido: fica só uma
          compras.removeWhere((c) => c != nova && c.id == nova.id);
          notifyListeners();
        }, onError: (Object e) => _erro(e));
  }

  void alternarCarrinho(Compra c) {
    c.noCarrinho = !c.noCarrinho;
    notifyListeners();
    if (!naNuvem || c.id == null) return;
    supabase
        .from('compras')
        .update({'no_carrinho': c.noCarrinho})
        .eq('id', int.parse(c.id!))
        .then((_) {}, onError: (Object e) => _erro(e));
  }

  void limparCarrinho() {
    // ? apaga pelos ids (e não por no_carrinho = true), para não levar
    // ? algo que outra pessoa acabou de marcar
    final ids = [
      for (final c in compras)
        if (c.noCarrinho && c.id != null) int.parse(c.id!),
    ];
    compras.removeWhere((c) => c.noCarrinho);
    notifyListeners();
    if (!naNuvem || ids.isEmpty) return;
    supabase
        .from('compras')
        .delete()
        .inFilter('id', ids)
        .then((_) {}, onError: (Object e) => _erro(e));
  }
}

// ? Fora da classe porque não depende dos dados e os testes usam-na sozinha.
// ? O ingrediente corresponde ao item se partilharem uma palavra com 4+ letras
// ? ("caixa de sobras de arroz" ↔ "Sobras de arroz"); palavras curtas
// ? ("ovo") comparam com o início do nome ("Ovos").
bool ingredienteCorresponde(Ingrediente ing, Item item) {
  final nomeItem = item.nome.toLowerCase();
  final palavras = ing.nome
      .toLowerCase()
      .split(' ')
      .where((p) => p.length >= 4)
      .toList();
  if (palavras.isEmpty) return nomeItem.startsWith(ing.nome.toLowerCase());
  return palavras.any((p) => nomeItem.contains(p));
}

// ? Uma só instância para a app toda: todos os ecrãs importam este
// ? "frigorifico" e veem os mesmos dados
final Frigorifico frigorifico = Frigorifico();

// ? Lista de compras de exemplo (antes de entrar na conta ou se a tabela
// ? compras ainda não existir)
List<Compra> _comprasExemplo() => [
  Compra(nome: 'Manteiga', motivo: 'Acabou no frigorífico'),
  Compra(nome: 'Farinha', motivo: 'Para as panquecas', tom: TagTom.marca),
  Compra(
    nome: 'Iogurte natural ×2',
    motivo: 'Pack mais pequeno',
    tom: TagTom.aviso,
  ),
  Compra(nome: 'Tomates', motivo: 'Acabou no frigorífico', noCarrinho: true),
];

// ? Aberturas da porta falsas, relativas a agora para caberem sempre nas
// ? últimas 24 h do gráfico, seja a que horas for
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
    // ? dias anteriores (só aparecem em 7 dias)
    a(60 * 30, 90, 5.0),
    a(60 * 52, 30, 4.2),
    a(60 * 100, 300, 6.8),
  ];
}

// ? Avisos falsos dos sensores (até a placa enviar eventos)
List<AlertaSensor> _alertasExemplo() {
  // ? a mesma abertura de 4 min das _aberturasExemplo
  return [
    AlertaSensor(
      titulo: 'Porta mal fechada',
      detalhe: 'Chegou a 7,4 °C durante 4 min',
      data: DateTime.now().subtract(const Duration(minutes: 160)),
    ),
  ];
}

// ? Histórico falso para o ecrã Impacto não começar vazio (os gráficos do
// ? mês precisam de dados para se perceber a ideia)
List<Evento> _eventosExemplo() {
  final agora = DateTime.now();
  final lista = <Evento>[];

  void usados(int n, int mesAtras) {
    for (int i = 0; i < n; i++) {
      lista.add(
        Evento(
          itemId: 'h$mesAtras-$i',
          nome: 'Exemplo',
          tipo: TipoEvento.usado,
          // ? DateTime corrige sozinho o mês 0 para dezembro do ano anterior;
          // ? no mês atual, os dias vão só até hoje (nada no futuro)
          data: DateTime(
            agora.year,
            agora.month - mesAtras,
            1 + i % (mesAtras == 0 ? agora.day : 28),
          ),
          pesoKg: 0.125,
        ),
      );
    }
  }

  void fora(String nome, String motivo, int mesAtras, int n) {
    lista.add(
      Evento(
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
      ),
    );
  }

  // ? ontem: fiambre usado a tempo (aparece nos Avisos)
  lista.add(
    Evento(
      itemId: '7',
      nome: 'Fiambre',
      tipo: TipoEvento.usado,
      data: DateUtils.dateOnly(agora).subtract(const Duration(hours: 4)),
      pesoKg: 0.05,
    ),
  );

  // ? este mês: 37 usados, 5 deitados fora (88 %)
  usados(37, 0);
  fora('Iogurte natural', 'Passou a validade', 0, 0);
  fora('Iogurte natural', 'Passou a validade', 0, 1);
  fora('Iogurte natural', 'Comprei a mais', 0, 2);
  fora('Fiambre', 'Passou a validade', 0, 3);
  fora('Alface', 'Estragou-se antes', 0, 4);
  // ? mês passado: 30 usados, 5 deitados fora (86 %)
  usados(30, 1);
  for (int n = 0; n < 5; n++) {
    fora('Iogurte natural', 'Passou a validade', 1, n);
  }
  return lista;
}
