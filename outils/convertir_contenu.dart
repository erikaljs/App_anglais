// Outil de conversion : transforme les deux sources de contenu
// (donnees/vocabulaire-anglais-A1-B2.xlsx et donnees/cours.md) en
// fichiers JSON utilisés par l'application (assets/contenu/*.json).
// Voir CLAUDE.md pour le format visé.
//
// À lancer depuis la racine du projet avec :
//   dart run outils/convertir_contenu.dart
//
// À relancer chaque fois que l'une des deux sources change.

import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';

const _cheminVocabulaire = 'donnees/vocabulaire-anglais-A1-B2.xlsx';
const _cheminCours = 'donnees/cours.md';
const _dossierSortie = 'assets/contenu';

/// Associe chaque valeur de la colonne "Catégorie appli" du tableur à
/// l'identifiant et au nom utilisés dans l'application. "Général" n'est
/// pas une catégorie de l'appli (Perso et Jeux n'ont pas de vocabulaire
/// dans ce tableur) : on l'ignore.
const _categories = {
  'Débutant': ('debutant', 'Débutant'),
  'Voyage': ('voyage', 'Voyage'),
  'Sport': ('sport', 'Sport'),
  'Technique': ('technique', 'Technique'),
};

void main() {
  final motsParCategorieEtModule = <String, Map<int, List<_Mot>>>{};
  final titreDuModule = <String, Map<int, String>>{};
  final niveauDuModule = <String, Map<int, String>>{};
  _lireVocabulaire(motsParCategorieEtModule, titreDuModule, niveauDuModule);

  final phrasesParModule = _lireCours();

  Directory(_dossierSortie).createSync(recursive: true);

  _categories.forEach((categorieAppli, info) {
    final (id, nom) = info;
    final modules = motsParCategorieEtModule[categorieAppli] ?? {};
    final numerosDeModule = modules.keys.toList()..sort();

    final lecons = [
      for (final module in numerosDeModule)
        {
          'id': '$id-module-$module',
          'titre': titreDuModule[categorieAppli]![module],
          'niveau': niveauDuModule[categorieAppli]![module],
          'cartes': [
            for (final mot in modules[module]!) {'en': mot.en, 'fr': mot.fr},
          ],
          'phrases': phrasesParModule[module] ?? const [],
          // Les mini-leçons ne sont écrites (à la main) que pour Débutant.
          'miniLecon': id == 'debutant' ? _miniLeconsDebutant[module] : null,
        },
    ];

    final nombreDeMots = modules.values.fold(0, (s, l) => s + l.length);
    final nombreDePhrases = lecons.fold<int>(
      0,
      (s, l) => s + (l['phrases'] as List).length,
    );
    final contenu = {'id': id, 'nom': nom, 'lecons': lecons};
    File('$_dossierSortie/$id.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(contenu),
      encoding: utf8,
    );
    print(
      '✓ $_dossierSortie/$id.json : ${lecons.length} leçon(s), '
      '$nombreDeMots mots, $nombreDePhrases phrases',
    );
  });
}

// ---------------------------------------------------------------------------
// Lecture du tableur de vocabulaire
// ---------------------------------------------------------------------------

void _lireVocabulaire(
  Map<String, Map<int, List<_Mot>>> motsParCategorieEtModule,
  Map<String, Map<int, String>> titreDuModule,
  Map<String, Map<int, String>> niveauDuModule,
) {
  final fichier = File(_cheminVocabulaire);
  if (!fichier.existsSync()) {
    stderr.writeln('Fichier introuvable : $_cheminVocabulaire');
    exit(1);
  }

  final classeur = Excel.decodeBytes(fichier.readAsBytesSync());
  final feuille = classeur.tables['Tout le vocabulaire'];
  if (feuille == null) {
    stderr.writeln('Onglet "Tout le vocabulaire" introuvable.');
    exit(1);
  }

  var numeroLigne = 0;
  for (final rangee in feuille.rows) {
    numeroLigne++;
    if (numeroLigne == 1) continue; // ligne d'en-tête

    final niveau = _texte(rangee.elementAtOrNull(1));
    final module = _entier(rangee.elementAtOrNull(2));
    final theme = _texte(rangee.elementAtOrNull(3));
    final anglais = _texte(rangee.elementAtOrNull(4));
    final francais = _texte(rangee.elementAtOrNull(5));
    final categorieAppli = _texte(rangee.elementAtOrNull(7));

    if (anglais.isEmpty || francais.isEmpty) continue;

    motsParCategorieEtModule
        .putIfAbsent(categorieAppli, () => {})
        .putIfAbsent(module, () => [])
        .add(_Mot(anglais, francais));
    titreDuModule.putIfAbsent(categorieAppli, () => {})[module] = theme;
    niveauDuModule.putIfAbsent(categorieAppli, () => {})[module] = niveau;
  }
}

String _texte(Data? cellule) => cellule?.value?.toString().trim() ?? '';

int _entier(Data? cellule) {
  final valeur = cellule?.value;
  if (valeur is IntCellValue) return valeur.value;
  if (valeur is DoubleCellValue) return valeur.value.round();
  return int.tryParse(valeur?.toString() ?? '') ?? 0;
}

class _Mot {
  _Mot(this.en, this.fr);
  final String en;
  final String fr;
}

// ---------------------------------------------------------------------------
// Lecture des cours (phrases à traduire)
// ---------------------------------------------------------------------------

/// Cherche, dans chaque module de cours.md, l'exercice "Traduis : a) ... b)
/// ... c) ... d) ..." et sa correction, pour en faire 4 phrases à traduire
/// (français → anglais). Certains modules n'ont pas cet exercice (ex :
/// module 16, qui porte sur le discours indirect) : ils n'auront pas de
/// phrases, ce n'est pas une erreur.
Map<int, List<Map<String, dynamic>>> _lireCours() {
  final resultat = <int, List<Map<String, dynamic>>>{};

  final fichier = File(_cheminCours);
  if (!fichier.existsSync()) {
    stderr.writeln(
      '$_cheminCours introuvable : aucune phrase ne sera générée.',
    );
    return resultat;
  }
  final texte = fichier.readAsStringSync();

  final regexModule = RegExp(r'^## Module (\d+) — .+$', multiLine: true);
  final entetes = regexModule.allMatches(texte).toList();

  for (var i = 0; i < entetes.length; i++) {
    final numeroModule = int.parse(entetes[i].group(1)!);
    final debutBloc = entetes[i].end;
    final finBloc = i + 1 < entetes.length
        ? entetes[i + 1].start
        : texte.length;
    final bloc = texte.substring(debutBloc, finBloc);

    final idxExercices = bloc.indexOf('### Exercices');
    final idxCorrige = bloc.indexOf('### Corrigé');
    if (idxExercices == -1 || idxCorrige == -1) continue;

    final texteExercices = bloc.substring(idxExercices, idxCorrige);
    final finCorrige = bloc.indexOf('\n### ', idxCorrige + 1);
    final texteCorrige = bloc.substring(
      idxCorrige,
      finCorrige == -1 ? bloc.length : finCorrige,
    );

    final matchTraduis = RegExp(
      r'^(\d+)\.\s*Traduis\b.*?:\s*(.+)$',
      multiLine: true,
    ).firstMatch(texteExercices);
    if (matchTraduis == null) continue;

    final numeroExercice = matchTraduis.group(1)!;
    final phrasesFr = _decouperEnQuatre(matchTraduis.group(2)!);

    final matchCorrige = RegExp(
      '^$numeroExercice\\.\\s*(.+)\$',
      multiLine: true,
    ).firstMatch(texteCorrige);
    if (matchCorrige == null) continue;
    final reponsesEn = _decouperEnQuatre(matchCorrige.group(1)!);

    if (phrasesFr.length != 4 || reponsesEn.length != 4) continue;

    resultat[numeroModule] = [
      for (var j = 0; j < 4; j++)
        {'fr': phrasesFr[j], 'en': _variantesAcceptables(reponsesEn[j])},
    ];
  }

  return resultat;
}

/// Découpe un texte "a) xxx b) yyy c) zzz d) www" en 4 morceaux. Renvoie
/// une liste vide si le format ne correspond pas (on ignore alors cette
/// phrase plutôt que de générer n'importe quoi).
List<String> _decouperEnQuatre(String texte) {
  const marqueurs = ['a) ', 'b) ', 'c) ', 'd) '];
  final positions = <int>[];
  var curseur = 0;
  for (final marqueur in marqueurs) {
    final position = texte.indexOf(marqueur, curseur);
    if (position == -1) return const [];
    positions.add(position);
    curseur = position + marqueur.length;
  }
  return [
    for (var i = 0; i < positions.length; i++)
      texte
          .substring(
            positions[i] + marqueurs[i].length,
            i + 1 < positions.length ? positions[i + 1] : texte.length,
          )
          .trim(),
  ];
}

/// À partir d'une réponse du corrigé, extrait toutes les traductions
/// acceptées : les alternatives "(ou *...*)" et celles séparées par " / ".
List<String> _variantesAcceptables(String reponse) {
  var texte = reponse.trim();

  final regexOu = RegExp(r'\(ou\s*\*?([^)*]+)\*?\)');
  final alternativesOu = [
    for (final m in regexOu.allMatches(texte)) m.group(1)!.trim(),
  ];
  texte = texte.replaceAll(regexOu, '').trim();

  final variantes = [
    ...texte.split(' / ').map((s) => s.trim()),
    ...alternativesOu,
  ];

  return variantes
      .map((v) => v.replaceAll('*', '').trim())
      .where((v) => v.isNotEmpty)
      .toSet()
      .toList();
}

// ---------------------------------------------------------------------------
// Mini-leçons de la catégorie Débutant (écrites à la main à partir de
// cours.md : règle courte + exemples + QCM). Clé = numéro de module.
// ---------------------------------------------------------------------------

final Map<int, Map<String, dynamic>> _miniLeconsDebutant = {
  1: {
    'regle':
        'Le verbe "to be" (être) sert à dire qui tu es, ton âge, ta '
        'nationalité et ton métier : I am (I\'m), you are (you\'re), '
        'he/she/it is (\'s), we/they are (\'re).',
    'exemples': ["I'm Erika. I'm 21.", "She's French.", 'Are you a student? — Yes, I am.'],
    'qcm': [
      {
        'question': 'Comment dit-on « Je suis fatiguée » ?',
        'choix': ['I am tired', 'I is tired', 'I are tired'],
        'bonneReponseIndex': 0,
      },
      {
        'question': 'Comment dit-on « Il est ingénieur » ?',
        'choix': ['He is engineer', 'He is an engineer', 'He am an engineer'],
        'bonneReponseIndex': 1,
      },
      {
        'question': 'Quelle est la forme courte de "they are" ?',
        'choix': ["they's", "they're", "they'is"],
        'bonneReponseIndex': 1,
      },
      {
        'question': 'Comment pose-t-on la question « Es-tu étudiant ? » ?',
        'choix': ['You are a student?', 'Is you a student?', 'Are you a student?'],
        'bonneReponseIndex': 2,
      },
    ],
  },
  2: {
    'regle':
        'Le présent simple sert pour les habitudes et les vérités '
        'générales. Avec he/she/it, on ajoute "-s" au verbe à '
        'l\'affirmatif (she works), mais le verbe reste nu avec '
        'does/doesn\'t (she doesn\'t work, does she work?).',
    'exemples': ['I get up at 7 a.m.', "He doesn't drink coffee.", 'Do you live in Bordeaux? — Yes, I do.'],
    'qcm': [
      {
        'question': 'Complète : "She ___ TV every evening."',
        'choix': ['watch', 'watches', 'is watching'],
        'bonneReponseIndex': 1,
      },
      {
        'question': 'Comment dit-on « Il ne boit pas de café » ?',
        'choix': ["He don't drinks coffee", "He doesn't drink coffee", 'He not drink coffee'],
        'bonneReponseIndex': 1,
      },
      {
        'question': 'Où placer "always" dans "I am late" ?',
        'choix': ["I'm always late", "I always am late", "Always I'm late"],
        'bonneReponseIndex': 0,
      },
      {
        'question': 'Quelle préposition pour un jour précis : "___ Monday" ?',
        'choix': ['at', 'in', 'on'],
        'bonneReponseIndex': 2,
      },
    ],
  },
  3: {
    'regle':
        '"There is" + singulier, "there are" + pluriel, pour dire qu\'il '
        'y a quelque chose. On utilise "some" à l\'affirmatif et "any" '
        'au négatif ou à la question.',
    'exemples': ['There is a park near my house.', "There aren't any buses.", 'Are there any restaurants?'],
    'qcm': [
      {
        'question': '"___ a supermarket near here."',
        'choix': ['There is', 'There are', 'Is there'],
        'bonneReponseIndex': 0,
      },
      {
        'question': '"___ three bedrooms."',
        'choix': ['There is', 'There are', 'Are there'],
        'bonneReponseIndex': 1,
      },
      {
        'question': 'Comment dit-on « sous le livre » ?',
        'choix': ['on the book', 'under the book', 'between the book'],
        'bonneReponseIndex': 1,
      },
      {
        'question': '"The cat eats ___ food." (son, sa, à lui/elle pour une chose)',
        'choix': ["it's", 'its', 'his'],
        'bonneReponseIndex': 1,
      },
    ],
  },
  4: {
    'regle':
        'Le présent continu ("be" + verbe-ing) sert pour une action en '
        'train de se faire maintenant, ou une situation temporaire.',
    'exemples': ["I'm working.", 'Are you coming?', "It's raining."],
    'qcm': [
      {
        'question': 'Complète : "Look! It ___ (snow)."',
        'choix': ['snows', 'is snowing', 'snow'],
        'bonneReponseIndex': 1,
      },
      {
        'question': 'Quel verbe ne va presque jamais au présent continu ?',
        'choix': ['run', 'know', 'eat'],
        'bonneReponseIndex': 1,
      },
      {
        'question': 'Ce que TU ressens se dit avec quelle terminaison ?',
        'choix': ['-ing (ex : boring)', '-ed (ex : bored)', '-s (ex : bores)'],
        'bonneReponseIndex': 1,
      },
      {
        'question': 'Comment dit-on « Qu\'est-ce que tu fais ce soir ? » ?',
        'choix': ['What do you do tonight?', 'What you are doing tonight?', 'What are you doing tonight?'],
        'bonneReponseIndex': 2,
      },
    ],
  },
  5: {
    'regle':
        'Pour raconter le passé : "was/were" pour "être", et "-ed" pour '
        'les verbes réguliers (même forme à toutes les personnes). '
        'Négatif et question avec "did" + verbe nu.',
    'exemples': ['I was tired.', 'I visited Rome.', 'Did you call your mother?'],
    'qcm': [
      {
        'question': 'Complète : "I ___ (go) to Paris last weekend."',
        'choix': ['goed', 'went', 'go'],
        'bonneReponseIndex': 1,
      },
      {
        'question': 'Comment former le négatif au passé ?',
        'choix': ["didn't + verbe nu", "not + verbe-ed", "didn't + verbe-ed"],
        'bonneReponseIndex': 0,
      },
      {
        'question': 'Où placer "ago" ("il y a") ?',
        'choix': ['avant la durée : ago three years', 'après la durée : three years ago'],
        'bonneReponseIndex': 1,
      },
      {
        'question': 'Complète : "Where ___ you yesterday?"',
        'choix': ['was', 'were', 'are'],
        'bonneReponseIndex': 1,
      },
    ],
  },
  7: {
    'regle':
        'Pour comparer : adjectif court + "-er" (faster), adjectif long + '
        '"more" (more expensive), irréguliers (better, worse). Pour '
        'conseiller : "should" ; "mustn\'t" = interdit ; "don\'t have to" '
        '= pas obligé.',
    'exemples': ['This laptop is lighter than mine.', 'You should drink more water.', "You don't have to come."],
    'qcm': [
      {
        'question': 'Complète : "A plane is ___ (fast) than a train."',
        'choix': ['more fast', 'faster', 'fastest'],
        'bonneReponseIndex': 1,
      },
      {
        'question': 'Complète : "It\'s ___ (expensive) hotel in the city."',
        'choix': ['the expensivest', 'more expensive', 'the most expensive'],
        'bonneReponseIndex': 2,
      },
      {
        'question': '"mustn\'t" veut dire :',
        'choix': ['interdit', 'pas obligé', 'conseillé'],
        'bonneReponseIndex': 0,
      },
      {
        'question': 'Comment dit-on « Tu devrais faire du sport » ?',
        'choix': ['You must do some sport', 'You can do some sport', 'You should do some sport'],
        'bonneReponseIndex': 2,
      },
    ],
  },
};
