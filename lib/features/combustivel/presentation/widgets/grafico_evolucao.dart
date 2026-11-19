import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/formatadores.dart';
import '../../models/indicador_abastecimento.dart';

class GraficoEvolucao extends StatelessWidget {
  const GraficoEvolucao({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.cor,
    required this.indicadores,
    required this.extrairValor,
    required this.formatarValorEixo,
    required this.formatarValorTooltip,
    required this.mensagemInsuficiente,
  });

  final String titulo;
  final String subtitulo;
  final IconData icone;
  final Color cor;
  final List<IndicadorAbastecimento> indicadores;
  final double Function(IndicadorAbastecimento indicador) extrairValor;
  final String Function(double valor) formatarValorEixo;
  final String Function(double valor) formatarValorTooltip;
  final String mensagemInsuficiente;

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
                    color: cor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icone, size: 18, color: cor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitulo,
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (indicadores.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tema.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: tema.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        mensagemInsuficiente,
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 210,
                child: _construirGrafico(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _construirGrafico(BuildContext context) {
    final tema = Theme.of(context);
    final valores = indicadores.map(extrairValor).toList();
    final spots = <FlSpot>[
      for (var i = 0; i < valores.length; i++) FlSpot(i.toDouble(), valores[i]),
    ];

    final menor = valores.reduce(math.min);
    final maior = valores.reduce(math.max);
    final amplitude = (maior - menor).abs();
    final margemY = amplitude == 0
        ? math.max(maior.abs() * 0.25, 1.0)
        : amplitude * 0.22;

    final minY = math.max(0.0, menor - margemY);
    final maxY = maior + margemY;
    final intervaloY = math.max((maxY - minY) / 4, 0.1);

    final minX = spots.length == 1 ? -0.5 : 0.0;
    final maxX = spots.length == 1 ? 0.5 : (spots.length - 1).toDouble();
    final passoX = spots.length <= 5 ? 1 : (spots.length / 4).ceil();

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
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
                if (valor == meta.min || valor == meta.max) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    formatarValorEixo(valor),
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
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (valor, meta) {
                if (valor != valor.roundToDouble()) {
                  return const SizedBox.shrink();
                }
                final idx = valor.toInt();
                if (idx < 0 || idx >= indicadores.length) {
                  return const SizedBox.shrink();
                }
                final mostrar =
                    idx == 0 ||
                    idx == indicadores.length - 1 ||
                    idx % passoX == 0;
                if (!mostrar) return const SizedBox.shrink();

                final item = indicadores[idx];
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    Formatadores.formatarDataCurta(item.abastecimento.dataHora),
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
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipBorderRadius: BorderRadius.circular(10),
            getTooltipColor: (_) => const Color(0xFF1E293B),
            getTooltipItems: (pontosTocados) => pontosTocados.map((ponto) {
              final idx = ponto.x.round().clamp(0, indicadores.length - 1);
              final item = indicadores[idx];
              final data = Formatadores.formatarDataCurta(
                item.abastecimento.dataHora,
              );
              final combustivel = item.abastecimento.tipoCombustivel.rotulo;
              return LineTooltipItem(
                '${formatarValorTooltip(ponto.y)}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                children: [
                  TextSpan(
                    text: '#${item.sequencia} • $data ($combustivel)',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: spots.length >= 3,
            curveSmoothness: 0.28,
            preventCurveOverShooting: true,
            color: cor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: spots.length == 1 ? 6 : 4.5,
                    color: Colors.white,
                    strokeWidth: 2.5,
                    strokeColor: cor,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  cor.withValues(alpha: 0.24),
                  cor.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
