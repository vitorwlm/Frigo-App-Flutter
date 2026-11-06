import '../widgets/tag_chip.dart';

// Uma linha da lista de compras
class Compra {
  Compra({
    required this.nome,
    required this.motivo,
    this.tom = TagTom.neutro,
    this.noCarrinho = false,
  });

  final String nome;
  // porque está na lista: 'Acabou no frigorífico', 'Para as panquecas'…
  final String motivo;
  final TagTom tom;
  bool noCarrinho;
}
