import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../widgets/app_button.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/hero_card.dart';
import '../widgets/item_row.dart';
import '../widgets/list_card.dart';
import '../widgets/option_tile.dart';
import '../widgets/recipe_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_title.dart';
import '../widgets/small_widgets.dart';
import '../widgets/tag_chip.dart';

// Ecrã temporário para comparar os widgets com a página "- App" do Figma.
// Para o abrir: no main.dart troca home: const HomeShell() por home: const Galeria()
class Galeria extends StatelessWidget {
  const Galeria({super.key});

  @override
  Widget build(BuildContext context) {
    void nada() {}
    const espaco = SizedBox(height: AppSpacing.mid);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.midsmall),
          children: [
            ScreenHeader(
              subtitulo: 'Componentes',
              titulo: 'Galeria',
              acoes: [
                CircleIconButton(
                  icone: Icons.notifications_none,
                  tooltip: 'Avisos',
                  badge: '2',
                  onPressed: nada,
                ),
              ],
            ),
            espaco,
            const SectionTitle(titulo: 'Chips'),
            const SizedBox(height: AppSpacing.small),
            const Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              children: [
                TagChip(texto: 'Hoje', tom: TagTom.perigo),
                TagChip(texto: 'Amanhã', tom: TagTom.aviso),
                TagChip(texto: '4 dias', tom: TagTom.neutro),
                TagChip(texto: 'Tens', tom: TagTom.marca),
                TagChip(texto: '15 min', tom: TagTom.contorno),
              ],
            ),
            espaco,
            const SectionTitle(titulo: 'Botões'),
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              children: [
                AppButton(texto: 'Usei tudo', icone: Icons.check, onPressed: nada),
                AppButton(texto: 'Usei', tipo: BotaoTipo.tonal, icone: Icons.check, onPressed: nada),
                AppButton(texto: 'Cancelar', tipo: BotaoTipo.ghost, onPressed: nada),
                AppButton(
                  texto: 'Deitei fora',
                  tipo: BotaoTipo.stroke,
                  cor: BotaoCor.accent,
                  icone: Icons.delete_outline,
                  onPressed: nada,
                ),
                AppButton(texto: 'Já fechei', cor: BotaoCor.neutral, onPressed: nada),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            Row(
              children: [
                CircleIconButton(icone: Icons.settings_outlined, tooltip: 'superfície', onPressed: nada),
                CircleIconButton(icone: Icons.add, tooltip: 'contorno', estilo: CirculoEstilo.contorno, onPressed: nada),
                CircleIconButton(icone: Icons.check, tooltip: 'preenchido', estilo: CirculoEstilo.preenchido, onPressed: nada),
                CircleIconButton(icone: Icons.more_vert, tooltip: 'transparente', estilo: CirculoEstilo.transparente, onPressed: nada),
              ],
            ),
            espaco,
            const SectionTitle(titulo: 'Linha de lista', contador: 3),
            const SizedBox(height: AppSpacing.small),
            ListCard(
              children: [
                ItemRow(
                  titulo: 'Iogurte natural',
                  detalhe: '2 unidades',
                  estado: EstadoValidade.perigo,
                  chip: const TagChip(texto: 'Hoje', tom: TagTom.perigo),
                  trailing: AppButton(texto: 'Usei', tipo: BotaoTipo.tonal, onPressed: nada),
                ),
                ItemRow(
                  titulo: 'Ovos',
                  detalhe: '6 unidades',
                  estado: EstadoValidade.aviso,
                  chip: const TagChip(texto: 'Amanhã', tom: TagTom.aviso),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: nada,
                ),
                const ItemRow(
                  titulo: 'Azeite e sal',
                  estado: EstadoValidade.marca,
                  trailing: TagChip(texto: 'Tens', tom: TagTom.marca),
                ),
              ],
            ),
            espaco,
            const HeroCard(
              cor: Color(0xFF00656E),
              child: HeroPill(texto: 'Tudo bem', icone: Icons.check_circle),
            ),
            espaco,
            RecipeCard(
              titulo: 'Panquecas de iogurte',
              descricao: 'Salva o iogurte e 2 ovos',
              estado: 'Falta farinha',
              minutos: 25,
              tom: ReceitaTom.aviso,
              onTap: nada,
            ),
            espaco,
            ListCard(
              children: [
                OptionTile(icone: Icons.photo_camera_outlined, titulo: 'Tirar foto agora', descricao: 'Atualiza com a câmara do frigorífico', onTap: nada),
                OptionTile(icone: Icons.edit_outlined, titulo: 'Escrever à mão', descricao: 'Sobras, alimentos sem embalagem', tom: OpcaoTom.neutro, onTap: nada),
                const ReasonBar(motivo: 'Passou a validade', valor: 3, fracao: 0.6),
              ],
            ),
            espaco,
            const StepRow(numero: 1, texto: 'Salteia os espinafres 2 min.'),
            espaco,
            const Center(child: PageDots(total: 3, atual: 1)),
          ],
        ),
      ),
    );
  }
}
