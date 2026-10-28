import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../modeles/contenu.dart';
import '../../services/contenu_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import 'exercices_lecon_page.dart';

/// La liste des leçons d'une catégorie, avec leur statut (à faire / en
/// cours / terminée) et leur score. Touche une leçon pour commencer
/// l'exercice de cartes.
class ListeLeconsPage extends StatelessWidget {
  const ListeLeconsPage({
    super.key,
    required this.idCategorie,
    required this.nomCategorie,
  });

  final String idCategorie;
  final String nomCategorie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(nomCategorie)),
      body: FutureBuilder<Categorie>(
        future: ContenuService.charger(idCategorie),
        builder: (context, snapshotCategorie) {
          if (snapshotCategorie.hasError) {
            return Center(
              child: Text(
                'Impossible de charger le contenu : ${snapshotCategorie.error}',
                style: const TextStyle(color: AppColors.erreurTexte),
                textAlign: TextAlign.center,
              ),
            );
          }
          if (!snapshotCategorie.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final categorie = snapshotCategorie.data!;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ProgressService.toutesLesProgressions(),
            builder: (context, snapshotProgres) {
              final progresParLecon = {
                for (final d in snapshotProgres.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                  d.id: d.data(),
              };

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: categorie.lecons.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final lecon = categorie.lecons[index];
                  final progres = progresParLecon[lecon.id];
                  return _TuileLecon(lecon: lecon, progres: progres);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _TuileLecon extends StatelessWidget {
  const _TuileLecon({required this.lecon, required this.progres});

  final Lecon lecon;
  final Map<String, dynamic>? progres;

  @override
  Widget build(BuildContext context) {
    final statut = progres?['statut'] as String? ?? 'a_faire';
    final score = progres?['score'] as int?;

    final (libelleStatut, couleurStatut) = switch (statut) {
      'terminee' => ('Terminée', AppColors.succesTexte),
      'en_cours' => ('En cours', AppColors.orange),
      _ => ('À faire', AppColors.texteSecondaire),
    };

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(lecon.titre, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${lecon.niveau} · ${lecon.cartes.length} cartes · $libelleStatut'
          '${score != null ? ' ($score %)' : ''}',
          style: TextStyle(color: couleurStatut),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ExercicesLeconPage(lecon: lecon),
            ),
          );
        },
      ),
    );
  }
}
