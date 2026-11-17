// * ECRÃ DETALHE DO ALIMENTO (ecrã 06 do Figma).
// * Abre a partir do Início ou do Inventário (Navigator.push com o item).
// * Fluxo: ver validade → mudar quantidade / aberto → Editar (folha) →
// * receitas que o usam → Usei tudo / Deitei fora. Ao sair devolve uma
// * mensagem com Navigator.pop, e quem abriu mostra-a e grava o item.

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
import 'filtros_sheet.dart';
import 'receita_detalhe.dart';

const List<String> _meses = [
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];

// ? "6 nov": formato curto à mão, para não precisar do pacote intl só para isto
String _data(DateTime d) => '${d.day} ${_meses[d.month - 1]}';

// ? Recebe o próprio Item (não uma cópia): os + / − e o Aberto mudam-no logo,
// ? e quem abriu o ecrã chama frigorifico.atualizar(item) para gravar.
class DetalheAlimento extends StatefulWidget {
  const DetalheAlimento({super.key, required this.item});

  final Item item;

  @override
  State<DetalheAlimento> createState() => _DetalheAlimentoState();
}

class _DetalheAlimentoState extends State<DetalheAlimento> {
  // ? widget.item = o item passado ao construtor; o get só encurta o nome
  Item get item => widget.item;

  // ? + / − de 1 em 1 nas unidades e de 50 em 50 nas gramas
  int get _passo => item.porUnidade ? 1 : 50;

  List<Receita> get _receitas {
    // ? receitas com um ingrediente que tenha a 1.ª palavra do nome do alimento
    // ? ("Iogurte natural" → "iogurte"), para sugerir onde o gastar
    final String chave = item.nome.split(' ').first.toLowerCase();
    return frigorifico.receitas
        .where(
          (r) => r.ingredientes.any(
            (i) =>
                i.plural.toLowerCase().contains(chave) ||
                i.nome.toLowerCase().contains(chave),
          ),
        )
        .toList();
  }

  // ? pop com uma mensagem: quem abriu este ecrã mostra-a numa snackbar
  void _sair(String mensagem) => Navigator.pop(context, mensagem);

  // ? Folha para corrigir o que a câmara leu: nome, validade e categoria.
  // ? Usa variáveis locais e só muda o item se carregar Guardar, para fechar
  // ? a folha a deslizar não estragar nada
  Future<void> _editar() async {
    final nome = TextEditingController(text: item.nome);
    DateTime validade = item.validade;
    String categoria = item.categoria;

    final bool? guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppTokens.bgApp,
      // ? StatefulBuilder dá um setState só para a folha (setFolha), porque a
      // ? folha não é um widget meu com State
      builder: (folha) => StatefulBuilder(
        builder: (folha, setFolha) {
          final textTheme = Theme.of(folha).textTheme;
          return Padding(
            // ! sobe a folha quando o teclado abre, senão o teclado tapava o campo
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(folha).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
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
                  Text('Editar alimento', style: textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.midsmall),
                  TextField(
                    controller: nome,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  const SizedBox(height: AppSpacing.midsmall),
                  // ! DropdownButtonFormField = lista com o aspeto de um campo.
                  // ! Categoria fora da lista vira 'Outros' (senão dava erro)
                  DropdownButtonFormField<String>(
                    initialValue: todasCategorias.contains(categoria)
                        ? categoria
                        : 'Outros',
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: [
                      for (final c in todasCategorias)
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (v) => setFolha(() => categoria = v!),
                  ),
                  const SizedBox(height: AppSpacing.midsmall),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: const Text('Validade'),
                    subtitle: Text(_data(validade)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      // ? calendário do Material; devolve null se cancelar
                      final escolhida = await showDatePicker(
                        context: folha,
                        initialDate: validade,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (escolhida != null) {
                        setFolha(() => validade = escolhida);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.midsmall),
                  AppButton(
                    texto: 'Guardar',
                    expandir: true,
                    onPressed: () => Navigator.pop(folha, true),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    // ! lê o texto antes do dispose (depois já não dá)
    final String novoNome = nome.text.trim();
    nome.dispose();
    if (guardar != true || novoNome.isEmpty) return;
    frigorifico.editar(
      item,
      nome: novoNome,
      validade: validade,
      categoria: categoria,
    );
    // ? redesenha este ecrã com os valores novos
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    TextStyle? branco(TextStyle? s) => s?.copyWith(color: AppTokens.textOnHero);

    final int dias = item.dias;
    String prazo;
    // ! dias < 0 primeiro: antes um alimento já fora da validade dizia
    // ! "Expira hoje"
    if (dias < 0) {
      prazo = dias == -1 ? 'Expirou ontem' : 'Expirou há ${-dias} dias';
    } else if (dias == 0) {
      prazo = 'Expira hoje';
    } else if (dias == 1) {
      prazo = 'Expira amanhã';
    } else {
      prazo = 'Expira em $dias dias';
    }
    // ? dias já passados desde que entrou, para a barra de progresso
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
                  onPressed: _editar,
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
                        dias < 0
                            ? 'Expirou'
                            : dias == 0
                            ? 'Hoje'
                            : (dias == 1 ? '1 dia' : '$dias dias'),
                        style: branco(textTheme.displayLarge),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Text(
                        '${dias < 0 ? 'a' : 'até'} ${_data(item.validade)}',
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
            // ? Quantidade e aberto: mudam o item logo; grava quando o ecrã fecha
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
                              Text(
                                item.quantidadeTexto,
                                style: textTheme.labelLarge,
                              ),
                            ],
                          ),
                        ),
                        CircleIconButton(
                          icone: Icons.remove,
                          tooltip: 'Menos',
                          estilo: CirculoEstilo.contorno,
                          // ? null desativa o botão: não desce abaixo de 1 passo
                          // ? (para chegar a 0 há o "Usei tudo", que regista o evento)
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
            // ? Receitas que usam este alimento: liga o alimento a expirar a
            // ? uma forma de o gastar (ODS 12.3)
            if (receitas.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.midsmall),
              AppCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ReceitaDetalhe(receita: receitas.first),
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
                            // ? map + join: junta os títulos separados por vírgula
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
      // ? bottomNavigationBar para os botões ficarem sempre visíveis em baixo,
      // ? mesmo com scroll
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
