import 'package:flutter/material.dart';

import 'core/config/route_config.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Prototype',
      theme: AppTheme.darkTheme,
      routerConfig: RouteConfig.router,
    );
  }
}
