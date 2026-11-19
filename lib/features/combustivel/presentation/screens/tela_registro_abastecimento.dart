import 'package:flutter/material.dart';

import '../../../../core/utils/formatadores.dart';
import '../../data/repositories/repositorio_combustivel.dart';
import '../../models/abastecimento.dart';
import '../../models/tipo_combustivel.dart';
import '../../models/veiculo.dart';

class TelaRegistroAbastecimento extends StatefulWidget {
  const TelaRegistroAbastecimento({
    super.key,
    required this.veiculo,
    required this.repositorio,
    required this.abastecimentosExistentes,
  });

  final Veiculo veiculo;
  final RepositorioCombustivel repositorio;
  final List<Abastecimento> abastecimentosExistentes;

  @override
  State<TelaRegistroAbastecimento> createState() =>
      _TelaRegistroAbastecimentoState();
}

class _TelaRegistroAbastecimentoState extends State<TelaRegistroAbastecimento> {
  final _formKey = GlobalKey<FormState>();
  final _precoController = TextEditingController();
  final _quilometragemController = TextEditingController();
  final _litrosController = TextEditingController();

  TipoCombustivel _tipoCombustivel = TipoCombustivel.gasolina;
  DateTime _dataHora = DateTime.now();
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _precoController.addListener(_atualizarPrevia);
    _litrosController.addListener(_atualizarPrevia);
  }

  void _atualizarPrevia() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _precoController.removeListener(_atualizarPrevia);
    _litrosController.removeListener(_atualizarPrevia);
    _precoController.dispose();
    _quilometragemController.dispose();
    _litrosController.dispose();
    super.dispose();
  }

  double? get _valorTotalPrevisto {
    final preco = Formatadores.converterNumero(_precoController.text);
    final litros = Formatadores.converterNumero(_litrosController.text);
    if (preco == null || litros == null || preco <= 0 || litros <= 0) {
      return null;
    }
    return preco * litros;
  }

  Abastecimento? get _ultimoRegistro =>
      widget.abastecimentosExistentes.isEmpty
      ? null
      : widget.abastecimentosExistentes.last;

  Future<void> _selecionarData() async {
    final agora = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _dataHora,
      firstDate: DateTime(2000),
      lastDate: agora.add(const Duration(days: 1)),
      locale: const Locale('pt', 'BR'),
    );
    if (escolhida == null || !mounted) return;
    setState(() {
      _dataHora = DateTime(
        escolhida.year,
        escolhida.month,
        escolhida.day,
        _dataHora.hour,
        _dataHora.minute,
      );
    });
  }

  Future<void> _selecionarHora() async {
    final escolhida = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataHora),
    );
    if (escolhida == null || !mounted) return;
    setState(() {
      _dataHora = DateTime(
        _dataHora.year,
        _dataHora.month,
        _dataHora.day,
        escolhida.hour,
        escolhida.minute,
      );
    });
  }

  String? _validarPreco(String? valor) {
    final preco = Formatadores.converterNumero(valor ?? '');
    if (preco == null) return 'Informe o preço por litro.';
    if (preco <= 0) return 'O preço deve ser maior que zero.';
    return null;
  }

  String? _validarLitros(String? valor) {
    final litros = Formatadores.converterNumero(valor ?? '');
    if (litros == null) return 'Informe a quantidade de litros.';
    if (litros <= 0) return 'A quantidade deve ser maior que zero.';
    return null;
  }

  String? _validarQuilometragem(String? valor) {
    final km = Formatadores.converterNumero(valor ?? '');
    if (km == null) return 'Informe a quilometragem do veículo.';
    if (km < 0) return 'A quilometragem não pode ser negativa.';

    // Garante consistência cronológica para cálculo de distância percorrida.
    final dataUtc = _dataHora.toUtc();
    Abastecimento? anterior;
    Abastecimento? posterior;
    for (final reg in widget.abastecimentosExistentes) {
      if (!reg.dataHora.isAfter(dataUtc)) {
        anterior = reg;
      } else {
        posterior ??= reg;
      }
    }

    if (anterior != null && km <= anterior.quilometragem) {
      return 'Deve ser maior que ${Formatadores.formatarQuilometragem(anterior.quilometragem)} (registro anterior).';
    }
    if (posterior != null && km >= posterior.quilometragem) {
      return 'Deve ser menor que ${Formatadores.formatarQuilometragem(posterior.quilometragem)} (registro posterior).';
    }
    return null;
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    final valido = _formKey.currentState?.validate() ?? false;
    if (!valido) return;

    final veiculoId = widget.veiculo.id;
    if (veiculoId == null) return;

    setState(() => _salvando = true);
    try {
      final abastecimento = Abastecimento(
        veiculoId: veiculoId,
        tipoCombustivel: _tipoCombustivel,
        precoPorLitro: Formatadores.converterNumero(_precoController.text)!,
        quilometragem: Formatadores.converterNumero(
          _quilometragemController.text,
        )!,
        litros: Formatadores.converterNumero(_litrosController.text)!,
        dataHora: _dataHora,
      );
      await widget.repositorio.inserirAbastecimento(abastecimento);
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      Navigator.pop(context, true);
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível salvar o abastecimento: $erro'),
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final totalPrevisto = _valorTotalPrevisto;
    final ultimo = _ultimoRegistro;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar abastecimento')),
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
                    alpha: 0.4,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.veiculo.tipoVeiculo.icone,
                          color: tema.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.veiculo.tituloCompleto,
                                style: tema.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                ultimo == null
                                    ? '1º abastecimento (servirá como referência inicial)'
                                    : 'Última quilometragem: ${Formatadores.formatarQuilometragem(ultimo.quilometragem)}',
                                style: tema.textTheme.bodySmall?.copyWith(
                                  color: tema.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tipo de combustível',
                  style: tema.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<TipoCombustivel>(
                  segments: TipoCombustivel.values
                      .map(
                        (tipo) => ButtonSegment<TipoCombustivel>(
                          value: tipo,
                          label: Text(tipo.rotulo),
                          icon: Icon(tipo.icone, size: 18),
                        ),
                      )
                      .toList(),
                  selected: {_tipoCombustivel},
                  onSelectionChanged: (selecao) =>
                      setState(() => _tipoCombustivel = selecao.first),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _precoController,
                        decoration: const InputDecoration(
                          labelText: 'Preço por litro',
                          hintText: 'Ex.: 5,89',
                          prefixText: 'R\$ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: _validarPreco,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _litrosController,
                        decoration: const InputDecoration(
                          labelText: 'Litros abastecidos',
                          hintText: 'Ex.: 40,5',
                          suffixText: 'L',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: _validarLitros,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quilometragemController,
                  decoration: InputDecoration(
                    labelText: 'Quilometragem atual',
                    hintText: ultimo == null
                        ? 'Ex.: 45200'
                        : 'Acima de ${Formatadores.formatarQuilometragem(ultimo.quilometragem)}',
                    prefixIcon: const Icon(Icons.speed_outlined),
                    suffixText: 'km',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  validator: _validarQuilometragem,
                ),
                const SizedBox(height: 16),
                Text(
                  'Data e horário do abastecimento',
                  style: tema.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selecionarData,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(Formatadores.formatarData(_dataHora)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selecionarHora,
                        icon: const Icon(Icons.access_time_outlined),
                        label: Text(Formatadores.formatarHora(_dataHora)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  color: tema.colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Valor total do abastecimento',
                              style: tema.textTheme.labelMedium?.copyWith(
                                color: tema.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Preço por litro × quantidade de litros',
                              style: tema.textTheme.bodySmall?.copyWith(
                                color: tema.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Text(
                          totalPrevisto == null
                              ? 'R\$ 0,00'
                              : Formatadores.formatarMoeda(totalPrevisto),
                          style: tema.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: tema.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _salvando ? 'Salvando...' : 'Salvar abastecimento',
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
