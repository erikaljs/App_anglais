import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/game_service.dart';
import '../../services/mots_jeu_service.dart';
import '../../theme/app_colors.dart';
import 'words_defi_setup_page.dart';
import 'words_duel_page.dart';
import 'words_jeu_page.dart';

const themesJeux = {
  'sport': 'Sport',
  'voyage': 'Voyage',
  'technique': 'Technique',
  'melange': 'Mélange',
};

/// Accueil du jeu Words : jouer en solo, défier un ami, ou reprendre un
/// défi en cours.
class WordsAccueilPage extends StatefulWidget {
  const WordsAccueilPage({super.key});

  @override
  State<WordsAccueilPage> createState() => _WordsAccueilPageState();
}

class _WordsAccueilPageState extends State<WordsAccueilPage> {
  String _themeChoisi = 'melange';
  bool _chargement = false;

  Future<void> _jouerEnSolo() async {
    setState(() => _chargement = true);
    try {
      final grille = await MotsJeuService.genererGrille(_themeChoisi);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WordsJeuPage(
            grilles: [grille],
            theme: _themeChoisi,
            titre: 'Words solo',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monUid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Words')),
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
            onPressed: _chargement ? null : _jouerEnSolo,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Jouer en solo'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const WordsDefiSetupPage()),
            ),
            icon: const Icon(Icons.flag),
            label: const Text('Défier un ami'),
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
                  .where((d) => d.data()['jeu'] == 'words')
                  .toList();
              if (parties.isEmpty) {
                return const Text(
                  'Aucun défi Words pour l\'instant.',
                  style: TextStyle(color: AppColors.texteSecondaire),
                );
              }
              return Column(
                children: [
                  for (final partie in parties)
                    _TuileDefiWords(id: partie.id, donnees: partie.data(), monUid: monUid),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TuileDefiWords extends StatelessWidget {
  const _TuileDefiWords({required this.id, required this.donnees, required this.monUid});

  final String id;
  final Map<String, dynamic> donnees;
  final String monUid;

  @override
  Widget build(BuildContext context) {
    final statut = donnees['statut'] as String;
    final theme = themesJeux[donnees['theme']] ?? donnees['theme'];

    String sousTitre;
    VoidCallback? onTap;

    if (statut == 'terminee') {
      final monScore = GameService.scoreTotalWords(donnees, monUid) ?? 0;
      final joueurs = List<String>.from(donnees['joueurs'] as List);
      final autreUid = joueurs.firstWhere((u) => u != monUid);
      final scoreAutre = GameService.scoreTotalWords(donnees, autreUid) ?? 0;
      final resultat = monScore > scoreAutre
          ? 'Gagné'
          : (monScore < scoreAutre ? 'Perdu' : 'Égalité');
      sousTitre = 'Terminé · $resultat ($monScore contre $scoreAutre)';
    } else if (donnees['tourDe'] == monUid) {
      sousTitre = 'À toi de jouer !';
      onTap = () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => WordsDuelPage(idPartie: id)),
      );
    } else {
      sousTitre = 'En attente de l\'autre joueur…';
    }

    return Card(
      child: ListTile(
        leading: const Icon(Icons.extension),
        title: Text('Words · $theme'),
        subtitle: Text(sousTitre),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }
}
