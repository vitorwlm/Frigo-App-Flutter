// * Testes da lógica das receitas, da lista de compras e das conversões
// * com o Supabase. Correr com: flutter test
// * Testo só a lógica (sem ecrãs nem internet) porque é onde um erro de
// * contas passava despercebido: um "Tens tudo" errado ninguém nota a olhar.
import 'package:flutter_test/flutter_test.dart';

import 'package:app/data/frigorifico.dart';
import 'package:app/models/evento.dart';
import 'package:app/models/item.dart';
import 'package:app/models/receita.dart';
import 'package:app/services/nuvem.dart';
import 'package:app/widgets/item_row.dart';
import 'package:app/widgets/tag_chip.dart';

// ? Ajudantes para não repetir os mesmos dados em cada teste
Ingrediente _ovo({double stock = 0}) => Ingrediente(
  nome: 'ovo',
  plural: 'ovos',
  porPessoa: 1.5,
  unidade: 'unidades',
  stock: stock,
);

Item _item(String nome) => Item(
  id: '1',
  nome: nome,
  quantidade: 1,
  unidade: 'unidades',
  validade: DateTime(2026, 11, 10),
  entrada: DateTime(2026, 11, 8),
);

void main() {
  group('Ingrediente', () {
    test('unidades arredondam para cima (não se parte um ovo)', () {
      expect(_ovo().necessario(3), 5); // ? 1,5 × 3 = 4,5 → 5
    });

    test('gramas não arredondam', () {
      final g = Ingrediente(
        nome: 'espinafres',
        plural: 'espinafres',
        porPessoa: 100,
        unidade: 'g',
      );
      expect(g.necessario(3), 300);
      expect(g.texto(2), '200 g espinafres');
    });

    test('falta = o que é preciso menos o que há', () {
      expect(_ovo(stock: 2).falta(2), 1); // ? precisa de 3, tem 2
      expect(_ovo(stock: 10).falta(2), 0);
    });

    test('despensa nunca falta', () {
      final sal = Ingrediente(
        nome: 'Azeite e sal',
        plural: 'Azeite e sal',
        porPessoa: 0,
        unidade: '',
        despensa: true,
      );
      expect(sal.falta(4), 0);
      expect(sal.texto(4), 'Azeite e sal');
    });

    test('singular e plural no texto', () {
      final o = Ingrediente(
        nome: 'ovo',
        plural: 'ovos',
        porPessoa: 1,
        unidade: 'unidades',
      );
      expect(o.texto(1), '1 ovo');
      expect(o.texto(3), '3 ovos');
    });
  });

  group('Receita', () {
    Receita receita(double stockOvos) => Receita(
      id: '1',
      titulo: 'Omelete',
      descricao: '',
      minutos: 10,
      ingredientes: [_ovo(stock: stockOvos)],
      passos: const ['Bate os ovos.'],
    );

    test('tens tudo quando há stock suficiente', () {
      expect(receita(6).tensTudo(2), isTrue);
      expect(receita(6).estado(2), 'Tens tudo');
    });

    test('diz o que falta', () {
      expect(receita(1).tensTudo(2), isFalse);
      expect(receita(1).estado(2), 'Falta ovo');
    });
  });

  group('Supabase: receitas', () {
    test('linha → receita → linha fica igual', () {
      final linha = {
        'id': 7,
        'titulo': 'Panquecas',
        'descricao': 'Salva o iogurte',
        'minutos': 25,
        'pessoas': 3,
        'dificuldade': 'Média',
        'ingredientes': [
          {
            'nome': 'ovo',
            'plural': 'ovos',
            // ? o JSON pode trazer 1 (int) em vez de 1.0
            'por_pessoa': 1,
            'unidade': 'unidades',
            'despensa': false,
          },
        ],
        'passos': ['Mistura tudo.'],
      };
      final r = receitaDaLinha(linha);
      expect(r.id, '7');
      expect(r.pessoasBase, 3);
      expect(r.ingredientes.single.porPessoa, 1.0);

      final volta = linhaDaReceita(r);
      expect(volta['titulo'], 'Panquecas');
      expect(volta['dificuldade'], 'Média');
      expect((volta['ingredientes'] as List).single['plural'], 'ovos');
      expect(volta['passos'], ['Mistura tudo.']);
    });

    test('colunas em falta ficam com o valor por defeito', () {
      final r = receitaDaLinha({'id': 1, 'titulo': 'Sopa'});
      expect(r.descricao, '');
      expect(r.pessoasBase, 2);
      expect(r.ingredientes, isEmpty);
    });
  });

  group('Supabase: validades e compras', () {
    test('chave nova sem acentos nem espaços', () {
      expect(chaveNova('Frutos Secos'), 'frutos_secos');
      expect(chaveNova(' Laticínios '), 'laticinios');
    });

    test('nome da categoria com acentos', () {
      expect(nomeValidade('laticinios'), 'Laticínios');
      expect(nomeValidade('frutos_secos'), 'Frutos secos');
    });

    test('compra: tom desconhecido fica neutro', () {
      final c = compraDaLinha({
        'id': 3,
        'nome': 'Leite',
        'motivo': 'Acabou',
        'tom': 'qualquer',
        'no_carrinho': true,
      });
      expect(c.id, '3');
      expect(c.tom, TagTom.neutro);
      expect(c.noCarrinho, isTrue);
      expect(linhaDaCompra(c)['tom'], 'neutro');
    });
  });

  group('Ingrediente ↔ alimento do inventário', () {
    Ingrediente ing(String nome) =>
        Ingrediente(nome: nome, plural: nome, porPessoa: 1, unidade: 'unidades');

    test('palavra comum com 4+ letras', () {
      expect(
        ingredienteCorresponde(ing('caixa de sobras de arroz'), _item('Sobras de arroz')),
        isTrue,
      );
    });

    test('palavra curta compara com o início do nome', () {
      expect(ingredienteCorresponde(ing('ovo'), _item('Ovos')), isTrue);
      expect(ingredienteCorresponde(ing('ovo'), _item('Iogurte')), isFalse);
    });
  });

  group('Cozinhar e prazos', () {
    test('cozinhar gasta de vários itens até ter o que a receita pede', () {
      // ? sem Supabase (naNuvem = false): só mexe na memória
      final f = Frigorifico();
      final a = _item('Iogurte natural');
      final b = Item(
        id: '2',
        nome: 'Iogurte natural',
        quantidade: 1,
        unidade: 'unidades',
        validade: DateTime.now().add(const Duration(days: 5)),
        entrada: DateTime.now(),
      );
      f.itens.addAll([a, b]);
      final r = Receita(
        id: '1',
        titulo: 'Taça de iogurte',
        descricao: '',
        minutos: 5,
        pessoasBase: 1,
        ingredientes: [
          Ingrediente(
            nome: 'iogurte',
            plural: 'iogurtes',
            porPessoa: 2,
            unidade: 'unidades',
          ),
        ],
        passos: const [],
      );
      f.cozinhar(r, 1);
      expect(a.quantidade, 0);
      expect(b.quantidade, 0);
    });

    test('evento ↔ linha do historico', () {
      final e = eventoDaLinha({
        'id': 9,
        'item_id': 4,
        'nome': 'Ovos',
        'tipo': 'deitado_fora',
        'peso_kg': 0.2,
        'motivo': 'Passou a validade',
        'criado_em': '2026-11-10T10:00:00Z',
      });
      expect(e.tipo, TipoEvento.deitadoFora);
      expect(e.itemId, '4');
      expect(linhaDoEvento(e)['tipo'], 'deitado_fora');
      expect(linhaDoEvento(e)['item_id'], 4);
    });

    test('alimento já expirado não diz "Hoje"', () {
      expect(prazoDe(-2), 'Expirou');
      expect(prazoDe(0), 'Hoje');
    });
  });
}
