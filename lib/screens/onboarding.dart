// * ONBOARDING — só aparece a seguir a criar conta (frigorifico.verBoasVindas).
// * Fluxo: Boas-vindas (ecrã 15) → Começar → Ligar ao frigorífico (ecrã 16)
// * → Ligar → Escolher avisos (ecrã 17) → Concluir → irParaApp → HomeShell.
// * O Ligar ao frigorífico também abre pelas
// * Definições (dasDefinicoes), e aí volta atrás no fim.

import 'package:flutter/material.dart';

import '../data/frigorifico.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/item_row.dart';
import '../widgets/list_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_title.dart';
import '../widgets/small_widgets.dart';
import '../widgets/tag_chip.dart';
import 'confirmar_sheet.dart';

// ? Fecha o onboarding: o _Arranque do main.dart passa a mostrar a app.
// ? Função fora das classes porque o Saltar e o Ligar fazem o mesmo.
// ? popUntil fecha os ecrãs empilhados por cima (ex.: Ligar ao frigorífico).
void irParaApp(BuildContext context) {
  frigorifico.verBoasVindas = false;
  frigorifico.atualizar();
  Navigator.popUntil(context, (rota) => rota.isFirst);
}

// ? Rodapé dos passos: pontos + botão principal (igual nos dois ecrãs,
// ? por isso é um widget à parte)
class _Rodape extends StatelessWidget {
  const _Rodape({
    required this.passo,
    required this.texto,
    required this.onPressed,
  });

  final int passo;
  final String texto;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.midsmall,
        AppSpacing.midsmall,
        AppSpacing.midsmall,
        AppSpacing.midlarge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PageDots(total: 3, atual: passo),
          const SizedBox(height: AppSpacing.mid),
          AppButton(texto: texto, expandir: true, onPressed: onPressed),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ecrã 15 · Boas-vindas
// ---------------------------------------------------------------------------
class BoasVindas extends StatelessWidget {
  const BoasVindas({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // ? função local porque as 3 vantagens só mudam o ícone e o texto
    Widget vantagem(IconData icone, String texto) => Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTokens.bgTonalSoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icone, size: 22, color: AppTokens.textBrand),
        ),
        const SizedBox(width: AppSpacing.midsmall),
        Expanded(child: Text(texto, style: textTheme.labelLarge)),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.midsmall,
                ),
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      texto: 'Saltar',
                      tipo: BotaoTipo.ghost,
                      onPressed: () => irParaApp(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.mid),
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: AppTokens.bgTonal,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: const Icon(
                      Icons.kitchen_outlined,
                      size: 96,
                      color: AppTokens.textBrand,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.mid),
                  Text('Menos comida no lixo', style: textTheme.headlineLarge),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    'O Frigu vê o que tens no frigorífico e avisa-te antes '
                    'de estragar.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.mid),
                  vantagem(Icons.photo_camera_outlined,
                      'A câmara regista o que entra e sai'),
                  const SizedBox(height: AppSpacing.midsmall),
                  vantagem(Icons.notifications_none,
                      'Avisos antes de os alimentos expirarem'),
                  const SizedBox(height: AppSpacing.midsmall),
                  vantagem(Icons.restaurant_menu,
                      'Receitas com o que está a acabar'),
                ],
              ),
            ),
            _Rodape(
              passo: 0,
              texto: 'Começar',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LigarFrigorifico(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ecrã 16 · Ligar ao frigorífico (Wi-Fi da placa)
// ---------------------------------------------------------------------------
class LigarFrigorifico extends StatefulWidget {
  // ? true quando se abre pelas Definições: no fim volta atrás em vez de
  // ? abrir a app de novo (o mesmo ecrã serve os dois caminhos)
  const LigarFrigorifico({super.key, this.dasDefinicoes = false});

  final bool dasDefinicoes;

  @override
  State<LigarFrigorifico> createState() => _LigarFrigorificoState();
}

class _LigarFrigorificoState extends State<LigarFrigorifico> {
  // ? redes falsas por agora; mais tarde vêm da placa (ESP32) por Bluetooth
  final List<(String, String)> _redes = [
    ('MEO-5G-Casa', 'Sinal forte'),
    ('Vodafone-2F1A', 'Sinal médio'),
  ];
  // ? ↑ (String, String) = "record": dois valores juntos, lidos com .$1 e .$2

  String _rede = 'MEO-5G-Casa';
  final _palavraPasse = TextEditingController();
  bool _aLigar = false;

  @override
  void dispose() {
    // ! os controladores têm de ser libertados quando o ecrã fecha, senão
    // ! ficam na memória
    _palavraPasse.dispose();
    super.dispose();
  }

  // ? "Outra rede…": pede o nome numa caixa de diálogo; o await espera
  // ? até a pessoa carregar OK ou Cancelar
  Future<void> _outraRede() async {
    final controlador = TextEditingController();
    final nome = await showDialog<String>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Nome da rede'),
        content: TextField(controller: controlador, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogo, controlador.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (nome != null && nome.isNotEmpty) {
      setState(() {
        _redes.add((nome, 'Escrita à mão'));
        _rede = nome;
      });
    }
  }

  Future<void> _ligar() async {
    setState(() => _aLigar = true);
    // ? por agora finge 2 s; mais tarde envia a rede e a palavra-passe à placa
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _aLigar = false);

    if (widget.dasDefinicoes) {
      // ! guarda o messenger antes de fechar: depois do pop o context
      // ! deste ecrã deixa de existir e a snackbar não aparecia
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text('Frigu ligado a $_rede')));
    } else {
      // ? passo 3: escolher quando avisar
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EscolherAvisos()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final borda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: const BorderSide(color: AppTokens.border),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.midsmall,
                  AppSpacing.midsmall,
                  AppSpacing.midsmall,
                  AppSpacing.mid,
                ),
                children: [
                  ScreenHeader(
                    subtitulo: widget.dasDefinicoes ? 'Câmara' : 'Passo 2 de 3',
                    titulo: 'Ligar ao frigorífico',
                    voltar: true,
                  ),
                  const SizedBox(height: AppSpacing.midsmall),
                  // ? cartão "Frigu encontrado"
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.midsmall),
                    decoration: BoxDecoration(
                      color: AppTokens.bgTonalSoft,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi, size: 28, color: AppTokens.textBrand),
                        const SizedBox(width: AppSpacing.midsmall),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Frigu encontrado', style: textTheme.labelLarge),
                              Text(
                                'FRIGU-3A7C · por Bluetooth',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppTokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const TagChip(texto: 'Perto', tom: TagTom.marca),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.midsmall),
                  const SectionTitle(titulo: 'Escolhe a rede Wi-Fi de casa'),
                  const SizedBox(height: AppSpacing.midsmall),
                  ListCard(
                    children: [
                      for (final r in _redes)
                        ItemRow(
                          titulo: r.$1,
                          detalhe: r.$2,
                          onTap: () => setState(() => _rede = r.$1),
                          trailing: MarcarCirculo(
                            marcado: r.$1 == _rede,
                            onPressed: () => setState(() => _rede = r.$1),
                          ),
                        ),
                      ItemRow(
                        titulo: 'Outra rede…',
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _outraRede,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.midsmall),
                  Text(
                    'Palavra-passe de $_rede',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  TextField(
                    controller: _palavraPasse,
                    // ? esconde o texto com pontos
                    obscureText: true,
                    // ? setState vazio só para redesenhar: o botão Ligar
                    // ? liga-se quando a palavra-passe deixa de estar vazia
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: AppTokens.bgSurface,
                      border: borda,
                      enabledBorder: borda,
                      focusedBorder: borda.copyWith(
                        borderSide: const BorderSide(
                          color: AppTokens.statusBrand,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    'O Frigu só usa a rede 2,4 GHz.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _Rodape(
              passo: 1,
              texto: _aLigar ? 'A ligar…' : 'Ligar',
              // ? null = botão desligado (sem palavra-passe ou já a ligar)
              onPressed: _palavraPasse.text.isEmpty || _aLigar ? null : _ligar,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ecrã 17 · Escolher avisos (passo 3 de 3)
// ---------------------------------------------------------------------------
class EscolherAvisos extends StatelessWidget {
  const EscolherAvisos({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        // ? redesenha quando muda a antecedência ou o resumo
        child: ListenableBuilder(
          listenable: frigorifico,
          builder: (context, _) {
            final int dias = frigorifico.diasAviso;
            final bool resumo = frigorifico.resumoDiario;

            // ? exemplo do aviso com um alimento que já tens; sem nenhum,
            // ? usa o do Figma
            final aAvisar = frigorifico.aExpirar
                .where((i) => i.dias <= dias)
                .toList();
            String exemplo = 'Iogurte natural expira amanhã';
            EstadoValidade estado = EstadoValidade.perigo;
            if (aAvisar.isNotEmpty) {
              final i = aAvisar.first;
              final quando = i.dias <= 0
                  ? 'hoje'
                  : (i.dias == 1 ? 'amanhã' : 'em ${i.dias} dias');
              exemplo = '${i.nome} expira $quando';
              estado = estadoDe(i.dias);
            }

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.midsmall,
                      AppSpacing.midsmall,
                      AppSpacing.midsmall,
                      AppSpacing.mid,
                    ),
                    children: [
                      const ScreenHeader(
                        subtitulo: 'Passo 3 de 3',
                        titulo: 'Quando queres ser avisado?',
                        voltar: true,
                      ),
                      const SizedBox(height: AppSpacing.midsmall),
                      // ? os mesmos controlos das Definições (mesmos dados)
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
                              value: resumo,
                              onChanged: frigorifico.mudarResumoDiario,
                            ),
                            onTap: () => frigorifico.mudarResumoDiario(!resumo),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.midsmall),
                      const SectionTitle(titulo: 'Vais receber assim'),
                      const SizedBox(height: AppSpacing.midsmall),
                      ListCard(
                        children: [
                          ItemRow(
                            titulo: exemplo,
                            detalhe: resumo
                                ? 'Frigu · 8:00'
                                : 'Frigu · $dias ${dias == 1 ? 'dia' : 'dias'} antes',
                            estado: estado,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _Rodape(
                  passo: 2,
                  texto: 'Concluir',
                  onPressed: () => irParaApp(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
