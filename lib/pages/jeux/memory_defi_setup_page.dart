import 'package:flutter/material.dart';

import '../../services/game_service.dart';
import 'choisir_ami_widget.dart';
import 'memory_duel_page.dart';
import 'words_accueil_page.dart'; // pour la liste des thèmes communs

/// Formulaire pour défier un ami à Memory à distance : choisir l'ami et
/// le thème. Les deux joueront ensuite la même grille, chacun à son
/// rythme ; le plus rapide (et à égalité, le moins de coups) gagne.
class MemoryDefiSetupPage extends StatefulWidget {
  const MemoryDefiSetupPage({super.key});

  @override
  State<MemoryDefiSetupPage> createState() => _MemoryDefiSetupPageState();
}

class _MemoryDefiSetupPageState extends State<MemoryDefiSetupPage> {
  String? _amiChoisi;
  String _themeChoisi = 'melange';
  bool _enCours = false;

  Future<void> _lancerLeDefi() async {
    final amiChoisi = _amiChoisi;
    if (amiChoisi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis un ami à défier.')),
      );
      return;
    }

    setState(() => _enCours = true);
    try {
      final idPartie = await GameService.creerDuelMemory(
        adversaireUid: amiChoisi,
        theme: _themeChoisi,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MemoryDuelPage(idPartie: idPartie)),
      );
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Défier un ami')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Qui défier ?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ChoisirAmiWidget(
            amiSelectionne: _amiChoisi,
            onChoisi: (uid) => setState(() => _amiChoisi = uid),
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _enCours ? null : _lancerLeDefi,
            icon: const Icon(Icons.flag),
            label: const Text('Lancer le défi (et jouer tout de suite)'),
          ),
        ],
      ),
    );
  }
}
