import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatadores.dart';
import '../../models/indicador_abastecimento.dart';
import '../../models/tipo_combustivel.dart';

class GraficoValoresAbastecimento extends StatelessWidget {
  const GraficoValoresAbastecimento({
    super.key,
    required this.indicadores,
  });

  final List<IndicadorAbastecimento> indicadores;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.corValor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    size: 18,
                    color: AppTheme.corValor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Valor por abastecimento',
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Total gasto em reais (R\$) em cada registro',
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _LegendaCombustivel(tipo: TipoCombustivel.etanol),
                _LegendaCombustivel(tipo: TipoCombustivel.gasolina),
                _LegendaCombustivel(tipo: TipoCombustivel.diesel),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _construirGrafico(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirGrafico(BuildContext context) {
    final tema = Theme.of(context);
    final maiorValor = indicadores
        .map((e) => e.abastecimento.valorTotal)
        .reduce(math.max);
    final bruto = math.max(maiorValor * 1.18, 40.0);
    final maxY = ((bruto / 40).ceil() * 40).toDouble();
    final intervaloY = maxY / 4;
    final passoX = indicadores.length <= 6
        ? 1
        : (indicadores.length / 5).ceil();

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: intervaloY,
          getDrawingHorizontalLine: (_) => FlLine(
            color: tema.colorScheme.outlineVariant.withValues(alpha: 0.5),
            strokeWidth: 1,
            dashArray: const [4, 4],
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: tema.colorScheme.outlineVariant.withValues(alpha: 0.8),
            ),
            left: BorderSide(
              color: tema.colorScheme.outlineVariant.withValues(alpha: 0.8),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 54,
              interval: intervaloY,
              getTitlesWidget: (valor, meta) {
                if (valor == meta.max) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    'R\$${valor.round()}',
                    style: tema.textTheme.labelSmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (valor, meta) {
                final idx = valor.toInt();
                if (idx < 0 || idx >= indicadores.length) {
                  return const SizedBox.shrink();
                }
                final mostrar =
                    idx == 0 ||
                    idx == indicadores.length - 1 ||
                    idx % passoX == 0;
                if (!mostrar) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    Formatadores.formatarDataCurta(
                      indicadores[idx].abastecimento.dataHora,
                    ),
                    style: tema.textTheme.labelSmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipBorderRadius: BorderRadius.circular(10),
            getTooltipColor: (_) => const Color(0xFF1E293B),
            getTooltipItem: (grupo, grupoIdx, barra, barraIdx) {
              final item = indicadores[grupo.x];
              return BarTooltipItem(
                '${Formatadores.formatarMoeda(item.abastecimento.valorTotal)}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                children: [
                  TextSpan(
                    text:
                        '${item.abastecimento.tipoCombustivel.rotulo} • '
                        '${Formatadores.formatarLitros(item.abastecimento.litros)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < indicadores.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: indicadores[i].abastecimento.valorTotal,
                  color: indicadores[i].abastecimento.tipoCombustivel.cor,
                  width: indicadores.length > 8 ? 14 : 22,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LegendaCombustivel extends StatelessWidget {
  const _LegendaCombustivel({required this.tipo});

  final TipoCombustivel tipo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: tipo.cor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          tipo.rotulo,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
