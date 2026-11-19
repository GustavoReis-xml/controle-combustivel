import 'dart:convert';
import 'dart:io';

import 'package:controle_combustivel/app.dart';
import 'package:controle_combustivel/features/combustivel/data/database/banco_combustivel.dart';
import 'package:controle_combustivel/features/combustivel/data/repositories/repositorio_combustivel.dart';
import 'package:controle_combustivel/features/combustivel/services/brasil_api_fipe_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Directory pasta;
  late BancoCombustivel banco;
  late RepositorioCombustivel repositorio;
  late BrasilApiFipeService fipeService;

  setUp(() async {
    pasta = await Directory.systemTemp.createTemp('combustivel_widget_');
    banco = BancoCombustivel(
      caminho: p.join(pasta.path, 'controle_combustivel.db'),
      abrir: (caminho, opcoes) =>
          databaseFactoryFfi.openDatabase(caminho, options: opcoes),
    );
    repositorio = RepositorioCombustivel(banco);
    fipeService = BrasilApiFipeService(
      client: MockClient((req) async {
        if (req.url.path == '/api/fipe/marcas/v1/carros') {
          return http.Response(
            jsonEncode([
              {'nome': 'Honda', 'valor': '25'},
              {'nome': 'Toyota', 'valor': '56'},
            ]),
            200,
          );
        }
        if (req.url.path == '/api/fipe/veiculos/v1/carros/25') {
          return http.Response(
            jsonEncode([
              {'modelo': 'Civic Sedan EX 2.0 16V', 'valor': '5211'},
            ]),
            200,
          );
        }
        return http.Response('[]', 200);
      }),
    );
  });

  tearDown(() async {
    await banco.fechar();
    await pasta.delete(recursive: true);
  });

  testWidgets(
    'fluxo completo: cadastrar veículo via BrasilAPI, abastecer, ver gráficos e excluir',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        AppCombustivel(repositorio: repositorio, fipeService: fipeService),
      );
      await tester.pumpAndSettle();

      // Estado inicial sem veículo
      expect(find.text('Nenhum veículo cadastrado'), findsOneWidget);
      await tester.tap(find.text('Cadastrar veículo'));
      await tester.pumpAndSettle();

      // Seleciona Marca da BrasilAPI
      await tester.tap(find.text('Selecione a marca'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Honda'));
      await tester.pumpAndSettle();

      // Seleciona Modelo filtrado pela Marca
      await tester.tap(find.text('Selecione o modelo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Civic Sedan EX 2.0 16V'));
      await tester.pumpAndSettle();

      // Preenche Ano e Cilindrada
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ano'),
        '2022',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Cilindrada'),
        '2.0',
      );
      await tester.tap(find.text('Salvar veículo'));
      await tester.pumpAndSettle();

      expect(find.text('Civic Sedan EX 2.0 16V'), findsOneWidget);

      // 1º abastecimento (referência inicial)
      await tester.tap(find.text('Abastecer'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Preço por litro'),
        '6,00',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Litros abastecidos'),
        '40',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quilometragem atual'),
        '10000',
      );
      await tester.pump();
      expect(find.text('R\$ 240,00'), findsOneWidget);

      await tester.ensureVisible(find.text('Salvar abastecimento'));
      await tester.tap(find.text('Salvar abastecimento'));
      await tester.pumpAndSettle();

      // No 1º abastecimento: mostra valor total, mas ainda sem gráficos de linha
      expect(find.text('R\$ 240,00'), findsWidgets);
      expect(find.byType(LineChart), findsNothing);

      // 2º abastecimento (gera km/L e R$/km e exibe os 2 LineCharts + BarChart)
      await tester.tap(find.text('Abastecer'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Preço por litro'),
        '6,00',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Litros abastecidos'),
        '40',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quilometragem atual'),
        '10400',
      );
      await tester.ensureVisible(find.text('Salvar abastecimento'));
      await tester.tap(find.text('Salvar abastecimento'));
      await tester.pumpAndSettle();

      // Verifica KPIs e gráficos (2 LineCharts: consumo e custo/km + 1 BarChart: valores)
      expect(find.text('10,00 km/L'), findsWidgets);
      expect(find.text('R\$ 0,60/km'), findsWidgets);
      expect(find.byType(LineChart), findsNWidgets(2));
      expect(find.byType(BarChart), findsOneWidget);

      // Navega para aba Veículo e exclui com confirmação
      await tester.tap(find.text('Veículo'));
      await tester.pumpAndSettle();
      expect(find.text('Honda'), findsOneWidget);

      await tester.ensureVisible(find.text('Excluir veículo'));
      await tester.tap(find.text('Excluir veículo'));
      await tester.pumpAndSettle();

      expect(find.text('Excluir veículo?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir veículo'));
      await tester.pumpAndSettle();

      // Voltou ao estado sem veículo e abastecimentos foram removidos
      expect(find.text('Cadastre seu veículo'), findsOneWidget);
      expect(await repositorio.obterVeiculoAtual(), isNull);
    },
  );
}
