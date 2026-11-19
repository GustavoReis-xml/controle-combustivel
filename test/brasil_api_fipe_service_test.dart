import 'dart:convert';

import 'package:controle_combustivel/features/combustivel/models/tipo_veiculo_fipe.dart';
import 'package:controle_combustivel/features/combustivel/services/brasil_api_fipe_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('consulta marcas e modelos filtrados pela marca na BrasilAPI', () async {
    final urlsChamadas = <Uri>[];
    final client = MockClient((requisicao) async {
      urlsChamadas.add(requisicao.url);
      if (requisicao.url.path == '/api/fipe/marcas/v1/carros') {
        return http.Response(
          jsonEncode([
            {'nome': 'VW - VolksWagen', 'valor': '59'},
            {'nome': 'Honda', 'valor': '25'},
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      if (requisicao.url.path == '/api/fipe/veiculos/v1/carros/25') {
        return http.Response(
          jsonEncode([
            {'modelo': 'HR-V EXL 1.5', 'valor': '7200'},
            {'modelo': 'Civic Sedan EX 2.0 16V', 'valor': '5211'},
            {'modelo': 'Civic Sedan EX 2.0 16V', 'valor': '5211'},
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response('Not Found', 404);
    });

    final servico = BrasilApiFipeService(client: client);
    final marcas = await servico.listarMarcas(TipoVeiculoFipe.carros);
    expect(marcas.map((m) => m.nome), ['Honda', 'VW - VolksWagen']);

    // Segunda chamada usa cache em memória
    await servico.listarMarcas(TipoVeiculoFipe.carros);
    expect(urlsChamadas.length, 1);

    final modelos = await servico.listarModelos(
      TipoVeiculoFipe.carros,
      marcas.first.codigo,
    );
    expect(modelos.map((m) => m.nome), [
      'Civic Sedan EX 2.0 16V',
      'HR-V EXL 1.5',
    ]);
    expect(
      urlsChamadas.last.toString(),
      'https://brasilapi.com.br/api/fipe/veiculos/v1/carros/25',
    );
  });

  test('propaga erro amigável quando BrasilAPI retorna HTTP 500', () async {
    final client = MockClient((_) async => http.Response('Erro interno', 500));
    final servico = BrasilApiFipeService(client: client);

    await expectLater(
      servico.listarMarcas(TipoVeiculoFipe.carros),
      throwsA(
        predicate(
          (erro) => erro.toString().contains('BrasilAPI (HTTP 500)'),
        ),
      ),
    );
  });
}
