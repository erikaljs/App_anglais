import 'dart:convert';

import 'package:flutter/services.dart';

import '../modeles/contenu.dart';

/// Charge le contenu des leçons depuis les fichiers JSON embarqués dans
/// l'appli (assets/contenu/), générés par outils/convertir_vocabulaire.dart.
class ContenuService {
  ContenuService._();

  /// Les catégories qui ont du vocabulaire (Perso et Jeux n'en ont pas :
  /// Perso vient des paquets de l'utilisateur, Jeux n'a pas de leçons).
  static const idsCategories = ['debutant', 'voyage', 'sport', 'technique'];

  static final Map<String, Categorie> _dejaChargees = {};

  /// Charge une catégorie (depuis le cache si on l'a déjà lue).
  static Future<Categorie> charger(String idCategorie) async {
    final dejaEnCache = _dejaChargees[idCategorie];
    if (dejaEnCache != null) return dejaEnCache;

    final texte = await rootBundle.loadString(
      'assets/contenu/$idCategorie.json',
    );
    final categorie = Categorie.fromJson(
      jsonDecode(texte) as Map<String, dynamic>,
    );
    _dejaChargees[idCategorie] = categorie;
    return categorie;
  }

  /// Charge toutes les catégories de vocabulaire d'un coup (utile pour la Home).
  static Future<List<Categorie>> chargerToutes() async {
    return [for (final id in idsCategories) await charger(id)];
  }
}
