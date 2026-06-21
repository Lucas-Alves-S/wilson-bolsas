import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/material_provider.dart';
import '../../widgets/confirmation_dialog.dart';

final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class MaterialsScreen extends StatelessWidget {
  const MaterialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Materiais'),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/materials/new'),
        child: const Icon(Icons.add),
      ),
      body: Consumer<MaterialProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.materials.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Nenhum material cadastrado',
                      style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 4),
                  Text('Toque no + para adicionar',
                      style:
                          TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: provider.materials.length,
            itemBuilder: (context, index) {
              final mat = provider.materials[index];
              return Dismissible(
                key: ValueKey(mat.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Theme.of(context).colorScheme.error,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) => showConfirmationDialog(
                  context,
                  title: 'Excluir material',
                  content:
                      'Deseja excluir "${mat.name}"? Esta ação não pode ser desfeita.',
                ),
                onDismissed: (_) =>
                    context.read<MaterialProvider>().remove(mat.id!),
                child: ListTile(
                  title: Text(mat.name),
                  subtitle: Text(mat.unit),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _fmt.format(mat.lastPricePerUnit),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => context.push('/materials/${mat.id}/edit'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
