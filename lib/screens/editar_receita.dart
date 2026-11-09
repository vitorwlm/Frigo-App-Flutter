// * ECRÃ EDITAR RECEITA (só o admin chega aqui, pela Administração).
// * Fluxo: dados gerais → ingredientes por pessoa (Juntar / tirar) → passos
// * (Juntar / tirar) → Guardar (frigorifico.guardarReceita) ou Apagar.
// * O mesmo ecrã cria (receita null) e edita, para não ter dois quase iguais.

import 'package:flutter/material.dart';

import '../data/frigorifico.dart';
import '../models/receita.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_title.dart';
import '../widgets/snack.dart';
import 'admin.dart';

// ? 1.5 → "1,5"; 100.0 → "100": para o campo mostrar o número como a
// ? pessoa o escreveria
String _numero(double v) => v == v.roundToDouble()
    ? '${v.round()}'
    : '$v'.replaceAll('.', ',');

// ? Os campos de um ingrediente enquanto se edita. Classe à parte porque
// ? cada ingrediente tem 3 controllers e assim ficam juntos (e são libertados
// ? juntos no dispose)
class _LinhaIngrediente {
  _LinhaIngrediente([Ingrediente? i])
    : nome = TextEditingController(text: i?.nome ?? ''),
      // ? plural igual ao nome fica vazio (é o valor por defeito), para o
      // ? admin só o escrever quando é diferente
      plural = TextEditingController(
        text: (i == null || i.plural == i.nome) ? '' : i.plural,
      ),
      quantidade = TextEditingController(
        text: (i == null || i.despensa) ? '' : _numero(i.porPessoa),
      ),
      unidade = (i == null || i.unidade.isEmpty) ? 'unidades' : i.unidade,
      despensa = i?.despensa ?? false;

  final TextEditingController nome;
  final TextEditingController plural;
  final TextEditingController quantidade;
  String unidade;
  bool despensa;

  // ? converte os campos de volta num Ingrediente; aceita "1,5" com vírgula
  Ingrediente paraIngrediente() {
    final String n = nome.text.trim();
    final String p = plural.text.trim();
    return Ingrediente(
      nome: n,
      plural: p.isEmpty ? n : p,
      porPessoa: despensa
          ? 0
          : double.tryParse(quantidade.text.trim().replaceAll(',', '.')) ?? 0,
      unidade: despensa ? '' : unidade,
      despensa: despensa,
    );
  }

  void dispose() {
    nome.dispose();
    plural.dispose();
    quantidade.dispose();
  }
}

// ? StatefulWidget porque os ingredientes e os passos mudam enquanto se edita
class EditarReceita extends StatefulWidget {
  const EditarReceita({super.key, this.receita});

  final Receita? receita;

  @override
  State<EditarReceita> createState() => _EditarReceitaState();
}

class _EditarReceitaState extends State<EditarReceita> {
  final _form = GlobalKey<FormState>();
  // ? late = só é criado quando se usa pela 1.ª vez (aí já há widget), o que
  // ? deixa usar widget.receita sem precisar do initState
  late final _titulo = TextEditingController(text: widget.receita?.titulo);
  late final _descricao =
      TextEditingController(text: widget.receita?.descricao);
  late final _minutos = TextEditingController(
    text: '${widget.receita?.minutos ?? 15}',
  );
  late int _pessoas = widget.receita?.pessoasBase ?? 2;
  late String _dificuldade = widget.receita?.dificuldade ?? 'Fácil';
  late final List<_LinhaIngrediente> _ingredientes = widget.receita == null
      ? [_LinhaIngrediente()]
      : [for (final i in widget.receita!.ingredientes) _LinhaIngrediente(i)];
  late final List<TextEditingController> _passos = widget.receita == null
      ? [TextEditingController()]
      : [
          for (final p in widget.receita!.passos)
            TextEditingController(text: p),
        ];
  // ? desliga os botões enquanto espera pelo Supabase (evita gravar 2 vezes)
  bool _aGuardar = false;

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _minutos.dispose();
    for (final l in _ingredientes) {
      l.dispose();
    }
    for (final c in _passos) {
      c.dispose();
    }
    super.dispose();
  }

  // ? o mesmo estilo dos campos do Login, para a app ser coerente
  InputDecoration _campo(String rotulo, {String? dica}) {
    final borda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: const BorderSide(color: AppTokens.border),
    );
    return InputDecoration(
      labelText: rotulo,
      hintText: dica,
      filled: true,
      fillColor: AppTokens.bgSurface,
      border: borda,
      enabledBorder: borda,
      focusedBorder: borda.copyWith(
        borderSide: const BorderSide(color: AppTokens.statusBrand, width: 2),
      ),
    );
  }

  // ? validator reutilizado em vários campos
  String? _obrigatorio(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Obrigatório' : null;

  // ? valida → monta a Receita → grava → volta à Administração
  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    // ? linhas vazias são ignoradas em vez de darem erro
    final ingredientes = [
      for (final l in _ingredientes)
        if (l.nome.text.trim().isNotEmpty) l.paraIngrediente(),
    ];
    final passos = [
      for (final c in _passos)
        if (c.text.trim().isNotEmpty) c.text.trim(),
    ];
    if (ingredientes.isEmpty || passos.isEmpty) {
      mostrarMensagem(context, 'Junta pelo menos um ingrediente e um passo.');
      return;
    }

    final r = Receita(
      // ? id vazio = receita nova (o frigorifico faz insert em vez de update)
      id: widget.receita?.id ?? '',
      titulo: _titulo.text.trim(),
      descricao: _descricao.text.trim(),
      minutos: int.parse(_minutos.text.trim()),
      ingredientes: ingredientes,
      passos: passos,
      pessoasBase: _pessoas,
      dificuldade: _dificuldade,
    );

    setState(() => _aGuardar = true);
    final erro = await frigorifico.guardarReceita(r);
    // ! mounted: depois do await o ecrã pode já ter fechado
    if (!mounted) return;
    setState(() => _aGuardar = false);
    if (erro != null) {
      mostrarMensagem(context, erro);
      return;
    }
    mostrarMensagem(context, 'Receita guardada');
    Navigator.pop(context);
  }

  Future<void> _apagar() async {
    final bool sim = await confirmar(
      context,
      titulo: 'Apagar ${widget.receita!.titulo}?',
      texto: 'A receita deixa de aparecer a todos.',
      botao: 'Apagar',
    );
    if (!sim || !mounted) return;
    final erro = await frigorifico.apagarReceita(widget.receita!);
    if (!mounted) return;
    mostrarMensagem(context, erro ?? 'Receita apagada');
    if (erro == null) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool nova = widget.receita == null;
    const espaco = SizedBox(height: AppSpacing.small);

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.midsmall,
              AppSpacing.midsmall,
              AppSpacing.midsmall,
              AppSpacing.mid,
            ),
            children: [
              ScreenHeader(
                subtitulo: 'Administração',
                titulo: nova ? 'Nova receita' : 'Editar receita',
                voltar: true,
              ),
              const SizedBox(height: AppSpacing.midsmall),

              // * ---- Dados gerais ----
              TextFormField(
                controller: _titulo,
                textCapitalization: TextCapitalization.sentences,
                decoration: _campo('Título'),
                validator: _obrigatorio,
              ),
              espaco,
              TextFormField(
                controller: _descricao,
                textCapitalization: TextCapitalization.sentences,
                decoration: _campo(
                  'Descrição',
                  dica: 'Ex.: Salva o iogurte e os ovos',
                ),
              ),
              espaco,
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minutos,
                      keyboardType: TextInputType.number,
                      decoration: _campo('Minutos'),
                      validator: (v) {
                        final int? n = int.tryParse(v?.trim() ?? '');
                        return (n == null || n <= 0) ? 'Maior que 0' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _pessoas,
                      decoration: _campo('Pessoas'),
                      items: [
                        for (int n = 1; n <= 6; n++)
                          DropdownMenuItem(value: n, child: Text('$n')),
                      ],
                      onChanged: (v) => setState(() => _pessoas = v ?? 2),
                    ),
                  ),
                ],
              ),
              espaco,
              SegmentedButton<String>(
                showSelectedIcon: false,
                expandedInsets: EdgeInsets.zero,
                segments: const [
                  ButtonSegment(value: 'Fácil', label: Text('Fácil')),
                  ButtonSegment(value: 'Média', label: Text('Média')),
                  ButtonSegment(value: 'Difícil', label: Text('Difícil')),
                ],
                selected: {_dificuldade},
                onSelectionChanged: (s) =>
                    setState(() => _dificuldade = s.first),
              ),
              const SizedBox(height: AppSpacing.mid),

              // * ---- Ingredientes ----
              SectionTitle(
                titulo: 'Ingredientes por pessoa',
                contador: _ingredientes.length,
              ),
              espaco,
              for (int i = 0; i < _ingredientes.length; i++) ...[
                _cartaoIngrediente(i),
                espaco,
              ],
              AppButton(
                texto: 'Juntar ingrediente',
                icone: Icons.add,
                tipo: BotaoTipo.tonal,
                expandir: true,
                onPressed: () =>
                    setState(() => _ingredientes.add(_LinhaIngrediente())),
              ),
              const SizedBox(height: AppSpacing.mid),

              // * ---- Passos ----
              SectionTitle(titulo: 'Passos', contador: _passos.length),
              espaco,
              for (int i = 0; i < _passos.length; i++) ...[
                // ? key do controller pela mesma razão dos ingredientes (em baixo)
                Row(
                  key: ObjectKey(_passos[i]),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16, right: 8),
                      child: Text('${i + 1}.', style: textTheme.labelLarge),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _passos[i],
                        // ? várias linhas: cresce com o texto
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _campo('Passo ${i + 1}'),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tirar passo',
                      icon: const Icon(Icons.close),
                      // ? fica pelo menos um passo; removeAt devolve o
                      // ? controller, que é logo libertado
                      onPressed: _passos.length == 1
                          ? null
                          : () => setState(() {
                              _passos.removeAt(i).dispose();
                            }),
                    ),
                  ],
                ),
                espaco,
              ],
              AppButton(
                texto: 'Juntar passo',
                icone: Icons.add,
                tipo: BotaoTipo.tonal,
                expandir: true,
                onPressed: () =>
                    setState(() => _passos.add(TextEditingController())),
              ),
              const SizedBox(height: AppSpacing.mid),

              AppButton(
                texto: _aGuardar ? 'A guardar…' : 'Guardar',
                icone: Icons.check,
                expandir: true,
                // ? null = botão desligado enquanto guarda
                onPressed: _aGuardar ? null : _guardar,
              ),
              // ? uma receita nova ainda não existe: não há nada para apagar
              if (!nova) ...[
                espaco,
                AppButton(
                  texto: 'Apagar receita',
                  icone: Icons.delete_outline,
                  tipo: BotaoTipo.stroke,
                  cor: BotaoCor.accent,
                  expandir: true,
                  onPressed: _aGuardar ? null : _apagar,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _cartaoIngrediente(int i) {
    final l = _ingredientes[i];
    // ! key: ao tirar um ingrediente do meio, cada cartão continua ligado
    // ! ao seu ingrediente (senão a lista de unidades ficava trocada)
    return AppCard(
      key: ObjectKey(l),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: l.nome,
                  decoration: _campo('Nome', dica: 'ovo'),
                  validator: _obrigatorio,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: TextFormField(
                  controller: l.plural,
                  decoration: _campo('Plural', dica: 'ovos'),
                ),
              ),
              IconButton(
                tooltip: 'Tirar ingrediente',
                icon: const Icon(Icons.close),
                onPressed: _ingredientes.length == 1
                    ? null
                    : () => setState(() {
                        _ingredientes.removeAt(i).dispose();
                      }),
              ),
            ],
          ),
          // ? azeite, sal…: sem quantidade, conta sempre como "tens"
          // ? (a câmara não os vê e quase toda a gente os tem)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Despensa (azeite, sal…)'),
            value: l.despensa,
            onChanged: (v) => setState(() => l.despensa = v),
          ),
          if (!l.despensa)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: l.quantidade,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _campo('Por pessoa', dica: '1,5'),
                    validator: (v) {
                      final double? n = double.tryParse(
                        (v ?? '').trim().replaceAll(',', '.'),
                      );
                      return (n == null || n <= 0) ? 'Maior que 0' : null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  // TODO: se a receita tiver outra unidade (ex.: 'L'), o dropdown dá erro: juntar à lista ou trocar por 'unidades'
                  child: DropdownButtonFormField<String>(
                    initialValue: l.unidade,
                    decoration: _campo('Unidade'),
                    items: const [
                      DropdownMenuItem(value: 'unidades', child: Text('unidades')),
                      DropdownMenuItem(value: 'g', child: Text('g')),
                      DropdownMenuItem(value: 'ml', child: Text('ml')),
                    ],
                    onChanged: (v) => setState(() => l.unidade = v ?? 'unidades'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
