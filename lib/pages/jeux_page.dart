import 'package:flutter/material.dart';

/// Page des jeux : plus tard, Words et Memory.
/// Pour l'instant, elle ne contient qu'un titre.
class JeuxPage extends StatelessWidget {
  const JeuxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Jeux'),
    );
  }
}
