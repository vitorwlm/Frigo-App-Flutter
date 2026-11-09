import 'package:flutter/material.dart';

import '../data/frigorifico.dart';
import '../models/receita.dart';
import '../services/nuvem.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/item_row.dart';
import '../widgets/list_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_title.dart';
import '../widgets/snack.dart';
import '../widgets/tag_chip.dart';
import 'editar_receita.dart';

// ? "1 dia" / "7 dias": singular e plural certos
String _textoDias(int n) => n == 1 ? '1 dia' : '$n dias';

// * ECRÃ ADMINISTRAÇÃO (só aparece ao admin, nas Definições).
// * CRUD das receitas (toca / Nova receita → EditarReceita) e dos dias de
// * validade por categoria (caixa _editarValidade). As escritas passam pelo
// * frigorifico e o RLS do Supabase confirma que és mesmo admin.
class Admin extends StatelessWidget {
  const Admin({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const seta = Icon(Icons.chevron_right, color: AppTokens.textPrimary);

    return Scaffold(
      body: SafeArea(
        // ? redesenha quando uma receita ou validade muda (também pelo
        // ? Realtime, se outro admin mudar)
        child: ListenableBuilder(
          listenable: frigorifico,
          builder: (context, _) {
            final receitas = frigorifico.receitas;
            // ? categorias por ordem alfabética do nome com acentos (pela
            // ? chave, "laticinios" ficava fora do sítio)
            final categorias = frigorifico.validades.keys.toList()
              ..sort((a, b) => nomeValidade(a).compareTo(nomeValidade(b)));

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.midsmall,
                AppSpacing.midsmall,
                AppSpacing.midsmall,
                AppSpacing.mid,
              ),
              children: [
                const ScreenHeader(
                  subtitulo: 'Só administrador',
                  titulo: 'Administração',
                  voltar: true,
                ),
                const SizedBox(height: AppSpacing.midsmall),

                // * ---- Receitas ----
                SectionTitle(titulo: 'Receitas', contador: receitas.length),
                const SizedBox(height: AppSpacing.small),
                if (receitas.isEmpty)
                  Text(
                    'Ainda não há receitas.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTokens.textSecondary,
                    ),
                  )
                else
                  ListCard(
                    children: [
                      for (final r in receitas)
                        ItemRow(
                          titulo: r.titulo,
                          detalhe:
                              '${r.minutos} min · '
                              '${r.ingredientes.length} ingredientes · '
                              '${r.pessoasBase} pessoas',
                          trailing: seta,
                          onTap: () => _abrirReceita(context, r),
                        ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.small),
                AppButton(
                  texto: 'Nova receita',
                  icone: Icons.add,
                  tipo: BotaoTipo.tonal,
                  expandir: true,
                  onPressed: () => _abrirReceita(context, null),
                ),
                const SizedBox(height: AppSpacing.mid),

                // * ---- Validades ----
                SectionTitle(
                  titulo: 'Validades por categoria',
                  contador: categorias.length,
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  'Dias até expirar quando um alimento entra sem validade.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.small),
                if (categorias.isNotEmpty)
                  ListCard(
                    children: [
                      for (final c in categorias)
                        ItemRow(
                          titulo: nomeValidade(c),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TagChip(
                                texto: _textoDias(frigorifico.validades[c]!),
                              ),
                              const SizedBox(width: AppSpacing.small),
                              seta,
                            ],
                          ),
                          onTap: () => _editarValidade(context, c),
                        ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.small),
                AppButton(
                  texto: 'Nova categoria',
                  icone: Icons.add,
                  tipo: BotaoTipo.tonal,
                  expandir: true,
                  onPressed: () => _editarValidade(context, null),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ? null = receita nova: o mesmo ecrã serve para criar e para editar
  void _abrirReceita(BuildContext context, Receita? r) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditarReceita(receita: r)),
    );
  }

  // ? Caixa para criar (categoria null) ou mudar/apagar uma categoria.
  // ? Caixa e não ecrã porque são só 2 campos
  Future<void> _editarValidade(BuildContext context, String? categoria) async {
    final bool nova = categoria == null;
    final nome = TextEditingController();
    final dias = TextEditingController(
      text: nova ? '7' : '${frigorifico.validades[categoria]}',
    );

    // ? a caixa devolve 'guardar', 'apagar' ou null (Cancelar), para tratar
    // ? as 3 saídas aqui em baixo num só sítio
    final String? acao = await showDialog<String>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: Text(nova ? 'Nova categoria' : nomeValidade(categoria)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (nova)
              TextField(
                controller: nome,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
            TextField(
              controller: dias,
              autofocus: !nova,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Dias até expirar'),
            ),
          ],
        ),
        actions: [
          if (!nova)
            TextButton(
              onPressed: () => Navigator.pop(dialogo, 'apagar'),
              child: const Text(
                'Apagar',
                style: TextStyle(color: AppTokens.textDanger),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogo),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogo, 'guardar'),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    // ! context.mounted: depois do await o ecrã pode já ter fechado
    if (acao == null || !context.mounted) return;

    String? erro;
    if (acao == 'apagar') {
      // ? apagar pede confirmação porque não dá para desfazer
      final bool sim = await confirmar(
        context,
        titulo: 'Apagar ${nomeValidade(categoria!)}?',
        texto: 'Os alimentos desta categoria ficam sem categoria.',
        botao: 'Apagar',
      );
      if (!sim) return;
      erro = await frigorifico.apagarValidade(categoria);
    } else {
      final int? n = int.tryParse(dias.text.trim());
      // ? categoria nova: "Frutos secos" → "frutos_secos" (nuvem.dart)
      final String chave = nova ? chaveNova(nome.text) : categoria;
      if (n == null || n <= 0 || chave.isEmpty) {
        mostrarMensagem(
          context,
          'Escreve um nome e um número de dias maior que 0.',
        );
        return;
      }
      // ? o upsert ia substituir a que já existe sem avisar
      if (nova && frigorifico.validades.containsKey(chave)) {
        mostrarMensagem(
          context,
          'Já existe a categoria ${nomeValidade(chave)}.',
        );
        return;
      }
      erro = await frigorifico.guardarValidade(chave, n);
    }
    if (!context.mounted) return;
    mostrarMensagem(
      context,
      erro ?? (acao == 'apagar' ? 'Categoria apagada' : 'Guardado'),
    );
  }
}

// ? Pergunta "tens a certeza?"; devolve true se carregar no botão vermelho.
// ? Fora da classe e pública porque o EditarReceita também a usa
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String texto,
  required String botao,
}) async {
  final bool? sim = await showDialog<bool>(
    context: context,
    builder: (dialogo) => AlertDialog(
      title: Text(titulo),
      content: Text(texto),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogo, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogo, true),
          child: Text(
            botao,
            style: const TextStyle(color: AppTokens.textDanger),
          ),
        ),
      ],
    ),
  );
  return sim == true;
}
