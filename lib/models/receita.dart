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
  final String plural;
  // quantidade para 1 pessoa
  final double porPessoa;
  // 'unidades' ou 'g'
  final String unidade;
  // quanto tens em casa e dias até expirar (null = não tens).
  // Sem final: o frigorifico atualiza-os a partir do inventário.
  double stock;
  int? dias;
  // azeite, sal… contamos sempre como "tens"
  final bool despensa;

  bool get porUnidade => unidade == 'unidades';

  double necessario(int pessoas) {
    final double total = porPessoa * pessoas;
    // ovos e iogurtes não se partem: arredonda para cima
    return porUnidade ? total.ceilToDouble() : total;
  }

  double falta(int pessoas) {
    if (despensa) return 0;
    final double f = necessario(pessoas) - stock;
    return f > 0 ? f : 0;
  }

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

  // any / every = "algum" / "todos" da lista cumprem a condição
  bool tensTudo(int pessoas) =>
      ingredientes.every((i) => i.falta(pessoas) == 0);

  // quantos alimentos a expirar (≤ 2 dias) a receita aproveita
  int get salva =>
      ingredientes.where((i) => i.dias != null && i.dias! <= 2).length;

  String estado(int pessoas) {
    if (tensTudo(pessoas)) return 'Tens tudo';
    final emFalta = ingredientes.firstWhere((i) => i.falta(pessoas) > 0);
    return 'Falta ${emFalta.nome}';
  }
}
