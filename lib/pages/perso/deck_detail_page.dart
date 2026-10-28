import 'package:flutter/material.dart';

import '../../modeles/deck.dart';
import '../../services/deck_service.dart';
import '../../theme/app_colors.dart';
import '../apprentissage/cartes_page.dart';
import '../apprentissage/phrases_page.dart';
import 'deck_form_page.dart';

/// Le détail d'un paquet : réviser ses cartes/phrases, et selon le cas
/// le modifier (si c'est le mien) ou l'ajouter à mes révisions / en
/// faire une copie (si c'est celui d'un ami).
class DeckDetailPage extends StatefulWidget {
  const DeckDetailPage({
    super.key,
    required this.paquet,
    required this.estMonPaquet,
    this.dejaSuivi = false,
  });

  final Deck paquet;
  final bool estMonPaquet;
  final bool dejaSuivi;

  @override
  State<DeckDetailPage> createState() => _DeckDetailPageState();
}

class _DeckDetailPageState extends State<DeckDetailPage> {
  late bool _suivi = widget.dejaSuivi;
  bool _enCours = false;

  Future<void> _basculerSuivi() async {
    setState(() => _enCours = true);
    try {
      if (_suivi) {
        await DeckService.arreterDeSuivre(widget.paquet.id);
      } else {
        await DeckService.suivrePaquet(widget.paquet);
      }
      setState(() => _suivi = !_suivi);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  Future<void> _copier() async {
    setState(() => _enCours = true);
    try {
      await DeckService.copierPaquet(widget.paquet);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copie ajoutée à tes paquets !')),
        );
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paquet = widget.paquet;
    return Scaffold(
      appBar: AppBar(
        title: Text(paquet.nom),
        actions: [
          if (widget.estMonPaquet)
            IconButton(
              tooltip: 'Modifier',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DeckFormPage(paquetExistant: paquet),
                  ),
                );
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${paquet.cartes.length} cartes · ${paquet.phrases.length} phrases',
            style: const TextStyle(color: AppColors.texteSecondaire),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.style),
              title: const Text('Réviser les cartes'),
              enabled: paquet.cartes.isNotEmpty,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CartesPage(lecon: paquet.versLecon()),
                ),
              ),
            ),
          ),
          if (paquet.phrases.isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.translate),
                title: const Text('Réviser les phrases'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PhrasesPage(lecon: paquet.versLecon()),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (!widget.estMonPaquet) ...[
            FilledButton.tonalIcon(
              onPressed: _enCours ? null : _basculerSuivi,
              icon: Icon(_suivi ? Icons.bookmark_remove : Icons.bookmark_add),
              label: Text(_suivi ? 'Retirer de mes révisions' : 'Ajouter à mes révisions'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _enCours ? null : _copier,
              icon: const Icon(Icons.copy),
              label: const Text('Faire une copie'),
            ),
          ],
        ],
      ),
    );
  }
}
