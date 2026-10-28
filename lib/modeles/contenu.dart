/// Les modèles de données du contenu d'apprentissage (fichiers JSON dans
/// assets/contenu/, voir CLAUDE.md). Ce contenu est fixe, embarqué dans
/// l'appli : Firestore ne sert que pour les données des utilisateurs.
library;

/// Une catégorie (Débutant, Voyage, Sport, Technique...), avec ses leçons.
class Categorie {
  const Categorie({required this.id, required this.nom, required this.lecons});

  final String id;
  final String nom;
  final List<Lecon> lecons;

  factory Categorie.fromJson(Map<String, dynamic> json) {
    return Categorie(
      id: json['id'] as String,
      nom: json['nom'] as String,
      lecons: [
        for (final l in (json['lecons'] as List)) Lecon.fromJson(l),
      ],
    );
  }
}

/// Une leçon : un ensemble de cartes (et plus tard, des phrases et une
/// mini-leçon).
class Lecon {
  const Lecon({
    required this.id,
    required this.titre,
    required this.niveau,
    required this.cartes,
  });

  final String id;
  final String titre;
  final String niveau;
  final List<Carte> cartes;

  factory Lecon.fromJson(Map<String, dynamic> json) {
    return Lecon(
      id: json['id'] as String,
      titre: json['titre'] as String,
      niveau: json['niveau'] as String,
      cartes: [
        for (final c in (json['cartes'] as List)) Carte.fromJson(c),
      ],
    );
  }
}

/// Une carte de vocabulaire : un mot ou une expression, anglais et français.
class Carte {
  const Carte({required this.en, required this.fr});

  final String en;
  final String fr;

  factory Carte.fromJson(Map<String, dynamic> json) {
    return Carte(en: json['en'] as String, fr: json['fr'] as String);
  }
}
