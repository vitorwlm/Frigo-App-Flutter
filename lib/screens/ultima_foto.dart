// * Ecrã 18 · Última foto da câmara ("O teu frigorífico").
// * Abre no "Ver foto" do cartão de cima do Início.
// * Mostra a última foto da tabela fotos (bucket privado "fotos") com uma
// * caixa à volta de cada alimento, e por baixo a lista do que foi
// * reconhecido. As caixas só aparecem se a Edge Function analisar-foto
// * guardar em itens_detetados o campo box_2d do Gemini.

import 'package:flutter/material.dart';

import '../data/frigorifico.dart';
import '../models/item.dart';
import '../services/nuvem.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/item_row.dart';
import '../widgets/list_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_title.dart';
import '../widgets/snack.dart';
import '../widgets/tag_chip.dart';
import 'confirmar_sheet.dart';

// ? Uma caixa à volta de um alimento na foto, em frações (0–1) da foto
class _Caixa {
  _Caixa(
    this.nome,
    this.topo,
    this.esquerda,
    this.fundo,
    this.direita,
    this.certo,
  );

  final String nome;
  final double topo, esquerda, fundo, direita;
  final bool certo;
}

// ? A última foto: o link para a ver e as caixas
class _Foto {
  _Foto(this.url, this.tiradaEm, this.caixas);

  final String url;
  final DateTime tiradaEm;
  final List<_Caixa> caixas;
}

// ? Lê a última foto do Supabase; null se ainda não houver nenhuma
Future<_Foto?> _ultimaFoto() async {
  final linha = await supabase
      .from('fotos')
      .select('caminho, itens_detetados, tirada_em')
      .order('tirada_em', ascending: false)
      .limit(1)
      .maybeSingle();
  if (linha == null) return null;

  // ? o bucket é privado: pede um link que dura 1 hora
  final url = await supabase.storage
      .from('fotos')
      .createSignedUrl(linha['caminho'] as String, 3600);

  // ? o Gemini devolve box_2d = [cima, esquerda, baixo, direita] de 0 a 1000
  final caixas = <_Caixa>[];
  for (final d in (linha['itens_detetados'] as List? ?? [])) {
    if (d is! Map || d['box_2d'] is! List) continue;
    final b = (d['box_2d'] as List).map((v) => (v as num) / 1000).toList();
    if (b.length != 4) continue;
    final certeza = (d['confianca'] ?? d['certeza'] ?? 100) as num;
    caixas.add(
      _Caixa(
        '${d['nome'] ?? '?'}',
        b[0],
        b[1],
        b[2],
        b[3],
        // ? 0–1 ou 0–100, conforme o que o Gemini mandar
        (certeza <= 1 ? certeza * 100 : certeza) >= 60,
      ),
    );
  }
  return _Foto(
    url,
    DateTime.parse(linha['tirada_em'] as String).toLocal(),
    caixas,
  );
}

String _ha(DateTime t) {
  final int min = DateTime.now().difference(t).inMinutes;
  if (min < 1) return 'Visto agora';
  if (min < 60) return 'Visto há $min min';
  if (min < 60 * 24) return 'Visto há ${min ~/ 60} h';
  return 'Visto há ${min ~/ (60 * 24)} dias';
}

class UltimaFoto extends StatefulWidget {
  const UltimaFoto({super.key});

  @override
  State<UltimaFoto> createState() => _UltimaFotoState();
}

class _UltimaFotoState extends State<UltimaFoto> {
  // ? guardado no estado: o FutureBuilder não volta a pedir a cada build
  late Future<_Foto?> _foto = _carregar();

  Future<_Foto?> _carregar() async {
    // ? sem sessão no Supabase (dados de exemplo) não há foto
    if (!frigorifico.naNuvem) return null;
    try {
      return await _ultimaFoto();
    } catch (e) {
      debugPrint('Foto: $e');
      return null;
    }
  }

  // ? Pede a foto à placa (frigorifico.pedirFoto) e volta a ler a última
  // ? foto quando já deve estar analisada: a placa vê o pedido em até 10 s
  // ? e o Gemini demora 10–30 s
  Future<void> _tirarFoto() async {
    final erro = await frigorifico.pedirFoto();
    if (!mounted) return;
    mostrarMensagem(context, erro ?? 'Pedido enviado à câmara · ~30 s');
    if (erro != null) return;
    await Future.delayed(const Duration(seconds: 45));
    // ! mounted: a pessoa pode ter saído do ecrã durante a espera
    if (!mounted) return;
    setState(() => _foto = _carregar());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<_Foto?>(
          future: _foto,
          builder: (context, snap) {
            final foto = snap.data;
            final aCarregar = snap.connectionState != ConnectionState.done;

            return ListenableBuilder(
              listenable: frigorifico,
              builder: (context, _) => ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.midsmall,
                  AppSpacing.midsmall,
                  AppSpacing.midsmall,
                  AppSpacing.mid,
                ),
                children: [
                  ScreenHeader(
                    subtitulo: foto == null
                        ? 'Última foto'
                        : _ha(foto.tiradaEm),
                    titulo: 'O teu frigorífico',
                    voltar: true,
                    acoes: [
                      CircleIconButton(
                        icone: Icons.photo_camera_outlined,
                        tooltip: 'Tirar foto agora',
                        onPressed: _tirarFoto,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.midsmall),
                  _QuadroFoto(foto: foto, aCarregar: aCarregar),
                  const SizedBox(height: AppSpacing.midsmall),
                  ..._reconhecidos(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ? Lista do que está no frigorífico: primeiro o que a câmara tem a
  // ? certeza, no fim o que falta confirmar (toca para confirmar)
  List<Widget> _reconhecidos(BuildContext context) {
    final itens =
        frigorifico.noFrigorifico.where((i) => i.quantidade > 0).toList()
          ..sort((a, b) => b.certeza.compareTo(a.certeza));
    return [
      SectionTitle(titulo: 'Reconhecidos', contador: itens.length),
      const SizedBox(height: AppSpacing.midsmall),
      if (itens.isEmpty)
        Text(
          'A câmara ainda não reconheceu nada.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppTokens.textSecondary),
        )
      else
        ListCard(children: [for (final i in itens) _linha(context, i)]),
    ];
  }

  Widget _linha(BuildContext context, Item i) {
    final bool duvida = i.certeza < 60;
    return ItemRow(
      titulo: duvida ? '${i.nome}?' : i.nome,
      detalhe: duvida ? 'Toca para confirmar' : i.prateleira,
      estado: duvida ? EstadoValidade.aviso : EstadoValidade.nenhum,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TagChip(
            texto: '${i.certeza} %',
            tom: duvida ? TagTom.aviso : TagTom.marca,
          ),
          if (duvida) ...[
            const SizedBox(width: AppSpacing.small),
            const Icon(Icons.chevron_right, color: AppTokens.textPrimary),
          ],
        ],
      ),
      onTap: duvida ? () => mostrarConfirmar(context, i) : null,
    );
  }
}

// ? Quadro escuro com a foto e as caixas por cima
class _QuadroFoto extends StatelessWidget {
  const _QuadroFoto({required this.foto, required this.aCarregar});

  final _Foto? foto;
  final bool aCarregar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cinza = textTheme.bodySmall?.copyWith(color: AppColors.gray400);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        color: AppColors.gray800,
        // ? a OV3660 tira fotos 4:3; assim as caixas batem certo com a foto
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: aCarregar
              ? const Center(child: CircularProgressIndicator())
              : foto == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_camera_outlined,
                        size: 32,
                        color: AppColors.gray400,
                      ),
                      const SizedBox(height: AppSpacing.small),
                      Text('Ainda não há fotos da câmara', style: cinza),
                    ],
                  ),
                )
              // ? LayoutBuilder dá o tamanho real do quadro para pôr
              // ? as caixas no sítio certo
              : LayoutBuilder(
                  builder: (context, c) => Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          foto!.url,
                          fit: BoxFit.fill,
                          errorBuilder: (_, _, _) => Center(
                            child: Text(
                              'Não deu para abrir a foto',
                              style: cinza,
                            ),
                          ),
                        ),
                      ),
                      for (final cx in foto!.caixas)
                        ..._caixa(cx, c.maxWidth, c.maxHeight),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ? a caixa à volta do alimento + a etiqueta com o nome por cima
  List<Widget> _caixa(_Caixa cx, double w, double h) {
    final cor = cx.certo ? AppColors.primary300 : AppColors.warning400;
    final topo = cx.topo * h;
    return [
      Positioned(
        left: cx.esquerda * w,
        top: topo,
        width: (cx.direita - cx.esquerda) * w,
        height: (cx.fundo - cx.topo) * h,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: cor, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      Positioned(
        left: cx.esquerda * w,
        // ? por cima da caixa; se não couber, por dentro
        top: topo >= 28 ? topo - 28 : topo + 4,
        child: TagChip(
          texto: cx.certo ? cx.nome : 'A confirmar',
          tom: cx.certo ? TagTom.marca : TagTom.aviso,
        ),
      ),
    ];
  }
}
