import 'package:cloud_firestore/cloud_firestore.dart';

import 'contenu.dart';

/// Une phrase d'un paquet perso : une seule traduction (pas plusieurs
/// variantes comme pour le contenu officiel, puisque c'est l'utilisateur
/// qui l'écrit lui-même).
class PhrasePerso {
  const PhrasePerso({required this.fr, required this.en});

  final String fr;
  final String en;

  factory PhrasePerso.fromJson(Map<String, dynamic> json) {
    return PhrasePerso(fr: json['fr'] as String, en: json['en'] as String);
  }

  Map<String, dynamic> versJson() => {'fr': fr, 'en': en};
}

/// Un paquet créé par un utilisateur (users/{uid}/decks/{id}, voir
/// CLAUDE.md) : son nom, sa visibilité, ses cartes et ses phrases.
class Deck {
  const Deck({
    required this.id,
    required this.proprietaireId,
    required this.nom,
    required this.visibilite,
    required this.cartes,
    required this.phrases,
  });

  final String id;
  final String proprietaireId;
  final String nom;
  final String visibilite; // "amis" ou "prive"
  final List<Carte> cartes;
  final List<PhrasePerso> phrases;

  bool get estVisibleDesAmis => visibilite == 'amis';

  factory Deck.depuisDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
    String proprietaireId,
  ) {
    final donnees = document.data() ?? {};
    return Deck(
      id: document.id,
      proprietaireId: proprietaireId,
      nom: donnees['nom'] as String? ?? '(sans nom)',
      visibilite: donnees['visibilite'] as String? ?? 'amis',
      cartes: [
        for (final c in (donnees['cartes'] as List? ?? const []))
          Carte.fromJson(c as Map<String, dynamic>),
      ],
      phrases: [
        for (final p in (donnees['phrases'] as List? ?? const []))
          PhrasePerso.fromJson(p as Map<String, dynamic>),
      ],
    );
  }

  Map<String, dynamic> versJson() => {
    'nom': nom,
    'visibilite': visibilite,
    'cartes': [for (final c in cartes) {'en': c.en, 'fr': c.fr}],
    'phrases': [for (final p in phrases) p.versJson()],
    'misAJourLe': FieldValue.serverTimestamp(),
  };

  /// Convertit ce paquet en Lecon générique, pour réutiliser les écrans
  /// d'exercice (cartes, phrases) déjà construits pour le contenu officiel.
  Lecon versLecon() {
    return Lecon(
      id: 'deck-$id',
      titre: nom,
      niveau: 'Perso',
      cartes: cartes,
      phrases: [for (final p in phrases) Phrase(fr: p.fr, en: [p.en])],
    );
  }
}
