// * Receitas e ingredientes. Vêm da tabela receitas (o admin cria-as no ecrã
// * Administração); o frigorifico preenche stock e dias de cada ingrediente
// * a partir do inventário, e daí sai o "Tens tudo" / "Falta…" dos ecrãs.

class Ingrediente {
  Ingrediente({
    required this.nome,
    required this.plural,
    required this.porPessoa,
    required this.unidade,
    this.stock = 0,
    this.dias,
    this.despensa = false,
  });

  final String nome;
  // ? plural à parte porque "1 ovo" / "3 ovos" não se faz só com um "s"
  final String plural;
  // ? quantidade para 1 pessoa: assim a receita escala para qualquer número
  // ? de pessoas sem guardar várias versões
  final double porPessoa;
  // ? 'unidades' ou 'g'
  final String unidade;
  // ? quanto tens em casa e dias até expirar (null = não tens).
  // ? Sem final: o frigorifico atualiza-os a partir do inventário
  // ? (_sincronizarReceitas), sempre que algo muda.
  double stock;
  int? dias;
  // ? azeite, sal… contamos sempre como "tens" porque a câmara não os vê
  // ? e quase toda a gente os tem
  final bool despensa;

  bool get porUnidade => unidade == 'unidades';

  double necessario(int pessoas) {
    final double total = porPessoa * pessoas;
    // ? ovos e iogurtes não se partem: arredonda para cima
    return porUnidade ? total.ceilToDouble() : total;
  }

  // ? quanto falta comprar (0 = tens o suficiente); usado pela lista de compras
  double falta(int pessoas) {
    if (despensa) return 0;
    final double f = necessario(pessoas) - stock;
    return f > 0 ? f : 0;
  }

  // ? "3 ovos", "200 g espinafres": o texto que aparece no detalhe da receita
  String texto(int pessoas) {
    if (despensa) return nome;
    final int q = necessario(pessoas).round();
    if (porUnidade) return '$q ${q == 1 ? nome : plural}';
    return '$q $unidade $nome';
  }
}

class Receita {
  const Receita({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.minutos,
    required this.ingredientes,
    required this.passos,
    this.pessoasBase = 2,
    this.dificuldade = 'Fácil',
  });

  final String id;
  final String titulo;
  final String descricao;
  final int minutos;
  final List<Ingrediente> ingredientes;
  final List<String> passos;
  final int pessoasBase;
  final String dificuldade;

  // ? every = "todos" da lista cumprem a condição (any = "algum")
  bool tensTudo(int pessoas) =>
      ingredientes.every((i) => i.falta(pessoas) == 0);

  // ? quantos alimentos a expirar (≤ 2 dias) a receita aproveita: é por isto
  // ? que a receita do dia é escolhida (menos desperdício)
  int get salva =>
      ingredientes.where((i) => i.dias != null && i.dias! <= 2).length;

  // ? texto da etiqueta do cartão da receita
  String estado(int pessoas) {
    if (tensTudo(pessoas)) return 'Tens tudo';
    final emFalta = ingredientes.firstWhere((i) => i.falta(pessoas) > 0);
    return 'Falta ${emFalta.nome}';
  }
}
