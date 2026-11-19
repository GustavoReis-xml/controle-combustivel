import 'package:controle_combustivel/features/combustivel/models/abastecimento.dart';
import 'package:controle_combustivel/features/combustivel/models/tipo_combustivel.dart';
import 'package:controle_combustivel/features/combustivel/services/calculadora_indicadores.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Abastecimento criar({
    required int id,
    required double km,
    required double litros,
    required double preco,
    required DateTime dataHora,
    TipoCombustivel tipo = TipoCombustivel.gasolina,
  }) => Abastecimento(
    id: id,
    veiculoId: 1,
    tipoCombustivel: tipo,
    precoPorLitro: preco,
    quilometragem: km,
    litros: litros,
    dataHora: dataHora,
  );

  test('retorna resumo zerado quando não há abastecimentos', () {
    final resumo = CalculadoraIndicadores.calcular(const []);
    expect(resumo.totalAbastecimentos, 0);
    expect(resumo.totalGasto, 0);
    expect(resumo.distanciaTotal, 0);
    expect(resumo.consumoMedioKmPorLitro, isNull);
    expect(resumo.custoMedioPorKm, isNull);
  });

  test('primeiro abastecimento é referência inicial sem km/L nem R\$/km', () {
    final primeiro = criar(
      id: 1,
      km: 10000,
      litros: 40,
      preco: 6.00,
      dataHora: DateTime.utc(2026, 11, 1, 12),
    );
    final resumo = CalculadoraIndicadores.calcular([primeiro]);

    expect(resumo.totalAbastecimentos, 1);
    expect(resumo.totalGasto, closeTo(240.0, 0.001));
    expect(resumo.indicadoresComCalculo, isEmpty);

    final ind = resumo.indicadoresCronologicos.single;
    expect(ind.ehReferenciaInicial, isTrue);
    expect(ind.possuiIndicadores, isFalse);
    expect(ind.distanciaPercorrida, isNull);
    expect(ind.consumoKmPorLitro, isNull);
    expect(ind.custoPorKm, isNull);
  });

  test('calcula distância, km/L e R\$/km corretamente a partir do 2º registro', () {
    // Passados fora de ordem cronológica para validar a ordenação interna.
    final reg3 = criar(
      id: 3,
      km: 10750,
      litros: 30,
      preco: 4.50, // total = 135.00; dist = 350; km/L = 350/30 = 11.6667; R$/km = 135/350 = 0.3857
      tipo: TipoCombustivel.etanol,
      dataHora: DateTime.utc(2026, 11, 15, 18),
    );
    final reg1 = criar(
      id: 1,
      km: 10000,
      litros: 42,
      preco: 5.90, // total = 247.80 (referência inicial)
      dataHora: DateTime.utc(2026, 11, 1, 10),
    );
    final reg2 = criar(
      id: 2,
      km: 10400,
      litros: 40,
      preco: 6.00, // total = 240.00; dist = 400; km/L = 10.0; R$/km = 0.60
      dataHora: DateTime.utc(2026, 11, 8, 14),
    );

    final resumo = CalculadoraIndicadores.calcular([reg3, reg1, reg2]);

    expect(resumo.totalAbastecimentos, 3);
    expect(resumo.indicadoresComCalculo.length, 2);
    expect(resumo.totalGasto, closeTo(247.80 + 240.00 + 135.00, 0.001));
    expect(resumo.distanciaTotal, closeTo(750.0, 0.001));

    final ind1 = resumo.indicadoresCronologicos[0];
    final ind2 = resumo.indicadoresCronologicos[1];
    final ind3 = resumo.indicadoresCronologicos[2];

    expect(ind1.sequencia, 1);
    expect(ind1.ehReferenciaInicial, isTrue);
    expect(ind1.consumoKmPorLitro, isNull);
    expect(ind1.custoPorKm, isNull);

    expect(ind2.sequencia, 2);
    expect(ind2.distanciaPercorrida, closeTo(400.0, 0.001));
    expect(ind2.consumoKmPorLitro, closeTo(10.0, 0.001));
    expect(ind2.custoPorKm, closeTo(0.60, 0.001));

    expect(ind3.sequencia, 3);
    expect(ind3.distanciaPercorrida, closeTo(350.0, 0.001));
    expect(ind3.consumoKmPorLitro, closeTo(350 / 30, 0.0001));
    expect(ind3.custoPorKm, closeTo(135 / 350, 0.0001));

    // Médias globais dos trechos medidos: 750 km / 70 L e R$ 375 / 750 km
    expect(resumo.consumoMedioKmPorLitro, closeTo(750 / 70, 0.0001));
    expect(resumo.custoMedioPorKm, closeTo(375 / 750, 0.0001));
  });
}
