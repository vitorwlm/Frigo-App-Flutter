// * ECRÃ INVENTÁRIO — 2.º separador da HomeShell (main.dart).
// * Fluxo: pesquisa + filtros rápidos + botão de filtros (filtros_sheet.dart)
// * → separador Frigorífico / Acabou → linhas: tocar abre o detalhe (ou o
// * "É isto?" do confirmar_sheet.dart se a câmara não tem a certeza);
// * deslizar → Usei / Deitei fora; no Acabou, Comprar → lista de compras.
// * Ecrãs 05 (lista), 21 (filtros) e 22 (deslizar) do Figma.

import 'package:flutter/material.dart';

import '../data/frigorifico.dart';
import '../models/item.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/estados.dart';
import '../widgets/item_row.dart';
import '../widgets/list_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_title.dart';
import '../widgets/snack.dart';
import '../widgets/tag_chip.dart';
import 'detalhe_alimento.dart';
import 'confirmar_sheet.dart';
import 'filtros_sheet.dart';

// ? filtros rápidos por baixo da pesquisa (enum para só haver um ligado)
enum Rapido { aExpirar, abertos, aConfirmar }

// ? StatefulWidget porque guarda a pesquisa, os filtros e o separador
class Inventario extends StatefulWidget {
  const Inventario({super.key});

  @override
  State<Inventario> createState() => _InventarioState();
}

class _InventarioState extends State<Inventario> {
  // ? os itens vêm do frigorifico partilhado (os mesmos do Início), por isso
  // ? é só um get e não uma cópia da lista
  List<Item> get _itens => frigorifico.itens;

  // ? Ouve o frigorifico com addListener (e não ListenableBuilder) porque o
  // ? ecrã já é Stateful: se o Início ou o Realtime mudarem algo, redesenha-se
  @override
  void initState() {
    super.initState();
    frigorifico.addListener(_mudou);
  }

  // ! tira o listener ao fechar, senão chamava setState num ecrã que já não
  // ! existe
  @override
  void dispose() {
    frigorifico.removeListener(_mudou);
    super.dispose();
  }

  void _mudou() => setState(() {});
  Local _local = Local.frigorifico;
  String _pesquisa = '';
  Filtros _filtros = Filtros();
  // ? null = nenhum filtro rápido ligado
  Rapido? _rapido;
  // ? cartão da dica de deslizar; desaparece quando se fecha
  bool _dica = true;

  // ? switch sobre o enum: o compilador obriga a tratar todos os casos.
  // ? certeza < 60 = a câmara não tem a certeza do que viu
  bool _passaRapido(Item i, Rapido? r) {
    switch (r) {
      case null:
        return true;
      case Rapido.aExpirar:
        return i.dias <= 4;
      case Rapido.abertos:
        return i.aberto;
      case Rapido.aConfirmar:
        return i.certeza < 60;
    }
  }

  // ? o número que aparece em cada chip
  int _contarRapido(Rapido r) =>
      _itens.where((i) => i.local == _local && _passaRapido(i, r)).length;

  // ? aplica pesquisa e filtros; recebe os filtros como parâmetro para a
  // ? folha de filtros conseguir contar o "Ver N" antes de os aplicar
  List<Item> _filtrar(Filtros f, Local local) {
    final lista = _itens.where((i) {
      if (i.local != local) return false;
      if (_pesquisa.isNotEmpty &&
          !i.nome.toLowerCase().contains(_pesquisa.toLowerCase())) {
        return false;
      }
      if (!_passaRapido(i, _rapido)) return false;
      if (f.soAbertos && !i.aberto) return false;
      if (f.soIncertos && i.certeza >= 60) return false;
      if (f.categorias.isNotEmpty && !f.categorias.contains(i.categoria)) {
        return false;
      }
      return true;
    }).toList();

    // ? sort recebe uma função que compara dois itens (negativo = a vem antes)
    switch (f.ordem) {
      case Ordem.validade:
        lista.sort((a, b) => a.dias.compareTo(b.dias));
      case Ordem.nome:
        lista.sort((a, b) => a.nome.compareTo(b.nome));
      case Ordem.recentes:
        lista.sort((a, b) => b.entrada.compareTo(a.entrada));
    }
    return lista;
  }

  int _contar(Local local) => _itens.where((i) => i.local == local).length;

  // * ---- ações ----

  // ? Guarda o "antes" para o Anular da snackbar conseguir desfazer
  void _usei(Item item) {
    final int antes = item.quantidade;
    final Local localAntes = item.local;
    frigorifico.usar(item);
    mostrarAnular(
      context,
      item.quantidade > 0
          ? 'Usaste 1 ${item.nome.toLowerCase()} · fica ${item.quantidade}'
          : 'Acabou: ${item.nome}',
      () => frigorifico.repor(item, antes, localAntes),
    );
  }

  void _deiteiFora(Item item) {
    final int antes = item.quantidade;
    final Local localAntes = item.local;
    frigorifico.deitarFora(item);
    mostrarAnular(
      context,
      '${item.nome} deitado fora',
      () => frigorifico.repor(item, antes, localAntes),
    );
  }

  // ? A folha de filtros devolve os filtros novos (ou null se fechou sem
  // ? aplicar); a função passada conta quantos ficariam, para o botão "Ver N"
  Future<void> _abrirFiltros() async {
    final novos = await mostrarFiltros(
      context,
      _filtros,
      (f) => _filtrar(f, _local).length,
    );
    if (novos != null) setState(() => _filtros = novos);
  }

  Future<void> _abrirDetalhe(Item item) async {
    // ? await espera que o ecrã de detalhe feche; pode devolver uma mensagem
    // ? (ex.: "Guardado") para mostrar aqui
    final String? mensagem = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => DetalheAlimento(item: item)),
    );
    // ? o detalhe pode ter mudado a quantidade: avisa todos os ecrãs
    frigorifico.atualizar(item);
    // ! mounted = o ecrã ainda existe (pode ter sido fechado durante o await)
    if (mensagem != null && mounted) mostrarMensagem(context, mensagem);
  }

  // * ---- interface ----

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lista = _filtrar(_filtros, _local);
    final int total = _itens.where((i) => i.local != Local.acabou).length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.midsmall,
          AppSpacing.midsmall,
          AppSpacing.midsmall,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              subtitulo:
                  '$total alimentos · visto ${ha(frigorifico.ultimaLeitura)}',
              titulo: 'Inventário',
              acoes: [
                CircleIconButton(
                  icone: Icons.tune,
                  tooltip: 'Ordenar e filtrar',
                  badge: _filtros.ativos > 0 ? '${_filtros.ativos}' : null,
                  onPressed: _abrirFiltros,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.midsmall),
            TextField(
              onChanged: (texto) => setState(() => _pesquisa = texto),
              decoration: InputDecoration(
                hintText: 'Procurar alimento',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppTokens.bgSurface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(color: AppTokens.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(
                    color: AppColors.primary500,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            // ? Wrap e não Row: os chips passam para a linha de baixo se não
            // ? couberem (ecrãs pequenos ou letra grande)
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              children: [
                _chipRapido(Rapido.aExpirar, 'A expirar'),
                _chipRapido(Rapido.abertos, 'Abertos'),
                _chipRapido(Rapido.aConfirmar, 'A confirmar'),
              ],
            ),
            const SizedBox(height: AppSpacing.midsmall),
            SegmentedButton<Local>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: Local.frigorifico,
                  label: Text('Frigorífico ${_contar(Local.frigorifico)}'),
                ),
                ButtonSegment(
                  value: Local.acabou,
                  label: Text('Acabou ${_contar(Local.acabou)}'),
                ),
              ],
              selected: {_local},
              onSelectionChanged: (s) => setState(() => _local = s.first),
            ),
            const SizedBox(height: AppSpacing.small),
            // ? Expanded para só a lista fazer scroll; a pesquisa fica fixa
            Expanded(
              // ? frigorífico vazio (ecrã 05) é diferente de "os filtros não
              // ? deixaram nada": aí basta dizer que não há resultados
              child:
                  _local == Local.frigorifico && _contar(Local.frigorifico) == 0
                  ? const Center(
                      child: EstadoVazio(
                        titulo: 'O frigorífico está vazio!',
                        texto:
                            'Adiciona o que compraste ao frigorífico!\n'
                            'O frigo diz-te o que está a expirar',
                      ),
                    )
                  : lista.isEmpty
                  ? Center(
                      child: Text(
                        'Nada por aqui',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppTokens.textSecondary,
                        ),
                      ),
                    )
                  : ListView(
                      // ? 88 em baixo para o botão Adicionar não tapar a última linha
                      padding: const EdgeInsets.only(
                        top: AppSpacing.small,
                        bottom: 88,
                      ),
                      children: _seccoes(lista, textTheme),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ? Separador Acabou: só a lista com o botão Comprar (o que acabou é o que
  // ? é preciso comprar). Separador Frigorífico: secções por urgência.
  List<Widget> _seccoes(List<Item> lista, TextTheme textTheme) {
    if (_local == Local.acabou) {
      return [
        SectionTitle(titulo: 'Acabou', contador: lista.length),
        const SizedBox(height: AppSpacing.small),
        ListCard(
          children: [
            for (final i in lista)
              ItemRow(
                titulo: i.nome,
                leading: CategoryAvatar(icone: iconeCategoria(i.categoria)),
                chip: TagChip(texto: i.categoria),
                trailing: AppButton(
                  texto: 'Comprar',
                  tipo: BotaoTipo.tonal,
                  onPressed: () {
                    frigorifico.adicionarCompra(
                      i.nome,
                      'Acabou no frigorífico',
                    );
                    mostrarMensagem(
                      context,
                      '${i.nome} ficou na lista de compras',
                    );
                  },
                ),
              ),
          ],
        ),
      ];
    }

    // ? no frigorífico separa o que expira em 4 dias ou menos, para o mais
    // ? urgente aparecer primeiro (ODS 12.3)
    final emBreve = lista.where((i) => i.dias <= 4).toList();
    final resto = lista.where((i) => i.dias > 4).toList();

    return [
      if (_dica) ...[
        _cartaoDica(textTheme),
        const SizedBox(height: AppSpacing.midsmall),
      ],
      if (emBreve.isNotEmpty) ...[
        SectionTitle(titulo: 'Expira em breve', contador: emBreve.length),
        const SizedBox(height: AppSpacing.small),
        ListCard(children: [for (final i in emBreve) _linha(i)]),
        const SizedBox(height: AppSpacing.mid),
      ],
      if (resto.isNotEmpty) ...[
        SectionTitle(titulo: 'Frescos', contador: resto.length),
        const SizedBox(height: AppSpacing.small),
        ListCard(children: [for (final i in resto) _linha(i)]),
      ],
    ];
  }

  // ? ChoiceChip porque só um pode estar ligado de cada vez
  Widget _chipRapido(Rapido r, String texto) {
    return ChoiceChip(
      label: Text('$texto ${_contarRapido(r)}'),
      selected: _rapido == r,
      showCheckmark: false,
      selectedColor: AppTokens.bgTonalSoft,
      backgroundColor: AppTokens.bgApp,
      side: const BorderSide(color: AppTokens.borderStrong),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      // ? carregar no que já está ligado desliga-o (volta a null)
      onSelected: (sim) => setState(() => _rapido = sim ? r : null),
    );
  }

  // ? Explica o deslizar, que não se vê à primeira (ecrã 22 do Figma)
  Widget _cartaoDica(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.midsmall,
        AppSpacing.small,
        0,
        AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: AppTokens.bgTonalSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(Icons.swipe, color: AppTokens.textBrand),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              'Desliza para a direita para usar 1, para a esquerda se deitaste fora.',
              style: textTheme.bodySmall?.copyWith(color: AppTokens.textBrand),
            ),
          ),
          IconButton(
            tooltip: 'Fechar dica',
            icon: const Icon(Icons.close, color: AppTokens.textBrand),
            onPressed: () => setState(() => _dica = false),
          ),
        ],
      ),
    );
  }

  // ? Linha que se pode deslizar (ecrã 22). Dismissible porque já traz o
  // ? gesto e os fundos de cada lado; deslizar é mais rápido do que abrir menus
  Widget _linha(Item item) {
    final EstadoValidade estado = estadoDe(item.dias);
    final textTheme = Theme.of(context).textTheme;

    return Dismissible(
      // ! a key tem de ser única e estável: usa o id, nunca o índice (com o
      // ! índice, ao filtrar, o Flutter confundia as linhas)
      key: ValueKey(item.id),
      // ? fundo ao deslizar para a direita (Usei)
      background: Container(
        color: AppTokens.bgTonal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mid),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check, color: AppTokens.textBrand),
            const SizedBox(width: AppSpacing.small),
            Text(
              item.porUnidade ? 'Usei 1' : 'Usei tudo',
              style: textTheme.labelLarge?.copyWith(color: AppTokens.textBrand),
            ),
          ],
        ),
      ),
      // ? fundo ao deslizar para a esquerda (Deitei fora)
      secondaryBackground: Container(
        color: AppTokens.bgDanger,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mid),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_outline, color: AppTokens.textDanger),
            const SizedBox(width: AppSpacing.small),
            Text(
              'Deitei fora',
              style: textTheme.labelLarge?.copyWith(
                color: AppTokens.textDanger,
              ),
            ),
          ],
        ),
      ),
      // ? decide o que fazer; devolve sempre false para a linha voltar ao
      // ? sítio: quem a tira da lista é o frigorifico (se o alimento acabar,
      // ? passa para o Acabou e a lista atualiza sozinha)
      confirmDismiss: (direcao) async {
        if (direcao == DismissDirection.startToEnd) {
          _usei(item);
        } else {
          _deiteiFora(item);
        }
        return false;
      },
      child: ItemRow(
        titulo: item.nome,
        leading: CategoryAvatar(icone: iconeCategoria(item.categoria)),
        detalhe: item.certeza < 60
            ? 'A confirmar · ${item.certeza} %'
            : item.aberto
            ? '${item.quantidadeTexto} · aberto'
            : item.quantidadeTexto,
        estado: estado,
        chip: TagChip(texto: prazoDe(item.dias), tom: tomDe(estado)),
        trailing: const Icon(Icons.chevron_right),
        // ? a câmara não tem a certeza: pergunta primeiro o que é (ecrã 12),
        // ? para o inventário não ficar com nomes errados
        onTap: () => item.certeza < 60
            ? mostrarConfirmar(context, item)
            : _abrirDetalhe(item),
      ),
    );
  }
}
