import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Page de profil : plus tard, le pseudo, l'avatar, le code ami et les amis.
/// Pour l'instant, juste un titre et un bouton de déconnexion pour tester.
class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Profil'),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: AuthService.deconnexion,
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}
