import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/marca_fipe.dart';
import '../models/modelo_fipe.dart';
import '../models/tipo_veiculo_fipe.dart';

class BrasilApiFipeService {
  BrasilApiFipeService({http.Client? client})
    : _client = client ?? http.Client(),
      _proprioClient = client == null;

  static const _host = 'brasilapi.com.br';
  static const _timeout = Duration(seconds: 15);

  final http.Client _client;
  final bool _proprioClient;

  final Map<TipoVeiculoFipe, List<MarcaFipe>> _cacheMarcas = {};
  final Map<String, List<ModeloFipe>> _cacheModelos = {};

  /// Consulta marcas na BrasilAPI: GET /api/fipe/marcas/v1/{tipoVeiculo}
  Future<List<MarcaFipe>> listarMarcas(
    TipoVeiculoFipe tipo, {
    bool ignorarCache = false,
  }) async {
    if (!ignorarCache && _cacheMarcas.containsKey(tipo)) {
      return _cacheMarcas[tipo]!;
    }

    final uri = Uri.https(_host, '/api/fipe/marcas/v1/${tipo.codigoApi}');
    final corpo = await _executarGet(uri, 'consultar as marcas');

    final marcas = corpo
        .whereType<Map<String, Object?>>()
        .map(MarcaFipe.fromJson)
        .toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

    _cacheMarcas[tipo] = List.unmodifiable(marcas);
    return _cacheMarcas[tipo]!;
  }

  /// Consulta modelos de uma marca na BrasilAPI:
  /// GET /api/fipe/veiculos/v1/{tipoVeiculo}/{codigoMarca}
  Future<List<ModeloFipe>> listarModelos(
    TipoVeiculoFipe tipo,
    String codigoMarca, {
    bool ignorarCache = false,
  }) async {
    final chave = '${tipo.codigoApi}:$codigoMarca';
    if (!ignorarCache && _cacheModelos.containsKey(chave)) {
      return _cacheModelos[chave]!;
    }

    final uri = Uri.https(
      _host,
      '/api/fipe/veiculos/v1/${tipo.codigoApi}/$codigoMarca',
    );
    final corpo = await _executarGet(uri, 'consultar os modelos');

    final vistos = <String>{};
    final modelos = <ModeloFipe>[];
    for (final item in corpo.whereType<Map<String, Object?>>()) {
      final modelo = ModeloFipe.fromJson(item);
      if (vistos.add(modelo.nome.toLowerCase())) {
        modelos.add(modelo);
      }
    }
    modelos.sort(
      (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
    );

    _cacheModelos[chave] = List.unmodifiable(modelos);
    return _cacheModelos[chave]!;
  }

  Future<List<Object?>> _executarGet(Uri uri, String operacao) async {
    try {
      final resposta = await _client.get(
        uri,
        headers: const {'Accept': 'application/json'},
      ).timeout(_timeout);

      if (resposta.statusCode != 200) {
        throw Exception(
          'Não foi possível $operacao na BrasilAPI (HTTP ${resposta.statusCode}).',
        );
      }

      final decodificado = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (decodificado is! List) {
        throw const FormatException(
          'Formato inesperado retornado pela BrasilAPI.',
        );
      }
      return decodificado.cast<Object?>();
    } on TimeoutException {
      throw Exception(
        'Tempo esgotado ao $operacao. Verifique sua conexão com a internet.',
      );
    } on SocketException {
      throw Exception(
        'Sem conexão com a internet para $operacao na BrasilAPI.',
      );
    } on http.ClientException {
      throw Exception(
        'Falha de rede ao $operacao na BrasilAPI. Tente novamente.',
      );
    }
  }

  void fechar() {
    if (_proprioClient) {
      _client.close();
    }
  }
}
