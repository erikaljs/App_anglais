import 'package:flutter/material.dart';

import 'navigation/app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MonAnglaisApp());
}

/// Racine de l'application : définit le titre, le thème, et affiche
/// la navigation principale (AppShell).
class MonAnglaisApp extends StatelessWidget {
  const MonAnglaisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mon anglais',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.clair,
      home: const AppShell(),
    );
  }
}
