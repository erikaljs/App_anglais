import 'package:flutter/material.dart';

/// Les avatars que l'utilisateur peut choisir sur son profil : juste des
/// icônes Material (pas d'emoji, voir CLAUDE.md), identifiées par un nom
/// qu'on enregistre dans Firestore (champ "avatar" de users/{uid}).
class AppAvatars {
  AppAvatars._();

  static const Map<String, IconData> icones = {
    'etoile': Icons.star,
    'soleil': Icons.wb_sunny,
    'lune': Icons.nightlight_round,
    'fusee': Icons.rocket_launch,
    'coeur': Icons.favorite,
    'trefle': Icons.eco,
    'eclair': Icons.bolt,
    'cible': Icons.track_changes,
  };

  /// L'icône à afficher pour un identifiant d'avatar. Si l'identifiant est
  /// inconnu (ou absent), on affiche l'étoile par défaut.
  static IconData icone(String? id) => icones[id] ?? icones['etoile']!;
}
