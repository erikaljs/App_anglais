import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/user_service.dart';
import '../../theme/app_colors.dart';

/// Une liste à choix unique pour sélectionner un ami parmi les siens.
class ChoisirAmiWidget extends StatelessWidget {
  const ChoisirAmiWidget({
    super.key,
    required this.amiSelectionne,
    required this.onChoisi,
  });

  final String? amiSelectionne;
  final void Function(String uid) onChoisi;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: UserService.monProfil(),
      builder: (context, snapshot) {
        final amis = List<String>.from(snapshot.data?.data()?['amis'] ?? const []);
        if (amis.isEmpty) {
          return const Text(
            'Tu n\'as pas encore d\'ami. Ajoute-en depuis ton profil !',
            style: TextStyle(color: AppColors.texteSecondaire),
          );
        }
        return RadioGroup<String>(
          groupValue: amiSelectionne,
          onChanged: (valeur) => onChoisi(valeur!),
          child: Column(
            children: [
              for (final uid in amis)
                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: UserService.profilDe(uid),
                  builder: (context, snapshotAmi) {
                    final pseudo = snapshotAmi.data?.data()?['pseudo'] as String? ?? '…';
                    return RadioListTile<String>(title: Text(pseudo), value: uid);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
