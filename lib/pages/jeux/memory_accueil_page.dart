import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/game_service.dart';
import '../../services/memory_jeu_service.dart';
import '../../theme/app_colors.dart';
import 'memory_defi_setup_page.dart';
import 'memory_duel_page.dart';
import 'memory_local_page.dart';
import 'words_accueil_page.dart'; // pour la liste des thèmes communs

/// Accueil du jeu Memory : à 2 sur le même appareil, défier un ami à
/// distance, ou reprendre un défi en cours.
class MemoryAccueilPage extends StatefulWidget {
  const MemoryAccueilPage({super.key});

  @override
  State<MemoryAccueilPage> createState() => _MemoryAccueilPageState();
}

class _MemoryAccueilPageState extends State<MemoryAccueilPage> {
  String _themeChoisi = 'melange';
  bool _chargement = false;

  Future<void> _jouerA2SurMemeAppareil() async {
    setState(() => _chargement = true);
    try {
      final cartes = await MemoryJeuService.genererGrille(_themeChoisi);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => MemoryLocalPage(cartes: cartes)),
      );
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monUid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Memory')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Thème',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final entree in themesJeux.entries)
                ChoiceChip(
                  label: Text(entree.value),
                  selected: _themeChoisi == entree.key,
                  onSelected: (_) => setState(() => _themeChoisi = entree.key),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _chargement ? null : _jouerA2SurMemeAppareil,
            icon: const Icon(Icons.people),
            label: const Text('Jouer à 2, même appareil'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const MemoryDefiSetupPage()),
            ),
            icon: const Icon(Icons.flag),
            label: const Text('Défier un ami à distance'),
          ),
          const SizedBox(height: 24),
          Text(
            'Mes défis en cours',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: GameService.mesParties(),
            builder: (context, snapshot) {
              final parties = (snapshot.data?.docs ?? const [])
                  .where((d) => d.data()['jeu'] == 'memory')
                  .toList();
              if (parties.isEmpty) {
                return const Text(
                  'Aucun défi Memory pour l\'instant.',
                  style: TextStyle(color: AppColors.texteSecondaire),
                );
              }
              return Column(
                children: [
                  for (final partie in parties)
                    _TuileDefiMemory(id: partie.id, donnees: partie.data(), monUid: monUid),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TuileDefiMemory extends StatelessWidget {
  const _TuileDefiMemory({required this.id, required this.donnees, required this.monUid});

  final String id;
  final Map<String, dynamic> donnees;
  final String monUid;

  @override
  Widget build(BuildContext context) {
    final statut = donnees['statut'] as String;
    final theme = themesJeux[donnees['theme']] ?? donnees['theme'];
    final aiDejaJoue = GameService.aiDejaJoueMemory(donnees);

    String sousTitre;
    VoidCallback? onTap;

    if (statut == 'terminee') {
      final gagnant = GameService.gagnantMemory(donnees);
      sousTitre = gagnant == monUid ? 'Terminé · Gagné !' : 'Terminé · Perdu';
    } else if (aiDejaJoue) {
      sousTitre = 'En attente de ton ami…';
    } else {
      sousTitre = 'À jouer !';
      onTap = () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => MemoryDuelPage(idPartie: id)),
      );
    }

    return Card(
      child: ListTile(
        leading: const Icon(Icons.grid_view),
        title: Text('Memory · $theme'),
        subtitle: Text(sousTitre),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }
}
