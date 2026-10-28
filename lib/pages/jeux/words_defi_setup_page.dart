import 'package:flutter/material.dart';

import '../../services/game_service.dart';
import '../../theme/app_colors.dart';
import 'choisir_ami_widget.dart';
import 'words_accueil_page.dart';
import 'words_duel_page.dart';

const _minuteursPossibles = {
  30: '30 secondes',
  60: '1 minute',
  120: '2 minutes',
  180: '3 minutes',
};

/// Formulaire pour défier un ami à Words : choisir l'ami, le thème et
/// le minuteur de chaque manche.
class WordsDefiSetupPage extends StatefulWidget {
  const WordsDefiSetupPage({super.key});

  @override
  State<WordsDefiSetupPage> createState() => _WordsDefiSetupPageState();
}

class _WordsDefiSetupPageState extends State<WordsDefiSetupPage> {
  String? _amiChoisi;
  String _themeChoisi = 'melange';
  int _minuteurChoisi = 60;
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
      final idPartie = await GameService.creerDuelWords(
        adversaireUid: amiChoisi,
        theme: _themeChoisi,
        minuteurSecondes: _minuteurChoisi,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => WordsDuelPage(idPartie: idPartie)),
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
          Text(
            'Minuteur par manche (2 manches)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final entree in _minuteursPossibles.entries)
                ChoiceChip(
                  label: Text(entree.value),
                  selected: _minuteurChoisi == entree.key,
                  onSelected: (_) => setState(() => _minuteurChoisi = entree.key),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _enCours ? null : _lancerLeDefi,
            icon: const Icon(Icons.flag),
            label: const Text('Lancer le défi (et jouer ma 1ère manche)'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tu joues tes 2 manches tout de suite. Ton ami jouera les '
            'siennes ensuite, avec le même minuteur.',
            style: TextStyle(color: AppColors.texteSecondaire, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
