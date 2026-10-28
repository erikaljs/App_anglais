import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Enregistre et lit la progression de l'utilisateur dans les leçons
/// (collection users/{uid}/progress, voir CLAUDE.md).
class ProgressService {
  ProgressService._();

  static final _db = FirebaseFirestore.instance;

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static CollectionReference<Map<String, dynamic>> get _progressionsRef =>
      _db.collection('users').doc(_uid).collection('progress');

  /// Toutes les progressions de l'utilisateur, en direct : utilisé pour
  /// calculer les barres de progression sur la Home.
  static Stream<QuerySnapshot<Map<String, dynamic>>> toutesLesProgressions() {
    return _progressionsRef.snapshots();
  }

  /// Enregistre le résultat d'un exercice (cartes, phrases ou mini-leçon),
  /// pour une leçon officielle ou un paquet perso.
  ///
  /// [score] est le pourcentage de réussite (0 à 100). C'est "terminé" si
  /// tout était réussi, sinon "en cours" (l'utilisateur pourra refaire
  /// l'exercice plus tard).
  static Future<void> enregistrerResultatLecon({
    required String leconId,
    required int score,
    String type = 'lecon',
  }) {
    return _progressionsRef.doc(leconId).set({
      'type': type,
      'refId': leconId,
      'statut': score >= 100 ? 'terminee' : 'en_cours',
      'score': score,
      'derniereFois': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
