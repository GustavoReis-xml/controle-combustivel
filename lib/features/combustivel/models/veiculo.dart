import 'tipo_veiculo_fipe.dart';

class Veiculo {
  Veiculo({
    this.id,
    this.tipoVeiculo = TipoVeiculoFipe.carros,
    required String marca,
    required String modelo,
    required this.ano,
    required String cilindrada,
  }) : marca = marca.trim(),
       modelo = modelo.trim(),
       cilindrada = cilindrada.trim() {
    if (this.marca.isEmpty) {
      throw ArgumentError('A marca do veículo é obrigatória.');
    }
    if (this.modelo.isEmpty) {
      throw ArgumentError('O modelo do veículo é obrigatório.');
    }
    final anoMaximo = DateTime.now().year + 2;
    if (ano < 1900 || ano > anoMaximo) {
      throw ArgumentError('Ano do veículo inválido: $ano.');
    }
    if (this.cilindrada.isEmpty) {
      throw ArgumentError('A cilindrada do motor é obrigatória.');
    }
  }

  final int? id;
  final TipoVeiculoFipe tipoVeiculo;
  final String marca;
  final String modelo;
  final int ano;
  final String cilindrada;

  String get tituloCompleto => '$marca $modelo';

  Veiculo copyWith({
    int? id,
    TipoVeiculoFipe? tipoVeiculo,
    String? marca,
    String? modelo,
    int? ano,
    String? cilindrada,
  }) => Veiculo(
    id: id ?? this.id,
    tipoVeiculo: tipoVeiculo ?? this.tipoVeiculo,
    marca: marca ?? this.marca,
    modelo: modelo ?? this.modelo,
    ano: ano ?? this.ano,
    cilindrada: cilindrada ?? this.cilindrada,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'tipo_veiculo': tipoVeiculo.codigoApi,
    'marca': marca,
    'modelo': modelo,
    'ano': ano,
    'cilindrada': cilindrada,
  };

  factory Veiculo.fromMap(Map<String, Object?> mapa) => Veiculo(
    id: mapa['id'] as int?,
    tipoVeiculo: TipoVeiculoFipe.fromCodigo(
      (mapa['tipo_veiculo'] as String?) ?? 'carros',
    ),
    marca: mapa['marca'] as String,
    modelo: mapa['modelo'] as String,
    ano: (mapa['ano'] as num).toInt(),
    cilindrada: mapa['cilindrada'] as String,
  );
}
