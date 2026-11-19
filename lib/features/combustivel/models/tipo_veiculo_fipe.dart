import 'package:flutter/material.dart';

enum TipoVeiculoFipe {
  carros(
    codigoApi: 'carros',
    rotulo: 'Carros',
    icone: Icons.directions_car_outlined,
  ),
  motos(
    codigoApi: 'motos',
    rotulo: 'Motos',
    icone: Icons.two_wheeler_outlined,
  ),
  caminhoes(
    codigoApi: 'caminhoes',
    rotulo: 'Caminhões',
    icone: Icons.local_shipping_outlined,
  );

  const TipoVeiculoFipe({
    required this.codigoApi,
    required this.rotulo,
    required this.icone,
  });

  final String codigoApi;
  final String rotulo;
  final IconData icone;

  static TipoVeiculoFipe fromCodigo(String valor) {
    final normalizado = valor.trim().toLowerCase();
    for (final tipo in values) {
      if (tipo.codigoApi == normalizado) return tipo;
    }
    return TipoVeiculoFipe.carros;
  }
}
