import 'package:flutter/material.dart';

import '../data/frigorifico.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/list_card.dart';
import '../widgets/item_row.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_title.dart';
import '../widgets/snack.dart';
import '../widgets/tag_chip.dart';
import 'onboarding.dart';


String _nomeEstado(EstadoFrigu e) {
  switch (e) {
    case EstadoFrigu.ok:
      return 'Tudo bem';
    case EstadoFrigu.temperaturaAlta:
      return 'Temperatura alta';
    case EstadoFrigu.semLigacao:
      return 'Sem ligação';
    case EstadoFrigu.portaAberta:
      return 'Porta aberta';
  }
}

// Ecrã 14 do Figma
class Definicoes extends StatelessWidget {
  const Definicoes({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const seta = Icon(Icons.chevron_right, color: AppTokens.textPrimary);

    return Scaffold(
      body: SafeArea(
        // redesenha quando uma definição muda
        child: ListenableBuilder(
          listenable: frigorifico,
          builder: (context, _) {
            final int dias = frigorifico.diasAviso;

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.midsmall,
                AppSpacing.midsmall,
                AppSpacing.midsmall,
                AppSpacing.mid,
              ),
              children: [
                const ScreenHeader(
                  subtitulo: 'Frigu',
                  titulo: 'Definições',
                  voltar: true,
                ),
                const SizedBox(height: AppSpacing.midsmall),

                // ---- Avisos ----
                const SectionTitle(titulo: 'Avisos'),
                const SizedBox(height: AppSpacing.midsmall),
                ListCard(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.midsmall),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Avisar-me com antecedência de',
                            style: textTheme.labelLarge,
                          ),
                          const SizedBox(height: AppSpacing.small),
                          SegmentedButton<int>(
                            showSelectedIcon: false,
                            // ocupa a largura toda
                            expandedInsets: EdgeInsets.zero,
                            segments: const [
                              ButtonSegment(value: 1, label: Text('1 dia')),
                              ButtonSegment(value: 2, label: Text('2 dias')),
                              ButtonSegment(value: 3, label: Text('3 dias')),
                            ],
                            selected: {dias},
                            onSelectionChanged: (s) =>
                                frigorifico.mudarDiasAviso(s.first),
                          ),
                        ],
                      ),
                    ),
                    ItemRow(
                      titulo: 'Resumo diário às 8:00',
                      detalhe: dias == 1
                          ? 'O que expira amanhã'
                          : 'O que expira nos próximos $dias dias',
                      trailing: Switch(
                        value: frigorifico.resumoDiario,
                        onChanged: frigorifico.mudarResumoDiario,
                      ),
                      // tocar na linha também liga/desliga
                      onTap: () => frigorifico.mudarResumoDiario(
                        !frigorifico.resumoDiario,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.midsmall),

                // ---- Frigorífico ----
                const SectionTitle(titulo: 'Frigorífico'),
                const SizedBox(height: AppSpacing.midsmall),
                ListCard(
                  children: [
                    ItemRow(
                      titulo: 'Temperatura-alvo',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TagChip(
                            texto:
                                '${numeroPt(frigorifico.alvoMin)}–${numeroPt(frigorifico.alvoMax)} °C',
                          ),
                          const SizedBox(width: AppSpacing.small),
                          seta,
                        ],
                      ),
                      onTap: () => _mudarTemperatura(context),
                    ),
                    ItemRow(
                      titulo: 'Câmara',
                      detalhe: 'Tira uma foto quando a porta fecha',
                      trailing: seta,
                      // reabre o passo do Wi-Fi do onboarding
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const LigarFrigorifico(dasDefinicoes: true),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.midsmall),

                // ---- Demonstração ----
                // muda os sensores falsos para ver os 4 estados do Início
                const SectionTitle(titulo: 'Demonstração'),
                const SizedBox(height: AppSpacing.midsmall),
                ListCard(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.midsmall),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Estado do frigorífico', style: textTheme.labelLarge),
                          const SizedBox(height: AppSpacing.small),
                          if (frigorifico.temLeiturasReais)
                            Text(
                              'Há leituras da placa: o estado volta ao real '
                              'na próxima leitura.',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppTokens.textSecondary,
                              ),
                            ),
                          Wrap(
                            spacing: AppSpacing.small,
                            runSpacing: AppSpacing.small,
                            children: [
                              for (final e in EstadoFrigu.values)
                                ChoiceChip(
                                  label: Text(_nomeEstado(e)),
                                  selected: frigorifico.estado == e,
                                  onSelected: (_) => frigorifico.simular(e),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ItemRow(
                      titulo: 'Pôr alimentos de exemplo',
                      detalhe: 'Envia os alimentos de teste para o Supabase',
                      trailing: seta,
                      onTap: () async {
                        final msg = await frigorifico.enviarExemplos();
                        if (context.mounted) mostrarMensagem(context, msg);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.midsmall),

                // ---- Conta ----
                const SectionTitle(titulo: 'Conta'),
                const SizedBox(height: AppSpacing.midsmall),
                ListCard(
                  children: [
                    ItemRow(
                      titulo: frigorifico.nomeUtilizador,
                      detalhe: frigorifico.email,
                      trailing: TagChip(
                        texto: frigorifico.eAdmin ? 'Administrador' : 'Utilizador',
                        tom: frigorifico.eAdmin ? TagTom.marca : TagTom.neutro,
                      ),
                    ),
                    ItemRow(
                      titulo: 'Terminar sessão',
                      corTitulo: AppTokens.textDanger,
                      onTap: () => _terminarSessao(context),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Folha com um RangeSlider para escolher o mínimo e o máximo
  void _mudarTemperatura(BuildContext context) {
    RangeValues valores = RangeValues(frigorifico.alvoMin, frigorifico.alvoMax);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;
        // StatefulBuilder: setState só para esta folha
        return StatefulBuilder(
          builder: (context, setFolha) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.midsmall,
              0,
              AppSpacing.midsmall,
              AppSpacing.mid,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Temperatura-alvo', style: textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.small),
                Text(
                  '${numeroPt(valores.start)}–${numeroPt(valores.end)} °C',
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppTokens.textBrand,
                  ),
                ),
                RangeSlider(
                  values: valores,
                  min: 0,
                  max: 8,
                  // passos de 0,5 °C
                  divisions: 16,
                  onChanged: (v) {
                    // pelo menos 1 °C entre o mínimo e o máximo
                    if (v.end - v.start >= 1) setFolha(() => valores = v);
                  },
                ),
                Text(
                  'Acima do máximo durante 5 min, a app avisa-te.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.midsmall),
                AppButton(
                  texto: 'Guardar',
                  expandir: true,
                  onPressed: () async {
                    // guarda o messenger antes de fechar a folha
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    final erro =
                        await frigorifico.mudarAlvo(valores.start, valores.end);
                    if (erro != null) {
                      messenger.showSnackBar(SnackBar(content: Text(erro)));
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _terminarSessao(BuildContext context) async {
    // showDialog devolve o valor passado ao Navigator.pop
    final bool? sim = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminar sessão?'),
        content: const Text('Tens de voltar a entrar para ver o frigorífico.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Terminar sessão',
              style: TextStyle(color: AppTokens.textDanger),
            ),
          ),
        ],
      ),
    );
    // mounted = o ecrã ainda existe depois do await
    if (sim == true && context.mounted) {
      // fecha os ecrãs por cima: o _PortaoLogin do main.dart mostra o Login
      Navigator.popUntil(context, (rota) => rota.isFirst);
      await frigorifico.sair();
    }
  }
}
