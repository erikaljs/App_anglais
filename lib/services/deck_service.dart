import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../modeles/deck.dart';

/// Tout ce qui concerne les paquets perso : les siens (créer, modifier,
/// supprimer), ceux des amis (suivre, copier). Voir CLAUDE.md pour le
/// détail des collections (decks, decksSuivis).
class DeckService {
  DeckService._();

  static final _db = FirebaseFirestore.instance;

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static CollectionReference<Map<String, dynamic>> _decksDe(String uid) =>
      _db.collection('users').doc(uid).collection('decks');

  static CollectionReference<Map<String, dynamic>> get _mesDecksSuivis =>
      _db.collection('users').doc(_uid).collection('decksSuivis');

  /// Mes propres paquets, en direct.
  static Stream<List<Deck>> mesPaquets() {
    return _decksDe(_uid).snapshots().map(
      (snapshot) => [
        for (final doc in snapshot.docs) Deck.depuisDocument(doc, _uid),
      ],
    );
  }

  /// Les paquets d'un ami visibles par ses amis (à afficher sur son profil).
  static Future<List<Deck>> paquetsAmi(String uidAmi) async {
    final snapshot = await _decksDe(uidAmi)
        .where('visibilite', isEqualTo: 'amis')
        .get();
    return [for (final doc in snapshot.docs) Deck.depuisDocument(doc, uidAmi)];
  }

  /// Crée un nouveau paquet (vide ou avec un contenu initial) et renvoie
  /// son identifiant.
  static Future<String> creerPaquet({
    required String nom,
    required String visibilite,
    List<Map<String, String>> cartes = const [],
    List<Map<String, String>> phrases = const [],
  }) async {
    final document = await _decksDe(_uid).add({
      'nom': nom,
      'visibilite': visibilite,
      'cartes': cartes,
      'phrases': phrases,
      'misAJourLe': FieldValue.serverTimestamp(),
    });
    return document.id;
  }

  /// Met à jour un paquet existant (le mien).
  static Future<void> modifierPaquet(Deck paquet) {
    return _decksDe(_uid).doc(paquet.id).update(paquet.versJson());
  }

  static Future<void> supprimerPaquet(String id) async {
    await _decksDe(_uid).doc(id).delete();
    // On arrête aussi de le suivre si on le suivait soi-même (cas rare,
    // mais ça évite une révision qui pointe vers rien).
    await _mesDecksSuivis.doc(id).delete().catchError((_) {});
  }

  /// Ajoute le paquet d'un ami à mes révisions (lien vers l'original : si
  /// l'ami le modifie, je vois ses modifications).
  static Future<void> suivrePaquet(Deck paquet) {
    return _mesDecksSuivis.doc(paquet.id).set({
      'proprietaireId': paquet.proprietaireId,
      'paquetId': paquet.id,
      'ajouteLe': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> arreterDeSuivre(String paquetId) {
    return _mesDecksSuivis.doc(paquetId).delete();
  }

  /// Mes paquets suivis (liens vers des paquets d'amis), en direct.
  static Stream<QuerySnapshot<Map<String, dynamic>>> mesPaquetsSuivis() {
    return _mesDecksSuivis.snapshots();
  }

  /// Lit un paquet précis chez son propriétaire (pour afficher une
  /// révision suivie, toujours à jour).
  static Future<Deck?> lirePaquet({
    required String proprietaireId,
    required String paquetId,
  }) async {
    final document = await _decksDe(proprietaireId).doc(paquetId).get();
    if (!document.exists) return null;
    return Deck.depuisDocument(document, proprietaireId);
  }

  /// Fait une copie modifiable d'un paquet d'ami, dans mes propres paquets.
  static Future<String> copierPaquet(Deck original) {
    return creerPaquet(
      nom: '${original.nom} (copie)',
      visibilite: 'prive',
      cartes: [for (final c in original.cartes) {'en': c.en, 'fr': c.fr}],
      phrases: [for (final p in original.phrases) p.versJson().cast<String, String>()],
    );
  }
}
