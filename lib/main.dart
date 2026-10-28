import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'navigation/app_shell.dart';
import 'pages/auth/connexion_page.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Nécessaire avant d'utiliser un plugin natif (ici Firebase) dans Flutter.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MonAnglaisApp());
}

/// Racine de l'application : définit le titre, le thème, et choisit
/// l'écran à afficher selon que l'utilisateur est connecté ou non.
class MonAnglaisApp extends StatelessWidget {
  const MonAnglaisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mon anglais',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.clair,
      home: StreamBuilder<User?>(
        // Cet écouteur se déclenche à chaque connexion/déconnexion, et
        // aussi une première fois au démarrage pour dire si quelqu'un
        // était déjà connecté.
        stream: AuthService.changementsConnexion,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final utilisateurConnecte = snapshot.data != null;
          return utilisateurConnecte ? const AppShell() : const ConnexionPage();
        },
      ),
    );
  }
}
