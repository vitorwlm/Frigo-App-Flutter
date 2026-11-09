import 'package:flutter/material.dart';

// * Um alimento do inventário. Vem da tabela itens (services/nuvem.dart
// * converte) e é usado por quase todos os ecrãs: Início, Inventário, detalhe.

// ? onde está o alimento (separadores do Inventário: Frigorífico / Acabou).
// ? enum e não bool para dar para acrescentar outros sítios mais tarde
enum Local { frigorifico, acabou }

class Item {
  Item({
    required this.id,
    required this.nome,
    required this.quantidade,
    required this.unidade,
    required this.validade,
    required this.entrada,
    this.local = Local.frigorifico,
    this.aberto = false,
    this.categoria = 'Outros',
    this.prateleira = 'Prateleira do meio',
    this.certeza = 100,
    this.alternativas = const {},
    this.motivoSaida,
  });

  final String id;
  // ? sem final: muda quando confirmas o que a câmara viu
  // ? (os campos final nunca mudam depois de o item ser criado)
  String nome;
  // ? sem final: estes mudam quando usas ou abres
  int quantidade;
  Local local;
  bool aberto;
  final String unidade;
  // ? sem final: podem mudar no Editar do detalhe
  DateTime validade;
  // ? dia em que entrou no frigorífico (câmara ou à mão): com a validade dá
  // ? a barra de cor de quanto tempo de vida ainda tem
  final DateTime entrada;
  String categoria;
  final String prateleira;
  // ? 0–100, vem do Gemini; passa a 100 quando confirmas. Abaixo de um
  // ? certo valor o Inventário pergunta "É isto?"
  int certeza;
  // ? outros palpites do Gemini: nome → certeza (ecrã 12)
  final Map<String, int> alternativas;
  // ? porque saiu: 'consumido' ou 'desperdicado' (coluna motivo_saida),
  // ? é o que o Impacto usa para contar o desperdício
  String? motivoSaida;

  // ? get = propriedade calculada, usa-se como item.dias (sem parênteses).
  // ? Calculado e não guardado porque muda sozinho de um dia para o outro
  int get dias {
    // ! DateUtils.dateOnly tira as horas, senão às 23h o "amanhã" dava 0 dias
    final hoje = DateUtils.dateOnly(DateTime.now());
    return DateUtils.dateOnly(validade).difference(hoje).inDays;
  }

  // ! vida total do alimento (entrada → validade), para a percentagem da
  // ! barra de cor; nunca menos de 1 para não dividir por 0
  int get diasTotais {
    final total = DateUtils.dateOnly(validade)
        .difference(DateUtils.dateOnly(entrada))
        .inDays;
    return total < 1 ? 1 : total;
  }

  bool get porUnidade => unidade == 'unidades';

  // ? Peso aproximado, para o Impacto (kg salvos e CO2). Aproximado porque a
  // ? câmara não pesa nada: chega para mostrar a ordem de grandeza
  double pesoDe(int qtd) {
    switch (unidade) {
      case 'g':
        return qtd / 1000;
      case 'L':
        return qtd.toDouble();
      case 'caixa':
        return qtd * 0.3;
      default:
        // ? uma unidade (ovo, iogurte…) conta como 100 g
        return qtd * 0.1;
    }
  }

  // ? texto pronto a mostrar, para todos os ecrãs escreverem igual
  String get quantidadeTexto {
    if (porUnidade) {
      return quantidade == 1 ? '1 unidade' : '$quantidade unidades';
    }
    return '$quantidade $unidade';
  }
}

// ? ícone de cada categoria, para o CategoryAvatar (fora da classe porque
// ? também é usado para categorias sem item, ex.: nos filtros)
IconData iconeCategoria(String categoria) {
  switch (categoria) {
    case 'Laticínios':
      return Icons.local_drink_outlined;
    case 'Ovos':
      return Icons.egg_outlined;
    case 'Legumes':
      return Icons.eco_outlined;
    case 'Sobras':
      return Icons.rice_bowl_outlined;
    case 'Carne e peixe':
      return Icons.set_meal_outlined;
    default:
      return Icons.kitchen_outlined;
  }
}
