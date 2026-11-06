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

// Fecha o onboarding: o _Arranque do main.dart passa a mostrar a app.
// popUntil fecha os ecrãs empilhados por cima (ex.: Ligar ao frigorífico).
void irParaApp(BuildContext context) {
  frigorifico.verBoasVindas = false;
  frigorifico.atualizar();
  Navigator.popUntil(context, (rota) => rota.isFirst);
}

// Rodapé dos passos: pontos + botão principal
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
  // true quando se abre pelas Definições: no fim volta atrás em vez de
  // abrir a app de novo
  const LigarFrigorifico({super.key, this.dasDefinicoes = false});

  final bool dasDefinicoes;

  @override
  State<LigarFrigorifico> createState() => _LigarFrigorificoState();
}

class _LigarFrigorificoState extends State<LigarFrigorifico> {
  // redes falsas; mais tarde vêm da placa (ESP32) por Bluetooth
  final List<(String, String)> _redes = [
    ('MEO-5G-Casa', 'Sinal forte'),
    ('Vodafone-2F1A', 'Sinal médio'),
  ];
  // ↑ (String, String) = "record": dois valores juntos, lidos com .$1 e .$2

  String _rede = 'MEO-5G-Casa';
  final _palavraPasse = TextEditingController();
  bool _aLigar = false;

  @override
  void dispose() {
    // os controladores têm de ser libertados quando o ecrã fecha
    _palavraPasse.dispose();
    super.dispose();
  }

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
    // mais tarde: enviar a rede e a palavra-passe à placa
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _aLigar = false);

    if (widget.dasDefinicoes) {
      // guarda o messenger antes de fechar: depois do pop o context
      // deste ecrã deixa de existir
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text('Frigu ligado a $_rede')));
    } else {
      // o passo 3 (Escolher avisos) ainda não existe: segue para a app
      irParaApp(context);
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
                  // cartão "Frigu encontrado"
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
                    // esconde o texto com pontos
                    obscureText: true,
                    // redesenha para ligar/desligar o botão Ligar
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
              // null = botão desligado
              onPressed: _palavraPasse.text.isEmpty || _aLigar ? null : _ligar,
            ),
          ],
        ),
      ),
    );
  }
}
