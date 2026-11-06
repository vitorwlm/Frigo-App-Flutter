import 'package:flutter/material.dart';

import '../data/frigorifico.dart';
import '../models/item.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/hero_card.dart';
import '../widgets/item_row.dart';
import '../widgets/list_card.dart';
import '../widgets/recipe_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_title.dart';
import '../widgets/snack.dart';
import '../widgets/tag_chip.dart';
import 'avisos.dart';
import 'definicoes.dart';
import 'detalhe_alimento.dart';
import 'historico_temperatura.dart';
import 'receita_detalhe.dart';

// "há 2 min", "há 3 h"
String _ha(DateTime t) {
  final int min = DateTime.now().difference(t).inMinutes;
  if (min < 1) return 'agora';
  if (min < 60) return 'há $min min';
  return 'há ${min ~/ 60} h';
}

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  // ---- ações ----

  void _usei(BuildContext context, Item item) {
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

  Future<void> _abrirDetalhe(BuildContext context, Item item) async {
    final String? mensagem = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => DetalheAlimento(item: item)),
    );
    frigorifico.atualizar(item);
    if (mensagem != null && context.mounted) mostrarMensagem(context, mensagem);
  }

  // menu do botão ⋮ de cada linha
  void _maisOpcoes(BuildContext context, Item item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (folha) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Ver detalhes'),
              onTap: () {
                Navigator.pop(folha);
                _abrirDetalhe(context, item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.done_all),
              title: const Text('Usei tudo'),
              onTap: () {
                Navigator.pop(folha);
                final int antes = item.quantidade;
                frigorifico.usarTudo(item);
                mostrarAnular(context, 'Usaste ${item.nome.toLowerCase()} a tempo',
                    () => frigorifico.repor(item, antes, Local.frigorifico));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTokens.textDanger),
              title: const Text('Deitei fora'),
              onTap: () {
                Navigator.pop(folha);
                final int antes = item.quantidade;
                frigorifico.deitarFora(item);
                mostrarAnular(context, '${item.nome} deitado fora',
                    () => frigorifico.repor(item, antes, Local.frigorifico));
              },
            ),
          ],
          ),
        ),
      ),
    );
  }

  // ---- interface ----

  @override
  Widget build(BuildContext context) {
    final int hora = DateTime.now().hour;
    String saudacao;
    if (hora < 12) {
      saudacao = 'Bom dia,';
    } else if (hora < 20) {
      saudacao = 'Boa tarde,';
    } else {
      saudacao = 'Boa noite,';
    }

    // ListenableBuilder redesenha o ecrã sempre que o frigorifico avisa
    return ListenableBuilder(
      listenable: frigorifico,
      builder: (context, _) {
        final aExpirar = frigorifico.aExpirar;
        final int urgentes = aExpirar.where((i) => i.dias <= 1).length;
        final receita = frigorifico.receitaDoDia;
        final textTheme = Theme.of(context).textTheme;

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
                subtitulo: saudacao,
                titulo: frigorifico.nomeUtilizador.isEmpty
                    ? 'Olá'
                    : frigorifico.nomeUtilizador,
                acoes: [
                  CircleIconButton(
                    icone: Icons.notifications_none,
                    tooltip: 'Avisos',
                    badge: urgentes > 0 ? '$urgentes' : null,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Avisos()),
                    ),
                  ),
                  CircleIconButton(
                    icone: Icons.settings_outlined,
                    tooltip: 'Definições',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Definicoes()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.midsmall),
              // o Supabase falhou (ex.: SQL por correr): avisa e usa os falsos
              if (!frigorifico.naNuvem && frigorifico.erroNuvem != null) ...[
                AppCard(
                  child: Text(
                    'Não foi possível ler o Supabase. A mostrar dados de '
                    'exemplo.\n${frigorifico.erroNuvem}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppTokens.textDanger,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.midsmall),
              ],
              _HeroInicio(
                // o estado vem dos sensores (Demonstração nas Definições)
                estado: frigorifico.estado,
                total: frigorifico.totalEmCasa,
                onAbrir: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoricoTemperatura(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.mid),
              SectionTitle(titulo: 'A expirar', contador: aExpirar.length),
              const SizedBox(height: AppSpacing.small),
              if (aExpirar.isEmpty)
                AppCard(
                  child: Text(
                    'Nada a expirar nos próximos 4 dias.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTokens.textSecondary,
                    ),
                  ),
                )
              else
                ListCard(
                  children: [
                    for (final item in aExpirar) _linha(context, item),
                  ],
                ),
              if (frigorifico.estado != EstadoFrigu.temperaturaAlta) ...[
                const SizedBox(height: AppSpacing.mid),
                const SectionTitle(titulo: 'Cozinha isto hoje'),
                const SizedBox(height: AppSpacing.small),
                RecipeCard(
                  titulo: receita.titulo,
                  descricao: receita.descricao,
                  estado: receita.estado(receita.pessoasBase),
                  minutos: receita.minutos,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReceitaDetalhe(receita: receita),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _linha(BuildContext context, Item item) {
    final EstadoValidade estado = estadoDe(item.dias);
    return ItemRow(
      titulo: item.nome,
      detalhe: item.quantidadeTexto,
      estado: estado,
      chip: TagChip(texto: prazoDe(item.dias), tom: tomDe(estado)),
      onTap: () => _abrirDetalhe(context, item),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(
            texto: 'Usei',
            tipo: BotaoTipo.tonal,
            icone: Icons.check,
            onPressed: () => _usei(context, item),
          ),
          CircleIconButton(
            icone: Icons.more_vert,
            tooltip: 'Mais opções',
            estilo: CirculoEstilo.transparente,
            onPressed: () => _maisOpcoes(context, item),
          ),
        ],
      ),
    );
  }
}

// Cartão de cima do Início, muda conforme o estado
class _HeroInicio extends StatelessWidget {
  const _HeroInicio({
    required this.estado,
    required this.total,
    required this.onAbrir,
  });

  final EstadoFrigu estado;
  final int total;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    TextStyle? branco(TextStyle? s) => s?.copyWith(color: AppTokens.textOnHero);

    Color cor = AppTokens.heroOk;
    String pilula = 'Tudo bem';
    IconData icone = Icons.check_circle;
    String link = 'Detalhes';
    String numero = '$total';
    String unidade = 'alimentos';
    final f = frigorifico;
    final String alvo =
        '${numeroPt(f.alvoMin)}–${numeroPt(f.alvoMax)} °C';
    String direita1 = graus(f.temperatura);
    String direita2 = '${f.humidade} % humidade';
    String mensagem = 'Visto ${_ha(f.ultimaLeitura)} · porta fechada';
    String? botao;
    VoidCallback? acao;

    switch (estado) {
      case EstadoFrigu.ok:
        break;
      case EstadoFrigu.temperaturaAlta:
        cor = AppTokens.heroDanger;
        pilula = 'Temperatura alta';
        icone = Icons.warning_amber_rounded;
        link = 'Histórico';
        numero = graus(f.temperatura);
        unidade = 'alvo $alvo';
        direita1 = '';
        direita2 = '';
        mensagem =
            'Acima do alvo. Vê se a porta ficou mal fechada ou se há algo quente lá dentro.';
        botao = 'Já fechei a porta';
        acao = () {
          f.fecharPorta();
          mostrarMensagem(context, 'Avisamos se a temperatura não voltar ao alvo');
        };
      case EstadoFrigu.semLigacao:
        cor = AppTokens.heroOffline;
        pilula = 'Sem ligação';
        icone = Icons.wifi_off;
        link = '';
        mensagem =
            'Última leitura ${_ha(f.ultimaLeitura)} · a lista pode estar desatualizada';
        botao = 'Tentar ligar de novo';
        acao = () async {
          mostrarMensagem(context, 'A ligar ao Frigu…');
          await f.reconectar();
          if (context.mounted) mostrarMensagem(context, 'Ligado de novo');
        };
      case EstadoFrigu.portaAberta:
        cor = AppTokens.heroWarning;
        pilula = 'Porta aberta';
        icone = Icons.door_front_door_outlined;
        link = '';
        final int aberta =
            DateTime.now().difference(f.portaAbertaDesde!).inMinutes;
        numero = '$aberta min';
        unidade = 'aberta';
        direita2 = 'a subir';
        mensagem =
            'Fecha a porta para o frigorífico voltar aos $alvo. Avisamos outra vez aos 5 min.';
    }

    return HeroCard(
      cor: cor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HeroPill(texto: pilula, icone: icone),
              const Spacer(),
              if (link.isNotEmpty)
                InkWell(
                  onTap: onAbrir,
                  child: Row(
                    children: [
                      Text(link, style: branco(textTheme.labelLarge)),
                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppTokens.textOnHero,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.midsmall),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(numero, style: branco(textTheme.displayLarge)),
                    const SizedBox(width: AppSpacing.small),
                    Flexible(
                      child: Text(
                        unidade,
                        style: branco(
                          estado == EstadoFrigu.temperaturaAlta
                              ? textTheme.labelMedium
                              : textTheme.headlineSmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (direita1.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(direita1, style: branco(textTheme.labelLarge)),
                    Text(direita2, style: branco(textTheme.bodySmall)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(mensagem, style: branco(textTheme.bodySmall)),
          if (botao != null) ...[
            const SizedBox(height: AppSpacing.midsmall),
            AppButton(
              texto: botao,
              cor: BotaoCor.neutral,
              icone: estado == EstadoFrigu.temperaturaAlta ? Icons.check : null,
              expandir: true,
              onPressed: acao,
            ),
          ],
        ],
      ),
    );
  }
}
