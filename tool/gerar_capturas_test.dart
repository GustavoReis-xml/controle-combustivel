import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:controle_combustivel/core/theme/app_theme.dart';
import 'package:controle_combustivel/features/combustivel/data/database/banco_combustivel.dart';
import 'package:controle_combustivel/features/combustivel/data/repositories/repositorio_combustivel.dart';
import 'package:controle_combustivel/features/combustivel/models/abastecimento.dart';
import 'package:controle_combustivel/features/combustivel/models/tipo_combustivel.dart';
import 'package:controle_combustivel/features/combustivel/models/tipo_veiculo_fipe.dart';
import 'package:controle_combustivel/features/combustivel/models/veiculo.dart';
import 'package:controle_combustivel/features/combustivel/presentation/screens/tela_cadastro_veiculo.dart';
import 'package:controle_combustivel/features/combustivel/presentation/screens/tela_principal.dart';
import 'package:controle_combustivel/features/combustivel/presentation/screens/tela_registro_abastecimento.dart';
import 'package:controle_combustivel/features/combustivel/services/brasil_api_fipe_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;

class _RepositorioCaptura extends RepositorioCombustivel {
  _RepositorioCaptura() : super(BancoCombustivel());

  Veiculo? _veiculo;
  final List<Abastecimento> _abastecimentos = [];
  int _proximoVeiculoId = 1;
  int _proximoAbastecimentoId = 1;

  @override
  Future<Veiculo?> obterVeiculoAtual() async => _veiculo;

  @override
  Future<Veiculo> cadastrarVeiculo(Veiculo veiculo) async {
    _veiculo = veiculo.copyWith(id: _proximoVeiculoId++);
    return _veiculo!;
  }

  @override
  Future<void> excluirVeiculoAtual() async {
    _veiculo = null;
    _abastecimentos.clear();
  }

  @override
  Future<Abastecimento> inserirAbastecimento(
    Abastecimento abastecimento,
  ) async {
    final salvo = abastecimento.copyWith(id: _proximoAbastecimentoId++);
    _abastecimentos.add(salvo);
    return salvo;
  }

  @override
  Future<List<Abastecimento>> listarAbastecimentos(int veiculoId) async =>
      List<Abastecimento>.from(_abastecimentos);

  @override
  Future<void> excluirAbastecimento(int id) async {
    _abastecimentos.removeWhere((a) => a.id == id);
  }
}

Future<void> _carregarFontesReais() async {
  final fontDirEnv = Platform.environment['FLUTTER_MATERIAL_FONTS'];
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final robotoDirEnv = Platform.environment['ROBOTO_FONTS_DIR'];

  final diretorios = <String>[
    if (fontDirEnv != null && fontDirEnv.isNotEmpty) fontDirEnv,
    if (flutterRoot != null && flutterRoot.isNotEmpty)
      p.join(flutterRoot, 'bin', 'cache', 'artifacts', 'material_fonts'),
    if (robotoDirEnv != null && robotoDirEnv.isNotEmpty) robotoDirEnv,
    '/usr/share/fonts/truetype/roboto/unhinted/RobotoTTF',
    '/usr/share/fonts/truetype/roboto',
  ];

  Future<void> carregarFamilia(String familia, List<String> arquivos) async {
    final loader = FontLoader(familia);
    var adicionou = false;
    for (final arquivo in arquivos) {
      for (final dir in diretorios) {
        final f = File(p.join(dir, arquivo));
        if (f.existsSync()) {
          final bytes = await f.readAsBytes();
          loader.addFont(Future.value(ByteData.sublistView(bytes)));
          adicionou = true;
          break;
        }
      }
    }
    if (adicionou) await loader.load();
  }

  await carregarFamilia('Roboto', [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Light.ttf',
  ]);
  await carregarFamilia('FlutterTest', [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]);
  await carregarFamilia('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

Widget _molduraApp(Widget tela, GlobalKey chaveCaptura) => RepaintBoundary(
  key: chaveCaptura,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: AppTheme.construir(),
    home: tela,
  ),
);

Future<void> _salvarCaptura(
  WidgetTester tester,
  GlobalKey chaveCaptura,
  String nomeArquivo,
) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final boundary =
      chaveCaptura.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final imagem = await boundary.toImage(pixelRatio: 2.0);
    final bytes = await imagem.toByteData(format: ui.ImageByteFormat.png);
    imagem.dispose();
    final saida = File(p.join('docs', 'screenshots', nomeArquivo));
    await saida.parent.create(recursive: true);
    await saida.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('gera capturas reais das telas principais do aplicativo', (
    tester,
  ) async {
    await tester.runAsync(_carregarFontesReais);

    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repositorio = _RepositorioCaptura();
    final fipeService = BrasilApiFipeService(
      client: MockClient((req) async {
        if (req.url.path == '/api/fipe/marcas/v1/carros') {
          return http.Response(
            jsonEncode([
              {'nome': 'Fiat', 'valor': '21'},
              {'nome': 'Honda', 'valor': '25'},
              {'nome': 'Toyota', 'valor': '56'},
              {'nome': 'VW - VolksWagen', 'valor': '59'},
            ]),
            200,
          );
        }
        if (req.url.path == '/api/fipe/veiculos/v1/carros/25') {
          return http.Response(
            jsonEncode([
              {'modelo': 'City Sedan EX 1.5 Flex 16V Aut.', 'valor': '6100'},
              {'modelo': 'Civic Sedan EX 2.0 Flex 16V Aut.', 'valor': '5211'},
              {'modelo': 'HR-V EXL 1.5 Flex 16V Aut.', 'valor': '7200'},
            ]),
            200,
          );
        }
        return http.Response('[]', 200);
      }),
    );

    // 1. Captura: Cadastro de veículo com BrasilAPI FIPE preenchido
    final chaveCadastro = GlobalKey();
    await tester.pumpWidget(
      _molduraApp(
        TelaCadastroVeiculo(repositorio: repositorio, fipeService: fipeService),
        chaveCadastro,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selecione a marca'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Honda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selecione o modelo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Civic Sedan EX 2.0 Flex 16V Aut.'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Ano'), '2022');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cilindrada'),
      '2.0',
    );
    await _salvarCaptura(tester, chaveCadastro, '01_cadastro_veiculo.png');

    // Popula dados realistas em memória para as telas seguintes
    final veiculo = await repositorio.cadastrarVeiculo(
      Veiculo(
        tipoVeiculo: TipoVeiculoFipe.carros,
        marca: 'Honda',
        modelo: 'Civic Sedan EX 2.0 Flex 16V Aut.',
        ano: 2022,
        cilindrada: '2.0',
      ),
    );
    final registros = [
      Abastecimento(
        veiculoId: veiculo.id!,
        tipoCombustivel: TipoCombustivel.gasolina,
        precoPorLitro: 5.89,
        quilometragem: 42100,
        litros: 42.0,
        dataHora: DateTime(2026, 10, 15, 8, 30),
      ),
      Abastecimento(
        veiculoId: veiculo.id!,
        tipoCombustivel: TipoCombustivel.gasolina,
        precoPorLitro: 5.95,
        quilometragem: 42590,
        litros: 40.5,
        dataHora: DateTime(2026, 10, 23, 18, 15),
      ),
      Abastecimento(
        veiculoId: veiculo.id!,
        tipoCombustivel: TipoCombustivel.etanol,
        precoPorLitro: 3.99,
        quilometragem: 42950,
        litros: 41.0,
        dataHora: DateTime(2026, 11, 1, 9, 45),
      ),
      Abastecimento(
        veiculoId: veiculo.id!,
        tipoCombustivel: TipoCombustivel.etanol,
        precoPorLitro: 4.09,
        quilometragem: 43325,
        litros: 40.2,
        dataHora: DateTime(2026, 11, 9, 17, 20),
      ),
      Abastecimento(
        veiculoId: veiculo.id!,
        tipoCombustivel: TipoCombustivel.gasolina,
        precoPorLitro: 5.79,
        quilometragem: 43835,
        litros: 39.8,
        dataHora: DateTime(2026, 11, 17, 19, 10),
      ),
    ];
    for (final reg in registros) {
      await repositorio.inserirAbastecimento(reg);
    }
    final abastecimentos = await repositorio.listarAbastecimentos(veiculo.id!);

    // 2. Captura: Dashboard (KPIs + Gráfico de Consumo km/L)
    final chaveDashboard = GlobalKey();
    await tester.pumpWidget(
      _molduraApp(
        TelaPrincipal(
          repositorio: repositorio,
          fipeService: fipeService,
          abaInicial: 0,
        ),
        chaveDashboard,
      ),
    );
    await _salvarCaptura(tester, chaveDashboard, '02_dashboard_consumo.png');

    // 3. Captura: Dashboard rolado (Gráfico de Custo R$/km + Valor por Abastecimento)
    await tester.drag(find.byType(ListView).first, const Offset(0, -680));
    await _salvarCaptura(tester, chaveDashboard, '03_dashboard_graficos.png');

    // 4. Captura: Histórico de abastecimentos (rolado suavemente para exibir também o #1 Referência inicial)
    final chaveHistorico = GlobalKey();
    await tester.pumpWidget(
      _molduraApp(
        TelaPrincipal(
          repositorio: repositorio,
          fipeService: fipeService,
          abaInicial: 1,
        ),
        chaveHistorico,
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -240));
    await _salvarCaptura(
      tester,
      chaveHistorico,
      '04_historico_abastecimentos.png',
    );

    // 5. Captura: Registro de novo abastecimento (com prévia ao vivo)
    final chaveRegistro = GlobalKey();
    await tester.pumpWidget(
      _molduraApp(
        TelaRegistroAbastecimento(
          veiculo: veiculo,
          repositorio: repositorio,
          abastecimentosExistentes: abastecimentos,
        ),
        chaveRegistro,
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Preço por litro'),
      '5,89',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Litros abastecidos'),
      '41,5',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quilometragem atual'),
      '44350',
    );
    await _salvarCaptura(tester, chaveRegistro, '05_registro_abastecimento.png');

    // 6. Captura: Meu Veículo (detalhes e opção de exclusão)
    final chaveVeiculo = GlobalKey();
    await tester.pumpWidget(
      _molduraApp(
        TelaPrincipal(
          repositorio: repositorio,
          fipeService: fipeService,
          abaInicial: 2,
        ),
        chaveVeiculo,
      ),
    );
    await _salvarCaptura(tester, chaveVeiculo, '06_meu_veiculo.png');
  });
}
