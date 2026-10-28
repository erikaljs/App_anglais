import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Erreur d'inscription ou de connexion, avec un message déjà en français
/// et compréhensible, prêt à être affiché à l'écran.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Toute la logique des comptes : inscription, connexion, déconnexion.
///
/// Firebase Auth exige un e-mail pour créer un compte. Comme on ne veut
/// qu'un pseudo et un mot de passe, on fabrique en coulisse un faux e-mail
/// à partir du pseudo : "pseudo@mon-anglais.local". L'utilisateur ne le
/// voit jamais.
class AuthService {
  AuthService._();

  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  // Un pseudo valide : 3 à 20 lettres, chiffres ou tirets bas (voir CLAUDE.md).
  static final _regexPseudo = RegExp(r'^[A-Za-z0-9_]{3,20}$');

  // Caractères utilisés pour le code ami : pas de 0, O, 1, I (trop ressemblants).
  static const _caracteresCodeAmi = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  /// Émet l'utilisateur connecté (ou null) chaque fois que l'état de
  /// connexion change. Utilisé par main.dart pour savoir quel écran afficher.
  static Stream<User?> get changementsConnexion => _auth.authStateChanges();

  static String _emailPourPseudo(String pseudoMinuscule) =>
      '$pseudoMinuscule@mon-anglais.local';

  /// Crée un nouveau compte : réserve le pseudo, crée le compte Firebase Auth,
  /// génère un code ami, puis enregistre le profil dans Firestore.
  static Future<void> inscription({
    required String pseudo,
    required String motDePasse,
  }) async {
    final pseudoPropre = pseudo.trim();
    if (!_regexPseudo.hasMatch(pseudoPropre)) {
      throw const AuthException(
        'Le pseudo doit contenir 3 à 20 lettres, chiffres ou _ (sans espace ni accent).',
      );
    }
    final pseudoMinuscule = pseudoPropre.toLowerCase();
    final refPseudo = _db.collection('pseudos').doc(pseudoMinuscule);

    // 1. On réserve le pseudo tout de suite, pour que personne d'autre ne
    //    puisse le prendre pendant qu'on crée le compte.
    await _db.runTransaction((transaction) async {
      final document = await transaction.get(refPseudo);
      if (document.exists) {
        throw const AuthException('Ce pseudo est déjà pris.');
      }
      transaction.set(refPseudo, {'uid': '_reservation'});
    });

    UserCredential identifiants;
    try {
      identifiants = await _auth.createUserWithEmailAndPassword(
        email: _emailPourPseudo(pseudoMinuscule),
        password: motDePasse,
      );
    } catch (erreur) {
      // La création du compte a échoué : on annule la réservation du pseudo.
      await refPseudo.delete();
      throw AuthException(_messageErreur(erreur));
    }

    final uid = identifiants.user!.uid;
    final codeAmi = await _genererCodeAmiUnique();

    // 2. On enregistre tout en une fois : le pseudo, le code ami et le profil.
    final lot = _db.batch();
    lot.set(refPseudo, {'uid': uid});
    lot.set(_db.collection('codesAmis').doc(codeAmi), {'uid': uid});
    lot.set(_db.collection('users').doc(uid), {
      'pseudo': pseudoPropre,
      'codeAmi': codeAmi,
      'avatar': 'etoile',
      'xp': 0,
      'serieJours': 0,
      'derniereActivite': FieldValue.serverTimestamp(),
      'dateInscription': FieldValue.serverTimestamp(),
      'amis': <String>[],
      'bloques': <String>[],
    });
    await lot.commit();
  }

  /// Essaie plusieurs codes au hasard jusqu'à en trouver un qui n'existe pas encore.
  static Future<String> _genererCodeAmiUnique() async {
    for (var tentative = 0; tentative < 5; tentative++) {
      final code = _genererCode();
      final document = await _db.collection('codesAmis').doc(code).get();
      if (!document.exists) return code;
    }
    throw const AuthException(
      'Impossible de générer un code ami pour le moment, réessaie.',
    );
  }

  static String _genererCode() {
    final hasard = Random.secure();
    return List.generate(
      6,
      (_) => _caracteresCodeAmi[hasard.nextInt(_caracteresCodeAmi.length)],
    ).join();
  }

  /// Connecte un utilisateur déjà inscrit avec son pseudo et son mot de passe.
  static Future<void> connexion({
    required String pseudo,
    required String motDePasse,
  }) async {
    final pseudoMinuscule = pseudo.trim().toLowerCase();
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailPourPseudo(pseudoMinuscule),
        password: motDePasse,
      );
    } catch (erreur) {
      throw AuthException(_messageErreur(erreur));
    }
  }

  static Future<void> deconnexion() => _auth.signOut();

  /// Traduit les erreurs techniques de Firebase en phrases compréhensibles.
  static String _messageErreur(Object erreur) {
    if (erreur is FirebaseAuthException) {
      switch (erreur.code) {
        case 'email-already-in-use':
          return 'Ce pseudo est déjà pris.';
        case 'weak-password':
          return 'Le mot de passe doit faire au moins 6 caractères.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Pseudo ou mot de passe incorrect.';
        case 'too-many-requests':
          return 'Trop de tentatives. Réessaie dans quelques minutes.';
        case 'invalid-email':
          return 'Ce pseudo n\'est pas valide.';
        default:
          return 'Une erreur est survenue (${erreur.code}).';
      }
    }
    return 'Une erreur est survenue. Vérifie ta connexion internet.';
  }
}
