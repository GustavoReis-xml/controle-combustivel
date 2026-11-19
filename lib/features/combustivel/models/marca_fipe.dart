class MarcaFipe {
  const MarcaFipe({required this.codigo, required this.nome});

  final String codigo;
  final String nome;

  factory MarcaFipe.fromJson(Map<String, Object?> json) {
    final nome = (json['nome'] ?? '').toString().trim();
    final codigo = (json['valor'] ?? '').toString().trim();
    if (nome.isEmpty || codigo.isEmpty) {
      throw const FormatException('Marca inválida recebida da BrasilAPI.');
    }
    return MarcaFipe(codigo: codigo, nome: nome);
  }

  @override
  bool operator ==(Object other) =>
      other is MarcaFipe && other.codigo == codigo && other.nome == nome;

  @override
  int get hashCode => Object.hash(codigo, nome);

  @override
  String toString() => nome;
}
