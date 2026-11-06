import 'package:flutter/material.dart';

// onde está o alimento (separadores do Inventário)
enum Local { frigorifico, arca, acabou }

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
  });

  final String id;
  final String nome;
  // sem final: estes mudam quando usas, congelas ou abres
  int quantidade;
  Local local;
  bool aberto;
  final String unidade;
  final DateTime validade;
  // dia em que a câmara o viu pela primeira vez
  final DateTime entrada;
  final String categoria;
  final String prateleira;
  // 0–100, vem do Gemini
  final int certeza;

  // get = propriedade calculada, usa-se como item.dias (sem parênteses)
  int get dias {
    // DateUtils.dateOnly tira as horas, para contar dias inteiros
    final hoje = DateUtils.dateOnly(DateTime.now());
    return DateUtils.dateOnly(validade).difference(hoje).inDays;
  }

  int get diasTotais {
    final total = DateUtils.dateOnly(validade)
        .difference(DateUtils.dateOnly(entrada))
        .inDays;
    return total < 1 ? 1 : total;
  }

  bool get porUnidade => unidade == 'unidades';

  // peso aproximado, para o Impacto (kg salvos e CO2)
  double pesoDe(int qtd) {
    switch (unidade) {
      case 'g':
        return qtd / 1000;
      case 'L':
        return qtd.toDouble();
      case 'caixa':
        return qtd * 0.3;
      default:
        // uma unidade (ovo, iogurte…) conta como 100 g
        return qtd * 0.1;
    }
  }

  String get quantidadeTexto {
    if (porUnidade) {
      return quantidade == 1 ? '1 unidade' : '$quantidade unidades';
    }
    return '$quantidade $unidade';
  }
}

// ícone de cada categoria, para o CategoryAvatar
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
