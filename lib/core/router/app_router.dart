import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../screens/home/home_screen.dart';
import '../../screens/materials/material_form_screen.dart';
import '../../screens/materials/materials_screen.dart';
import '../../screens/models/model_detail_screen.dart';
import '../../screens/models/model_form_screen.dart';
import '../../screens/models/models_screen.dart';
import '../../screens/movements/stock_movement_form_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    ShellRoute(
      builder: (context, state, child) => _ScaffoldWithNav(child: child),
      routes: [
        GoRoute(
          path: '/models',
          builder: (context, state) => const ModelsScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const ModelFormScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) =>
                  ModelDetailScreen(id: int.parse(state.pathParameters['id']!)),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => ModelFormScreen(
                    modelId: int.parse(state.pathParameters['id']!),
                  ),
                ),
                GoRoute(
                  path: 'movement',
                  builder: (context, state) => StockMovementFormScreen(
                    modelId: int.parse(state.pathParameters['id']!),
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/materials',
          builder: (context, state) => const MaterialsScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const MaterialFormScreen(),
            ),
            GoRoute(
              path: ':id/edit',
              builder: (context, state) => MaterialFormScreen(
                materialId: int.parse(state.pathParameters['id']!),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

class _ScaffoldWithNav extends StatelessWidget {
  final Widget child;
  const _ScaffoldWithNav({required this.child});

  static int _tabIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/materials')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex(context),
        onDestinationSelected: (i) {
          if (i == 0) context.go('/models');
          if (i == 1) context.go('/materials');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.shopping_bag), label: 'Modelos'),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Materiais'),
        ],
      ),
    );
  }
}
