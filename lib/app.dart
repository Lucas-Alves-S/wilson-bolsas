import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/database/database_helper.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/material_provider.dart';
import 'providers/purse_model_provider.dart';
import 'providers/stock_movement_provider.dart';
import 'repositories/material_repository.dart';
import 'repositories/purse_model_repository.dart';
import 'repositories/stock_movement_repository.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseHelper.instance;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MaterialProvider(MaterialRepository(db))..loadAll(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              PurseModelProvider(PurseModelRepository(db))..loadAll(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              StockMovementProvider(StockMovementRepository(db)),
        ),
      ],
      child: MaterialApp.router(
        title: 'Wilson Bolsas',
        theme: AppTheme.light,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
        // Android 13+ predictive back decides at gesture-start whether to hand
        // the gesture to the app, based on SystemNavigator.setFrameworkHandlesBack.
        // With go_router's bottom-nav shell, the inner navigator reports
        // canHandlePop:false at a tab root, so the OS would exit before our
        // shell PopScope runs. Force the framework to always own back; the shell
        // PopScope in app_router.dart then decides whether to navigate or exit.
        onNavigationNotification: (_) {
          SystemNavigator.setFrameworkHandlesBack(true);
          return true;
        },
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
