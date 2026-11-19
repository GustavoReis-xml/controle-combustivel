import 'dart:io';

import 'package:controle_combustivel/features/combustivel/data/database/banco_combustivel.dart';
import 'package:controle_combustivel/features/combustivel/data/repositories/repositorio_combustivel.dart';
import 'package:controle_combustivel/features/combustivel/models/abastecimento.dart';
import 'package:controle_combustivel/features/combustivel/models/tipo_combustivel.dart';
import 'package:controle_combustivel/features/combustivel/models/tipo_veiculo_fipe.dart';
import 'package:controle_combustivel/features/combustivel/models/veiculo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Directory pasta;
  late BancoCombustivel banco;
  late RepositorioCombustivel repositorio;

  setUp(() async {
    pasta = await Directory.systemTemp.createTemp('combustivel_teste_');
    banco = BancoCombustivel(
      caminho: p.join(pasta.path, 'controle_combustivel.db'),
      abrir: (caminho, opcoes) =>
          databaseFactoryFfi.openDatabase(caminho, options: opcoes),
    );
    repositorio = RepositorioCombustivel(banco);
  });

  tearDown(() async {
    await banco.fechar();
    await pasta.delete(recursive: true);
  });

  Veiculo criarVeiculo({String modelo = 'Civic Sedan EX 2.0 16V'}) => Veiculo(
    tipoVeiculo: TipoVeiculoFipe.carros,
    marca: 'Honda',
    modelo: modelo,
    ano: 2022,
    cilindrada: '2.0',
  );

  test('persiste veículo e abastecimentos após fechar e reabrir o banco', () async {
    final veiculo = await repositorio.cadastrarVeiculo(criarVeiculo());
    expect(veiculo.id, isNotNull);

    await repositorio.inserirAbastecimento(
      Abastecimento(
        veiculoId: veiculo.id!,
        tipoCombustivel: TipoCombustivel.gasolina,
        precoPorLitro: 5.89,
        quilometragem: 42000,
        litros: 40,
        dataHora: DateTime.utc(2026, 11, 5, 13, 30),
      ),
    );

    await banco.fechar();

    final recuperado = await repositorio.obterVeiculoAtual();
    expect(recuperado, isNotNull);
    expect(recuperado!.marca, 'Honda');
    expect(recuperado.modelo, 'Civic Sedan EX 2.0 16V');
    expect(recuperado.ano, 2022);
    expect(recuperado.cilindrada, '2.0');

    final registros = await repositorio.listarAbastecimentos(recuperado.id!);
    expect(registros.length, 1);
    expect(registros.first.valorTotal, closeTo(235.60, 0.001));
    expect(registros.first.tipoCombustivel, TipoCombustivel.gasolina);
  });

  test('permite apenas um veículo cadastrado por vez', () async {
    await repositorio.cadastrarVeiculo(criarVeiculo());

    await expectLater(
      repositorio.cadastrarVeiculo(criarVeiculo(modelo: 'Fit EX 1.5')),
      throwsStateError,
    );
  });

  test('excluir veículo remove também todos os abastecimentos associados', () async {
    final veiculo = await repositorio.cadastrarVeiculo(criarVeiculo());
    await repositorio.inserirAbastecimento(
      Abastecimento(
        veiculoId: veiculo.id!,
        tipoCombustivel: TipoCombustivel.etanol,
        precoPorLitro: 4.19,
        quilometragem: 42000,
        litros: 38,
        dataHora: DateTime.utc(2026, 11, 1, 10),
      ),
    );
    await repositorio.inserirAbastecimento(
      Abastecimento(
        veiculoId: veiculo.id!,
        tipoCombustivel: TipoCombustivel.diesel,
        precoPorLitro: 6.10,
        quilometragem: 42400,
        litros: 35,
        dataHora: DateTime.utc(2026, 11, 10, 15),
      ),
    );

    await repositorio.excluirVeiculoAtual();

    expect(await repositorio.obterVeiculoAtual(), isNull);
    final db = await banco.conexao;
    final contagem = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM abastecimentos',
    );
    expect(contagem.single['total'], 0);

    // Após exclusão, permite cadastrar outro veículo
    final novo = await repositorio.cadastrarVeiculo(
      criarVeiculo(modelo: 'HR-V EXL 1.5'),
    );
    expect(novo.modelo, 'HR-V EXL 1.5');
  });
}
