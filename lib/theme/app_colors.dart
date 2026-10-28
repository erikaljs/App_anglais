import 'package:flutter/material.dart';

/// Toutes les couleurs de l'application, reprises de la maquette (voir CLAUDE.md).
///
/// On les regroupe ici pour ne jamais écrire un code couleur "en dur"
/// dans les écrans : si on veut changer une couleur plus tard, on la
/// change une seule fois, à cet endroit.
class AppColors {
  AppColors._(); // Empêche de créer une instance : cette classe ne sert qu'à ranger des constantes.

  // Couleurs principales.
  static const bleuPrincipal = Color(0xFF2F5BEA);
  static const bleuFonce = Color(0xFF16213E);
  static const fond = Color(0xFFF5F6FA);

  // Cartes et textes.
  static const carteBordure = Color(0xFFE3E6EF);
  static const texteSecondaire = Color(0xFF4A5470);

  // Série de jours / progression.
  static const orange = Color(0xFFFF8A3D);

  // Messages de succès et d'erreur.
  static const succesTexte = Color(0xFF0A6B53);
  static const succesFond = Color(0xFFE2F4EE);
  static const erreurTexte = Color(0xFFB42318);
  static const erreurFond = Color(0xFFFDECEA);

  // Couleurs par catégorie (fond, puis texte).
  static const debutantFond = Color(0xFFE6ECFD);
  static const debutantTexte = Color(0xFF2348C7);
  static const voyageFond = Color(0xFFE2F4EE);
  static const voyageTexte = Color(0xFF0A6B53);
  static const sportFond = Color(0xFFFDEBDD);
  static const sportTexte = Color(0xFFA8380B);
  static const techniqueFond = Color(0xFFEEE7FA);
  static const techniqueTexte = Color(0xFF5B33A6);
  static const persoFond = Colors.white;
  static const persoTexte = Color(0xFF16213E);
  static const jeuxFond = Color(0xFF16213E);
  static const jeuxTexte = Colors.white;

  /// Les couleurs (fond, texte) d'une catégorie à partir de son identifiant
  /// (ex: "sport"). Utilisé pour les tuiles de la Home.
  static (Color fond, Color texte) couleursCategorie(String idCategorie) {
    switch (idCategorie) {
      case 'debutant':
        return (debutantFond, debutantTexte);
      case 'voyage':
        return (voyageFond, voyageTexte);
      case 'sport':
        return (sportFond, sportTexte);
      case 'technique':
        return (techniqueFond, techniqueTexte);
      case 'perso':
        return (persoFond, persoTexte);
      case 'jeux':
        return (jeuxFond, jeuxTexte);
      default:
        return (fond, bleuFonce);
    }
  }
}
