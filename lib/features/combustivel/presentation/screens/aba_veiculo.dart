import 'package:flutter/material.dart';

import '../../models/veiculo.dart';
import '../widgets/card_veiculo_resumo.dart';

class AbaVeiculo extends StatelessWidget {
  const AbaVeiculo({
    super.key,
    required this.veiculo,
    required this.totalAbastecimentos,
    required this.aoCadastrarVeiculo,
    required this.aoExcluirVeiculo,
  });

  final Veiculo? veiculo;
  final int totalAbastecimentos;
  final VoidCallback aoCadastrarVeiculo;
  final VoidCallback aoExcluirVeiculo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final veiculoAtual = veiculo;

    if (veiculoAtual == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: tema.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_car_outlined,
                  size: 48,
                  color: tema.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Cadastre seu veículo',
                style: tema.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecione a marca e o modelo diretamente da BrasilAPI (Tabela FIPE) e informe o ano e a cilindrada do motor.',
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: aoCadastrarVeiculo,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Cadastrar veículo'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CardVeiculoResumo(
          veiculo: veiculoAtual,
          totalAbastecimentos: totalAbastecimentos,
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _LinhaDetalhe(
                icone: veiculoAtual.tipoVeiculo.icone,
                rotulo: 'Categoria',
                valor: veiculoAtual.tipoVeiculo.rotulo,
              ),
              const Divider(height: 1),
              _LinhaDetalhe(
                icone: Icons.factory_outlined,
                rotulo: 'Marca',
                valor: veiculoAtual.marca,
              ),
              const Divider(height: 1),
              _LinhaDetalhe(
                icone: Icons.directions_car_outlined,
                rotulo: 'Modelo',
                valor: veiculoAtual.modelo,
              ),
              const Divider(height: 1),
              _LinhaDetalhe(
                icone: Icons.calendar_today_outlined,
                rotulo: 'Ano',
                valor: veiculoAtual.ano.toString(),
              ),
              const Divider(height: 1),
              _LinhaDetalhe(
                icone: Icons.speed_outlined,
                rotulo: 'Cilindrada do motor',
                valor: veiculoAtual.cilindrada,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: tema.colorScheme.errorContainer.withValues(alpha: 0.35),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: tema.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Trocar de veículo',
                        style: tema.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: tema.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'O aplicativo permite apenas um veículo cadastrado por vez. '
                  'Para cadastrar outro veículo, exclua o veículo atual — todos os abastecimentos associados também serão removidos.',
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: aoExcluirVeiculo,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tema.colorScheme.error,
                    side: BorderSide(color: tema.colorScheme.error),
                  ),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Excluir veículo'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LinhaDetalhe extends StatelessWidget {
  const _LinhaDetalhe({
    required this.icone,
    required this.rotulo,
    required this.valor,
  });

  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return ListTile(
      leading: Icon(icone, color: tema.colorScheme.primary),
      title: Text(
        rotulo,
        style: tema.textTheme.labelMedium?.copyWith(
          color: tema.colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(
        valor,
        style: tema.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: tema.colorScheme.onSurface,
        ),
      ),
    );
  }
}
