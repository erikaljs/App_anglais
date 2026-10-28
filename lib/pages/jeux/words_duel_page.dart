import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/game_service.dart';
import '../../theme/app_colors.dart';
import 'words_accueil_page.dart';
import 'words_jeu_page.dart';

/// Gère le déroulement d'un duel Words : affiche la manche à jouer (si
/// c'est mon tour), lance l'écran de jeu, puis enchaîne la manche
/// suivante ou revient à l'accueil une fois mes 2 manches terminées.
class WordsDuelPage extends StatefulWidget {
  const WordsDuelPage({super.key, required this.idPartie});

  final String idPartie;

  @override
  State<WordsDuelPage> createState() => _WordsDuelPageState();
}

class _WordsDuelPageState extends State<WordsDuelPage> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _futurePartie;

  @override
  void initState() {
    super.initState();
    _futurePartie = _charger();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _charger() {
    return FirebaseFirestore.instance.collection('games').doc(widget.idPartie).get();
  }

  Future<void> _jouerLaManche(Map<String, dynamic> partie, int manche) async {
    final grilles = GameService.grillesDeLaManche(partie, manche);
    final minuteur = partie['minuteur'] as int;

    final completeur = Completer<int>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WordsJeuPage(
          grilles: grilles,
          minuteurSecondes: minuteur,
          titre: 'Words · manche $manche',
          onTerminer: (score) {
            if (!completeur.isCompleted) completeur.complete(score);
          },
        ),
      ),
    );
    if (!completeur.isCompleted) completeur.complete(0); // sorti sans terminer

    final score = await completeur.future;
    await GameService.enregistrerMancheWords(
      idPartie: widget.idPartie,
      manche: manche,
      score: score,
    );

    if (!mounted) return;
    setState(() => _futurePartie = _charger());
  }

  @override
  Widget build(BuildContext context) {
    final monUid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Duel Words')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _futurePartie,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final partie = snapshot.data!.data()!;
          final statut = partie['statut'] as String;
          final manche = partie['manche'] as int;
          final tourDe = partie['tourDe'] as String;

          if (statut == 'terminee') {
            final monScore = GameService.scoreTotalWords(partie, monUid) ?? 0;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, size: 48, color: AppColors.orange),
                  const SizedBox(height: 12),
                  Text('Duel terminé ! Ton score : $monScore', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const WordsAccueilPage()),
                      (route) => route.isFirst,
                    ),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            );
          }

          if (tourDe != monUid) {
            return const Center(
              child: Text(
                'Ce n\'est pas ton tour : en attente de ton ami.',
                style: TextStyle(color: AppColors.texteSecondaire),
              ),
            );
          }

          final mesScores = Map<String, dynamic>.from(
            (partie['scores'] as Map)[monUid] as Map? ?? {},
          );
          final dejaJoueCetteManche = mesScores.containsKey('manche$manche');
          if (dejaJoueCetteManche) {
            // Au cas où : on relit, la manche a dû avancer.
            return const Center(child: CircularProgressIndicator());
          }

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Manche $manche / 2', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Minuteur : ${partie['minuteur']} secondes',
                  style: const TextStyle(color: AppColors.texteSecondaire),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _jouerLaManche(partie, manche),
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
}
