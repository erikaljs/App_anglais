import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../modeles/deck.dart';
import '../services/deck_service.dart';
import '../theme/app_colors.dart';
import 'perso/deck_detail_page.dart';
import 'perso/deck_form_page.dart';

/// Page "Perso" : mes paquets de cartes et phrases, et ceux des amis que
/// j'ai ajoutés à mes révisions.
class PersoPage extends StatelessWidget {
  const PersoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nouveau paquet',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const DeckFormPage()),
        ),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Mes paquets',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Deck>>(
            stream: DeckService.mesPaquets(),
            builder: (context, snapshot) {
              final paquets = snapshot.data ?? const [];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (paquets.isEmpty) {
                return const Text(
                  'Pas encore de paquet : touche le bouton + pour en créer un.',
                  style: TextStyle(color: AppColors.texteSecondaire),
                );
              }
              return Column(
                children: [
                  for (final paquet in paquets)
                    _TuilePaquet(
                      titre: paquet.nom,
                      sousTitre:
                          '${paquet.cartes.length} cartes · ${paquet.phrases.length} phrases'
                          ' · ${paquet.estVisibleDesAmis ? "visible par mes amis" : "privé"}',
                      icone: paquet.estVisibleDesAmis ? Icons.group : Icons.lock,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DeckDetailPage(paquet: paquet, estMonPaquet: true),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Mes révisions (paquets d\'amis)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: DeckService.mesPaquetsSuivis(),
            builder: (context, snapshot) {
              final suivis = snapshot.data?.docs ?? const [];
              if (suivis.isEmpty) {
                return const Text(
                  'Rien pour l\'instant : ajoute un paquet depuis le profil d\'un ami.',
                  style: TextStyle(color: AppColors.texteSecondaire),
                );
              }
              return Column(
                children: [
                  for (final suivi in suivis)
                    _TuilePaquetSuivi(
                      proprietaireId: suivi.data()['proprietaireId'] as String,
                      paquetId: suivi.data()['paquetId'] as String,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TuilePaquet extends StatelessWidget {
  const _TuilePaquet({
    required this.titre,
    required this.sousTitre,
    required this.icone,
    required this.onTap,
  });

  final String titre;
  final String sousTitre;
  final IconData icone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icone),
        title: Text(titre, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(sousTitre),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// Un paquet suivi : on relit toujours la version actuelle chez son
/// propriétaire (si l'ami l'a modifié, mis en privé ou supprimé, ou si
/// l'amitié a été retirée, ça se reflète ici automatiquement).
class _TuilePaquetSuivi extends StatelessWidget {
  const _TuilePaquetSuivi({required this.proprietaireId, required this.paquetId});

  final String proprietaireId;
  final String paquetId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Deck?>(
      future: DeckService.lirePaquet(proprietaireId: proprietaireId, paquetId: paquetId)
          .catchError((_) => null),
      builder: (context, snapshot) {
        final paquet = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        if (paquet == null) {
          // Le paquet n'existe plus, ou n'est plus visible (privé,
          // supprimé, ou l'amitié a été retirée) : on ne l'affiche plus.
          return const SizedBox.shrink();
        }
        return _TuilePaquet(
          titre: paquet.nom,
          sousTitre: '${paquet.cartes.length} cartes · ${paquet.phrases.length} phrases',
          icone: Icons.group,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DeckDetailPage(
                paquet: paquet,
                estMonPaquet: false,
                dejaSuivi: true,
              ),
            ),
          ),
        );
      },
    );
  }
}
