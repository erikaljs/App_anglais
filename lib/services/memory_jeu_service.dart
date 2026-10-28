import 'dart:math';

import 'contenu_service.dart';

/// Une carte du jeu Memory : un texte affiché (anglais ou français) et
/// l'identifiant de la paire à laquelle elle appartient.
class CarteMemory {
  const CarteMemory({required this.texte, required this.idPaire});

  final String texte;
  final String idPaire;

  factory CarteMemory.fromJson(Map<String, dynamic> json) {
    return CarteMemory(texte: json['texte'] as String, idPaire: json['idPaire'] as String);
  }

  Map<String, dynamic> versJson() => {'texte': texte, 'idPaire': idPaire};
}

/// Fabrique les grilles du jeu Memory (paires mot anglais / traduction
/// française) à partir du vocabulaire déjà embarqué dans l'appli.
class MemoryJeuService {
  MemoryJeuService._();

  static const _categoriesParTheme = {
    'sport': ['sport'],
    'voyage': ['voyage'],
    'technique': ['technique'],
    'melange': ['sport', 'voyage', 'technique'],
  };

  /// Génère [nombreDePaires] paires (donc 2x ce nombre de cartes),
  /// mélangées, pour un thème donné.
  static Future<List<CarteMemory>> genererGrille(
    String theme, {
    int nombreDePaires = 8,
  }) async {
    final categories = _categoriesParTheme[theme] ?? const ['sport'];
    final motsVus = <String>{};
    final mots = <(String, String)>[]; // (anglais, français)

    for (final idCategorie in categories) {
      final categorie = await ContenuService.charger(idCategorie);
      for (final lecon in categorie.lecons) {
        for (final carte in lecon.cartes) {
          if (motsVus.add(carte.en)) {
            mots.add((carte.en, carte.fr));
          }
        }
      }
    }

    mots.shuffle();
    final choisis = mots.take(nombreDePaires).toList();

    final cartes = <CarteMemory>[];
    for (var i = 0; i < choisis.length; i++) {
      final idPaire = 'paire$i';
      cartes.add(CarteMemory(texte: choisis[i].$1, idPaire: idPaire));
      cartes.add(CarteMemory(texte: choisis[i].$2, idPaire: idPaire));
    }
    cartes.shuffle(Random());
    return cartes;
  }
}
