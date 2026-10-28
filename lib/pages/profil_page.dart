import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/app_avatars.dart';
import '../theme/app_colors.dart';
import 'profil/ajouter_ami_dialog.dart';
import 'profil/avatar_dialog.dart';

/// Page de profil : pseudo, avatar, statistiques, code ami, demandes
/// d'ami reçues et liste des amis.
class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: UserService.monProfil(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final donnees = snapshot.data!.data() ?? {};
        final pseudo = donnees['pseudo'] as String? ?? '';
        final avatar = donnees['avatar'] as String? ?? 'etoile';
        final codeAmi = donnees['codeAmi'] as String? ?? '';
        final serieJours = donnees['serieJours'] as int? ?? 0;
        final amis = List<String>.from(donnees['amis'] ?? const []);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _EnTeteProfil(pseudo: pseudo, avatar: avatar),
            const SizedBox(height: 24),
            _LigneStatistiques(serieJours: serieJours),
            const SizedBox(height: 24),
            _CarteCodeAmi(codeAmi: codeAmi),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => ouvrirAjoutAmi(context),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Ajouter un ami'),
            ),
            const SizedBox(height: 24),
            const _TitreSection('Demandes reçues'),
            const _SectionDemandes(),
            const SizedBox(height: 24),
            _TitreSection('Mes amis (${amis.length})'),
            _SectionAmis(amis: amis),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: AuthService.deconnexion,
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );
  }
}

class _EnTeteProfil extends StatelessWidget {
  const _EnTeteProfil({required this.pseudo, required this.avatar});

  final String pseudo;
  final String avatar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () async {
            final choix = await choisirAvatar(context, avatar);
            if (choix != null) {
              await UserService.changerAvatar(choix);
            }
          },
          borderRadius: BorderRadius.circular(40),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.bleuPrincipal.withValues(alpha: 0.12),
            child: Icon(
              AppAvatars.icone(avatar),
              size: 36,
              color: AppColors.bleuPrincipal,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          pseudo,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Text(
          'Touche l\'avatar pour le changer',
          style: TextStyle(color: AppColors.texteSecondaire, fontSize: 12),
        ),
      ],
    );
  }
}

class _LigneStatistiques extends StatelessWidget {
  const _LigneStatistiques({required this.serieJours});

  final int serieJours;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CarteStat(
            icone: Icons.local_fire_department,
            couleur: AppColors.orange,
            valeur: '$serieJours',
            libelle: 'jours de série',
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _CarteStat(
            icone: Icons.menu_book,
            couleur: AppColors.bleuPrincipal,
            valeur: '0',
            libelle: 'mots appris',
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _CarteStat(
            icone: Icons.emoji_events,
            couleur: AppColors.bleuFonce,
            valeur: '0',
            libelle: 'duels gagnés',
          ),
        ),
      ],
    );
  }
}

class _CarteStat extends StatelessWidget {
  const _CarteStat({
    required this.icone,
    required this.couleur,
    required this.valeur,
    required this.libelle,
  });

  final IconData icone;
  final Color couleur;
  final String valeur;
  final String libelle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icone, color: couleur),
            const SizedBox(height: 8),
            Text(
              valeur,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              libelle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.texteSecondaire,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarteCodeAmi extends StatelessWidget {
  const _CarteCodeAmi({required this.codeAmi});

  final String codeAmi;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Ton code ami',
                style: TextStyle(color: AppColors.texteSecondaire),
              ),
            ),
            Text(
              codeAmi,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
            IconButton(
              tooltip: 'Copier le code',
              icon: const Icon(Icons.copy),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: codeAmi));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code ami copié !')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TitreSection extends StatelessWidget {
  const _TitreSection(this.titre);

  final String titre;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        titre,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Liste des demandes d'ami en attente, avec boutons Accepter / Refuser.
class _SectionDemandes extends StatelessWidget {
  const _SectionDemandes();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: UserService.demandesRecues(),
      builder: (context, snapshot) {
        final demandes = snapshot.data?.docs ?? [];
        if (demandes.isEmpty) {
          return const Text(
            'Aucune demande en attente.',
            style: TextStyle(color: AppColors.texteSecondaire),
          );
        }
        return Column(
          children: [
            for (final demande in demandes)
              _TuileDemande(
                demandeId: demande.id,
                uidDemandeur: demande.data()['de'] as String,
              ),
          ],
        );
      },
    );
  }
}

class _TuileDemande extends StatelessWidget {
  const _TuileDemande({required this.demandeId, required this.uidDemandeur});

  final String demandeId;
  final String uidDemandeur;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: UserService.profilDe(uidDemandeur),
      builder: (context, snapshot) {
        final pseudo = snapshot.data?.data()?['pseudo'] as String? ?? '…';
        return Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(pseudo),
            subtitle: const Text('Souhaite devenir ton ami'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Refuser',
                  icon: const Icon(Icons.close, color: AppColors.erreurTexte),
                  onPressed: () => UserService.refuserDemande(demandeId),
                ),
                IconButton(
                  tooltip: 'Accepter',
                  icon: const Icon(
                    Icons.check,
                    color: AppColors.succesTexte,
                  ),
                  onPressed: () => UserService.accepterDemande(
                    demandeId: demandeId,
                    uidDemandeur: uidDemandeur,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Liste des amis actuels.
class _SectionAmis extends StatelessWidget {
  const _SectionAmis({required this.amis});

  final List<String> amis;

  @override
  Widget build(BuildContext context) {
    if (amis.isEmpty) {
      return const Text(
        'Pas encore d\'amis : partage ton code pour en ajouter !',
        style: TextStyle(color: AppColors.texteSecondaire),
      );
    }
    return Column(
      children: [for (final uid in amis) _TuileAmi(uid: uid)],
    );
  }
}

class _TuileAmi extends StatelessWidget {
  const _TuileAmi({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: UserService.profilDe(uid),
      builder: (context, snapshot) {
        final donnees = snapshot.data?.data();
        final pseudo = donnees?['pseudo'] as String? ?? '…';
        final avatar = donnees?['avatar'] as String?;
        return Card(
          child: ListTile(
            leading: Icon(AppAvatars.icone(avatar)),
            title: Text(pseudo),
          ),
        );
      },
    );
  }
}
