import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../modeles/deck.dart';
import '../../services/deck_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_avatars.dart';
import '../../theme/app_colors.dart';
import '../perso/deck_detail_page.dart';

/// Le profil d'un ami : son pseudo, son avatar, et ses paquets visibles
/// par ses amis (section "Ses paquets").
class ProfilAmiPage extends StatelessWidget {
  const ProfilAmiPage({super.key, required this.uid});

  final String uid;

  Future<void> _retirerAmi(BuildContext context) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer cet ami ?'),
        content: const Text(
          'Vous ne serez plus amis. Ses paquets partagés disparaîtront de '
          'tes révisions, et les tiens des siennes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirme != true) return;

    await UserService.retirerAmi(uid);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, snapshotProfil) {
          if (!snapshotProfil.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final donnees = snapshotProfil.data!.data() ?? {};
          final pseudo = donnees['pseudo'] as String? ?? '…';
          final avatar = donnees['avatar'] as String?;
          final serieJours = donnees['serieJours'] as int? ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.bleuPrincipal.withValues(alpha: 0.12),
                    child: Icon(AppAvatars.icone(avatar), size: 32, color: AppColors.bleuPrincipal),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pseudo,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '$serieJours jours de série',
                    style: const TextStyle(color: AppColors.texteSecondaire),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Ses paquets',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Deck>>(
                future: DeckService.paquetsAmi(uid),
                builder: (context, snapshotPaquets) {
                  if (!snapshotPaquets.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final paquets = snapshotPaquets.data!;
                  if (paquets.isEmpty) {
                    return const Text(
                      'Pas de paquet visible pour l\'instant.',
                      style: TextStyle(color: AppColors.texteSecondaire),
                    );
                  }
                  return Column(
                    children: [
                      for (final paquet in paquets)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.style),
                            title: Text(paquet.nom, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              '${paquet.cartes.length} cartes · ${paquet.phrases.length} phrases',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => DeckDetailPage(paquet: paquet, estMonPaquet: false),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _retirerAmi(context),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.erreurTexte),
                icon: const Icon(Icons.person_remove_outlined),
                label: const Text('Retirer cet ami'),
              ),
            ],
          );
        },
      ),
    );
  }
}
