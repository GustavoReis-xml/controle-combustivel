import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/combustivel/data/database/banco_combustivel.dart';
import 'features/combustivel/data/repositories/repositorio_combustivel.dart';
import 'features/combustivel/presentation/screens/tela_principal.dart';
import 'features/combustivel/services/brasil_api_fipe_service.dart';

class AppCombustivel extends StatefulWidget {
  const AppCombustivel({
    super.key,
    this.repositorio,
    this.fipeService,
  });

  final RepositorioCombustivel? repositorio;
  final BrasilApiFipeService? fipeService;

  @override
  State<AppCombustivel> createState() => _AppCombustivelState();
}

class _AppCombustivelState extends State<AppCombustivel> {
  late final RepositorioCombustivel _repositorio;
  late final BrasilApiFipeService _fipeService;
  late final bool _criouFipeService;

  @override
  void initState() {
    super.initState();
    _repositorio =
        widget.repositorio ?? RepositorioCombustivel(BancoCombustivel());
    _criouFipeService = widget.fipeService == null;
    _fipeService = widget.fipeService ?? BrasilApiFipeService();
  }

  @override
  void dispose() {
    if (_criouFipeService) {
      _fipeService.fechar();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Controle de Combustível',
    debugShowCheckedModeBanner: false,
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: AppTheme.construir(),
    home: TelaPrincipal(
      repositorio: _repositorio,
      fipeService: _fipeService,
    ),
  );
}
