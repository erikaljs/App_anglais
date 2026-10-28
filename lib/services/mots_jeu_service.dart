import 'dart:math';

import '../modeles/grille_mots.dart';
import 'contenu_service.dart';

/// Fabrique les grilles du jeu Words à partir du vocabulaire déjà
/// embarqué dans l'appli (assets/contenu/) : pas besoin d'une liste de
/// mots séparée.
class MotsJeuService {
  MotsJeuService._();

  /// Les catégories de contenu qui composent chaque thème du jeu.
  static const _categoriesParTheme = {
    'sport': ['sport'],
    'voyage': ['voyage'],
    'technique': ['technique'],
    'melange': ['sport', 'voyage', 'technique'],
  };

  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  static final Map<String, List<(String, String)>> _cacheMots = {};

  /// Les mots utilisables pour un thème : anglais en majuscules (une
  /// seule "mot", 3 à 10 lettres, sans espace ni apostrophe, pour tenir
  /// sur la grille) et leur traduction française.
  static Future<List<(String, String)>> _motsDuTheme(String theme) async {
    final dejaEnCache = _cacheMots[theme];
    if (dejaEnCache != null) return dejaEnCache;

    final categories = _categoriesParTheme[theme] ?? const ['sport'];
    final motsVus = <String>{};
    final mots = <(String, String)>[];
    for (final idCategorie in categories) {
      final categorie = await ContenuService.charger(idCategorie);
      for (final lecon in categorie.lecons) {
        for (final carte in lecon.cartes) {
          final mot = carte.en.toUpperCase();
          if (RegExp(r'^[A-Z]{3,10}$').hasMatch(mot) && motsVus.add(mot)) {
            mots.add((mot, carte.fr));
          }
        }
      }
    }
    _cacheMots[theme] = mots;
    return mots;
  }

  /// Génère une grille pour un thème donné, avec un mot choisi au hasard.
  static Future<GrilleMots> genererGrille(String theme) async {
    final mots = List.of(await _motsDuTheme(theme))..shuffle();
    if (mots.isEmpty) {
      throw Exception('Aucun mot disponible pour le thème "$theme".');
    }
    final (mot, traduction) = mots.first;
    return _construireGrille(mot, traduction);
  }

  /// Plusieurs grilles d'un coup (une manche de jeu), avec des mots
  /// différents entre eux si possible.
  static Future<List<GrilleMots>> genererManche(String theme, int nombreDeMots) async {
    final mots = List.of(await _motsDuTheme(theme))..shuffle();
    final choisis = mots.take(nombreDeMots).toList();
    return [for (final (mot, traduction) in choisis) _construireGrille(mot, traduction)];
  }

  static GrilleMots _construireGrille(String mot, String traduction) {
    final hasard = Random();
    final cellules = List<String>.filled(16, '');
    final indicesDisponibles = List.generate(16, (i) => i)..shuffle(hasard);

    for (var i = 0; i < mot.length; i++) {
      cellules[indicesDisponibles[i]] = mot[i];
    }
    for (var i = mot.length; i < 16; i++) {
      cellules[indicesDisponibles[i]] = _alphabet[hasard.nextInt(_alphabet.length)];
    }

    return GrilleMots(lettres: cellules, motCible: mot, traduction: traduction);
  }
}
