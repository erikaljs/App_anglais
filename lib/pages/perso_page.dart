import 'package:flutter/material.dart';

/// Page "Perso" : plus tard, les paquets de cartes créés par l'utilisateur.
/// Pour l'instant, elle ne contient qu'un titre.
class PersoPage extends StatelessWidget {
  const PersoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Perso'),
    );
  }
}
