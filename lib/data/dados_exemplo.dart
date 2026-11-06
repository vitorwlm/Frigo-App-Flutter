import 'package:flutter/material.dart';

import '../models/item.dart';
import '../models/receita.dart';

// Dados falsos até a app ler do Supabase.
// São funções (e não const) porque as datas dependem do dia de hoje.

DateTime _daqui(int dias) =>
    DateUtils.dateOnly(DateTime.now()).add(Duration(days: dias));

List<Item> itensExemplo() => [
  Item(id: '1', nome: 'Iogurte natural', quantidade: 2, unidade: 'unidades', validade: _daqui(0), entrada: _daqui(-10), aberto: true, categoria: 'Laticínios', prateleira: 'Prateleira de cima'),
  Item(id: '2', nome: 'Ovos', quantidade: 6, unidade: 'unidades', validade: _daqui(1), entrada: _daqui(-13), categoria: 'Ovos'),
  Item(id: '3', nome: 'Sobras de arroz', quantidade: 1, unidade: 'caixa', validade: _daqui(2), entrada: _daqui(-1), categoria: 'Sobras'),
  Item(id: '4', nome: 'Espinafres', quantidade: 200, unidade: 'g', validade: _daqui(4), entrada: _daqui(-2), categoria: 'Legumes', prateleira: 'Gaveta'),
  Item(id: '5', nome: 'Queijo fresco', quantidade: 1, unidade: 'unidades', validade: _daqui(6), entrada: _daqui(-4), categoria: 'Laticínios'),
  Item(id: '6', nome: 'Leite meio-gordo', quantidade: 1, unidade: 'L', validade: _daqui(9), entrada: _daqui(-2), aberto: true, categoria: 'Laticínios', prateleira: 'Porta'),
  Item(id: '7', nome: 'Fiambre', quantidade: 150, unidade: 'g', validade: _daqui(5), entrada: _daqui(-2), categoria: 'Carne e peixe'),
  Item(id: '8', nome: 'Iogurte grego', quantidade: 1, unidade: 'unidades', validade: _daqui(12), entrada: _daqui(0), categoria: 'Laticínios', prateleira: 'Prateleira de cima', certeza: 54, alternativas: {'Iogurte natural': 31}),
  Item(id: '12', nome: 'Manteiga', quantidade: 0, unidade: 'unidades', validade: _daqui(-3), entrada: _daqui(-40), local: Local.acabou, categoria: 'Laticínios'),
  Item(id: '13', nome: 'Tomates', quantidade: 0, unidade: 'unidades', validade: _daqui(-1), entrada: _daqui(-8), local: Local.acabou, categoria: 'Legumes'),
];

List<Receita> receitasExemplo() => [
  Receita(
    id: 'r1',
    titulo: 'Omelete de espinafres',
    descricao: 'Salva o iogurte e os ovos',
    minutos: 15,
    ingredientes: [
      Ingrediente(nome: 'iogurte natural', plural: 'iogurtes naturais', porPessoa: 0.5, unidade: 'unidades', stock: 2, dias: 0),
      Ingrediente(nome: 'ovo', plural: 'ovos', porPessoa: 1.5, unidade: 'unidades', stock: 6, dias: 1),
      Ingrediente(nome: 'espinafres', plural: 'espinafres', porPessoa: 100, unidade: 'g', stock: 200, dias: 4),
      Ingrediente(nome: 'Azeite e sal', plural: 'Azeite e sal', porPessoa: 0, unidade: '', despensa: true),
    ],
    passos: [
      'Salteia os espinafres 2 min.',
      'Bate os ovos com o iogurte e junta.',
      'Lume brando 5 min, dobra e serve.',
    ],
  ),
  Receita(
    id: 'r2',
    titulo: 'Arroz salteado com ovo',
    descricao: 'Salva as sobras de arroz e 2 ovos',
    minutos: 20,
    ingredientes: [
      Ingrediente(nome: 'caixa de sobras de arroz', plural: 'caixas de sobras de arroz', porPessoa: 0.5, unidade: 'unidades', stock: 1, dias: 2),
      Ingrediente(nome: 'ovo', plural: 'ovos', porPessoa: 1, unidade: 'unidades', stock: 6, dias: 1),
      Ingrediente(nome: 'Azeite e sal', plural: 'Azeite e sal', porPessoa: 0, unidade: '', despensa: true),
    ],
    passos: [
      'Aquece o arroz numa frigideira com azeite.',
      'Junta os ovos batidos e mexe até cozerem.',
      'Tempera e serve.',
    ],
  ),
  Receita(
    id: 'r3',
    titulo: 'Panquecas de iogurte',
    descricao: 'Salva o iogurte e 2 ovos',
    minutos: 25,
    ingredientes: [
      Ingrediente(nome: 'iogurte natural', plural: 'iogurtes naturais', porPessoa: 0.5, unidade: 'unidades', stock: 2, dias: 0),
      Ingrediente(nome: 'ovo', plural: 'ovos', porPessoa: 1, unidade: 'unidades', stock: 6, dias: 1),
      Ingrediente(nome: 'farinha', plural: 'farinha', porPessoa: 50, unidade: 'g', stock: 0),
    ],
    passos: [
      'Mistura o iogurte, os ovos e a farinha.',
      'Deita conchas pequenas numa frigideira quente.',
      'Vira quando aparecerem bolhas.',
    ],
  ),
];
