import 'package:flutter/material.dart';

import '../../../../core/utils/formatadores.dart';
import '../../data/repositories/repositorio_combustivel.dart';
import '../../models/abastecimento.dart';
import '../../models/indicador_abastecimento.dart';
import '../../models/veiculo.dart';
import '../../services/brasil_api_fipe_service.dart';
import '../../services/calculadora_indicadores.dart';
import 'aba_abastecimentos.dart';
import 'aba_dashboard.dart';
import 'aba_veiculo.dart';
import 'tela_cadastro_veiculo.dart';
import 'tela_registro_abastecimento.dart';

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({
    super.key,
    required this.repositorio,
    required this.fipeService,
    this.abaInicial = 0,
  });

  final RepositorioCombustivel repositorio;
  final BrasilApiFipeService fipeService;
  final int abaInicial;

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  late int _abaAtual;
  bool _carregando = true;
  String? _erro;
  Veiculo? _veiculo;
  List<Abastecimento> _abastecimentos = const [];
  ResumoDashboard _resumo = CalculadoraIndicadores.calcular(const []);

  @override
  void initState() {
    super.initState();
    _abaAtual = widget.abaInicial;
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final veiculo = await widget.repositorio.obterVeiculoAtual();
      final abastecimentos = veiculo?.id == null
          ? const <Abastecimento>[]
          : await widget.repositorio.listarAbastecimentos(veiculo!.id!);
      if (!mounted) return;
      setState(() {
        _veiculo = veiculo;
        _abastecimentos = abastecimentos;
        _resumo = CalculadoraIndicadores.calcular(abastecimentos);
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar os dados salvos: $erro';
        _carregando = false;
      });
    }
  }

  Future<void> _abrirCadastroVeiculo() async {
    final cadastrou = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => TelaCadastroVeiculo(
          repositorio: widget.repositorio,
          fipeService: widget.fipeService,
        ),
      ),
    );
    if (cadastrou == true && mounted) {
      await _carregarDados();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veículo cadastrado com sucesso.')),
      );
    }
  }

  Future<void> _abrirRegistroAbastecimento() async {
    final veiculo = _veiculo;
    if (veiculo == null) return;
    final salvou = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => TelaRegistroAbastecimento(
          veiculo: veiculo,
          repositorio: widget.repositorio,
          abastecimentosExistentes: _abastecimentos,
        ),
      ),
    );
    if (salvou == true && mounted) {
      await _carregarDados();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Abastecimento registrado com sucesso.')),
      );
    }
  }

  Future<void> _confirmarExclusaoVeiculo() async {
    final veiculo = _veiculo;
    if (veiculo == null) return;
    final qtd = _abastecimentos.length;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir veículo?'),
        content: Text(
          'Deseja excluir ${veiculo.tituloCompleto} (${veiculo.ano})?\n\n'
          'Esta operação é permanente e também removerá '
          '${qtd == 0 ? 'os dados associados a ele.' : qtd == 1 ? 'o abastecimento associado a ele.' : 'todos os $qtd abastecimentos associados a ele.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir veículo'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    try {
      await widget.repositorio.excluirVeiculoAtual();
      if (!mounted) return;
      await _carregarDados();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veículo e abastecimentos excluídos com sucesso.'),
        ),
      );
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível excluir o veículo: $erro')),
      );
    }
  }

  Future<void> _confirmarExclusaoAbastecimento(
    Abastecimento abastecimento,
  ) async {
    final id = abastecimento.id;
    if (id == null) return;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir abastecimento?'),
        content: Text(
          'Deseja remover o abastecimento de '
          '${Formatadores.formatarMoeda(abastecimento.valorTotal)} em '
          '${Formatadores.formatarDataHora(abastecimento.dataHora)}? '
          'Os indicadores serão recalculados automaticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    try {
      await widget.repositorio.excluirAbastecimento(id);
      if (!mounted) return;
      await _carregarDados();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Abastecimento excluído.')),
      );
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível excluir o abastecimento: $erro'),
        ),
      );
    }
  }

  String get _tituloAba => switch (_abaAtual) {
    0 => 'Dashboard',
    1 => 'Abastecimentos',
    _ => 'Meu veículo',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tituloAba),
        actions: [
          IconButton(
            onPressed: _carregando ? null : _carregarDados,
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(child: _construirCorpo()),
      floatingActionButton: _veiculo != null && _abaAtual != 2
          ? FloatingActionButton.extended(
              onPressed: _abrirRegistroAbastecimento,
              icon: const Icon(Icons.local_gas_station_outlined),
              label: const Text('Abastecer'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _abaAtual,
        onDestinationSelected: (indice) => setState(() => _abaAtual = indice),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_gas_station_outlined),
            selectedIcon: Icon(Icons.local_gas_station),
            label: 'Abastecimentos',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Veículo',
          ),
        ],
      ),
    );
  }

  Widget _construirCorpo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 44,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(_erro!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _carregarDados,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return switch (_abaAtual) {
      0 => AbaDashboard(
        veiculo: _veiculo,
        resumo: _resumo,
        aoCadastrarVeiculo: _abrirCadastroVeiculo,
        aoRegistrarAbastecimento: _abrirRegistroAbastecimento,
        aoVerTodosAbastecimentos: () => setState(() => _abaAtual = 1),
        aoAbrirVeiculo: () => setState(() => _abaAtual = 2),
      ),
      1 => AbaAbastecimentos(
        veiculo: _veiculo,
        resumo: _resumo,
        aoCadastrarVeiculo: _abrirCadastroVeiculo,
        aoRegistrarAbastecimento: _abrirRegistroAbastecimento,
        aoExcluirAbastecimento: _confirmarExclusaoAbastecimento,
      ),
      _ => AbaVeiculo(
        veiculo: _veiculo,
        totalAbastecimentos: _abastecimentos.length,
        aoCadastrarVeiculo: _abrirCadastroVeiculo,
        aoExcluirVeiculo: _confirmarExclusaoVeiculo,
      ),
    };
  }
}
