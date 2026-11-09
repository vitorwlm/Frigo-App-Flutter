// * PONTE ENTRE A APP E O SUPABASE
// * Converte linhas das tabelas (Map) em objetos da app (Item, Compra, Receita)
// * e o contrário. Quem lê e grava é o data/frigorifico.dart; este ficheiro só
// * traduz, para os ecrãs nunca precisarem de saber os nomes das colunas.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/compra.dart';
import '../models/item.dart';
import '../models/receita.dart';
import '../widgets/tag_chip.dart';

// ? Atalho porque o cliente é usado em muitos ficheiros: escrever supabase
// ? é mais curto do que Supabase.instance.client (iniciado no main.dart)
SupabaseClient get supabase => Supabase.instance.client;

// ---------------------------------------------------------------------------
// Categorias: a base de dados usa chaves sem acentos (tabela validades),
// porque são chaves estrangeiras e assim não há erros de escrita;
// a app mostra os nomes com acentos.
// ---------------------------------------------------------------------------
const Map<String, String> _chaveDaCategoria = {
  'Laticínios': 'laticinios',
  'Ovos': 'ovos',
  'Legumes': 'legumes',
  'Sobras': 'sobras',
  'Carne e peixe': 'carne',
  'Outros': 'outros',
};

String chaveCategoria(String nome) => _chaveDaCategoria[nome] ?? 'outros';

String nomeCategoria(String? chave) {
  switch (chave) {
    case 'carne':
    case 'peixe':
      return 'Carne e peixe';
    // ? na app a fruta aparece junto com os legumes (o filtro tem menos opções)
    case 'fruta':
      return 'Legumes';
    default:
      // ? procura ao contrário (chave → nome) para não ter um 2.º mapa igual
      for (final e in _chaveDaCategoria.entries) {
        if (e.value == chave) return e.key;
      }
      return 'Outros';
  }
}

// ? "2026-11-06": o Postgres guarda a validade como date (sem horas),
// ? por isso não uso toIso8601String, que acrescentava as horas
String _data(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ? Linha da tabela itens → Item da app (usado ao carregar e no Realtime)
Item itemDaLinha(Map<String, dynamic> l) {
  final DateTime criado = DateTime.parse(l['criado_em'] as String).toLocal();
  final String? validade = l['validade'] as String?;
  final int quantidade = l['quantidade'] as int;
  return Item(
    id: '${l['id']}',
    nome: l['nome'] as String,
    quantidade: quantidade,
    unidade: (l['unidade'] as String?) ?? 'unidades',
    // ! Sem validade não devia acontecer (o trigger calcula-a pela categoria),
    // ! mas ponho uma semana para a app nunca rebentar com um null
    validade: validade != null
        ? DateTime.parse(validade)
        : criado.add(const Duration(days: 7)),
    entrada: DateUtils.dateOnly(criado),
    // ? não há coluna "local": um item com quantidade 0 é um item que acabou
    local: quantidade > 0 ? Local.frigorifico : Local.acabou,
    aberto: (l['aberto'] as bool?) ?? false,
    categoria: nomeCategoria(l['categoria'] as String?),
    prateleira: (l['prateleira'] as String?) ?? 'Prateleira do meio',
    certeza: (l['certeza'] as int?) ?? 100,
    motivoSaida: l['motivo_saida'] as String?,
  );
}

// ? Item da app → só as colunas que a app pode mudar (id, criado_em e fotos
// ? ficam de fora porque é o Supabase ou a câmara que as preenchem)
Map<String, dynamic> linhaDoItem(Item i) => {
  'nome': i.nome,
  'quantidade': i.quantidade,
  'unidade': i.unidade,
  'categoria': chaveCategoria(i.categoria),
  'validade': _data(i.validade),
  'aberto': i.aberto,
  'certeza': i.certeza,
  'prateleira': i.prateleira,
  // ? quando acaba, guarda quando e porquê: é com isto que o ecrã Impacto
  // ? conta o que foi consumido e o que foi deitado fora
  'removido_em': i.quantidade == 0 ? DateTime.now().toUtc().toIso8601String() : null,
  'motivo_saida': i.quantidade == 0 ? i.motivoSaida : null,
};

// ? Linha da tabela compras → Compra da app (lista partilhada em Realtime)
Compra compraDaLinha(Map<String, dynamic> l) => Compra(
  id: '${l['id']}',
  nome: l['nome'] as String,
  motivo: (l['motivo'] as String?) ?? '',
  // ? o tom vai guardado pelo nome ('aviso', 'marca'…) e não pelo índice,
  // ? para não trocar de cor se a ordem do enum TagTom mudar
  tom: TagTom.values.asNameMap()[l['tom']] ?? TagTom.neutro,
  noCarrinho: (l['no_carrinho'] as bool?) ?? false,
);

// ? Compra da app → colunas da tabela compras
Map<String, dynamic> linhaDaCompra(Compra c) => {
  'nome': c.nome,
  'motivo': c.motivo,
  'tom': c.tom.name,
  'no_carrinho': c.noCarrinho,
};

// ---------------------------------------------------------------------------
// Receitas: os ingredientes vão numa coluna jsonb, um objeto por ingrediente,
// em vez de outra tabela, porque são sempre lidos e gravados com a receita
// {"nome":"ovo", "plural":"ovos", "por_pessoa":1.5, "unidade":"unidades", "despensa":false}
// ---------------------------------------------------------------------------
Receita receitaDaLinha(Map<String, dynamic> l) => Receita(
  id: '${l['id']}',
  titulo: l['titulo'] as String,
  descricao: (l['descricao'] as String?) ?? '',
  minutos: (l['minutos'] as int?) ?? 0,
  pessoasBase: (l['pessoas'] as int?) ?? 2,
  dificuldade: (l['dificuldade'] as String?) ?? 'Fácil',
  ingredientes: [
    for (final Map<String, dynamic> i in (l['ingredientes'] as List?) ?? [])
      Ingrediente(
        nome: i['nome'] as String,
        plural: (i['plural'] as String?) ?? i['nome'] as String,
        // ? num e não double porque o JSON tanto traz 1 (int) como 1.5 (double)
        porPessoa: (i['por_pessoa'] as num?)?.toDouble() ?? 0,
        unidade: (i['unidade'] as String?) ?? 'unidades',
        despensa: (i['despensa'] as bool?) ?? false,
      ),
  ],
  passos: [for (final p in (l['passos'] as List?) ?? []) p as String],
);

Map<String, dynamic> linhaDaReceita(Receita r) => {
  'titulo': r.titulo,
  'descricao': r.descricao,
  'minutos': r.minutos,
  'pessoas': r.pessoasBase,
  'dificuldade': r.dificuldade,
  'ingredientes': [
    for (final i in r.ingredientes)
      {
        'nome': i.nome,
        'plural': i.plural,
        'por_pessoa': i.porPessoa,
        'unidade': i.unidade,
        'despensa': i.despensa,
      },
  ],
  'passos': r.passos,
};

// ---------------------------------------------------------------------------
// Validades: nomes com acentos para as chaves da tabela validades
// (ecrã Administração)
// ---------------------------------------------------------------------------
const Map<String, String> _nomesValidade = {
  'laticinios': 'Laticínios',
  'ovos': 'Ovos',
  'carne': 'Carne',
  'peixe': 'Peixe',
  'fruta': 'Fruta',
  'legumes': 'Legumes',
  'molhos': 'Molhos',
  'bebidas': 'Bebidas',
  'sobras': 'Sobras',
  'outros': 'Outros',
};

String nomeValidade(String chave) {
  final conhecido = _nomesValidade[chave];
  if (conhecido != null) return conhecido;
  // ? categoria criada no Admin e que não está no mapa:
  // ? "frutos_secos" → "Frutos secos"
  final texto = chave.replaceAll('_', ' ');
  return texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);
}

// ? "Frutos Secos" → "frutos_secos": chave sem acentos nem espaços, para
// ? ficar igual às que já estão na tabela validades
String chaveNova(String nome) {
  const acentos = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'é': 'e', 'ê': 'e', 'í': 'i',
    'ó': 'o', 'ô': 'o', 'õ': 'o', 'ú': 'u', 'ç': 'c',
  };
  final buffer = StringBuffer();
  for (final letra in nome.trim().toLowerCase().split('')) {
    buffer.write(acentos[letra] ?? (letra == ' ' ? '_' : letra));
  }
  return buffer.toString();
}

// ? O Supabase Auth só dá erros em inglês: traduzo os que o utilizador pode
// ? ver no Login; os outros aparecem tal como vêm
String erroEmPortugues(Object e) {
  final String msg = e is AuthException ? e.message : e.toString();
  final m = msg.toLowerCase();
  if (m.contains('invalid login')) return 'Email ou palavra-passe errados.';
  if (m.contains('already registered')) {
    return 'Já existe uma conta com este email.';
  }
  if (m.contains('email not confirmed')) {
    return 'Confirma o email (vê a caixa de correio) e depois entra.';
  }
  if (m.contains('password should be')) {
    return 'A palavra-passe tem de ter pelo menos 6 caracteres.';
  }
  if (m.contains('valid email') || m.contains('invalid format')) {
    return 'Este email não é válido.';
  }
  if (m.contains('socket') || m.contains('network') || m.contains('failed host')) {
    return 'Sem internet. Tenta outra vez.';
  }
  return msg;
}
