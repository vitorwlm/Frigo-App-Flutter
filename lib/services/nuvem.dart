import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/item.dart';

// Atalho para o cliente do Supabase (iniciado no main.dart)
SupabaseClient get supabase => Supabase.instance.client;

// ---------------------------------------------------------------------------
// Categorias: a base de dados usa chaves simples (tabela validades),
// a app mostra nomes com acentos.
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
    case 'fruta':
      return 'Legumes';
    default:
      // procura o nome cuja chave é esta
      for (final e in _chaveDaCategoria.entries) {
        if (e.value == chave) return e.key;
      }
      return 'Outros';
  }
}

// "2026-11-06" (o tipo date do Postgres)
String _data(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// Linha da tabela itens → Item da app
Item itemDaLinha(Map<String, dynamic> l) {
  final DateTime criado = DateTime.parse(l['criado_em'] as String).toLocal();
  final String? validade = l['validade'] as String?;
  final int quantidade = l['quantidade'] as int;
  return Item(
    id: '${l['id']}',
    nome: l['nome'] as String,
    quantidade: quantidade,
    unidade: (l['unidade'] as String?) ?? 'unidades',
    // sem validade (não devia acontecer, o trigger calcula-a): uma semana
    validade: validade != null
        ? DateTime.parse(validade)
        : criado.add(const Duration(days: 7)),
    entrada: DateUtils.dateOnly(criado),
    local: quantidade > 0 ? Local.frigorifico : Local.acabou,
    aberto: (l['aberto'] as bool?) ?? false,
    categoria: nomeCategoria(l['categoria'] as String?),
    prateleira: (l['prateleira'] as String?) ?? 'Prateleira do meio',
    certeza: (l['certeza'] as int?) ?? 100,
    motivoSaida: l['motivo_saida'] as String?,
  );
}

// Item da app → colunas que a app pode mudar
Map<String, dynamic> linhaDoItem(Item i) => {
  'nome': i.nome,
  'quantidade': i.quantidade,
  'unidade': i.unidade,
  'categoria': chaveCategoria(i.categoria),
  'validade': _data(i.validade),
  'aberto': i.aberto,
  'certeza': i.certeza,
  'prateleira': i.prateleira,
  // quando acaba, guarda quando e porquê (base do ecrã Impacto)
  'removido_em': i.quantidade == 0 ? DateTime.now().toUtc().toIso8601String() : null,
  'motivo_saida': i.quantidade == 0 ? i.motivoSaida : null,
};

// Mensagens de erro do Supabase Auth em português
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
