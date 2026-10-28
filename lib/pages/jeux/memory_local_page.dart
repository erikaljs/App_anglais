import 'package:flutter/material.dart';

import '../../services/memory_jeu_service.dart';
import '../../theme/app_colors.dart';

/// Memory à 2 joueurs sur le même appareil : chacun son tour, le plus
/// de paires trouvées gagne.
class MemoryLocalPage extends StatefulWidget {
  const MemoryLocalPage({super.key, required this.cartes});

  final List<CarteMemory> cartes;

  @override
  State<MemoryLocalPage> createState() => _MemoryLocalPageState();
}

class _MemoryLocalPageState extends State<MemoryLocalPage> {
  late final List<bool> _retournees = List.filled(widget.cartes.length, false);
  late final List<bool> _trouvees = List.filled(widget.cartes.length, false);
  final List<int> _joueur1 = []; // index des cartes des paires trouvées
  final List<int> _joueur2 = [];
  int _joueurActuel = 1;
  List<int> _selection = [];
  bool _enPause = false; // pendant l'affichage d'une paire ratée

  int get _scoreJoueur1 => _joueur1.length ~/ 2;
  int get _scoreJoueur2 => _joueur2.length ~/ 2;
  bool get _termine => _trouvees.every((t) => t);

  void _toucherCarte(int index) {
    if (_enPause || _retournees[index] || _trouvees[index] || _selection.length == 2) {
      return;
    }
    setState(() {
      _retournees[index] = true;
      _selection.add(index);
    });

    if (_selection.length == 2) {
      _verifierPaire();
    }
  }

  Future<void> _verifierPaire() async {
    final [a, b] = _selection;
    final memeMot = widget.cartes[a].idPaire == widget.cartes[b].idPaire;

    if (memeMot) {
      setState(() {
        _trouvees[a] = true;
        _trouvees[b] = true;
        if (_joueurActuel == 1) {
          _joueur1.addAll([a, b]);
        } else {
          _joueur2.addAll([a, b]);
        }
        _selection = [];
      });
      // Le joueur qui trouve une paire continue à jouer.
    } else {
      setState(() => _enPause = true);
      await Future.delayed(const Duration(milliseconds: 900));
      setState(() {
        _retournees[a] = false;
        _retournees[b] = false;
        _selection = [];
        _enPause = false;
        _joueurActuel = _joueurActuel == 1 ? 2 : 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory · même appareil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _termine ? _ecranFin() : _ecranJeu(),
      ),
    );
  }

  Widget _ecranJeu() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _carteScore('Joueur 1', _scoreJoueur1, _joueurActuel == 1),
            _carteScore('Joueur 2', _scoreJoueur2, _joueurActuel == 2),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: widget.cartes.length,
            itemBuilder: (context, index) {
              final visible = _retournees[index] || _trouvees[index];
              return InkWell(
                onTap: () => _toucherCarte(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: _trouvees[index]
                        ? AppColors.succesFond
                        : (visible ? AppColors.bleuPrincipal.withValues(alpha: 0.12) : AppColors.bleuFonce),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.carteBordure),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(4),
                  child: visible
                      ? Text(
                          widget.cartes[index].texte,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _carteScore(String nom, int score, bool actif) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: actif ? AppColors.bleuPrincipal.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: actif ? AppColors.bleuPrincipal : AppColors.carteBordure),
      ),
      child: Column(
        children: [
          Text(nom, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('$score paires'),
        ],
      ),
    );
  }

  Widget _ecranFin() {
    final gagnant = _scoreJoueur1 == _scoreJoueur2
        ? 'Égalité !'
        : (_scoreJoueur1 > _scoreJoueur2 ? 'Joueur 1 gagne !' : 'Joueur 2 gagne !');
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, size: 48, color: AppColors.orange),
          const SizedBox(height: 12),
          Text(gagnant, style: Theme.of(context).textTheme.titleLarge),
          Text('$_scoreJoueur1 contre $_scoreJoueur2 paires'),
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
