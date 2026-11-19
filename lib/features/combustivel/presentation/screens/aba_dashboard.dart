import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatadores.dart';
import '../../models/indicador_abastecimento.dart';
import '../../models/veiculo.dart';
import '../widgets/card_kpi.dart';
import '../widgets/card_veiculo_resumo.dart';
import '../widgets/grafico_evolucao.dart';
import '../widgets/grafico_valores.dart';
import '../widgets/item_abastecimento.dart';

class AbaDashboard extends StatelessWidget {
  const AbaDashboard({
    super.key,
    required this.veiculo,
    required this.resumo,
    required this.aoCadastrarVeiculo,
    required this.aoRegistrarAbastecimento,
    required this.aoVerTodosAbastecimentos,
    required this.aoAbrirVeiculo,
  });

  final Veiculo? veiculo;
  final ResumoDashboard resumo;
  final VoidCallback aoCadastrarVeiculo;
  final VoidCallback aoRegistrarAbastecimento;
  final VoidCallback aoVerTodosAbastecimentos;
  final VoidCallback aoAbrirVeiculo;

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
                  Icons.directions_car_filled_outlined,
                  size: 48,
                  color: tema.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Nenhum veículo cadastrado',
                style: tema.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Cadastre seu veículo consultando marcas e modelos na BrasilAPI para começar a registrar abastecimentos e acompanhar o consumo.',
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

    if (resumo.totalAbastecimentos == 0) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CardVeiculoResumo(
            veiculo: veiculoAtual,
            totalAbastecimentos: 0,
            aoTocar: aoAbrirVeiculo,
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.local_gas_station_outlined,
                    size: 44,
                    color: tema.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Registre o primeiro abastecimento',
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'O primeiro abastecimento de tanque cheio servirá como referência inicial. A partir do segundo registro, os gráficos de consumo (km/L) e custo por quilômetro (R\$/km) serão exibidos automaticamente.',
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
          ),
        ],
      );
    }

    final ultimo = resumo.ultimoCalculado;
    final recentes = resumo.indicadoresMaisRecentesPrimeiro.take(3).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        CardVeiculoResumo(
          veiculo: veiculoAtual,
          totalAbastecimentos: resumo.totalAbastecimentos,
          aoTocar: aoAbrirVeiculo,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CardKpi(
                titulo: 'Total gasto',
                valor: Formatadores.formatarMoeda(resumo.totalGasto),
                subtitulo: Formatadores.formatarLitros(resumo.totalLitros),
                icone: Icons.payments_outlined,
                corDestaque: AppTheme.corValor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CardKpi(
                titulo: 'Distância medida',
                valor: resumo.distanciaTotal > 0
                    ? Formatadores.formatarQuilometragem(resumo.distanciaTotal)
                    : '—',
                subtitulo: resumo.distanciaTotal > 0
                    ? '${resumo.indicadoresComCalculo.length} ${resumo.indicadoresComCalculo.length == 1 ? 'trecho' : 'trechos'}'
                    : 'Aguardando 2º registro',
                icone: Icons.route_outlined,
                corDestaque: tema.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CardKpi(
                titulo: 'Consumo médio',
                valor: resumo.consumoMedioKmPorLitro == null
                    ? '—'
                    : Formatadores.formatarConsumo(
                        resumo.consumoMedioKmPorLitro!,
                      ),
                subtitulo: ultimo?.consumoKmPorLitro == null
                    ? '1º é referência inicial'
                    : 'Último: ${Formatadores.formatarConsumo(ultimo!.consumoKmPorLitro!)}',
                icone: Icons.local_gas_station_outlined,
                corDestaque: AppTheme.corConsumo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CardKpi(
                titulo: 'Custo médio/km',
                valor: resumo.custoMedioPorKm == null
                    ? '—'
                    : Formatadores.formatarCustoPorKm(resumo.custoMedioPorKm!),
                subtitulo: ultimo?.custoPorKm == null
                    ? '1º é referência inicial'
                    : 'Último: ${Formatadores.formatarCustoPorKm(ultimo!.custoPorKm!)}',
                icone: Icons.trending_up_rounded,
                corDestaque: AppTheme.corCustoKm,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GraficoEvolucao(
          titulo: 'Evolução do consumo (km/L)',
          subtitulo: 'Distância percorrida ÷ litros abastecidos (a partir do 2º)',
          icone: Icons.eco_outlined,
          cor: AppTheme.corConsumo,
          indicadores: resumo.indicadoresComCalculo,
          extrairValor: (item) => item.consumoKmPorLitro!,
          formatarValorEixo: (v) => Formatadores.formatarNumero(v, casasDecimais: 1),
          formatarValorTooltip: Formatadores.formatarConsumo,
          mensagemInsuficiente:
              'O 1º abastecimento é referência inicial. Registre o 2º abastecimento para visualizar a evolução do consumo em km/L.',
        ),
        const SizedBox(height: 16),
        GraficoEvolucao(
          titulo: 'Evolução do custo por km (R\$/km)',
          subtitulo: 'Valor total ÷ distância percorrida (a partir do 2º)',
          icone: Icons.attach_money_rounded,
          cor: AppTheme.corCustoKm,
          indicadores: resumo.indicadoresComCalculo,
          extrairValor: (item) => item.custoPorKm!,
          formatarValorEixo: (v) =>
              'R\$${Formatadores.formatarNumero(v, casasDecimais: 2)}',
          formatarValorTooltip: Formatadores.formatarCustoPorKm,
          mensagemInsuficiente:
              'O 1º abastecimento é referência inicial. Registre o 2º abastecimento para visualizar a evolução do custo em R\$/km.',
        ),
        const SizedBox(height: 16),
        GraficoValoresAbastecimento(
          indicadores: resumo.indicadoresCronologicos,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Últimos abastecimentos',
              style: tema.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (resumo.totalAbastecimentos > 3)
              TextButton(
                onPressed: aoVerTodosAbastecimentos,
                child: const Text('Ver todos'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (final item in recentes) ...[
          ItemAbastecimento(indicador: item),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
