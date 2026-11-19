import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class BancoCombustivel {
  BancoCombustivel({
    String? caminho,
    Future<Database> Function(String, OpenDatabaseOptions)? abrir,
  }) : _caminho = caminho,
       _abrir =
           abrir ??
           ((caminhoBanco, opcoes) =>
               databaseFactory.openDatabase(caminhoBanco, options: opcoes));

  final String? _caminho;
  final Future<Database> Function(String, OpenDatabaseOptions) _abrir;
  Future<Database>? _conexao;

  Future<Database> get conexao => _conexao ??= _abrirBanco();

  Future<Database> _abrirBanco() async {
    try {
      final caminho =
          _caminho ?? p.join(await getDatabasesPath(), 'controle_combustivel.db');
      return await _abrir(
        caminho,
        OpenDatabaseOptions(
          version: 1,
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
          },
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE veiculos (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                tipo_veiculo TEXT NOT NULL,
                marca TEXT NOT NULL,
                modelo TEXT NOT NULL,
                ano INTEGER NOT NULL,
                cilindrada TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE abastecimentos (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                veiculo_id INTEGER NOT NULL,
                tipo_combustivel TEXT NOT NULL,
                preco_por_litro REAL NOT NULL,
                quilometragem REAL NOT NULL,
                litros REAL NOT NULL,
                valor_total REAL NOT NULL,
                data_hora TEXT NOT NULL,
                FOREIGN KEY (veiculo_id) REFERENCES veiculos (id) ON DELETE CASCADE
              )
            ''');
            await db.execute('''
              CREATE INDEX idx_abastecimentos_veiculo_data
              ON abastecimentos (veiculo_id, data_hora, quilometragem)
            ''');
          },
        ),
      );
    } catch (_) {
      _conexao = null;
      rethrow;
    }
  }

  Future<void> fechar() async {
    final conexao = _conexao;
    if (conexao == null) return;
    try {
      await (await conexao).close();
    } finally {
      _conexao = null;
    }
  }
}
