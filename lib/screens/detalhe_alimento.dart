import 'package:flutter/material.dart';

import '../data/frigorifico.dart';
import '../models/item.dart';
import '../models/receita.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/hero_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/tag_chip.dart';
import 'receita_detalhe.dart';

const List<String> _meses = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

String _data(DateTime d) => '${d.day} ${_meses[d.month - 1]}';

// Ecrã 06 do Figma. Muda o item recebido e, ao sair, devolve uma mensagem.
class DetalheAlimento extends StatefulWidget {
  const DetalheAlimento({super.key, required this.item});

  final Item item;

  @override
  State<DetalheAlimento> createState() => _DetalheAlimentoState();
}

class _DetalheAlimentoState extends State<DetalheAlimento> {
  // widget.item = o item passado ao construtor
  Item get item => widget.item;

  int get _passo => item.porUnidade ? 1 : 50;

  List<Receita> get _receitas {
    // receitas com um ingrediente que tenha a 1.ª palavra do nome do alimento
    final String chave = item.nome.split(' ').first.toLowerCase();
    return frigorifico.receitas
        .where((r) => r.ingredientes.any(
              (i) => i.plural.toLowerCase().contains(chave) ||
                  i.nome.toLowerCase().contains(chave),
            ))
        .toList();
  }

  void _sair(String mensagem) => Navigator.pop(context, mensagem);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    TextStyle? branco(TextStyle? s) => s?.copyWith(color: AppTokens.textOnHero);

    final int dias = item.dias;
    String prazo;
    if (dias <= 0) {
      prazo = 'Expira hoje';
    } else if (dias == 1) {
      prazo = 'Expira amanhã';
    } else {
      prazo = 'Expira em $dias dias';
    }
    final int passados = item.diasTotais - (dias < 0 ? 0 : dias);
    final receitas = _receitas;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.midsmall),
          children: [
            ScreenHeader(
              voltar: true,
              subtitulo: item.prateleira,
              titulo: item.nome,
              acoes: [
                CircleIconButton(
                  icone: Icons.edit_outlined,
                  tooltip: 'Editar',
                  onPressed: () => debugPrint('editar'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.midsmall),
            HeroCard(
              cor: AppTokens.heroOk,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TagChip(
                    texto: prazo,
                    tom: dias <= 0 ? TagTom.perigo : TagTom.aviso,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        dias <= 0 ? 'Hoje' : (dias == 1 ? '1 dia' : '$dias dias'),
                        style: branco(textTheme.displayLarge),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Text(
                        'até ${_data(item.validade)}',
                        style: branco(textTheme.bodyMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.midsmall),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: LinearProgressIndicator(
                      value: passados / item.diasTotais,
                      minHeight: 8,
                      backgroundColor: AppTokens.heroBorder,
                      color: AppColors.danger300,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Visto pela câmara a ${_data(item.entrada)}',
                          style: branco(textTheme.bodySmall),
                        ),
                      ),
                      Text(
                        'dia $passados de ${item.diasTotais}',
                        style: branco(textTheme.bodySmall),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.midsmall),
            // Quantidade e aberto
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.midsmall,
                      AppSpacing.small,
                      AppSpacing.small,
                      AppSpacing.small,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quantidade',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppTokens.textSecondary,
                                ),
                              ),
                              Text(item.quantidadeTexto, style: textTheme.labelLarge),
                            ],
                          ),
                        ),
                        CircleIconButton(
                          icone: Icons.remove,
                          tooltip: 'Menos',
                          estilo: CirculoEstilo.contorno,
                          // null desativa o botão: não desce abaixo de 1 passo
                          onPressed: item.quantidade > _passo
                              ? () => setState(() => item.quantidade -= _passo)
                              : null,
                        ),
                        const SizedBox(width: AppSpacing.small),
                        CircleIconButton(
                          icone: Icons.add,
                          tooltip: 'Mais',
                          estilo: CirculoEstilo.contorno,
                          onPressed: () =>
                              setState(() => item.quantidade += _passo),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTokens.border),
                  SwitchListTile(
                    title: Text(
                      'Aberto',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppTokens.textSecondary,
                      ),
                    ),
                    value: item.aberto,
                    onChanged: (v) => setState(() => item.aberto = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.midsmall),
            // Congelar
            if (item.local == Local.frigorifico)
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTokens.bgTonalSoft,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.ac_unit, color: AppColors.primary600),
                    ),
                    const SizedBox(width: AppSpacing.midsmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Não vais usar a tempo?', style: textTheme.labelLarge),
                          Text(
                            'Congela e dura muito mais',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      texto: 'Congelar',
                      tipo: BotaoTipo.tonal,
                      onPressed: () {
                        frigorifico.congelar(item);
                        _sair('${item.nome} foi para a arca');
                      },
                    ),
                  ],
                ),
              ),
            // Receitas que usam este alimento
            if (receitas.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.midsmall),
              AppCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReceitaDetalhe(receita: receitas.first),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${receitas.length} '
                                    '${receitas.length == 1 ? 'receita usa' : 'receitas usam'} '
                                    '${item.nome}'
                                .toUpperCase(),
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.primary500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            // map + join: junta os títulos separados por vírgula
                            receitas.map((r) => r.titulo).join(', '),
                            style: textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      // botões sempre visíveis em baixo
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.midsmall),
          child: Row(
            children: [
              AppButton(
                texto: 'Deitei fora',
                tipo: BotaoTipo.stroke,
                cor: BotaoCor.accent,
                icone: Icons.delete_outline,
                onPressed: () {
                  frigorifico.deitarFora(item);
                  _sair('${item.nome} deitado fora');
                },
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: AppButton(
                  texto: 'Usei tudo',
                  icone: Icons.check,
                  expandir: true,
                  onPressed: () {
                    frigorifico.usarTudo(item);
                    _sair('Usaste ${item.nome.toLowerCase()} a tempo');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
