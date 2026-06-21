import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/purse_model_provider.dart';
import '../../providers/stock_movement_provider.dart';
import '../../widgets/profit_chip.dart';
import '../../widgets/stock_badge.dart';

final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

class ModelDetailScreen extends StatefulWidget {
  final int id;
  const ModelDetailScreen({super.key, required this.id});

  @override
  State<ModelDetailScreen> createState() => _ModelDetailScreenState();
}

class _ModelDetailScreenState extends State<ModelDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final modelProvider = context.read<PurseModelProvider>();
    final movementProvider = context.read<StockMovementProvider>();
    await modelProvider.loadDetail(widget.id);
    await movementProvider.loadForModel(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PurseModelProvider>(
      builder: (context, provider, _) {
        final detail = provider.selected;

        if (detail == null || detail.model.id != widget.id) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final model = detail.model;
        return Scaffold(
          appBar: AppBar(
            title: Text(model.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar',
                onPressed: () =>
                    context.push('/models/${widget.id}/edit').then((_) => _load()),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context
                .push('/models/${widget.id}/movement')
                .then((_) => _load()),
            icon: const Icon(Icons.swap_vert),
            label: const Text('Movimentar estoque'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _SummaryCard(detail: detail),
              const SizedBox(height: 16),
              _BomSection(detail: detail),
              const SizedBox(height: 16),
              _MovementsSection(modelId: widget.id),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final dynamic detail;
  const _SummaryCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final model = detail.model;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Resumo financeiro',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                StockBadge(stock: model.currentStock),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(
              label: 'Preço de venda',
              value: _currency.format(model.sellingPrice),
              valueColor: colorScheme.primary,
            ),
            _InfoRow(
              label: 'Custo de produção',
              value: _currency.format(detail.cost),
              valueColor: Colors.orange.shade700,
            ),
            const Divider(height: 16),
            Row(
              children: [
                const Expanded(child: Text('Lucro por unidade')),
                ProfitChip(profit: detail.profit),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Margem',
              value: '${detail.marginPercent.toStringAsFixed(1)}%',
              valueColor: detail.profit >= 0
                  ? Colors.green.shade700
                  : Colors.red.shade700,
            ),
            _InfoRow(
              label: 'Valor total em estoque',
              value: _currency.format(model.sellingPrice * model.currentStock),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _BomSection extends StatelessWidget {
  final dynamic detail;
  const _BomSection({required this.detail});

  @override
  Widget build(BuildContext context) {
    final bom = detail.bom as List;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ficha técnica',
                style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: 24),
            if (bom.isEmpty)
              Text(
                'Nenhum material cadastrado para este modelo.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ...bom.map((mm) {
              final mat = mm.material;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(mat?.name ?? 'Material #${mm.materialId}'),
                    ),
                    Text(
                      '${mm.quantityPerUnit} ${mat?.unit ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _currency.format(
                          mm.quantityPerUnit * (mat?.lastPricePerUnit ?? 0)),
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MovementsSection extends StatelessWidget {
  final int modelId;
  const _MovementsSection({required this.modelId});

  @override
  Widget build(BuildContext context) {
    return Consumer<StockMovementProvider>(
      builder: (context, provider, _) {
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Histórico de movimentações',
                    style: Theme.of(context).textTheme.titleMedium),
                const Divider(height: 24),
                if (provider.loading)
                  const Center(child: CircularProgressIndicator())
                else if (provider.movements.isEmpty)
                  Text(
                    'Nenhuma movimentação registrada.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  )
                else
                  ...provider.movements.map((mv) {
                    final positive = mv.delta > 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            positive
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: positive
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mv.reason ?? (positive ? 'Entrada' : 'Saída'),
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  _dateFormat.format(mv.movedAt),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${positive ? '+' : ''}${mv.delta}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: positive
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}
