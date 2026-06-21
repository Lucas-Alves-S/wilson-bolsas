import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../providers/purse_model_provider.dart';
import '../../repositories/purse_model_repository.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/profit_chip.dart';
import '../../widgets/stock_badge.dart';

class ModelsScreen extends StatefulWidget {
  const ModelsScreen({super.key});

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  final Map<int, double> _profits = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProfits();
  }

  Future<void> _loadProfits() async {
    final provider = context.read<PurseModelProvider>();
    final repo = PurseModelRepository(DatabaseHelper.instance);
    final updated = <int, double>{};
    for (final model in provider.models) {
      if (model.id == null) continue;
      final bom = await repo.getWithBom(model.id!);
      updated[model.id!] = bom.profit;
    }
    if (mounted) setState(() => _profits.addAll(updated));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modelos'),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final provider = context.read<PurseModelProvider>();
          await context.push('/models/new');
          await provider.loadAll();
          _loadProfits();
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<PurseModelProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.models.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Nenhum modelo cadastrado',
                      style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 4),
                  Text('Toque no + para adicionar',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: provider.models.length,
            itemBuilder: (context, index) {
              final model = provider.models[index];
              return Dismissible(
                key: ValueKey(model.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Theme.of(context).colorScheme.error,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) => showConfirmationDialog(
                  context,
                  title: 'Excluir modelo',
                  content:
                      'Deseja excluir "${model.name}"? Esta ação não pode ser desfeita.',
                ),
                onDismissed: (_) {
                  _profits.remove(model.id);
                  context.read<PurseModelProvider>().remove(model.id!);
                },
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final provider = context.read<PurseModelProvider>();
                      await context.push('/models/${model.id}');
                      await provider.loadAll();
                      _loadProfits();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  model.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                              StockBadge(stock: model.currentStock),
                            ],
                          ),
                          if (_profits.containsKey(model.id)) ...[
                            const SizedBox(height: 8),
                            ProfitChip(profit: _profits[model.id]!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
