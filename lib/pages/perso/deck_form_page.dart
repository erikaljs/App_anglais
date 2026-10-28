import 'package:flutter/material.dart';

import '../../modeles/contenu.dart';
import '../../modeles/deck.dart';
import '../../services/deck_service.dart';
import '../../theme/app_colors.dart';

/// Formulaire pour créer un nouveau paquet, ou modifier un paquet
/// existant (si [paquetExistant] est fourni).
class DeckFormPage extends StatefulWidget {
  const DeckFormPage({super.key, this.paquetExistant});

  final Deck? paquetExistant;

  @override
  State<DeckFormPage> createState() => _DeckFormPageState();
}

class _CarteModifiable {
  _CarteModifiable({String en = '', String fr = ''})
    : controleurEn = TextEditingController(text: en),
      controleurFr = TextEditingController(text: fr);

  final TextEditingController controleurEn;
  final TextEditingController controleurFr;
}

class _PhraseModifiable {
  _PhraseModifiable({String fr = '', String en = ''})
    : controleurFr = TextEditingController(text: fr),
      controleurEn = TextEditingController(text: en);

  final TextEditingController controleurFr;
  final TextEditingController controleurEn;
}

class _DeckFormPageState extends State<DeckFormPage> {
  late final TextEditingController _controleurNom;
  late String _visibilite;
  late List<_CarteModifiable> _cartes;
  late List<_PhraseModifiable> _phrases;
  bool _enregistrementEnCours = false;

  bool get _modeEdition => widget.paquetExistant != null;

  @override
  void initState() {
    super.initState();
    final paquet = widget.paquetExistant;
    _controleurNom = TextEditingController(text: paquet?.nom ?? '');
    _visibilite = paquet?.visibilite ?? 'amis';
    _cartes = [
      for (final c in paquet?.cartes ?? const <Carte>[])
        _CarteModifiable(en: c.en, fr: c.fr),
    ];
    _phrases = [
      for (final p in paquet?.phrases ?? const <PhrasePerso>[])
        _PhraseModifiable(fr: p.fr, en: p.en),
    ];
  }

  @override
  void dispose() {
    _controleurNom.dispose();
    for (final c in _cartes) {
      c.controleurEn.dispose();
      c.controleurFr.dispose();
    }
    for (final p in _phrases) {
      p.controleurFr.dispose();
      p.controleurEn.dispose();
    }
    super.dispose();
  }

  Future<void> _enregistrer() async {
    final nom = _controleurNom.text.trim();
    if (nom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donne un nom à ton paquet.')),
      );
      return;
    }

    final cartes = [
      for (final c in _cartes)
        if (c.controleurEn.text.trim().isNotEmpty && c.controleurFr.text.trim().isNotEmpty)
          {'en': c.controleurEn.text.trim(), 'fr': c.controleurFr.text.trim()},
    ];
    final phrases = [
      for (final p in _phrases)
        if (p.controleurFr.text.trim().isNotEmpty && p.controleurEn.text.trim().isNotEmpty)
          {'fr': p.controleurFr.text.trim(), 'en': p.controleurEn.text.trim()},
    ];

    setState(() => _enregistrementEnCours = true);
    try {
      if (_modeEdition) {
        final paquetModifie = Deck(
          id: widget.paquetExistant!.id,
          proprietaireId: widget.paquetExistant!.proprietaireId,
          nom: nom,
          visibilite: _visibilite,
          cartes: [for (final c in cartes) Carte(en: c['en']!, fr: c['fr']!)],
          phrases: [for (final p in phrases) PhrasePerso(fr: p['fr']!, en: p['en']!)],
        );
        await DeckService.modifierPaquet(paquetModifie);
      } else {
        await DeckService.creerPaquet(
          nom: nom,
          visibilite: _visibilite,
          cartes: cartes,
          phrases: phrases,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _enregistrementEnCours = false);
    }
  }

  Future<void> _supprimer() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce paquet ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirme != true) return;
    await DeckService.supprimerPaquet(widget.paquetExistant!.id);
    if (mounted) {
      Navigator.of(context).pop(); // ferme le formulaire
      Navigator.of(context).pop(); // ferme le détail du paquet
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_modeEdition ? 'Modifier le paquet' : 'Nouveau paquet'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controleurNom,
            decoration: const InputDecoration(
              labelText: 'Nom du paquet',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'amis', label: Text('Visible par mes amis'), icon: Icon(Icons.group)),
              ButtonSegment(value: 'prive', label: Text('Privé'), icon: Icon(Icons.lock)),
            ],
            selected: {_visibilite},
            onSelectionChanged: (valeurs) => setState(() => _visibilite = valeurs.first),
          ),
          const SizedBox(height: 24),
          Text(
            'Cartes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _cartes.length; i++) _ligneCarte(i),
          OutlinedButton.icon(
            onPressed: () => setState(() => _cartes.add(_CarteModifiable())),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une carte'),
          ),
          const SizedBox(height: 24),
          Text(
            'Phrases à traduire',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _phrases.length; i++) _lignePhrase(i),
          OutlinedButton.icon(
            onPressed: () => setState(() => _phrases.add(_PhraseModifiable())),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une phrase'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _enregistrementEnCours ? null : _enregistrer,
            child: Text(_enregistrementEnCours ? 'Enregistrement…' : 'Enregistrer'),
          ),
          if (_modeEdition) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _supprimer,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.erreurTexte),
              child: const Text('Supprimer ce paquet'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ligneCarte(int index) {
    final carte = _cartes[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: carte.controleurEn,
              decoration: const InputDecoration(labelText: 'Anglais', isDense: true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: carte.controleurFr,
              decoration: const InputDecoration(labelText: 'Français', isDense: true),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => _cartes.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Widget _lignePhrase(int index) {
    final phrase = _phrases[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: phrase.controleurFr,
              decoration: const InputDecoration(labelText: 'Français', isDense: true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: phrase.controleurEn,
              decoration: const InputDecoration(labelText: 'Anglais', isDense: true),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => _phrases.removeAt(index)),
          ),
        ],
      ),
    );
  }
}
