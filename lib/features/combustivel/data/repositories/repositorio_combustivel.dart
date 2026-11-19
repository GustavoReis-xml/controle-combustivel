import '../../models/abastecimento.dart';
import '../../models/veiculo.dart';
import '../database/banco_combustivel.dart';

class RepositorioCombustivel {
  RepositorioCombustivel(this._banco);

  final BancoCombustivel _banco;

  Future<Veiculo?> obterVeiculoAtual() async {
    final db = await _banco.conexao;
    final registros = await db.query('veiculos', orderBy: 'id ASC', limit: 1);
    if (registros.isEmpty) return null;
    return Veiculo.fromMap(registros.first);
  }

  /// Permite o cadastro de apenas um veículo por vez.
  Future<Veiculo> cadastrarVeiculo(Veiculo veiculo) async {
    final db = await _banco.conexao;
    return db.transaction((txn) async {
      final existentes = await txn.query('veiculos', columns: ['id'], limit: 1);
      if (existentes.isNotEmpty) {
        throw StateError(
          'Já existe um veículo cadastrado. Exclua o veículo atual antes de cadastrar outro.',
        );
      }
      final id = await txn.insert('veiculos', veiculo.toMap());
      return veiculo.copyWith(id: id);
    });
  }

  /// Remove o veículo atual e todos os abastecimentos associados a ele.
  Future<void> excluirVeiculoAtual() async {
    final db = await _banco.conexao;
    await db.transaction((txn) async {
      await txn.delete('abastecimentos');
      await txn.delete('veiculos');
    });
  }

  Future<Abastecimento> inserirAbastecimento(
    Abastecimento abastecimento,
  ) async {
    final db = await _banco.conexao;
    final id = await db.insert('abastecimentos', abastecimento.toMap());
    return abastecimento.copyWith(id: id);
  }

  Future<List<Abastecimento>> listarAbastecimentos(int veiculoId) async {
    final db = await _banco.conexao;
    final registros = await db.query(
      'abastecimentos',
      where: 'veiculo_id = ?',
      whereArgs: [veiculoId],
      orderBy: 'data_hora ASC, quilometragem ASC, id ASC',
    );
    return registros.map(Abastecimento.fromMap).toList();
  }

  Future<void> excluirAbastecimento(int id) async {
    final db = await _banco.conexao;
    await db.delete('abastecimentos', where: 'id = ?', whereArgs: [id]);
  }
}
