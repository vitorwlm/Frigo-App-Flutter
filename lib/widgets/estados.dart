import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import 'app_button.dart';
import 'list_card.dart';
import 'section_title.dart';

// * Estados "vazio" e "a carregar" dos ecrãs (ecrãs 04, 05, 25 e 26 do Figma).
// * Num ficheiro só porque são os dois "o que mostrar quando ainda não há
// * dados", e assim os ecrãs ficam todos iguais.

// ? Mensagem ao centro quando não há nada para mostrar: título a negrito e,
// ? por baixo, uma frase a dizer o que fazer a seguir (opcional)
class EstadoVazio extends StatelessWidget {
  const EstadoVazio({super.key, required this.titulo, this.texto});

  final String titulo;
  final String? texto;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mid),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color: AppTokens.textSecondary,
            ),
          ),
          if (texto != null) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              texto!,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: AppTokens.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ? Retângulo cinzento que ocupa o lugar de um texto ou cartão enquanto os
// ? dados carregam
class _Bloco extends StatelessWidget {
  const _Bloco({
    this.largura,
    required this.altura,
    this.cor = AppColors.gray200,
    this.raio = AppRadius.sm,
  });

  // ? null = ocupa a largura toda
  final double? largura;
  final double altura;
  final Color cor;
  final double raio;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: largura,
      height: altura,
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(raio),
      ),
    );
  }
}

// ? Círculo branco com ícone, igual aos botões do cabeçalho mas sem toque
// ? (ainda não há nada para abrir)
class _Circulo extends StatelessWidget {
  const _Circulo(this.icone);

  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: AppTokens.bgSurface,
        shape: BoxShape.circle,
      ),
      child: Icon(icone, color: AppTokens.textPrimary),
    );
  }
}

// * Esqueleto do Início (ecrã 25 · Empty state do Figma): a forma do ecrã
// * com blocos cinzentos, enquanto o _Arranque do main.dart carrega o
// * Supabase. Melhor do que só uma rodinha: a pessoa já vê onde vai
// * aparecer cada coisa.
class EsqueletoInicio extends StatelessWidget {
  const EsqueletoInicio({super.key});

  @override
  Widget build(BuildContext context) {
    // ? uma linha de "A expirar": nome e quantidade em blocos, Usei cinzento
    Widget linha() => Padding(
      padding: const EdgeInsets.all(AppSpacing.midsmall),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bloco(largura: 104, altura: 26),
                SizedBox(height: AppSpacing.small),
                _Bloco(largura: 52, altura: 24),
              ],
            ),
          ),
          // ? onPressed null = desativado: o Flutter pinta-o a cinzento
          const AppButton(
            texto: 'Usei',
            tipo: BotaoTipo.tonal,
            icone: Icons.check,
            onPressed: null,
          ),
          const SizedBox(width: AppSpacing.small),
          Icon(Icons.more_vert, color: AppTokens.textPrimary),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          // ? sem scroll: é só a forma do ecrã, não há nada para ver mais abaixo
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.midsmall),
          children: [
            // ? cabeçalho: saudação e nome em blocos, sino e definições
            const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bloco(largura: 164, altura: 18),
                      SizedBox(height: 6),
                      _Bloco(largura: 164, altura: 24),
                    ],
                  ),
                ),
                _Circulo(Icons.notifications_none),
                SizedBox(width: AppSpacing.small),
                _Circulo(Icons.settings_outlined),
              ],
            ),
            const SizedBox(height: AppSpacing.mid),
            // ? cartão grande de cima, com a pílula do estado mais clara
            Container(
              height: 176,
              padding: const EdgeInsets.all(AppSpacing.mid),
              alignment: Alignment.topLeft,
              decoration: BoxDecoration(
                color: AppTokens.heroOffline,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const _Bloco(
                largura: 120,
                altura: 36,
                cor: AppColors.gray400,
                raio: AppRadius.full,
              ),
            ),
            const SizedBox(height: AppSpacing.mid),
            const SectionTitle(titulo: 'A expirar'),
            const SizedBox(height: AppSpacing.small),
            ListCard(children: [linha(), linha(), linha()]),
            const SizedBox(height: AppSpacing.mid),
            const SectionTitle(titulo: 'Cozinha isto hoje'),
            const SizedBox(height: AppSpacing.small),
            // ? cartão da receita: foto à esquerda e 3 linhas de texto
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTokens.bgSurface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppTokens.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: const Row(
                children: [
                  _Bloco(
                    largura: 92,
                    altura: 120,
                    cor: AppTokens.heroOffline,
                    raio: 0,
                  ),
                  SizedBox(width: AppSpacing.midsmall),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Bloco(largura: 104, altura: 22),
                        SizedBox(height: AppSpacing.small),
                        _Bloco(largura: 104, altura: 22),
                        SizedBox(height: AppSpacing.small),
                        _Bloco(largura: 104, altura: 16),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppTokens.textPrimary),
                  SizedBox(width: AppSpacing.midsmall),
                ],
              ),
            ),
          ],
        ),
      ),
      // ? lugar do botão Adicionar
      floatingActionButton: const _Bloco(
        largura: 160,
        altura: 52,
        cor: AppColors.gray600,
        raio: AppRadius.md,
      ),
      // ? a barra de baixo já aparece, igual à da app, mas ainda sem reagir
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.kitchen), label: 'Inventário'),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu),
            label: 'Receitas',
          ),
          NavigationDestination(icon: Icon(Icons.eco), label: 'Impacto'),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart),
            label: 'Compras',
          ),
        ],
      ),
    );
  }
}
