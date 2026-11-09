// * FOLHA "É ISTO?" (ecrã 12 do Figma) + o círculo de escolher.
// * Abre no Inventário ao tocar num alimento com certeza < 60 %.
// * Fluxo: escolher um palpite do Gemini (ou escrever outro) → Confirmar
// * (frigorifico.confirmar) ou "Não está no frigorífico" (remover + Anular).

import 'package:flutter/material.dart';

import '../data/frigorifico.dart';
import '../models/item.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/item_row.dart';
import '../widgets/list_card.dart';
import '../widgets/snack.dart';
import '../widgets/tag_chip.dart';

// ? Círculo de escolher (Marcar da Linha de lista do Figma): cheio com ✓ ou
// ? vazio. Está aqui mas é público porque o onboarding também o usa
class MarcarCirculo extends StatelessWidget {
  const MarcarCirculo({
    super.key,
    required this.marcado,
    required this.onPressed,
  });

  final bool marcado;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CircleIconButton(
      icone: Icons.check,
      tooltip: marcado ? 'Escolhido' : 'Escolher',
      estilo: marcado ? CirculoEstilo.preenchido : CirculoEstilo.contorno,
      // ? vazio = o ✓ fica transparente (assim o círculo não muda de tamanho)
      corIcone: marcado ? null : Colors.transparent,
      onPressed: onPressed,
    );
  }
}

// ? Função e não ecrã porque é uma folha por cima do Inventário: quem chama
// ? só passa o item
void mostrarConfirmar(BuildContext context, Item item) {
  // ? palpites do Gemini: o principal + as alternativas, num só Map para os
  // ? mostrar todos na mesma lista
  final Map<String, int> palpites = {item.nome: item.certeza, ...item.alternativas};
  String escolhido = item.nome;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppTokens.bgApp,
    builder: (folha) {
      final textTheme = Theme.of(folha).textTheme;
      // ? StatefulBuilder para a escolha mudar o círculo sem fechar a folha
      return StatefulBuilder(
        builder: (folha, setFolha) => SafeArea(
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
                Text('É isto?', style: textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.small),
                Text(
                  'A câmara viu algo novo na ${item.prateleira.toLowerCase()}, '
                  'mas não tem a certeza.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.midsmall),
                // ? lugar da foto recortada (vai vir da Edge Function analisar-foto,
                // ? com as caixas do Gemini); por agora só um ícone
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppTokens.bgTonal,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_camera_outlined,
                          size: 32, color: AppTokens.textBrand),
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        'Foto da câmara',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.midsmall),
                ListCard(
                  children: [
                    // ? .entries = pares nome → certeza do Map
                    for (final p in palpites.entries)
                      ItemRow(
                        titulo: p.key,
                        onTap: () => setFolha(() => escolhido = p.key),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TagChip(
                              texto: '${p.value} %',
                              tom: p.key == escolhido
                                  ? TagTom.marca
                                  : TagTom.neutro,
                            ),
                            const SizedBox(width: AppSpacing.small),
                            MarcarCirculo(
                              marcado: p.key == escolhido,
                              onPressed: () =>
                                  setFolha(() => escolhido = p.key),
                            ),
                          ],
                        ),
                      ),
                    ItemRow(
                      titulo: 'Outro alimento…',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final nome = await _pedirNome(folha);
                        if (nome != null) {
                          // ? o que a pessoa escreve tem certeza 100
                          setFolha(() {
                            palpites[nome] = 100;
                            escolhido = nome;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.midsmall),
                AppButton(
                  texto: 'Confirmar',
                  icone: Icons.check,
                  expandir: true,
                  onPressed: () {
                    frigorifico.confirmar(item, escolhido);
                    Navigator.pop(folha);
                    mostrarMensagem(context, '$escolhido confirmado');
                  },
                ),
                const SizedBox(height: AppSpacing.small),
                AppButton(
                  texto: 'Não está no frigorífico',
                  tipo: BotaoTipo.ghost,
                  expandir: true,
                  // ? guarda a posição (i) para o Anular o pôr no mesmo sítio
                  onPressed: () {
                    Navigator.pop(folha);
                    final int i = frigorifico.remover(item);
                    mostrarAnular(context, '${item.nome} removido',
                        () => frigorifico.inserir(i, item));
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ? Caixa para escrever o nome certo quando nenhum palpite está certo;
// ? devolve null se cancelar ou deixar vazio
Future<String?> _pedirNome(BuildContext context) {
  final controlador = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogo) => AlertDialog(
      title: const Text('Que alimento é?'),
      content: TextField(
        controller: controlador,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Ex.: Iogurte de aroma'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogo),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            final nome = controlador.text.trim();
            Navigator.pop(dialogo, nome.isEmpty ? null : nome);
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
