import 'package:flutter/material.dart';

import '../../modeles/contenu.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';

/// L'exercice de cartes (flashcards) pour une leçon : on retourne chaque
/// carte en la touchant, puis on la marque "Je sais" ou "À revoir" (au
/// choix avec les boutons, ou en balayant la carte vers la droite/gauche).
///
/// À la fin d'un tour, un écran récapitule les cartes ratées, avec la
/// possibilité de les revoir tout de suite.
class CartesPage extends StatefulWidget {
  const CartesPage({super.key, required this.lecon});

  final Lecon lecon;

  @override
  State<CartesPage> createState() => _CartesPageState();
}

class _CartesPageState extends State<CartesPage> {
  // Les cartes du tour en cours (au premier tour : toutes les cartes de
  // la leçon ; aux tours suivants : seulement celles ratées au tour d'avant).
  late List<Carte> _cartesDuTour;
  final List<Carte> _suesDuTour = [];
  final List<Carte> _rateesDuTour = [];
  bool _retourne = false;

  // Le score du tout premier tour : c'est lui qu'on enregistre, même si
  // l'utilisateur refait ensuite les cartes ratées plusieurs fois.
  int? _scorePremierTour;

  @override
  void initState() {
    super.initState();
    _cartesDuTour = List.of(widget.lecon.cartes);
  }

  int get _indexCourant => _suesDuTour.length + _rateesDuTour.length;

  bool get _tourTermine => _indexCourant >= _cartesDuTour.length;

  void _marquer(bool connue) {
    final carte = _cartesDuTour[_indexCourant];
    setState(() {
      if (connue) {
        _suesDuTour.add(carte);
      } else {
        _rateesDuTour.add(carte);
      }
      _retourne = false;
    });

    if (_tourTermine) {
      _scorePremierTour ??= ((_suesDuTour.length / widget.lecon.cartes.length) * 100)
          .round();
    }
  }

  void _revoirLesRatees() {
    setState(() {
      _cartesDuTour = List.of(_rateesDuTour);
      _suesDuTour.clear();
      _rateesDuTour.clear();
      _retourne = false;
    });
  }

  Future<void> _terminer() async {
    await ProgressService.enregistrerResultatLecon(
      leconId: widget.lecon.id,
      score: _scorePremierTour ?? 100,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lecon.titre)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _tourTermine ? _ecranRecap() : _ecranCarte(),
      ),
    );
  }

  Widget _ecranCarte() {
    final carte = _cartesDuTour[_indexCourant];
    return Column(
      children: [
        Text(
          'Carte ${_indexCourant + 1} / ${_cartesDuTour.length}',
          style: const TextStyle(color: AppColors.texteSecondaire),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: Dismissible(
              // Une clé différente à chaque carte : Flutter sait alors que
              // c'est une toute nouvelle carte, pas la même qu'on aurait
              // mal fait disparaître.
              key: ValueKey('${_indexCourant}_${carte.en}'),
              direction: DismissDirection.horizontal,
              onDismissed: (direction) {
                _marquer(direction == DismissDirection.startToEnd);
              },
              background: _fondSwipe(
                alignement: Alignment.centerLeft,
                couleur: AppColors.succesFond,
                texteCouleur: AppColors.succesTexte,
                icone: Icons.check_circle,
                texte: 'Je sais',
              ),
              secondaryBackground: _fondSwipe(
                alignement: Alignment.centerRight,
                couleur: AppColors.erreurFond,
                texteCouleur: AppColors.erreurTexte,
                icone: Icons.replay,
                texte: 'À revoir',
              ),
              child: GestureDetector(
                onTap: () => setState(() => _retourne = !_retourne),
                child: _carteVisuelle(carte),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _marquer(false),
                icon: const Icon(Icons.replay),
                label: const Text('À revoir'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _marquer(true),
                icon: const Icon(Icons.check),
                label: const Text('Je sais'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _carteVisuelle(Carte carte) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _retourne ? AppColors.bleuPrincipal.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.carteBordure),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _retourne ? carte.fr : carte.en,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            _retourne ? 'Français' : 'Touche la carte pour voir la traduction',
            style: const TextStyle(color: AppColors.texteSecondaire, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _fondSwipe({
    required Alignment alignement,
    required Color couleur,
    required Color texteCouleur,
    required IconData icone,
    required String texte,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: couleur,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: alignement,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, color: texteCouleur),
          const SizedBox(width: 8),
          Text(texte, style: TextStyle(color: texteCouleur, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _ecranRecap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          _rateesDuTour.isEmpty ? Icons.emoji_events : Icons.flag,
          size: 48,
          color: AppColors.orange,
        ),
        const SizedBox(height: 12),
        Text(
          _rateesDuTour.isEmpty
              ? 'Toutes les cartes sont connues !'
              : '${_suesDuTour.length} / ${_cartesDuTour.length} connues sur ce tour',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (_scorePremierTour != null) ...[
          const SizedBox(height: 4),
          Text(
            'Score de cette leçon : $_scorePremierTour %',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.texteSecondaire),
          ),
        ],
        const SizedBox(height: 16),
        if (_rateesDuTour.isNotEmpty)
          Expanded(
            child: ListView(
              children: [
                for (final carte in _rateesDuTour)
                  Card(
                    child: ListTile(
                      title: Text(carte.en),
                      subtitle: Text(carte.fr),
                    ),
                  ),
              ],
            ),
          )
        else
          const Spacer(),
        const SizedBox(height: 16),
        if (_rateesDuTour.isNotEmpty)
          FilledButton.icon(
            onPressed: _revoirLesRatees,
            icon: const Icon(Icons.replay),
            label: Text('Revoir les cartes ratées (${_rateesDuTour.length})'),
          ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _terminer,
          child: const Text('Terminer'),
        ),
      ],
    );
  }
}
