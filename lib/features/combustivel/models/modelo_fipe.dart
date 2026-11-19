class ModeloFipe {
  const ModeloFipe({required this.codigo, required this.nome});

  final String codigo;
  final String nome;

  factory ModeloFipe.fromJson(Map<String, Object?> json) {
    final nome = (json['modelo'] ?? json['nome'] ?? '').toString().trim();
    final codigoRaw = (json['valor'] ?? '').toString().trim();
    if (nome.isEmpty) {
      throw const FormatException('Modelo inválido recebido da BrasilAPI.');
    }
    return ModeloFipe(
      codigo: codigoRaw.isEmpty ? nome : codigoRaw,
      nome: nome,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ModeloFipe && other.codigo == codigo && other.nome == nome;

  @override
  int get hashCode => Object.hash(codigo, nome);

  @override
  String toString() => nome;
}
