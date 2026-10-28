import 'package:flutter/material.dart';

/// Page de profil : plus tard, le pseudo, l'avatar, le code ami et les amis.
/// Pour l'instant, elle ne contient qu'un titre.
class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profil'),
    );
  }
}
