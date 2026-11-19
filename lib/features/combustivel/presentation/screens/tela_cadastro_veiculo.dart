import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/repositories/repositorio_combustivel.dart';
import '../../models/marca_fipe.dart';
import '../../models/modelo_fipe.dart';
import '../../models/tipo_veiculo_fipe.dart';
import '../../models/veiculo.dart';
import '../../services/brasil_api_fipe_service.dart';
import '../widgets/seletor_pesquisavel.dart';

class TelaCadastroVeiculo extends StatefulWidget {
  const TelaCadastroVeiculo({
    super.key,
    required this.repositorio,
    required this.fipeService,
  });

  final RepositorioCombustivel repositorio;
  final BrasilApiFipeService fipeService;

  @override
  State<TelaCadastroVeiculo> createState() => _TelaCadastroVeiculoState();
}

class _TelaCadastroVeiculoState extends State<TelaCadastroVeiculo> {
  final _formKey = GlobalKey<FormState>();
  final _anoController = TextEditingController();
  final _cilindradaController = TextEditingController();

  TipoVeiculoFipe _tipoVeiculo = TipoVeiculoFipe.carros;

  List<MarcaFipe> _marcas = const [];
  List<ModeloFipe> _modelos = const [];

  MarcaFipe? _marcaSelecionada;
  ModeloFipe? _modeloSelecionado;

  bool _carregandoMarcas = false;
  bool _carregandoModelos = false;
  bool _salvando = false;

  String? _erroMarcas;
  String? _erroModelos;
  int _requisicaoMarcasId = 0;
  int _requisicaoModelosId = 0;

  @override
  void initState() {
    super.initState();
    _carregarMarcas();
  }

  @override
  void dispose() {
    _anoController.dispose();
    _cilindradaController.dispose();
    super.dispose();
  }

  Future<void> _carregarMarcas({bool ignorarCache = false}) async {
    final reqId = ++_requisicaoMarcasId;
    setState(() {
      _carregandoMarcas = true;
      _erroMarcas = null;
      _marcas = const [];
      _marcaSelecionada = null;
      _modelos = const [];
      _modeloSelecionado = null;
      _erroModelos = null;
      _carregandoModelos = false;
    });

    try {
      final marcas = await widget.fipeService.listarMarcas(
        _tipoVeiculo,
        ignorarCache: ignorarCache,
      );
      if (!mounted || reqId != _requisicaoMarcasId) return;
      setState(() {
        _marcas = marcas;
        _carregandoMarcas = false;
      });
    } catch (erro) {
      if (!mounted || reqId != _requisicaoMarcasId) return;
      setState(() {
        _erroMarcas = erro.toString().replaceFirst('Exception: ', '');
        _carregandoMarcas = false;
      });
    }
  }

  Future<void> _carregarModelos(
    MarcaFipe marca, {
    bool ignorarCache = false,
  }) async {
    final reqId = ++_requisicaoModelosId;
    setState(() {
      _carregandoModelos = true;
      _erroModelos = null;
      _modelos = const [];
      _modeloSelecionado = null;
    });

    try {
      final modelos = await widget.fipeService.listarModelos(
        _tipoVeiculo,
        marca.codigo,
        ignorarCache: ignorarCache,
      );
      if (!mounted || reqId != _requisicaoModelosId) return;
      setState(() {
        _modelos = modelos;
        _carregandoModelos = false;
      });
    } catch (erro) {
      if (!mounted || reqId != _requisicaoModelosId) return;
      setState(() {
        _erroModelos = erro.toString().replaceFirst('Exception: ', '');
        _carregandoModelos = false;
      });
    }
  }

  Future<void> _selecionarMarca() async {
    if (_carregandoMarcas || _marcas.isEmpty) return;
    final escolhida = await mostrarSeletorPesquisavel<MarcaFipe>(
      context: context,
      titulo: 'Selecionar marca (${_tipoVeiculo.rotulo})',
      dicaBusca: 'Pesquisar marca (ex.: Honda, Fiat, VW)...',
      itens: _marcas,
      obterTexto: (marca) => marca.nome,
      selecionado: _marcaSelecionada,
    );
    if (escolhida == null || !mounted) return;
    if (escolhida == _marcaSelecionada) return;
    setState(() => _marcaSelecionada = escolhida);
    await _carregarModelos(escolhida);
  }

  Future<void> _selecionarModelo() async {
    if (_marcaSelecionada == null || _carregandoModelos || _modelos.isEmpty) {
      return;
    }
    final escolhido = await mostrarSeletorPesquisavel<ModeloFipe>(
      context: context,
      titulo: 'Selecionar modelo — ${_marcaSelecionada!.nome}',
      dicaBusca: 'Pesquisar modelo...',
      itens: _modelos,
      obterTexto: (modelo) => modelo.nome,
      selecionado: _modeloSelecionado,
    );
    if (escolhido == null || !mounted) return;
    setState(() => _modeloSelecionado = escolhido);
  }

  String? _validarAno(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Informe o ano do veículo.';
    final ano = int.tryParse(texto);
    final anoMaximo = DateTime.now().year + 1;
    if (ano == null || ano < 1900 || ano > anoMaximo) {
      return 'Informe um ano válido entre 1900 e $anoMaximo.';
    }
    return null;
  }

  String? _validarCilindrada(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Informe a cilindrada do motor.';
    final contemDigitoPositivo = RegExp(r'[1-9]').hasMatch(texto);
    if (!contemDigitoPositivo) {
      return 'Informe uma cilindrada válida (ex.: 1.6 ou 160 cc).';
    }
    return null;
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    final valido = _formKey.currentState?.validate() ?? false;
    if (!valido) return;
    if (_marcaSelecionada == null || _modeloSelecionado == null) return;

    setState(() => _salvando = true);
    try {
      final veiculo = Veiculo(
        tipoVeiculo: _tipoVeiculo,
        marca: _marcaSelecionada!.nome,
        modelo: _modeloSelecionado!.nome,
        ano: int.parse(_anoController.text.trim()),
        cilindrada: _cilindradaController.text.trim(),
      );
      await widget.repositorio.cadastrarVeiculo(veiculo);
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      Navigator.pop(context, true);
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível salvar o veículo: ${erro.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar veículo')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: tema.colorScheme.primaryContainer.withValues(
                    alpha: 0.45,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_done_outlined,
                          color: tema.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'As marcas e modelos são consultados em tempo real na BrasilAPI (Tabela FIPE).',
                            style: tema.textTheme.bodySmall?.copyWith(
                              color: tema.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Categoria do veículo',
                  style: tema.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<TipoVeiculoFipe>(
                  segments: TipoVeiculoFipe.values
                      .map(
                        (tipo) => ButtonSegment<TipoVeiculoFipe>(
                          value: tipo,
                          label: Text(tipo.rotulo),
                          icon: Icon(tipo.icone, size: 18),
                        ),
                      )
                      .toList(),
                  selected: {_tipoVeiculo},
                  onSelectionChanged: _salvando
                      ? null
                      : (selecao) {
                          final novoTipo = selecao.first;
                          if (novoTipo == _tipoVeiculo) return;
                          setState(() => _tipoVeiculo = novoTipo);
                          _carregarMarcas();
                        },
                ),
                const SizedBox(height: 20),
                _CampoSeletorFipe<MarcaFipe>(
                  rotulo: 'Marca',
                  placeholder: _carregandoMarcas
                      ? 'Carregando marcas da BrasilAPI...'
                      : 'Selecione a marca',
                  valorSelecionado: _marcaSelecionada,
                  textoValor: _marcaSelecionada?.nome,
                  carregando: _carregandoMarcas,
                  habilitado: !_carregandoMarcas && _marcas.isNotEmpty,
                  erroApi: _erroMarcas,
                  aoTocar: _selecionarMarca,
                  aoTentarNovamente: () => _carregarMarcas(ignorarCache: true),
                  validator: (valor) => valor == null
                      ? 'Selecione a marca do veículo.'
                      : null,
                ),
                const SizedBox(height: 16),
                _CampoSeletorFipe<ModeloFipe>(
                  rotulo: 'Modelo',
                  placeholder: _marcaSelecionada == null
                      ? 'Escolha uma marca primeiro'
                      : _carregandoModelos
                      ? 'Carregando modelos de ${_marcaSelecionada!.nome}...'
                      : 'Selecione o modelo',
                  valorSelecionado: _modeloSelecionado,
                  textoValor: _modeloSelecionado?.nome,
                  carregando: _carregandoModelos,
                  habilitado:
                      _marcaSelecionada != null &&
                      !_carregandoModelos &&
                      _modelos.isNotEmpty,
                  erroApi: _erroModelos,
                  aoTocar: _selecionarModelo,
                  aoTentarNovamente: _marcaSelecionada == null
                      ? null
                      : () => _carregarModelos(
                          _marcaSelecionada!,
                          ignorarCache: true,
                        ),
                  validator: (valor) => valor == null
                      ? 'Selecione o modelo do veículo.'
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _anoController,
                        decoration: const InputDecoration(
                          labelText: 'Ano',
                          hintText: 'Ex.: 2022',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: _validarAno,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cilindradaController,
                        decoration: const InputDecoration(
                          labelText: 'Cilindrada',
                          hintText: 'Ex.: 1.6 ou 160 cc',
                          prefixIcon: Icon(Icons.speed_outlined),
                        ),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        validator: _validarCilindrada,
                        onFieldSubmitted: (_) => _salvar(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _salvando ? null : _salvar,
                  icon: _salvando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _salvando ? 'Salvando...' : 'Salvar veículo',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CampoSeletorFipe<T> extends StatelessWidget {
  const _CampoSeletorFipe({
    required this.rotulo,
    required this.placeholder,
    required this.valorSelecionado,
    required this.textoValor,
    required this.carregando,
    required this.habilitado,
    required this.aoTocar,
    required this.validator,
    this.erroApi,
    this.aoTentarNovamente,
  });

  final String rotulo;
  final String placeholder;
  final T? valorSelecionado;
  final String? textoValor;
  final bool carregando;
  final bool habilitado;
  final String? erroApi;
  final VoidCallback aoTocar;
  final VoidCallback? aoTentarNovamente;
  final FormFieldValidator<T> validator;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return FormField<T>(
      key: ValueKey('$rotulo-${textoValor ?? ''}'),
      initialValue: valorSelecionado,
      validator: validator,
      builder: (estado) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: habilitado ? aoTocar : null,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: rotulo,
                  errorText: estado.errorText,
                  enabled: habilitado,
                  suffixIcon: carregando
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.keyboard_arrow_down_rounded),
                ),
                isEmpty: textoValor == null,
                child: Text(
                  textoValor ?? placeholder,
                  style: tema.textTheme.bodyLarge?.copyWith(
                    color: textoValor == null
                        ? tema.colorScheme.onSurfaceVariant
                        : tema.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (erroApi != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 16,
                    color: tema.colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      erroApi!,
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.error,
                      ),
                    ),
                  ),
                  if (aoTentarNovamente != null)
                    TextButton(
                      onPressed: aoTentarNovamente,
                      child: const Text('Tentar novamente'),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
