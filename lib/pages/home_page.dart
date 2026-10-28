import 'package:flutter/material.dart';

/// Page d'accueil : plus tard, les catégories, la progression et le mot du jour.
/// Pour l'instant, elle ne contient qu'un titre.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Home'),
    );
  }
}
