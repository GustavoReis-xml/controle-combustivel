import 'abastecimento.dart';

class IndicadorAbastecimento {
  const IndicadorAbastecimento({
    required this.abastecimento,
    required this.sequencia,
    this.distanciaPercorrida,
    this.consumoKmPorLitro,
    this.custoPorKm,
  });

  final Abastecimento abastecimento;

  /// Posição cronológica (1 = primeiro abastecimento / referência inicial).
  final int sequencia;

  /// Quilometragem atual menos a quilometragem do abastecimento anterior.
  final double? distanciaPercorrida;

  /// Distância percorrida dividida pela quantidade de litros do abastecimento atual.
  final double? consumoKmPorLitro;

  /// Valor total do abastecimento atual dividido pela distância percorrida.
  final double? custoPorKm;

  bool get ehReferenciaInicial => sequencia == 1;

  bool get possuiIndicadores =>
      consumoKmPorLitro != null && custoPorKm != null && distanciaPercorrida != null;
}

class ResumoDashboard {
  const ResumoDashboard({
    required this.indicadoresCronologicos,
    required this.indicadoresComCalculo,
    required this.totalGasto,
    required this.totalLitros,
    required this.distanciaTotal,
    this.consumoMedioKmPorLitro,
    this.custoMedioPorKm,
    this.ultimoCalculado,
  });

  /// Todos os abastecimentos ordenados cronologicamente (do 1º ao mais recente).
  final List<IndicadorAbastecimento> indicadoresCronologicos;

  /// Apenas os abastecimentos a partir do 2º que possuem km/L e R$/km válidos.
  final List<IndicadorAbastecimento> indicadoresComCalculo;

  final double totalGasto;
  final double totalLitros;
  final double distanciaTotal;

  /// Consumo médio geral entre o 1º e o último abastecimento (distância total / litros dos trechos medidos).
  final double? consumoMedioKmPorLitro;

  /// Custo médio por quilômetro nos trechos medidos (gasto dos trechos medidos / distância total).
  final double? custoMedioPorKm;

  final IndicadorAbastecimento? ultimoCalculado;

  int get totalAbastecimentos => indicadoresCronologicos.length;

  List<IndicadorAbastecimento> get indicadoresMaisRecentesPrimeiro =>
      indicadoresCronologicos.reversed.toList();
}
