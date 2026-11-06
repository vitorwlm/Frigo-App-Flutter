import 'package:flutter/material.dart';

import '../models/compra.dart';
import '../models/evento.dart';
import '../models/item.dart';
import '../models/receita.dart';
import '../widgets/tag_chip.dart';
import 'dados_exemplo.dart';

// Os dados da app num só sítio, partilhados por todos os ecrãs.
// ChangeNotifier: quando algo muda, chama notifyListeners() e os ecrãs
// que estão a ouvir (ListenableBuilder ou addListener) redesenham-se.
// Mais tarde, estes métodos passam a ler e escrever no Supabase.
class Frigorifico extends ChangeNotifier {
  final List<Item> itens = itensExemplo();
  final List<Receita> receitas = receitasExemplo();
  final List<Evento> eventos = _eventosExemplo();
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

  // chama-se depois de mudar um item à mão (ex.: no ecrã de detalhe)
  void atualizar() => notifyListeners();

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
    }
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
          (item.dias < 0 ? 'Passou a validade' : 'Estragou-se antes'),
    ));
    item.quantidade = 0;
    item.local = Local.acabou;
    notifyListeners();
  }

  void congelar(Item item) {
    item.local = Local.arca;
    notifyListeners();
  }

  // botão Anular: volta ao que estava e apaga o último registo deste item
  void repor(Item item, int quantidade, Local local) {
    item.quantidade = quantidade;
    item.local = local;
    final int i = eventos.lastIndexWhere((e) => e.itemId == item.id);
    if (i != -1) eventos.removeAt(i);
    notifyListeners();
  }

  void adicionar({
    required String nome,
    required int quantidade,
    required String unidade,
    required int dias,
    required String categoria,
  }) {
    final hoje = DateUtils.dateOnly(DateTime.now());
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
      final String chave = ing.nome.length > 4
          ? ing.nome.substring(0, 4).toLowerCase()
          : ing.nome.toLowerCase();
      final candidatos = noFrigorifico
          .where((i) => i.nome.toLowerCase().startsWith(chave))
          .toList()
        ..sort((a, b) => a.dias.compareTo(b.dias));
      if (candidatos.isEmpty) continue;
      usar(candidatos.first, quantidade: ing.necessario(pessoas).round());
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

// uma só instância para a app toda
final Frigorifico frigorifico = Frigorifico();

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
        data: DateTime(agora.year, agora.month - mesAtras, 1 + i % 28),
        pesoKg: 0.125,
      ));
    }
  }

  void fora(String nome, String motivo, int mesAtras, int n) {
    lista.add(Evento(
      itemId: 'f$mesAtras-$n',
      nome: nome,
      tipo: TipoEvento.deitadoFora,
      data: DateTime(agora.year, agora.month - mesAtras, 1 + n),
      pesoKg: 0.25,
      motivo: motivo,
    ));
  }

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
