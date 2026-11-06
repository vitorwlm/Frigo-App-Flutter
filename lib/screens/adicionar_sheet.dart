import 'package:flutter/material.dart';

import '../data/frigorifico.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/list_card.dart';
import '../widgets/option_tile.dart';
import '../widgets/snack.dart';
import 'filtros_sheet.dart';

// Folha "Adicionar alimento" (ecrã 03 do Figma)
void mostrarAdicionar(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppTokens.bgApp,
    builder: (folha) {
      final textTheme = Theme.of(folha).textTheme;
      return SafeArea(
        child: Padding(
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
              Text('Adicionar alimento', style: textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.small),
              Text(
                'A câmara do frigorífico deteta os alimentos sozinha. '
                'Usa isto só para o que ela não vê.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppTokens.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.midsmall),
              ListCard(
                children: [
                  OptionTile(
                    icone: Icons.photo_camera_outlined,
                    titulo: 'Tirar foto agora',
                    descricao: 'Atualiza com a câmara do frigorífico',
                    onTap: () {
                      Navigator.pop(folha);
                      // mais tarde: chama a Edge Function analisar-foto
                      mostrarMensagem(context, 'Pedido enviado à câmara');
                    },
                  ),
                  OptionTile(
                    icone: Icons.qr_code_scanner,
                    titulo: 'Ler código de barras',
                    descricao: 'Validade e nome automáticos',
                    tom: OpcaoTom.suave,
                    onTap: () {
                      Navigator.pop(folha);
                      mostrarMensagem(context, 'Disponível em breve');
                    },
                  ),
                  OptionTile(
                    icone: Icons.edit_outlined,
                    titulo: 'Escrever à mão',
                    descricao: 'Sobras, alimentos sem embalagem',
                    tom: OpcaoTom.neutro,
                    onTap: () {
                      Navigator.pop(folha);
                      _escreverAMao(context);
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

// Janela para escrever um alimento à mão
Future<void> _escreverAMao(BuildContext context) async {
  // TextEditingController guarda o texto escrito num TextField
  final nome = TextEditingController();
  final quantidade = TextEditingController(text: '1');
  final dias = TextEditingController(text: '3');
  String unidade = 'unidades';
  String categoria = 'Sobras';

  final bool? guardar = await showDialog<bool>(
    context: context,
    builder: (dialogo) => StatefulBuilder(
      builder: (dialogo, setDialogo) => AlertDialog(
        title: const Text('Escrever à mão'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nome,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantidade,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantidade'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  // DropdownButton = lista que abre ao tocar
                  DropdownButton<String>(
                    value: unidade,
                    items: const [
                      DropdownMenuItem(value: 'unidades', child: Text('unidades')),
                      DropdownMenuItem(value: 'g', child: Text('g')),
                      DropdownMenuItem(value: 'L', child: Text('L')),
                      DropdownMenuItem(value: 'caixa', child: Text('caixa')),
                    ],
                    onChanged: (v) => setDialogo(() => unidade = v!),
                  ),
                ],
              ),
              TextField(
                controller: dias,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Dias até expirar',
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              DropdownButton<String>(
                value: categoria,
                isExpanded: true,
                items: [
                  for (final c in todasCategorias)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setDialogo(() => categoria = v!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );

  if (guardar != true || nome.text.trim().isEmpty) return;
  final int q = int.tryParse(quantidade.text) ?? 0;
  final int d = int.tryParse(dias.text) ?? -1;
  // não aceita quantidade 0 nem validade no passado
  if (q <= 0 || d < 0) {
    if (context.mounted) {
      mostrarMensagem(context, 'Quantidade e dias têm de ser números positivos');
    }
    return;
  }
  frigorifico.adicionar(
    nome: nome.text.trim(),
    // tryParse devolve null se o texto não for um número
    quantidade: q,
    unidade: unidade,
    dias: d,
    categoria: categoria,
  );
  if (context.mounted) mostrarMensagem(context, '${nome.text.trim()} adicionado');
}
