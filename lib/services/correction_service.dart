/// Corrige les réponses de l'exercice "Phrase à traduire".
///
/// Le but : accepter une réponse juste même si elle n'est pas tapée à
/// l'identique de la réponse attendue (majuscules, ponctuation, espaces,
/// formes contractées anglaises comme "he's" / "he is"), tout en
/// signalant gentiment les petites erreurs (faute de frappe, majuscule
/// manquante) plutôt que de les cacher.
library;

/// Le résultat d'une correction.
class ResultatCorrection {
  const ResultatCorrection({
    required this.correcte,
    this.message,
    this.conseilMajuscule,
  });

  /// true si la réponse est acceptée (même avec une petite faute tolérée).
  final bool correcte;

  /// Message à afficher sous la réponse, par exemple pour signaler qu'on a
  /// accepté une autre façon de dire la même chose, ou une faute de frappe.
  /// null si la réponse correspond exactement à la réponse principale.
  final String? message;

  /// Un petit conseil de majuscule (nationalité, langue, jour, mois), si
  /// applicable. N'empêche jamais la réponse d'être comptée juste.
  final String? conseilMajuscule;
}

class CorrectionService {
  CorrectionService._();

  /// Vérifie la réponse [saisie] par rapport aux réponses acceptées.
  /// [cibleAnglais] indique si la langue attendue est l'anglais (seule
  /// langue où on vérifie les majuscules de nationalités/jours/mois).
  static ResultatCorrection corriger({
    required String saisie,
    required List<String> reponsesAcceptees,
    required bool cibleAnglais,
  }) {
    if (reponsesAcceptees.isEmpty) {
      return const ResultatCorrection(correcte: false);
    }

    final saisieBase = _nettoyerBase(saisie).toLowerCase();
    final principalBase = _nettoyerBase(reponsesAcceptees.first).toLowerCase();
    final variantesSaisie = _toutesLesVariantes(saisie);

    // 1) Correspondance exacte, ou équivalente via une forme contractée.
    for (final reponse in reponsesAcceptees) {
      final variantesReponse = _toutesLesVariantes(reponse);
      if (variantesSaisie.intersection(variantesReponse).isNotEmpty) {
        final identiqueAuPrincipal = saisieBase == principalBase;
        return ResultatCorrection(
          correcte: true,
          message: identiqueAuPrincipal
              ? null
              : 'Bonne réponse ! Autre façon de dire : ${reponsesAcceptees.first}',
          conseilMajuscule: cibleAnglais ? _conseilMajuscule(reponse, saisie) : null,
        );
      }
    }

    // 2) Petite faute de frappe tolérée (une lettre, sur un mot de plus de
    //    4 lettres, le reste de la phrase étant identique). On compare les
    //    variantes développées (pas le texte brut) pour qu'une forme
    //    contractée mal orthographiée soit aussi reconnue (ex : "He is
    //    Itlian" face à "He's Italian.").
    for (final reponse in reponsesAcceptees) {
      final variantesReponse = _toutesLesVariantes(reponse);
      for (final varianteSaisie in variantesSaisie) {
        for (final varianteReponse in variantesReponse) {
          final motAttendu = _motProcheMaisDifferent(varianteSaisie, varianteReponse);
          if (motAttendu != null) {
            return ResultatCorrection(
              correcte: true,
              message: "Presque parfait ! Attention à l'orthographe : $reponse",
              conseilMajuscule: cibleAnglais ? _conseilMajuscule(reponse, saisie) : null,
            );
          }
        }
      }
    }

    return const ResultatCorrection(correcte: false);
  }

  // -------------------------------------------------------------------
  // Nettoyage de base : minuscules (fait par l'appelant quand besoin),
  // apostrophes normalisées, ponctuation courante retirée, espaces
  // multiples réduits. On garde les apostrophes : elles servent à
  // repérer les formes contractées à l'étape suivante.
  // -------------------------------------------------------------------
  static String _nettoyerBase(String texte) {
    var t = texte.replaceAll('’', "'").replaceAll('‘', "'");
    t = t.replaceAll(RegExp('[.,!?;:"()«»]'), '');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  // -------------------------------------------------------------------
  // Formes contractées anglaises sans ambiguïté : une seule expansion
  // possible, donc un simple remplacement de texte suffit.
  // -------------------------------------------------------------------
  static const Map<String, String> _contractionsFixes = {
    "isn't": 'is not',
    "aren't": 'are not',
    "wasn't": 'was not',
    "weren't": 'were not',
    "don't": 'do not',
    "doesn't": 'does not',
    "didn't": 'did not',
    "haven't": 'have not',
    "hasn't": 'has not',
    "hadn't": 'had not',
    "won't": 'will not',
    "can't": 'can not',
    'cannot': 'can not',
    "couldn't": 'could not',
    "shouldn't": 'should not',
    "wouldn't": 'would not',
    "mustn't": 'must not',
    "let's": 'let us',
  };

  static String _appliquerContractionsFixes(String texte) {
    var resultat = texte;
    _contractionsFixes.forEach((forme, developpee) {
      resultat = resultat.replaceAll(RegExp('\\b${RegExp.escape(forme)}\\b'), developpee);
    });
    return resultat;
  }

  // 'm, 're, 'll, 've ne sont jamais ambigus (toujours am/are/will/have),
  // quel que soit le pronom ou le nom devant.
  static String _appliquerSuffixesSansAmbiguite(String texte) {
    return texte
        .replaceAllMapped(RegExp(r"\b(\w+)'m\b"), (m) => '${m[1]} am')
        .replaceAllMapped(RegExp(r"\b(\w+)'re\b"), (m) => '${m[1]} are')
        .replaceAllMapped(RegExp(r"\b(\w+)'ll\b"), (m) => '${m[1]} will')
        .replaceAllMapped(RegExp(r"\b(\w+)'ve\b"), (m) => '${m[1]} have');
  }

  // -------------------------------------------------------------------
  // 's et 'd sont ambigus ("he's" = he is OU he has ; "he'd" = he would
  // OU he had ; "'s" peut aussi être un possessif, ex : "Tom's bike").
  // On génère toutes les variantes possibles et on acceptera si l'une
  // d'elles correspond.
  // -------------------------------------------------------------------
  static Set<String> _developperAmbigus(String texte) {
    final regex = RegExp(r"\b(\w+)'s\b|\b(\w+)'d\b");
    final correspondances = regex.allMatches(texte).toList();
    if (correspondances.isEmpty) return {texte};

    final optionsParOccurrence = [
      for (final m in correspondances)
        if (m.group(1) != null)
          ['${m.group(1)} is', '${m.group(1)} has', "${m.group(1)}'s"]
        else
          ['${m.group(2)} would', '${m.group(2)} had'],
    ];

    final resultats = <String>{};
    for (final combinaison in _produitCartesien(optionsParOccurrence)) {
      final buffer = StringBuffer();
      var dernierePosition = 0;
      for (var i = 0; i < correspondances.length; i++) {
        buffer.write(texte.substring(dernierePosition, correspondances[i].start));
        buffer.write(combinaison[i]);
        dernierePosition = correspondances[i].end;
      }
      buffer.write(texte.substring(dernierePosition));
      resultats.add(buffer.toString());
    }
    return resultats;
  }

  static Iterable<List<String>> _produitCartesien(List<List<String>> listes) {
    Iterable<List<String>> aux(int i) {
      if (i == listes.length) return [<String>[]];
      return [
        for (final suite in aux(i + 1))
          for (final choix in listes[i]) [choix, ...suite],
      ];
    }
    return aux(0);
  }

  /// Toutes les variantes possibles d'un texte (après nettoyage de base,
  /// en minuscules, et expansion de toutes les formes contractées).
  static Set<String> _toutesLesVariantes(String texteBrut) {
    final nettoye = _nettoyerBase(texteBrut).toLowerCase();
    final apresFixes = _appliquerContractionsFixes(nettoye);
    final apresSuffixes = _appliquerSuffixesSansAmbiguite(apresFixes);
    final variantes = _developperAmbigus(apresSuffixes);
    return {
      for (final v in variantes) v.replaceAll(RegExp(r'\s+'), ' ').trim(),
    };
  }

  // -------------------------------------------------------------------
  // Petite faute de frappe : même nombre de mots, un seul mot différent,
  // et ce mot ne diffère que d'une lettre (distance de Levenshtein = 1),
  // sur un mot de référence de plus de 4 lettres.
  // -------------------------------------------------------------------
  static String? _motProcheMaisDifferent(String saisieBase, String reponseBase) {
    final motsSaisie = saisieBase.split(' ');
    final motsReponse = reponseBase.split(' ');
    if (motsSaisie.length != motsReponse.length) return null;

    var indexDifferent = -1;
    var nombreDifferences = 0;
    for (var i = 0; i < motsReponse.length; i++) {
      if (motsSaisie[i] != motsReponse[i]) {
        nombreDifferences++;
        indexDifferent = i;
        if (nombreDifferences > 1) return null;
      }
    }
    if (nombreDifferences != 1) return null;

    final motAttendu = motsReponse[indexDifferent];
    final motSaisi = motsSaisie[indexDifferent];
    if (motAttendu.length <= 4) return null;
    if (_distanceLevenshtein(motSaisi, motAttendu) != 1) return null;

    return motAttendu;
  }

  static int _distanceLevenshtein(String a, String b) {
    if (a == b) return 0;
    final m = a.length;
    final n = b.length;
    if (m == 0) return n;
    if (n == 0) return m;

    var precedente = List<int>.generate(n + 1, (j) => j);
    for (var i = 1; i <= m; i++) {
      final courante = List<int>.filled(n + 1, 0);
      courante[0] = i;
      for (var j = 1; j <= n; j++) {
        final cout = a[i - 1] == b[j - 1] ? 0 : 1;
        courante[j] = [
          precedente[j] + 1, // suppression
          courante[j - 1] + 1, // insertion
          precedente[j - 1] + cout, // substitution
        ].reduce((x, y) => x < y ? x : y);
      }
      precedente = courante;
    }
    return precedente[n];
  }

  // -------------------------------------------------------------------
  // Conseil de majuscule : nationalités, langues, jours et mois prennent
  // une majuscule en anglais (pas en français).
  // -------------------------------------------------------------------
  static const Map<String, String> _motsAvecMajuscule = {
    'french': 'nationalités et langues',
    'italian': 'nationalités et langues',
    'english': 'nationalités et langues',
    'spanish': 'nationalités et langues',
    'german': 'nationalités et langues',
    'american': 'nationalités et langues',
    'british': 'nationalités et langues',
    'chinese': 'nationalités et langues',
    'japanese': 'nationalités et langues',
    'portuguese': 'nationalités et langues',
    'russian': 'nationalités et langues',
    'irish': 'nationalités et langues',
    'scottish': 'nationalités et langues',
    'welsh': 'nationalités et langues',
    'canadian': 'nationalités et langues',
    'australian': 'nationalités et langues',
    'belgian': 'nationalités et langues',
    'swiss': 'nationalités et langues',
    'monday': 'jours',
    'tuesday': 'jours',
    'wednesday': 'jours',
    'thursday': 'jours',
    'friday': 'jours',
    'saturday': 'jours',
    'sunday': 'jours',
    'january': 'mois',
    'february': 'mois',
    'march': 'mois',
    'april': 'mois',
    'june': 'mois',
    'july': 'mois',
    'august': 'mois',
    'september': 'mois',
    'october': 'mois',
    'november': 'mois',
    'december': 'mois',
  };

  static String? _conseilMajuscule(String reponseReference, String saisieBrute) {
    final motsReference = RegExp("[A-Za-zÀ-ÿ']+").allMatches(reponseReference);
    for (final m in motsReference) {
      final mot = m.group(0)!;
      final motMinuscule = mot.toLowerCase();
      final categorie = _motsAvecMajuscule[motMinuscule];
      if (categorie == null) continue;
      if (!_estMajuscule(mot)) continue; // le mot de référence n'est pas capitalisé : rien à vérifier

      final matchSaisie = RegExp('\\b$motMinuscule\\b', caseSensitive: false).firstMatch(saisieBrute);
      if (matchSaisie == null) continue;
      final motSaisi = matchSaisie.group(0)!;
      if (!_estMajuscule(motSaisi)) {
        final motAvecMajuscule = mot[0].toUpperCase() + mot.substring(1);
        return 'Juste ! En anglais, les $categorie prennent une majuscule : $motAvecMajuscule.';
      }
    }
    return null;
  }

  static bool _estMajuscule(String mot) =>
      mot.isNotEmpty && mot[0] != mot[0].toLowerCase();
}
