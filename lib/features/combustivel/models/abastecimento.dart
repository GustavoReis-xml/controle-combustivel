import 'tipo_combustivel.dart';

class Abastecimento {
  Abastecimento({
    this.id,
    required this.veiculoId,
    required this.tipoCombustivel,
    required this.precoPorLitro,
    required this.quilometragem,
    required this.litros,
    required DateTime dataHora,
  }) : dataHora = dataHora.toUtc() {
    if (!precoPorLitro.isFinite || precoPorLitro <= 0) {
      throw ArgumentError('O preço por litro deve ser maior que zero.');
    }
    if (!quilometragem.isFinite || quilometragem < 0) {
      throw ArgumentError('A quilometragem não pode ser negativa.');
    }
    if (!litros.isFinite || litros <= 0) {
      throw ArgumentError('A quantidade de litros deve ser maior que zero.');
    }
  }

  final int? id;
  final int veiculoId;
  final TipoCombustivel tipoCombustivel;
  final double precoPorLitro;
  final double quilometragem;
  final double litros;
  final DateTime dataHora;

  /// Valor total calculado multiplicando o preço por litro pela quantidade de litros.
  double get valorTotal => precoPorLitro * litros;

  Abastecimento copyWith({
    int? id,
    int? veiculoId,
    TipoCombustivel? tipoCombustivel,
    double? precoPorLitro,
    double? quilometragem,
    double? litros,
    DateTime? dataHora,
  }) => Abastecimento(
    id: id ?? this.id,
    veiculoId: veiculoId ?? this.veiculoId,
    tipoCombustivel: tipoCombustivel ?? this.tipoCombustivel,
    precoPorLitro: precoPorLitro ?? this.precoPorLitro,
    quilometragem: quilometragem ?? this.quilometragem,
    litros: litros ?? this.litros,
    dataHora: dataHora ?? this.dataHora,
  );

  Map<String, Object?> toMap() {
    final iso = dataHora.toUtc().toIso8601String();
    return {
      if (id != null) 'id': id,
      'veiculo_id': veiculoId,
      'tipo_combustivel': tipoCombustivel.codigo,
      'preco_por_litro': precoPorLitro,
      'quilometragem': quilometragem,
      'litros': litros,
      'valor_total': valorTotal,
      'data_hora': dataHora.microsecond == 0
          ? iso.replaceFirst('Z', '000Z')
          : iso,
    };
  }

  factory Abastecimento.fromMap(Map<String, Object?> mapa) => Abastecimento(
    id: mapa['id'] as int?,
    veiculoId: (mapa['veiculo_id'] as num).toInt(),
    tipoCombustivel: TipoCombustivel.fromCodigo(
      mapa['tipo_combustivel'] as String,
    ),
    precoPorLitro: (mapa['preco_por_litro'] as num).toDouble(),
    quilometragem: (mapa['quilometragem'] as num).toDouble(),
    litros: (mapa['litros'] as num).toDouble(),
    dataHora: DateTime.parse(mapa['data_hora'] as String).toUtc(),
  );
}
