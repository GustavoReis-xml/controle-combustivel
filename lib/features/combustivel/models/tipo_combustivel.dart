import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum TipoCombustivel {
  etanol(
    codigo: 'etanol',
    rotulo: 'Etanol',
    cor: AppTheme.corEtanol,
    icone: Icons.eco_outlined,
  ),
  gasolina(
    codigo: 'gasolina',
    rotulo: 'Gasolina',
    cor: AppTheme.corGasolina,
    icone: Icons.local_gas_station_outlined,
  ),
  diesel(
    codigo: 'diesel',
    rotulo: 'Diesel',
    cor: AppTheme.corDiesel,
    icone: Icons.local_shipping_outlined,
  );

  const TipoCombustivel({
    required this.codigo,
    required this.rotulo,
    required this.cor,
    required this.icone,
  });

  final String codigo;
  final String rotulo;
  final Color cor;
  final IconData icone;

  static TipoCombustivel fromCodigo(String valor) {
    final normalizado = valor.trim().toLowerCase();
    for (final tipo in values) {
      if (tipo.codigo == normalizado) return tipo;
    }
    throw ArgumentError('Tipo de combustível inválido: $valor');
  }
}
