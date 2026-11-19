import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatadores.dart';
import '../../models/indicador_abastecimento.dart';

class ItemAbastecimento extends StatelessWidget {
  const ItemAbastecimento({
    super.key,
    required this.indicador,
    this.aoExcluir,
  });

  final IndicadorAbastecimento indicador;
  final VoidCallback? aoExcluir;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final ab = indicador.abastecimento;
    final combustivel = ab.tipoCombustivel;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: combustivel.cor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        combustivel.icone,
                        size: 16,
                        color: combustivel.cor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        combustivel.rotulo,
                        style: TextStyle(
                          color: combustivel.cor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tema.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#${indicador.sequencia}',
                    style: tema.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatadores.formatarMoeda(ab.valorTotal),
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: tema.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      Formatadores.formatarDataHora(ab.dataHora),
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (aoExcluir != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: aoExcluir,
                    tooltip: 'Excluir abastecimento',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: tema.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _DetalheTexto(
                  icone: Icons.water_drop_outlined,
                  texto:
                      '${Formatadores.formatarLitros(ab.litros)} × '
                      '${Formatadores.formatarMoeda(ab.precoPorLitro)}/L',
                ),
                _DetalheTexto(
                  icone: Icons.speed_outlined,
                  texto: Formatadores.formatarQuilometragem(ab.quilometragem),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            if (indicador.ehReferenciaInicial)
              Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 16,
                    color: tema.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Referência inicial — indicadores de km/L e R\$/km são calculados a partir do 2º abastecimento.',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              )
            else if (indicador.possuiIndicadores)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ChipIndicador(
                    rotulo: 'Distância',
                    valor: Formatadores.formatarQuilometragem(
                      indicador.distanciaPercorrida!,
                    ),
                    cor: tema.colorScheme.secondary,
                  ),
                  _ChipIndicador(
                    rotulo: 'Consumo',
                    valor: Formatadores.formatarConsumo(
                      indicador.consumoKmPorLitro!,
                    ),
                    cor: AppTheme.corConsumo,
                  ),
                  _ChipIndicador(
                    rotulo: 'Custo/km',
                    valor: Formatadores.formatarCustoPorKm(
                      indicador.custoPorKm!,
                    ),
                    cor: AppTheme.corCustoKm,
                  ),
                ],
              )
            else
              Text(
                'Indicadores indisponíveis (quilometragem igual ou inferior ao registro anterior).',
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetalheTexto extends StatelessWidget {
  const _DetalheTexto({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 15, color: cor),
        const SizedBox(width: 5),
        Text(
          texto,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ChipIndicador extends StatelessWidget {
  const _ChipIndicador({
    required this.rotulo,
    required this.valor,
    required this.cor,
  });

  final String rotulo;
  final String valor;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rotulo,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}
