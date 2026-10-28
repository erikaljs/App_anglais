// Outil de conversion : transforme le tableur de vocabulaire
// (donnees/vocabulaire-anglais-A1-B2.xlsx) en fichiers JSON utilisés par
// l'application (assets/contenu/*.json). Voir CLAUDE.md pour le format.
//
// À lancer depuis la racine du projet avec :
//   dart run outils/convertir_vocabulaire.dart
//
// À relancer chaque fois que le tableur de vocabulaire change.

import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';

const _cheminSource = 'donnees/vocabulaire-anglais-A1-B2.xlsx';
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
  final fichier = File(_cheminSource);
  if (!fichier.existsSync()) {
    stderr.writeln('Fichier introuvable : $_cheminSource');
    exit(1);
  }

  final classeur = Excel.decodeBytes(fichier.readAsBytesSync());
  final feuille = classeur.tables['Tout le vocabulaire'];
  if (feuille == null) {
    stderr.writeln('Onglet "Tout le vocabulaire" introuvable.');
    exit(1);
  }

  // On regroupe les mots par catégorie d'appli, puis par module : chaque
  // module devient une leçon (ses cartes = les mots de ce module).
  final motsParCategorieEtModule = <String, Map<int, List<_Mot>>>{};
  final titreDuModule = <String, Map<int, String>>{};
  final niveauDuModule = <String, Map<int, String>>{};

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
            for (final mot in modules[module]!)
              {'en': mot.en, 'fr': mot.fr},
          ],
          'phrases': <Map<String, dynamic>>[],
          'miniLecon': null,
        },
    ];

    final nombreDeMots = modules.values.fold(0, (s, l) => s + l.length);
    final contenu = {'id': id, 'nom': nom, 'lecons': lecons};
    File('$_dossierSortie/$id.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(contenu),
      encoding: utf8,
    );
    print(
      '✓ $_dossierSortie/$id.json : ${lecons.length} leçon(s), $nombreDeMots mots',
    );
  });
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
