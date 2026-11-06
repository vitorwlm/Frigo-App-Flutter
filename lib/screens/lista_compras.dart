import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/frigorifico.dart';
import '../models/compra.dart';
import '../models/item.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/hero_card.dart';
import '../widgets/item_row.dart';
import '../widgets/list_card.dart';
import '../widgets/option_tile.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_title.dart';
import '../widgets/snack.dart';
import '../widgets/tag_chip.dart';

// Ecrãs 10 (lista) e 24 (partilhar) do Figma
class ListaCompras extends StatelessWidget {
  const ListaCompras({super.key});

  // texto da lista para partilhar ou copiar
  String _textoLista(List<Compra> porComprar) {
    final linhas = porComprar.map((c) => '• ${c.nome}').join('\n');
    return 'Lista de compras · Frigu\n$linhas';
  }

  void _partilhar(BuildContext context, List<Compra> porComprar) {
    final String texto = _textoLista(porComprar);
    showModalBottomSheet<void>(
      context: context,
      // deixa a folha crescer e fazer scroll em ecrãs pequenos
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppTokens.bgApp,
      builder: (folha) {
        final textTheme = Theme.of(folha).textTheme;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.midsmall,
              0,
              AppSpacing.midsmall,
              AppSpacing.midsmall,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Partilhar lista', style: textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.midsmall),
                AppCard(child: Text(texto, style: textTheme.bodyMedium)),
                const SizedBox(height: AppSpacing.midsmall),
                ListCard(
                  children: [
                    OptionTile(
                      icone: Icons.chat_bubble_outline,
                      titulo: 'Enviar por mensagem',
                      descricao: 'WhatsApp, SMS ou outra app',
                      onTap: () {
                        Navigator.pop(folha);
                        // abre a folha de partilha do telemóvel
                        SharePlus.instance.share(ShareParams(text: texto));
                      },
                    ),
                    OptionTile(
                      icone: Icons.copy,
                      titulo: 'Copiar texto',
                      descricao: 'Para colar onde quiseres',
                      tom: OpcaoTom.neutro,
                      onTap: () {
                        Navigator.pop(folha);
                        // Clipboard = área de transferência (copiar/colar)
                        Clipboard.setData(ClipboardData(text: texto));
                        mostrarMensagem(context, 'Lista copiada');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.small),
                AppButton(
                  texto: 'Cancelar',
                  tipo: BotaoTipo.ghost,
                  expandir: true,
                  onPressed: () => Navigator.pop(folha),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: frigorifico,
      builder: (context, _) {
        final textTheme = Theme.of(context).textTheme;
        final porComprar = frigorifico.compras.where((c) => !c.noCarrinho).toList();
        final noCarrinho = frigorifico.compras.where((c) => c.noCarrinho).toList();

        // o que ainda está bom em casa (5 dias ou mais): não vai para a lista
        final emCasa = frigorifico.noFrigorifico
            .where((i) => i.dias >= 5)
            .take(2)
            .map((Item i) => i.nome.toLowerCase())
            .toList();

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.midsmall,
              AppSpacing.midsmall,
              AppSpacing.midsmall,
              88,
            ),
            children: [
              ScreenHeader(
                subtitulo: '${porComprar.length} por comprar',
                titulo: 'Compras',
                acoes: [
                  CircleIconButton(
                    icone: Icons.share_outlined,
                    tooltip: 'Partilhar lista',
                    onPressed: porComprar.isEmpty
                        ? null
                        : () => _partilhar(context, porComprar),
                  ),
                ],
              ),
              if (emCasa.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.midsmall),
                HeroCard(
                  cor: AppTokens.heroOk,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HeroPill(texto: 'Já tens em casa', icone: Icons.check_circle),
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        '${_capitalizar(emCasa.join(' e '))} ainda estão bons. '
                        'Não os pomos na lista.',
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppTokens.textOnHero,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.mid),
              const SectionTitle(titulo: 'Por comprar'),
              const SizedBox(height: AppSpacing.small),
              if (porComprar.isEmpty)
                AppCard(
                  child: Text(
                    'Lista vazia. Usa o botão Adicionar.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTokens.textSecondary,
                    ),
                  ),
                )
              else
                ListCard(children: [for (final c in porComprar) _linha(c)]),
              if (noCarrinho.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.mid),
                Row(
                  children: [
                    const Expanded(child: SectionTitle(titulo: 'No carrinho')),
                    AppButton(
                      texto: 'Limpar',
                      tipo: BotaoTipo.ghost,
                      onPressed: frigorifico.limparCarrinho,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.small),
                ListCard(children: [for (final c in noCarrinho) _linha(c)]),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _linha(Compra c) {
    return ItemRow(
      titulo: c.nome,
      riscado: c.noCarrinho,
      chip: TagChip(texto: c.motivo, tom: c.tom),
      onTap: () => frigorifico.alternarCarrinho(c),
      trailing: _Marcar(
        marcado: c.noCarrinho,
        onTap: () => frigorifico.alternarCarrinho(c),
      ),
    );
  }

  String _capitalizar(String t) =>
      t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}

// Círculo de marcar: vazio por comprar, teal com ✓ no carrinho
class _Marcar extends StatelessWidget {
  const _Marcar({required this.marcado, required this.onTap});

  final bool marcado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: marcado ? 'Tirar do carrinho' : 'Pôr no carrinho',
      icon: Icon(
        Icons.check,
        color: marcado ? AppColors.white : Colors.transparent,
      ),
      style: IconButton.styleFrom(
        fixedSize: const Size(48, 48),
        backgroundColor: marcado ? AppColors.primary500 : AppTokens.bgSurface,
        side: marcado
            ? null
            : const BorderSide(color: AppTokens.border, width: 1.5),
      ),
    );
  }
}

// Janela para acrescentar à lista (botão Adicionar no separador Compras)
Future<void> mostrarNovaCompra(BuildContext context) async {
  final nome = TextEditingController();
  final bool? guardar = await showDialog<bool>(
    context: context,
    builder: (dialogo) => AlertDialog(
      title: const Text('Acrescentar à lista'),
      content: TextField(
        controller: nome,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: 'O que falta?'),
        // Enter no teclado também guarda
        onSubmitted: (_) => Navigator.pop(dialogo, true),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogo, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogo, true),
          child: const Text('Acrescentar'),
        ),
      ],
    ),
  );
  if (guardar == true && nome.text.trim().isNotEmpty) {
    frigorifico.adicionarCompra(nome.text.trim(), 'Escrito à mão');
  }
}
