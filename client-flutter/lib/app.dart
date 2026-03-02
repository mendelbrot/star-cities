import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:star_cities/core/router/app_state_manager.dart';
import 'package:star_cities/core/router/app_router.dart';
import 'package:star_cities/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppStateManager _appStateManager;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _appStateManager = AppStateManager(Supabase.instance.client);
    _router = createRouter(_appStateManager);
  }

  @override
  void dispose() {
    _appStateManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Star Cities',
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
