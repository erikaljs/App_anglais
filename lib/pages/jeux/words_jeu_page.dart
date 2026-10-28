import 'dart:async';

import 'package:flutter/material.dart';

import '../../modeles/grille_mots.dart';
import '../../services/mots_jeu_service.dart';
import '../../theme/app_colors.dart';

/// L'écran de jeu Words : on touche les lettres de la grille pour former
/// le mot caché. Réutilisé pour le mode solo (grilles générées à
/// l'infini, pas de minuteur) et pour une manche de duel (liste de
/// grilles fixée à l'avance, avec un minuteur).
class WordsJeuPage extends StatefulWidget {
  const WordsJeuPage({
    super.key,
    required this.grilles,
    this.theme,
    this.minuteurSecondes,
    this.onTerminer,
    this.titre = 'Words',
  });

  /// Les grilles à jouer dans l'ordre. En solo, on en ajoute de nouvelles
  /// au fur et à mesure (voir [theme]).
  final List<GrilleMots> grilles;

  /// Si non null : mode solo, on génère une nouvelle grille de ce thème
  /// chaque fois que le mot est trouvé.
  final String? theme;

  /// Si non null : un décompte s'affiche, et la partie s'arrête à 0.
  final int? minuteurSecondes;

  /// Appelé à la fin (minuteur à zéro, ou dernière grille terminée en
  /// duel) avec le score final. Pas appelé en solo (on quitte quand on
  /// veut avec le bouton retour).
  final void Function(int score)? onTerminer;

  final String titre;

  @override
  State<WordsJeuPage> createState() => _WordsJeuPageState();
}

class _WordsJeuPageState extends State<WordsJeuPage> {
  late List<GrilleMots> _grilles;
  int _index = 0;
  final List<int> _selection = [];
  int _score = 0;
  String? _messageErreur;
  Timer? _minuterie;
  int? _secondesRestantes;
  bool _termine = false;
  bool _chargementSuivante = false;

  bool get _modeSolo => widget.theme != null;

  @override
  void initState() {
    super.initState();
    _grilles = List.of(widget.grilles);
    _secondesRestantes = widget.minuteurSecondes;
    if (_secondesRestantes != null) {
      _minuterie = Timer.periodic(const Duration(seconds: 1), (_) => _tic());
    }
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    super.dispose();
  }

  void _tic() {
    setState(() {
      _secondesRestantes = (_secondesRestantes ?? 1) - 1;
      if (_secondesRestantes! <= 0) {
        _minuterie?.cancel();
        _finDePartie();
      }
    });
  }

  void _finDePartie() {
    if (_termine) return;
    setState(() => _termine = true);
    widget.onTerminer?.call(_score);
  }

  GrilleMots get _grilleCourante => _grilles[_index];

  void _toucherLettre(int indexCellule) {
    if (_termine) return;
    setState(() {
      _messageErreur = null;
      if (_selection.contains(indexCellule)) {
        // On retouche une lettre déjà choisie : on revient juste avant elle.
        final position = _selection.indexOf(indexCellule);
        _selection.removeRange(position, _selection.length);
      } else {
        _selection.add(indexCellule);
      }
    });
  }

  void _effacer() => setState(() {
    _selection.clear();
    _messageErreur = null;
  });

  String get _motEnCours =>
      [for (final i in _selection) _grilleCourante.lettres[i]].join();

  Future<void> _valider() async {
    final grille = _grilleCourante;
    if (_motEnCours != grille.motCible) {
      setState(() => _messageErreur = 'Pas ce mot-là, réessaie.');
      return;
    }

    setState(() {
      _score += grille.motCible.length * 2;
      _selection.clear();
      _messageErreur = null;
    });

    // La traduction française du mot trouvé s'affiche en bas de l'écran.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${grille.motCible} = ${grille.traduction}'),
        duration: const Duration(seconds: 2),
      ),
    );

    if (_index + 1 < _grilles.length) {
      setState(() => _index++);
    } else if (_modeSolo) {
      setState(() => _chargementSuivante = true);
      final nouvelle = await MotsJeuService.genererGrille(widget.theme!);
      if (!mounted) return;
      setState(() {
        _grilles.add(nouvelle);
        _index++;
        _chargementSuivante = false;
      });
    } else {
      // Dernière grille de la manche de duel : terminé.
      _minuterie?.cancel();
      _finDePartie();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titre),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'Score : $_score',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _termine ? _ecranFin() : _ecranJeu(),
      ),
    );
  }

  Widget _ecranJeu() {
    if (_chargementSuivante) {
      return const Center(child: CircularProgressIndicator());
    }
    final grille = _grilleCourante;
    return Column(
      children: [
        if (_secondesRestantes != null)
          Text(
            'Temps restant : $_secondesRestantes s',
            style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700),
          ),
        const SizedBox(height: 8),
        Text(
          'Mot ${_index + 1}${_modeSolo ? '' : ' / ${_grilles.length}'} · thème : ${widget.theme ?? ''}',
          style: const TextStyle(color: AppColors.texteSecondaire),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.carteBordure),
          ),
          alignment: Alignment.center,
          child: Text(
            _motEnCours.isEmpty ? ' ' : _motEnCours,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 4),
          ),
        ),
        if (_messageErreur != null) ...[
          const SizedBox(height: 8),
          Text(_messageErreur!, style: const TextStyle(color: AppColors.erreurTexte)),
        ],
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 16,
                itemBuilder: (context, index) {
                  final choisie = _selection.contains(index);
                  return InkWell(
                    onTap: () => _toucherLettre(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: choisie ? AppColors.bleuPrincipal : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.carteBordure),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        grille.lettres[index],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: choisie ? Colors.white : AppColors.bleuFonce,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(onPressed: _effacer, child: const Text('Effacer')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _selection.isEmpty ? null : _valider,
                child: const Text('Valider'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _ecranFin() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, size: 48, color: AppColors.orange),
          const SizedBox(height: 12),
          Text('Score final : $_score', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }
}
