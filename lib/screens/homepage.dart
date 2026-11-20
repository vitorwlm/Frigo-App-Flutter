// * ECRÃ INÍCIO — 1.º separador da HomeShell (main.dart).
// * Mostra: saudação + botões Avisos e Definições → cartão do estado do
// * frigorífico (toca → Histórico da temperatura) → "A expirar" (toca →
// * detalhe; Usei / ⋮) → receita do dia (toca → detalhe da receita).
// * Sem scroll de propósito (Figma, 1 nov): o mais urgente cabe num ecrã.

import 'package:flutter/material.dart';

import '../data/frigorifico.dart';
import '../models/item.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/hero_card.dart';
import '../widgets/estados.dart';
import '../widgets/item_row.dart';
import '../widgets/list_card.dart';
import '../widgets/recipe_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_title.dart';
import '../widgets/snack.dart';
import '../widgets/tag_chip.dart';
import '../main.dart';
import 'avisos.dart';
import 'definicoes.dart';
import 'detalhe_alimento.dart';
import 'historico_temperatura.dart';
import 'receita_detalhe.dart';
import 'ultima_foto.dart';

// ? StatelessWidget porque não guarda estado: os dados vêm todos do frigorifico
class Homepage extends StatelessWidget {
  const Homepage({super.key});

  // * ---- ações ----

  // ? Botão "Usei": tira 1 e mostra a snackbar com Anular. Guarda o "antes"
  // ? primeiro, porque o Anular precisa de saber para onde voltar
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

  // ? Abre o detalhe e espera que feche: o detalhe pode devolver uma
  // ? mensagem (ex.: "Guardado") para mostrar aqui numa snackbar
  Future<void> _abrirDetalhe(BuildContext context, Item item) async {
    final String? mensagem = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => DetalheAlimento(item: item)),
    );
    frigorifico.atualizar(item);
    // ! context.mounted: depois do await o ecrã pode já ter fechado
    if (mensagem != null && context.mounted) mostrarMensagem(context, mensagem);
  }

  // ? menu do botão ⋮ de cada linha. Bottom sheet em vez de mais botões na
  // ? linha, para a linha não ficar cheia (o Usei é o mais usado)
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
                // ? fecha a folha primeiro e usa o context do ecrã, não o da folha
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
                  mostrarAnular(
                    context,
                    'Usaste ${item.nome.toLowerCase()} a tempo',
                    () => frigorifico.repor(item, antes, Local.frigorifico),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppTokens.textDanger,
                ),
                title: const Text('Deitei fora'),
                onTap: () {
                  Navigator.pop(folha);
                  final int antes = item.quantidade;
                  frigorifico.deitarFora(item);
                  mostrarAnular(
                    context,
                    '${item.nome} deitado fora',
                    () => frigorifico.repor(item, antes, Local.frigorifico),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // * ---- interface ----

  @override
  Widget build(BuildContext context) {
    // ? a saudação muda com a hora do dia
    final int hora = DateTime.now().hour;
    String saudacao;
    if (hora < 12) {
      saudacao = 'Bom dia,';
    } else if (hora < 20) {
      saudacao = 'Boa tarde,';
    } else {
      saudacao = 'Boa noite,';
    }

    // ? ListenableBuilder redesenha o ecrã sempre que o frigorifico avisa
    // ? (ex.: chegou uma leitura nova pelo Realtime)
    return ListenableBuilder(
      listenable: frigorifico,
      builder: (context, _) {
        final aExpirar = frigorifico.aExpirar;
        // ? o número no sino só conta os urgentes (hoje ou amanhã)
        final int urgentes = aExpirar.where((i) => i.dias <= 1).length;
        final receita = frigorifico.receitaDoDia;
        final textTheme = Theme.of(context).textTheme;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.midsmall,
              AppSpacing.midsmall,
              AppSpacing.midsmall,
              // ? 88 em baixo para o botão flutuante não tapar a última linha
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
                      MaterialPageRoute(
                        builder: (context) => const Definicoes(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.midsmall),
              // ? o Supabase falhou (ex.: SQL por correr): avisa em vez de
              // ? mostrar dados de exemplo como se fossem verdadeiros
              if (!frigorifico.naNuvem && frigorifico.erroNuvem != null) ...[
                AppCard(
                  child: Text(
                    'Não foi possível ler o Supabase.\n'
                    '${frigorifico.erroNuvem}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppTokens.textDanger,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.midsmall),
              ],
              _HeroInicio(
                // ? o estado vem dos sensores (ou da Demonstração nas Definições)
                estado: frigorifico.estado,
                total: frigorifico.totalEmCasa,
                // ? o link do cartão muda com o estado (como no Figma):
                // ? Ver foto (18), Histórico (20) ou Ver inventário
                onAbrir: () {
                  switch (frigorifico.estado) {
                    case EstadoFrigu.ok:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UltimaFoto(),
                        ),
                      );
                    case EstadoFrigu.temperaturaAlta:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoricoTemperatura(),
                        ),
                      );
                    case EstadoFrigu.semLigacao:
                      separadorAtual.value = 1;
                    case EstadoFrigu.portaAberta:
                      break;
                  }
                },
              ),
              // ? frigorífico vazio (ecrã 26): uma mensagem a meio em vez das
              // ? secções A expirar e Cozinha isto hoje, que ficavam vazias
              if (frigorifico.totalEmCasa == 0) ...[
                const SizedBox(height: AppSpacing.large * 2),
                const EstadoVazio(
                  titulo: 'O frigorífico está vazio!',
                  texto:
                      'Adiciona o que compraste ao frigorífico!\n'
                      'O frigo diz-te o que está a expirar',
                ),
              ] else ...[
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
                // ? sem receitas na base de dados não mostra a secção; com a
                // ? temperatura alta também não, para o foco ficar no problema
                if (receita != null &&
                    frigorifico.estado != EstadoFrigu.temperaturaAlta) ...[
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
            ],
          ),
        );
      },
    );
  }

  // ? Uma linha de "A expirar": a cor e a etiqueta vêm dos dias que faltam
  // ? (estadoDe, prazoDe e tomDe estão no item_row.dart)
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

// ? Cartão de cima do Início, muda conforme o estado (ecrãs 01, 02, 13, 19).
// ? Começa com os valores do estado "ok" e o switch só muda o que é diferente,
// ? para não repetir tudo em cada caso
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
    // ? atalho porque todo o texto do cartão é branco
    TextStyle? branco(TextStyle? s) => s?.copyWith(color: AppTokens.textOnHero);

    Color cor = AppTokens.heroOk;
    String pilula = 'Tudo bem';
    IconData icone = Icons.check_circle;
    String link = 'Ver foto';
    String numero = '$total';
    String unidade = 'alimentos';
    final f = frigorifico;
    final String alvo = '${numeroPt(f.alvoMin)}–${numeroPt(f.alvoMax)} °C';
    String direita1 = graus(f.temperatura);
    String direita2 = '${f.humidade} % humidade';
    String mensagem = 'Visto ${ha(f.ultimaLeitura)} · porta fechada';
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
        mensagem = 'Acima do alvo. Vê se a porta ficou mal fechada ou se há algo quente lá dentro.';
        botao = 'Já fechei a porta';
        acao = () {
          f.fecharPorta();
          mostrarMensagem(
            context,
            'Avisamos se a temperatura não voltar ao alvo',
          );
        };
      case EstadoFrigu.semLigacao:
        cor = AppTokens.heroOffline;
        pilula = 'Sem ligação';
        icone = Icons.wifi_off;
        link = 'Ver inventário';
        mensagem =
            'Última leitura ${ha(f.ultimaLeitura)} · a lista pode estar desatualizada';
        botao = 'Tentar ligar de novo';
        // ? async porque espera pela placa antes de dizer "Ligado de novo"
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
        // ! porque neste estado portaAbertaDesde nunca é null
        final int aberta = DateTime.now()
            .difference(f.portaAbertaDesde!)
            .inMinutes;
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
                // ? baseline para o número grande e a unidade ficarem na mesma
                // ? linha de texto, como no Figma
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
