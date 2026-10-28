import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Erreur liée au profil ou aux amis, avec un message déjà en français.
class UserServiceException implements Exception {
  const UserServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Tout ce qui concerne le profil de l'utilisateur et ses amis :
/// lecture/écriture dans Firestore (collections users, codesAmis,
/// friendRequests). Voir CLAUDE.md pour le détail des collections.
class UserService {
  UserService._();

  static final _db = FirebaseFirestore.instance;

  static String get uidActuel => FirebaseAuth.instance.currentUser!.uid;

  /// Le document users/{uid} de l'utilisateur connecté, mis à jour en direct.
  static Stream<DocumentSnapshot<Map<String, dynamic>>> monProfil() {
    return _db.collection('users').doc(uidActuel).snapshots();
  }

  /// Le document users/{uid} d'un utilisateur quelconque (pour afficher le
  /// pseudo d'un ami, par exemple), lu une seule fois.
  static Future<DocumentSnapshot<Map<String, dynamic>>> profilDe(String uid) {
    return _db.collection('users').doc(uid).get();
  }

  static Future<void> changerAvatar(String avatar) {
    return _db.collection('users').doc(uidActuel).update({'avatar': avatar});
  }

  /// Envoie une demande d'ami à partir du code saisi par l'utilisateur.
  static Future<void> envoyerDemandeAmi(String codeSaisi) async {
    final code = codeSaisi.trim().toUpperCase();
    if (code.isEmpty) {
      throw const UserServiceException('Entre un code ami.');
    }

    final docCode = await _db.collection('codesAmis').doc(code).get();
    if (!docCode.exists) {
      throw const UserServiceException('Ce code ami n\'existe pas.');
    }
    final uidDestinataire = docCode.data()!['uid'] as String;

    if (uidDestinataire == uidActuel) {
      throw const UserServiceException('C\'est ton propre code ami !');
    }

    final monDocument = await _db.collection('users').doc(uidActuel).get();
    final amis = List<String>.from(monDocument.data()?['amis'] ?? []);
    if (amis.contains(uidDestinataire)) {
      throw const UserServiceException('Vous êtes déjà amis.');
    }

    // Un identifiant stable pour la demande, pour ne pas en créer deux fois
    // si on retape le même code.
    final idDemande = '${uidActuel}_$uidDestinataire';
    final demandeExistante = await _db
        .collection('friendRequests')
        .doc(idDemande)
        .get();
    if (demandeExistante.exists &&
        demandeExistante.data()?['statut'] == 'en_attente') {
      throw const UserServiceException(
        'Demande déjà envoyée, en attente de réponse.',
      );
    }

    await _db.collection('friendRequests').doc(idDemande).set({
      'de': uidActuel,
      'vers': uidDestinataire,
      'statut': 'en_attente',
      'envoyeeLe': FieldValue.serverTimestamp(),
    });
  }

  /// Les demandes d'ami reçues et pas encore traitées.
  static Stream<QuerySnapshot<Map<String, dynamic>>> demandesRecues() {
    return _db
        .collection('friendRequests')
        .where('vers', isEqualTo: uidActuel)
        .where('statut', isEqualTo: 'en_attente')
        .snapshots();
  }

  /// Accepte une demande : on devient amis des deux côtés.
  ///
  /// En deux temps : on marque d'abord la demande comme acceptée, puis on
  /// met à jour les deux listes d'amis. Les règles Firestore autorisent à
  /// ajouter son propre uid dans la liste d'amis de quelqu'un d'autre
  /// seulement si une demande acceptée existe déjà entre les deux ; il faut
  /// donc que l'étape 1 soit bien enregistrée avant l'étape 2.
  static Future<void> accepterDemande({
    required String demandeId,
    required String uidDemandeur,
  }) async {
    await _db.collection('friendRequests').doc(demandeId).update({
      'statut': 'acceptee',
    });

    final lot = _db.batch();
    lot.update(_db.collection('users').doc(uidActuel), {
      'amis': FieldValue.arrayUnion([uidDemandeur]),
    });
    lot.update(_db.collection('users').doc(uidDemandeur), {
      'amis': FieldValue.arrayUnion([uidActuel]),
    });
    await lot.commit();
  }

  static Future<void> refuserDemande(String demandeId) {
    return _db.collection('friendRequests').doc(demandeId).update({
      'statut': 'refusee',
    });
  }
}
