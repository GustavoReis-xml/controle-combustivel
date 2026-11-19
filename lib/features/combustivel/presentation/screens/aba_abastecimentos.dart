import 'package:flutter/material.dart';

import '../../../../core/utils/formatadores.dart';
import '../../models/abastecimento.dart';
import '../../models/indicador_abastecimento.dart';
import '../../models/veiculo.dart';
import '../widgets/item_abastecimento.dart';

class AbaAbastecimentos extends StatelessWidget {
  const AbaAbastecimentos({
    super.key,
    required this.veiculo,
    required this.resumo,
    required this.aoCadastrarVeiculo,
    required this.aoRegistrarAbastecimento,
    required this.aoExcluirAbastecimento,
  });

  final Veiculo? veiculo;
  final ResumoDashboard resumo;
  final VoidCallback aoCadastrarVeiculo;
  final VoidCallback aoRegistrarAbastecimento;
  final Future<void> Function(Abastecimento abastecimento)
  aoExcluirAbastecimento;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    if (veiculo == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 48,
                color: tema.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Cadastre um veículo primeiro',
                style: tema.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Os abastecimentos ficam vinculados ao veículo cadastrado no aplicativo.',
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
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

    if (resumo.totalAbastecimentos == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_gas_station_outlined,
                size: 48,
                color: tema.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum abastecimento registrado',
                style: tema.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Toque no botão abaixo para registrar o primeiro abastecimento de ${veiculo!.tituloCompleto}.',
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: aoRegistrarAbastecimento,
                icon: const Icon(Icons.add),
                label: const Text('Registrar abastecimento'),
              ),
            ],
          ),
        ),
      );
    }

    final itens = resumo.indicadoresMaisRecentesPrimeiro;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: itens.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              color: tema.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${resumo.totalAbastecimentos} '
                      '${resumo.totalAbastecimentos == 1 ? 'registro' : 'registros'}',
                      style: tema.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Total: ${Formatadores.formatarMoeda(resumo.totalGasto)}',
                      style: tema.textTheme.labelLarge?.copyWith(
                        color: tema.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final item = itens[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ItemAbastecimento(
            indicador: item,
            aoExcluir: () => aoExcluirAbastecimento(item.abastecimento),
          ),
        );
      },
    );
  }
}
