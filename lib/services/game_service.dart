import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../modeles/grille_mots.dart';
import 'memory_jeu_service.dart';
import 'mots_jeu_service.dart';

/// Nombre de mots à trouver par manche, en duel Words.
const nombreDeMotsParManche = 5;

/// Nombre de paires, en duel Memory.
const nombreDePairesDuel = 8;

/// Gère les parties entre amis (collection games, voir CLAUDE.md) :
/// Words (duel en 2 manches, tour par tour) et Memory (duel à distance,
/// même grille pour les deux, gagnant au temps/aux coups).
class GameService {
  GameService._();

  static final _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _parties =>
      _db.collection('games');

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  /// Mes parties (Words et Memory), en direct.
  static Stream<QuerySnapshot<Map<String, dynamic>>> mesParties() {
    return _parties.where('joueurs', arrayContains: _uid).snapshots();
  }

  // -------------------------------------------------------------------
  // Words : duel en 2 manches, les joueurs jouent chacun leur tour.
  // -------------------------------------------------------------------

  static Future<String> creerDuelWords({
    required String adversaireUid,
    required String theme,
    required int minuteurSecondes,
  }) async {
    final grillesManche1 = await MotsJeuService.genererManche(theme, nombreDeMotsParManche);
    final grillesManche2 = await MotsJeuService.genererManche(theme, nombreDeMotsParManche);

    final document = await _parties.add({
      'jeu': 'words',
      'joueurs': [_uid, adversaireUid],
      'theme': theme,
      'minuteur': minuteurSecondes,
      'manche': 1,
      'statut': 'en_cours',
      'tourDe': _uid,
      'grilles': {
        '1': [for (final g in grillesManche1) g.versJson()],
        '2': [for (final g in grillesManche2) g.versJson()],
      },
      'scores': {_uid: {}},
      'misAJourLe': FieldValue.serverTimestamp(),
    });
    return document.id;
  }

  /// Les grilles de la manche en cours pour MOI (celles que je dois jouer).
  static List<GrilleMots> grillesDeLaManche(
    Map<String, dynamic> partie,
    int manche,
  ) {
    final grilles = (partie['grilles'] as Map<String, dynamic>)['$manche'] as List;
    return [for (final g in grilles) GrilleMots.fromJson(g as Map<String, dynamic>)];
  }

  /// J'ai terminé une manche : j'enregistre mon score, et je passe la
  /// main à l'autre joueur si j'ai fini mes deux manches.
  static Future<void> enregistrerMancheWords({
    required String idPartie,
    required int manche,
    required int score,
  }) async {
    final document = await _parties.doc(idPartie).get();
    final donnees = document.data()!;
    final joueurs = List<String>.from(donnees['joueurs'] as List);
    final autreUid = joueurs.firstWhere((u) => u != _uid);

    final scores = Map<String, dynamic>.from(donnees['scores'] as Map? ?? {});
    final mesScores = Map<String, dynamic>.from(scores[_uid] as Map? ?? {});
    mesScores['manche$manche'] = score;
    scores[_uid] = mesScores;

    final maj = <String, dynamic>{
      'scores': scores,
      'misAJourLe': FieldValue.serverTimestamp(),
    };

    if (manche == 1) {
      maj['manche'] = 2; // je continue avec ma deuxième manche
    } else {
      final scoresAutre = Map<String, dynamic>.from(scores[autreUid] as Map? ?? {});
      final autreATermineSesDeuxManches =
          scoresAutre.containsKey('manche1') && scoresAutre.containsKey('manche2');
      if (autreATermineSesDeuxManches) {
        maj['statut'] = 'terminee';
      } else {
        maj['tourDe'] = autreUid;
        maj['manche'] = 1;
      }
    }

    await _parties.doc(idPartie).update(maj);
  }

  /// Le score total (2 manches) d'un joueur, ou null s'il n'a pas fini.
  static int? scoreTotalWords(Map<String, dynamic> partie, String uidJoueur) {
    final scores = Map<String, dynamic>.from(partie['scores'] as Map? ?? {});
    final mesScores = Map<String, dynamic>.from(scores[uidJoueur] as Map? ?? {});
    if (!mesScores.containsKey('manche1') || !mesScores.containsKey('manche2')) {
      return null;
    }
    return (mesScores['manche1'] as int) + (mesScores['manche2'] as int);
  }

  // -------------------------------------------------------------------
  // Memory : même grille pour les deux, chacun joue à son rythme.
  // -------------------------------------------------------------------

  static Future<String> creerDuelMemory({
    required String adversaireUid,
    required String theme,
  }) async {
    final cartes = await MemoryJeuService.genererGrille(theme, nombreDePaires: nombreDePairesDuel);

    final document = await _parties.add({
      'jeu': 'memory',
      'joueurs': [_uid, adversaireUid],
      'theme': theme,
      'statut': 'en_cours',
      'grilles': {
        'partagee': [for (final c in cartes) c.versJson()],
      },
      'scores': <String, dynamic>{},
      'misAJourLe': FieldValue.serverTimestamp(),
    });
    return document.id;
  }

  static List<CarteMemory> grilleMemoryPartagee(Map<String, dynamic> partie) {
    final cartes = (partie['grilles'] as Map<String, dynamic>)['partagee'] as List;
    return [for (final c in cartes) CarteMemory.fromJson(c as Map<String, dynamic>)];
  }

  static Future<void> enregistrerResultatMemory({
    required String idPartie,
    required int tempsSecondes,
    required int coups,
  }) async {
    final document = await _parties.doc(idPartie).get();
    final donnees = document.data()!;
    final scores = Map<String, dynamic>.from(donnees['scores'] as Map? ?? {});
    scores[_uid] = {'temps': tempsSecondes, 'coups': coups};

    await _parties.doc(idPartie).update({
      'scores': scores,
      'statut': scores.length >= 2 ? 'terminee' : 'en_attente',
      'misAJourLe': FieldValue.serverTimestamp(),
    });
  }

  /// Le gagnant d'un duel Memory terminé : le temps le plus court, et en
  /// cas d'égalité le moins de coups. Null si pas encore terminé.
  static String? gagnantMemory(Map<String, dynamic> partie) {
    final scores = Map<String, dynamic>.from(partie['scores'] as Map? ?? {});
    if (scores.length < 2) return null;
    final entrees = scores.entries.toList();
    entrees.sort((a, b) {
      final tempsA = (a.value as Map)['temps'] as int;
      final tempsB = (b.value as Map)['temps'] as int;
      if (tempsA != tempsB) return tempsA.compareTo(tempsB);
      final coupsA = (a.value as Map)['coups'] as int;
      final coupsB = (b.value as Map)['coups'] as int;
      return coupsA.compareTo(coupsB);
    });
    return entrees.first.key;
  }

  static bool aiDejaJoueMemory(Map<String, dynamic> partie) {
    final scores = Map<String, dynamic>.from(partie['scores'] as Map? ?? {});
    return scores.containsKey(_uid);
  }
}
