// * ECRÃ AVISOS (ecrã 04 do Figma). Abre pelo sino do Início.
// * Fluxo: regra de aviso (toca → Definições) → "A expirar" dentro dos dias
// * escolhidos (o que expira hoje tem Ver receita / Usei / Deitei fora) →
// * "Recentes" dos últimos 3 dias (alimentos usados ou deitados fora e
// * alertas dos sensores).

import 'package:flutter/material.dart';

import '../data/frigorifico.dart';
import '../models/evento.dart';
import '../models/item.dart';
import '../models/receita.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/item_row.dart';
import '../widgets/list_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_title.dart';
import '../widgets/snack.dart';
import '../widgets/tag_chip.dart';
import 'definicoes.dart';
import 'receita_detalhe.dart';

// ? Uma linha da secção "Recentes": vem de um Evento ou de um AlertaSensor.
// ? Classe só para este ecrã, para juntar os dois tipos numa só lista ordenada
class _Registo {
  _Registo(this.titulo, this.detalhe, this.data, this.estado, [this.chip]);

  final String titulo;
  final String detalhe;
  final DateTime data;
  final EstadoValidade estado;
  final String? chip;
}

// ? "hoje, 9:05", "ontem, 18:30", "há 3 dias": mais fácil de ler do que a data
String _quando(DateTime d) {
  final hoje = DateUtils.dateOnly(DateTime.now());
  final dias = hoje.difference(DateUtils.dateOnly(d)).inDays;
  final hora = '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  if (dias == 0) return 'hoje, $hora';
  if (dias == 1) return 'ontem, $hora';
  return 'há $dias dias';
}

// ? StatelessWidget: tudo vem do frigorifico, ouvido pelo ListenableBuilder
class Avisos extends StatelessWidget {
  const Avisos({super.key});

  // ? receita que usa este alimento (ou null se não houver), para o botão
  // ? "Ver receita": a forma mais útil de salvar o que expira hoje
  Receita? _receitaPara(Item item) {
    for (final r in frigorifico.receitas) {
      if (r.ingredientes.any((ing) => ingredienteCorresponde(ing, item))) {
        return r;
      }
    }
    return null;
  }

  // ? o que aconteceu nos últimos 3 dias, do mais recente para o mais antigo
  // ? (mais do que isso já não é um aviso, está no Impacto)
  List<_Registo> _recentes() {
    final limite = DateUtils.dateOnly(DateTime.now())
        .subtract(const Duration(days: 3));
    final lista = <_Registo>[];

    for (final e in frigorifico.eventos) {
      // ? os eventos "Exemplo" só servem para o Impacto ter números; aqui
      // ? apareciam como linhas sem sentido
      if (e.nome == 'Exemplo' || e.data.isBefore(limite)) continue;
      if (e.tipo == TipoEvento.usado) {
        lista.add(
          _Registo(
            '${e.nome} aproveitado',
            'Usado a tempo · ${_quando(e.data)}',
            e.data,
            EstadoValidade.marca,
            'Salvo',
          ),
        );
      } else {
        lista.add(
          _Registo(
            '${e.nome} deitado fora',
            '${e.motivo ?? 'Deitado fora'} · ${_quando(e.data)}',
            e.data,
            EstadoValidade.perigo,
          ),
        );
      }
    }
    for (final a in frigorifico.alertas) {
      if (a.data.isBefore(limite)) continue;
      lista.add(
        _Registo(
          a.titulo,
          '${a.detalhe} · ${_quando(a.data)}',
          a.data,
          EstadoValidade.perigo,
        ),
      );
    }
    // ? sort com compareTo ao contrário = mais recente primeiro
    lista.sort((a, b) => b.data.compareTo(a.data));
    return lista;
  }

  // ? Guardam o "antes" para o Anular da snackbar conseguir desfazer
  void _usei(BuildContext context, Item item) {
    final int antes = item.quantidade;
    final Local localAntes = item.local;
    frigorifico.usar(item);
    mostrarAnular(
      context,
      'Usaste ${item.nome.toLowerCase()} a tempo',
      () => frigorifico.repor(item, antes, localAntes),
    );
  }

  void _deiteiFora(BuildContext context, Item item) {
    final int antes = item.quantidade;
    frigorifico.deitarFora(item);
    mostrarAnular(
      context,
      '${item.nome} deitado fora',
      () => frigorifico.repor(item, antes, Local.frigorifico),
    );
  }

  Widget _linhaAlimento(BuildContext context, Item item) {
    final estado = estadoDe(item.dias);
    final receita = _receitaPara(item);
    final detalhe = item.aberto
        ? '${item.quantidadeTexto} · aberto'
        : item.quantidadeTexto;

    // ? o que expira hoje (ou já expirou) leva botões porque é para agir já;
    // ? o resto só o chip do prazo, para o ecrã não ficar cheio de botões
    if (item.dias > 0) {
      return ItemRow(
        titulo: item.nome,
        detalhe: detalhe,
        estado: estado,
        trailing: TagChip(texto: prazoDe(item.dias), tom: tomDe(estado)),
      );
    }

    return ItemRow(
      titulo: item.dias < 0
          ? '${item.nome} · já expirou'
          : '${item.nome} · expira hoje',
      detalhe: detalhe,
      estado: estado,
      acoes: Row(
        children: [
          if (receita != null) ...[
            Expanded(
              child: AppButton(
                texto: 'Ver receita',
                expandir: true,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReceitaDetalhe(receita: receita),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.small),
          ],
          Expanded(
            child: AppButton(
              texto: 'Usei',
              tipo: BotaoTipo.tonal,
              expandir: true,
              onPressed: () => _usei(context, item),
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          CircleIconButton(
            icone: Icons.delete_outline,
            tooltip: 'Deitei fora',
            estilo: CirculoEstilo.contorno,
            corIcone: AppTokens.textDanger,
            onPressed: () => _deiteiFora(context, item),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: frigorifico,
          builder: (context, _) {
            final int dias = frigorifico.diasAviso;
            // ? dentro do prazo de aviso escolhido nas Definições (1, 2 ou 3 dias)
            final alimentos = frigorifico.aExpirar
                .where((i) => i.dias <= dias)
                .toList();
            final recentes = _recentes();

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.midsmall,
                AppSpacing.midsmall,
                AppSpacing.midsmall,
                AppSpacing.mid,
              ),
              children: [
                const ScreenHeader(
                  subtitulo: 'Antes de estragar',
                  titulo: 'Avisos',
                  voltar: true,
                ),
                const SizedBox(height: AppSpacing.midsmall),
                ListCard(
                  children: [
                    ItemRow(
                      titulo: dias == 1
                          ? 'Avisar 1 dia antes'
                          : 'Avisar $dias dias antes',
                      detalhe: frigorifico.resumoDiario
                          ? 'Resumo diário às $horaResumo com uma receita'
                          : 'Resumo diário desligado',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Definicoes(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.midsmall),
                const SectionTitle(titulo: 'A expirar'),
                const SizedBox(height: AppSpacing.midsmall),
                if (alimentos.isEmpty)
                  Text(
                    'Nada a expirar nos próximos $dias dias.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppTokens.textSecondary),
                  )
                else
                  ListCard(
                    children: [
                      for (final item in alimentos)
                        _linhaAlimento(context, item),
                    ],
                  ),
                if (recentes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.midsmall),
                  const SectionTitle(titulo: 'Recentes'),
                  const SizedBox(height: AppSpacing.midsmall),
                  ListCard(
                    children: [
                      for (final r in recentes)
                        ItemRow(
                          titulo: r.titulo,
                          detalhe: r.detalhe,
                          estado: r.estado,
                          trailing: r.chip == null
                              ? null
                              : TagChip(texto: r.chip!, tom: TagTom.marca),
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
