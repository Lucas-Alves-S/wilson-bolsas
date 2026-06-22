import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../screens/home/home_screen.dart';
import '../../screens/materials/material_form_screen.dart';
import '../../screens/materials/materials_screen.dart';
import '../../screens/models/model_detail_screen.dart';
import '../../screens/models/model_form_screen.dart';
import '../../screens/models/models_screen.dart';
import '../../screens/movements/movements_screen.dart';
import '../../screens/movements/stock_movement_form_screen.dart';
import '../../widgets/app_bottom_nav.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Tracks the tab roots the user has visited so the Android back button can
/// retrace them. Lives for the app's lifetime (single shell). Tab navigations
/// use `context.go(...)`, which replaces the route stack — so without this the
/// inner navigator has nothing to pop and the OS would exit straight away.
final _tabHistory = _TabHistory();

class _TabHistory {
  final List<String> _stack = [];

  /// Records a visit, collapsing consecutive duplicates (this also keeps the
  /// back-induced `go()` from re-growing the stack).
  void record(String tabRoot) {
    if (_stack.isEmpty || _stack.last != tabRoot) _stack.add(tabRoot);
  }

  /// The tab to navigate back to, or `null` when the app should exit.
  String? pop() {
    if (_stack.length > 1) {
      _stack.removeLast();
      return _stack.last;
    }
    // Safety net: if we somehow aren't on Home, land there before exiting.
    if (_stack.isNotEmpty && _stack.last != '/') return '/';
    return null; // on Home with no history → leave the app to the OS
  }
}

/// Maps a location to its tab root, collapsing sub-routes (`/models/5` → `/models`).
String _tabRoot(String loc) {
  if (loc.startsWith('/models')) return '/models';
  if (loc.startsWith('/materials')) return '/materials';
  if (loc.startsWith('/movements')) return '/movements';
  return '/'; // Início
}

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) =>
          _ScaffoldWithNav(location: state.uri.toString(), child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
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
        GoRoute(
          path: '/movements',
          builder: (context, state) => const MovementsScreen(),
        ),
      ],
    ),
  ],
);

class _ScaffoldWithNav extends StatelessWidget {
  final String location;
  final Widget child;
  const _ScaffoldWithNav({required this.location, required this.child});

  @override
  Widget build(BuildContext context) {
    final tabRoot = _tabRoot(location);
    // Record every navigation here — the shell rebuilds for tab switches and
    // sub-route pushes alike, so it's the single chokepoint that sees them all.
    _tabHistory.record(tabRoot);

    final selectedIndex = switch (tabRoot) {
      '/models' => 1,
      '/materials' => 2,
      '/movements' => 3,
      _ => 0,
    };

    // The PopScope lives on the shell page (the root navigator's current route).
    // go_router's popRoute() only routes the Android back to the inner shell
    // navigator when it can pop (a pushed detail/form); at a tab root it calls
    // maybePop() on the ROOT navigator, which consults *this* PopScope. So tab
    // roots are handled here, while pushed sub-routes pop with default behavior.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final target = _tabHistory.pop();
        if (target == null) {
          SystemNavigator.pop(); // on Home, no history → leave the app to the OS
        } else {
          context.go(target); // retrace to the previously visited tab
        }
      },
      child: Scaffold(
        extendBody: true,
        body: child,
        bottomNavigationBar: AppBottomNav(
          selectedIndex: selectedIndex,
          onSelect: (i) {
            switch (i) {
              case 0:
                context.go('/');
              case 1:
                context.go('/models');
              case 2:
                context.go('/materials');
              case 3:
                context.go('/movements');
            }
          },
        ),
      ),
    );
  }
}
