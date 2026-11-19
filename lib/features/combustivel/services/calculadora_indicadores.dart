import '../models/abastecimento.dart';
import '../models/indicador_abastecimento.dart';

class CalculadoraIndicadores {
  /// Calcula os indicadores assumindo que todos os registros completam o tanque.
  ///
  /// - O 1º abastecimento (ordem cronológica) serve como referência inicial e
  ///   não apresenta indicadores de km/L ou R$/km.
  /// - A partir do 2º abastecimento:
  ///   - distância = km atual - km anterior
  ///   - consumo (km/L) = distância / litros atuais
  ///   - custo (R$/km) = valor total atual / distância
  static ResumoDashboard calcular(List<Abastecimento> abastecimentos) {
    if (abastecimentos.isEmpty) {
      return const ResumoDashboard(
        indicadoresCronologicos: [],
        indicadoresComCalculo: [],
        totalGasto: 0,
        totalLitros: 0,
        distanciaTotal: 0,
      );
    }

    final ordenados = List<Abastecimento>.from(abastecimentos)
      ..sort((a, b) {
        final porData = a.dataHora.compareTo(b.dataHora);
        if (porData != 0) return porData;
        final porKm = a.quilometragem.compareTo(b.quilometragem);
        if (porKm != 0) return porKm;
        return (a.id ?? 0).compareTo(b.id ?? 0);
      });

    final indicadores = <IndicadorAbastecimento>[];
    final comCalculo = <IndicadorAbastecimento>[];

    var totalGasto = 0.0;
    var totalLitros = 0.0;
    var distanciaTotal = 0.0;
    var litrosTrechosMedidos = 0.0;
    var gastoTrechosMedidos = 0.0;

    for (var i = 0; i < ordenados.length; i++) {
      final atual = ordenados[i];
      totalGasto += atual.valorTotal;
      totalLitros += atual.litros;

      if (i == 0) {
        // Primeiro abastecimento: referência inicial (sem km/L e sem R$/km)
        indicadores.add(
          IndicadorAbastecimento(abastecimento: atual, sequencia: 1),
        );
        continue;
      }

      final anterior = ordenados[i - 1];
      final distancia = atual.quilometragem - anterior.quilometragem;

      if (distancia > 0) {
        final consumo = distancia / atual.litros;
        final custoKm = atual.valorTotal / distancia;
        final indicador = IndicadorAbastecimento(
          abastecimento: atual,
          sequencia: i + 1,
          distanciaPercorrida: distancia,
          consumoKmPorLitro: consumo,
          custoPorKm: custoKm,
        );
        indicadores.add(indicador);
        comCalculo.add(indicador);

        distanciaTotal += distancia;
        litrosTrechosMedidos += atual.litros;
        gastoTrechosMedidos += atual.valorTotal;
      } else {
        indicadores.add(
          IndicadorAbastecimento(abastecimento: atual, sequencia: i + 1),
        );
      }
    }

    final consumoMedio = distanciaTotal > 0 && litrosTrechosMedidos > 0
        ? distanciaTotal / litrosTrechosMedidos
        : null;
    final custoMedio =
        distanciaTotal > 0 ? gastoTrechosMedidos / distanciaTotal : null;

    return ResumoDashboard(
      indicadoresCronologicos: List.unmodifiable(indicadores),
      indicadoresComCalculo: List.unmodifiable(comCalculo),
      totalGasto: totalGasto,
      totalLitros: totalLitros,
      distanciaTotal: distanciaTotal,
      consumoMedioKmPorLitro: consumoMedio,
      custoMedioPorKm: custoMedio,
      ultimoCalculado: comCalculo.isEmpty ? null : comCalculo.last,
    );
  }
}
