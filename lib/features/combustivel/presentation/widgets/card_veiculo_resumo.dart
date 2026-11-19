import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/veiculo.dart';

class CardVeiculoResumo extends StatelessWidget {
  const CardVeiculoResumo({
    super.key,
    required this.veiculo,
    this.totalAbastecimentos,
    this.aoTocar,
  });

  final Veiculo veiculo;
  final int? totalAbastecimentos;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Material(
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoTocar,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F5132), Color(0xFF198754)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        veiculo.tipoVeiculo.icone,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            veiculo.marca.toUpperCase(),
                            style: tema.textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            veiculo.modelo,
                            style: tema.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TagVeiculo(
                      icone: Icons.calendar_today_outlined,
                      texto: 'Ano ${veiculo.ano}',
                    ),
                    _TagVeiculo(
                      icone: Icons.speed_outlined,
                      texto: 'Motor ${veiculo.cilindrada}',
                    ),
                    if (totalAbastecimentos != null)
                      _TagVeiculo(
                        icone: Icons.local_gas_station_outlined,
                        texto: totalAbastecimentos == 1
                            ? '1 abastecimento'
                            : '$totalAbastecimentos abastecimentos',
                        destaque: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TagVeiculo extends StatelessWidget {
  const _TagVeiculo({
    required this.icone,
    required this.texto,
    this.destaque = false,
  });

  final IconData icone;
  final String texto;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: destaque
            ? AppTheme.corCustoKm.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
