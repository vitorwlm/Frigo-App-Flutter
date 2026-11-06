import 'package:flutter/material.dart';

import '../data/frigorifico.dart';
import '../models/receita.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/hero_card.dart';
import '../widgets/item_row.dart';
import '../widgets/recipe_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_title.dart';
import '../widgets/tag_chip.dart';
import 'receita_detalhe.dart';

enum FiltroReceita { todas, tensTudo, rapidas }

// Ecrã 07 do Figma
class Receitas extends StatefulWidget {
  const Receitas({super.key});

  @override
  State<Receitas> createState() => _ReceitasState();
}

class _ReceitasState extends State<Receitas> {
  FiltroReceita _filtro = FiltroReceita.todas;
  // pesquisa: campo aberto e o texto escrito
  bool _aProcurar = false;
  String _procura = '';
  final _campo = TextEditingController();

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  // procura no título, na descrição e nos ingredientes, sem ligar a maiúsculas
  bool _encontra(Receita r) {
    final q = _procura.trim().toLowerCase();
    if (q.isEmpty) return true;
    return r.titulo.toLowerCase().contains(q) ||
        r.descricao.toLowerCase().contains(q) ||
        r.ingredientes.any((i) => i.nome.toLowerCase().contains(q));
  }

  void _alternarPesquisa() {
    setState(() {
      _aProcurar = !_aProcurar;
      if (!_aProcurar) {
        _procura = '';
        _campo.clear();
      }
    });
  }

  bool _passa(Receita r) {
    switch (_filtro) {
      case FiltroReceita.todas:
        return true;
      case FiltroReceita.tensTudo:
        return r.tensTudo(r.pessoasBase);
      case FiltroReceita.rapidas:
        return r.minutos <= 20;
    }
  }

  Widget _chip(FiltroReceita f, String texto) {
    return ChoiceChip(
      label: Text(texto),
      selected: _filtro == f,
      showCheckmark: false,
      selectedColor: AppTokens.bgTonalSoft,
      backgroundColor: AppTokens.bgApp,
      side: const BorderSide(color: AppTokens.borderStrong),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      onSelected: (_) => setState(() => _filtro = f),
    );
  }

  void _abrir(BuildContext context, Receita r) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReceitaDetalhe(receita: r)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // redesenha quando o inventário muda (o que tens muda as receitas)
    return ListenableBuilder(
      listenable: frigorifico,
      builder: (context, _) => _conteudo(context),
    );
  }

  Widget _conteudo(BuildContext context) {
    final receitas = frigorifico.receitas;
    // a melhor para hoje: tens tudo e salva mais alimentos a expirar
    final candidatas = receitas.where((r) => r.tensTudo(r.pessoasBase)).toList()
      ..sort((a, b) => b.salva.compareTo(a.salva));
    // ↑ .. = faz o sort e devolve a própria lista
    final Receita destaque =
        candidatas.isNotEmpty ? candidatas.first : receitas.first;
    final outras =
        receitas.where((r) => r.id != destaque.id && _passa(r)).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.midsmall),
        children: [
          ScreenHeader(
            subtitulo: 'Com o que está a acabar',
            titulo: 'Receitas',
            acoes: [
              CircleIconButton(
                icone: _aProcurar ? Icons.close : Icons.search,
                tooltip: _aProcurar ? 'Fechar pesquisa' : 'Procurar receita',
                onPressed: _alternarPesquisa,
              ),
            ],
          ),
          if (_aProcurar) ...[
            const SizedBox(height: AppSpacing.small),
            TextField(
              controller: _campo,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _procura = v),
              decoration: InputDecoration(
                hintText: 'Receita ou ingrediente',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppTokens.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(color: AppTokens.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(color: AppTokens.border),
                ),
              ),
            ),
          ],
          // com texto escrito, mostra só os resultados
          if (_procura.trim().isNotEmpty) ..._resultados(context, receitas)
          else ..._normal(context, destaque, outras),
        ],
      ),
    );
  }

  List<Widget> _resultados(BuildContext context, List<Receita> receitas) {
    final encontradas = receitas.where(_encontra).toList();
    return [
      const SizedBox(height: AppSpacing.midsmall),
      SectionTitle(titulo: 'Resultados', contador: encontradas.length),
      const SizedBox(height: AppSpacing.small),
      if (encontradas.isEmpty)
        Text(
          'Nenhuma receita com "${_procura.trim()}"',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTokens.textSecondary,
          ),
        ),
      for (final r in encontradas) ..._cartao(context, r),
    ];
  }

  List<Widget> _normal(
    BuildContext context,
    Receita destaque,
    List<Receita> outras,
  ) {
    return [
      const SizedBox(height: AppSpacing.small),
      Wrap(
        spacing: AppSpacing.small,
        children: [
          _chip(FiltroReceita.todas, 'Todas'),
          _chip(FiltroReceita.tensTudo, 'Tens tudo'),
          _chip(FiltroReceita.rapidas, 'Até 20 min'),
        ],
      ),
      const SizedBox(height: AppSpacing.midsmall),
      _Destaque(receita: destaque, onTap: () => _abrir(context, destaque)),
      const SizedBox(height: AppSpacing.mid),
      const SectionTitle(titulo: 'Também aproveitam'),
      const SizedBox(height: AppSpacing.small),
      if (outras.isEmpty)
        Text(
          'Nenhuma receita com este filtro',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTokens.textSecondary,
          ),
        ),
      for (final r in outras) ..._cartao(context, r),
    ];
  }

  // cartão de uma receita + espaço por baixo
  List<Widget> _cartao(BuildContext context, Receita r) => [
    RecipeCard(
      titulo: r.titulo,
      descricao: r.descricao,
      estado: r.estado(r.pessoasBase),
      minutos: r.minutos,
      tom: r.tensTudo(r.pessoasBase) ? ReceitaTom.marca : ReceitaTom.aviso,
      mostrarFoto: false,
      onTap: () => _abrir(context, r),
    ),
    const SizedBox(height: AppSpacing.small),
  ];
}

// Cartão grande "Melhor para hoje"
class _Destaque extends StatelessWidget {
  const _Destaque({required this.receita, required this.onTap});

  final Receita receita;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // ingredientes que expiram em 2 dias ou menos, para os chips
    final aExpirar = receita.ingredientes
        .where((i) => i.dias != null && i.dias! <= 2)
        .toList();

    return Material(
      color: AppTokens.heroOk,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stack = widgets uns por cima dos outros
            SizedBox(
              height: 120,
              child: Stack(
                children: [
                  Container(color: AppColors.primary700),
                  const Center(
                    child: Icon(
                      Icons.restaurant,
                      size: 34,
                      color: AppColors.primary200,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: HeroPill(
                      texto: 'Salva ${receita.salva} alimentos',
                      icone: Icons.check_circle,
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 16,
                    child: Text(
                      '[foto]',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.primary200,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.mid),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MELHOR PARA HOJE',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppTokens.textOnHero,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    receita.titulo,
                    style: textTheme.headlineMedium?.copyWith(
                      color: AppTokens.textOnHero,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Wrap(
                    spacing: AppSpacing.small,
                    runSpacing: AppSpacing.small,
                    children: [
                      for (final i in aExpirar)
                        TagChip(
                          texto: '${i.plural} · ${prazoDe(i.dias!).toLowerCase()}',
                          tom: tomDe(estadoDe(i.dias!)),
                        ),
                      TagChip(
                        texto: '${receita.minutos} min',
                        tom: TagTom.contornoHero,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.midsmall),
                  AppButton(
                    texto: 'Ver receita',
                    cor: BotaoCor.neutral,
                    expandir: true,
                    onPressed: onTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
