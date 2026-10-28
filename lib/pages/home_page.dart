import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../modeles/contenu.dart';
import '../services/contenu_service.dart';
import '../services/progress_service.dart';
import '../theme/app_colors.dart';
import 'apprentissage/exercices_lecon_page.dart';
import 'apprentissage/liste_lecons_page.dart';

/// Page d'accueil : une tuile par catégorie, avec sa barre de progression
/// et un bouton pour reprendre la prochaine leçon non terminée.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Categorie>>(
      future: ContenuService.chargerToutes(),
      builder: (context, snapshotCategories) {
        if (snapshotCategories.hasError) {
          return Center(
            child: Text(
              'Impossible de charger le contenu : ${snapshotCategories.error}',
              style: const TextStyle(color: AppColors.erreurTexte),
              textAlign: TextAlign.center,
            ),
          );
        }
        if (!snapshotCategories.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final categories = snapshotCategories.data!;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: ProgressService.toutesLesProgressions(),
          builder: (context, snapshotProgres) {
            final progresParLecon = {
              for (final d in snapshotProgres.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                d.id: d.data(),
            };

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final categorie in categories)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TuileCategorie(
                      categorie: categorie,
                      progresParLecon: progresParLecon,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TuileCategorie extends StatelessWidget {
  const _TuileCategorie({
    required this.categorie,
    required this.progresParLecon,
  });

  final Categorie categorie;
  final Map<String, Map<String, dynamic>> progresParLecon;

  @override
  Widget build(BuildContext context) {
    final total = categorie.lecons.length;
    final terminees = categorie.lecons
        .where((l) => progresParLecon[l.id]?['statut'] == 'terminee')
        .length;
    final pourcentage = total == 0 ? 0.0 : terminees / total;

    // La prochaine leçon à faire : la première qui n'est pas terminée,
    // sinon (tout est fini) on recommence depuis la première.
    final prochaineLecon = categorie.lecons.firstWhere(
      (l) => progresParLecon[l.id]?['statut'] != 'terminee',
      orElse: () => categorie.lecons.first,
    );

    final (couleurFond, couleurTexte) = AppColors.couleursCategorie(categorie.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ListeLeconsPage(
              idCategorie: categorie.id,
              nomCategorie: categorie.nom,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: couleurFond,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.menu_book, color: couleurTexte),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categorie.nom,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '$terminees / $total leçons terminées',
                          style: const TextStyle(
                            color: AppColors.texteSecondaire,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pourcentage,
                  minHeight: 8,
                  backgroundColor: AppColors.carteBordure,
                  valueColor: const AlwaysStoppedAnimation(AppColors.orange),
                ),
              ),
              const SizedBox(height: 12),
              if (total > 0)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ExercicesLeconPage(lecon: prochaineLecon),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Reprendre'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
