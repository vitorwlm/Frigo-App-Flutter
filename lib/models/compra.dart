import '../widgets/tag_chip.dart';

// * Uma linha da lista de compras (ecrã Compras). Criada pelo botão Adicionar
// * das Compras, pelo "Acabou" do Inventário ou pelo que falta numa receita;
// * convertida de/para a tabela compras no services/nuvem.dart
class Compra {
  Compra({
    this.id,
    required this.nome,
    required this.motivo,
    this.tom = TagTom.neutro,
    this.noCarrinho = false,
  });

  // ? String? porque a compra aparece logo na lista e só tem id quando o
  // ? Supabase a gravar (null até lá)
  String? id;
  final String nome;
  // ? porque está na lista: 'Acabou no frigorífico', 'Para as panquecas'…
  // ? (ajuda a lembrar no supermercado para que é)
  final String motivo;
  // ? cor da etiqueta do motivo (aviso, marca, neutro)
  final TagTom tom;
  // ? sem final porque muda ao tocar na linha (vai para "No carrinho")
  bool noCarrinho;
}
