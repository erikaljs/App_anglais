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

/// Une leçon : ses cartes, ses phrases à traduire, et (parfois) une
/// mini-leçon.
class Lecon {
  const Lecon({
    required this.id,
    required this.titre,
    required this.niveau,
    required this.cartes,
    required this.phrases,
    this.miniLecon,
  });

  final String id;
  final String titre;
  final String niveau;
  final List<Carte> cartes;
  final List<Phrase> phrases;
  final MiniLecon? miniLecon;

  factory Lecon.fromJson(Map<String, dynamic> json) {
    return Lecon(
      id: json['id'] as String,
      titre: json['titre'] as String,
      niveau: json['niveau'] as String,
      cartes: [
        for (final c in (json['cartes'] as List)) Carte.fromJson(c),
      ],
      phrases: [
        for (final p in (json['phrases'] as List? ?? const [])) Phrase.fromJson(p),
      ],
      miniLecon: json['miniLecon'] != null
          ? MiniLecon.fromJson(json['miniLecon'] as Map<String, dynamic>)
          : null,
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

/// Une phrase à traduire. [en] contient une ou plusieurs traductions
/// anglaises acceptées (plusieurs réponses correctes possibles, voir
/// CLAUDE.md), [fr] n'en a qu'une.
class Phrase {
  const Phrase({required this.fr, required this.en});

  final String fr;
  final List<String> en;

  factory Phrase.fromJson(Map<String, dynamic> json) {
    return Phrase(
      fr: json['fr'] as String,
      en: [for (final e in (json['en'] as List)) e as String],
    );
  }
}

/// Une mini-leçon : une règle courte, des exemples, puis un petit quiz.
class MiniLecon {
  const MiniLecon({
    required this.regle,
    required this.exemples,
    required this.qcm,
  });

  final String regle;
  final List<String> exemples;
  final List<QuestionQcm> qcm;

  factory MiniLecon.fromJson(Map<String, dynamic> json) {
    return MiniLecon(
      regle: json['regle'] as String,
      exemples: [for (final e in (json['exemples'] as List)) e as String],
      qcm: [
        for (final q in (json['qcm'] as List)) QuestionQcm.fromJson(q),
      ],
    );
  }
}

/// Une question à choix multiples (3 à 5 propositions), avec l'indice de
/// la bonne réponse dans [choix].
class QuestionQcm {
  const QuestionQcm({
    required this.question,
    required this.choix,
    required this.bonneReponseIndex,
  });

  final String question;
  final List<String> choix;
  final int bonneReponseIndex;

  factory QuestionQcm.fromJson(Map<String, dynamic> json) {
    return QuestionQcm(
      question: json['question'] as String,
      choix: [for (final c in (json['choix'] as List)) c as String],
      bonneReponseIndex: json['bonneReponseIndex'] as int,
    );
  }
}
