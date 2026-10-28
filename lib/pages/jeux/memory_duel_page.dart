import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/game_service.dart';
import '../../services/memory_jeu_service.dart';
import '../../theme/app_colors.dart';
import 'words_accueil_page.dart'; // pour la liste des thèmes communs

/// Un duel Memory à distance : même grille pour les deux joueurs, qui
/// jouent chacun de leur côté. Si je n'ai pas encore joué, je joue mon
/// tour (chronométré) puis j'envoie mon résultat ; sinon j'attends ou
/// je vois le résultat final.
class MemoryDuelPage extends StatefulWidget {
  const MemoryDuelPage({super.key, required this.idPartie});

  final String idPartie;

  @override
  State<MemoryDuelPage> createState() => _MemoryDuelPageState();
}

class _MemoryDuelPageState extends State<MemoryDuelPage> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _futurePartie;

  @override
  void initState() {
    super.initState();
    _futurePartie = FirebaseFirestore.instance.collection('games').doc(widget.idPartie).get();
  }

  @override
  Widget build(BuildContext context) {
    final monUid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Duel Memory')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _futurePartie,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final partie = snapshot.data!.data()!;
          final statut = partie['statut'] as String;
          final theme = themesJeux[partie['theme']] ?? partie['theme'];

          if (statut == 'terminee') {
            final gagnant = GameService.gagnantMemory(partie);
            final scores = Map<String, dynamic>.from(partie['scores'] as Map);
            final monScore = Map<String, dynamic>.from(scores[monUid] as Map);
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    gagnant == monUid ? Icons.emoji_events : Icons.flag,
                    size: 48,
                    color: AppColors.orange,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    gagnant == monUid ? 'Tu as gagné !' : 'Perdu cette fois-ci.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Ton temps : ${monScore['temps']} s · ${monScore['coups']} coups'),
                ],
              ),
            );
          }

          if (GameService.aiDejaJoueMemory(partie)) {
            return const Center(
              child: Text(
                'Tu as déjà joué : en attente du résultat de ton ami.',
                style: TextStyle(color: AppColors.texteSecondaire),
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Memory · $theme', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Même grille que ton ami : le plus rapide gagne !',
                  style: TextStyle(color: AppColors.texteSecondaire),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _jouer(partie),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Commencer'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _jouer(Map<String, dynamic> partie) async {
    final cartes = GameService.grilleMemoryPartagee(partie);
    final resultat = await Navigator.of(context).push<(int, int)>(
      MaterialPageRoute(builder: (context) => _MemoryEssaiPage(cartes: cartes)),
    );
    if (resultat == null) return; // sorti sans terminer

    final (temps, coups) = resultat;
    await GameService.enregistrerResultatMemory(
      idPartie: widget.idPartie,
      tempsSecondes: temps,
      coups: coups,
    );
    if (!mounted) return;
    setState(() {
      _futurePartie = FirebaseFirestore.instance.collection('games').doc(widget.idPartie).get();
    });
  }
}

/// Un essai solo chronométré : on retourne les cartes pour trouver
/// toutes les paires, et on renvoie (temps en secondes, nombre de coups).
class _MemoryEssaiPage extends StatefulWidget {
  const _MemoryEssaiPage({required this.cartes});

  final List<CarteMemory> cartes;

  @override
  State<_MemoryEssaiPage> createState() => _MemoryEssaiPageState();
}

class _MemoryEssaiPageState extends State<_MemoryEssaiPage> {
  late final List<bool> _retournees = List.filled(widget.cartes.length, false);
  late final List<bool> _trouvees = List.filled(widget.cartes.length, false);
  List<int> _selection = [];
  bool _enPause = false;
  int _coups = 0;
  int _secondes = 0;
  Timer? _chrono;

  @override
  void initState() {
    super.initState();
    _chrono = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _secondes++));
  }

  @override
  void dispose() {
    _chrono?.cancel();
    super.dispose();
  }

  bool get _termine => _trouvees.every((t) => t);

  void _toucherCarte(int index) {
    if (_enPause || _retournees[index] || _trouvees[index] || _selection.length == 2) {
      return;
    }
    setState(() {
      _retournees[index] = true;
      _selection.add(index);
    });

    if (_selection.length == 2) _verifierPaire();
  }

  Future<void> _verifierPaire() async {
    final [a, b] = _selection;
    setState(() => _coups++);
    final memeMot = widget.cartes[a].idPaire == widget.cartes[b].idPaire;

    if (memeMot) {
      setState(() {
        _trouvees[a] = true;
        _trouvees[b] = true;
        _selection = [];
      });
      if (_termine) {
        _chrono?.cancel();
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) Navigator.of(context).pop((_secondes, _coups));
      }
    } else {
      setState(() => _enPause = true);
      await Future.delayed(const Duration(milliseconds: 700));
      setState(() {
        _retournees[a] = false;
        _retournees[b] = false;
        _selection = [];
        _enPause = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$_secondes s · $_coups coups')),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
    );
  }
}
