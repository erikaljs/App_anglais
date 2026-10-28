import 'dart:math';

import 'package:flutter/material.dart';

import '../../modeles/contenu.dart';
import '../../services/correction_service.dart';
import '../../services/progress_service.dart';
import '../../services/tts_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';

/// Une phrase à traduire, dans un sens choisi au hasard (français → anglais
/// ou anglais → français).
class _ExercicePhrase {
  const _ExercicePhrase({
    required this.consigne,
    required this.question,
    required this.reponsesAcceptees,
    required this.cibleAnglais,
  });

  final String consigne; // "Traduis en anglais" ou "Traduis en français"
  final String question;
  final List<String> reponsesAcceptees;
  final bool cibleAnglais;
}

/// L'exercice de traduction : une phrase à la fois, réponse tapée. La
/// correction (tolérance aux majuscules/ponctuation/contractions/fautes
/// de frappe) est faite par CorrectionService.
class PhrasesPage extends StatefulWidget {
  const PhrasesPage({super.key, required this.lecon});

  final Lecon lecon;

  @override
  State<PhrasesPage> createState() => _PhrasesPageState();
}

class _PhrasesPageState extends State<PhrasesPage> {
  late List<_ExercicePhrase> _exercices;
  final _controleur = TextEditingController();

  int _index = 0;
  ResultatCorrection? _resultat; // null = pas encore validé
  int _nombreDeReussites = 0;
  final List<_ExercicePhrase> _ratees = [];

  @override
  void initState() {
    super.initState();
    final hasard = Random();
    _exercices = [
      for (final phrase in widget.lecon.phrases)
        if (hasard.nextBool())
          _ExercicePhrase(
            consigne: 'Traduis en anglais',
            question: phrase.fr,
            reponsesAcceptees: phrase.en,
            cibleAnglais: true,
          )
        else
          _ExercicePhrase(
            consigne: 'Traduis en français',
            question: phrase.en.first,
            reponsesAcceptees: [phrase.fr],
            cibleAnglais: false,
          ),
    ];
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  void _valider() {
    final exercice = _exercices[_index];
    final resultat = CorrectionService.corriger(
      saisie: _controleur.text,
      reponsesAcceptees: exercice.reponsesAcceptees,
      cibleAnglais: exercice.cibleAnglais,
    );
    setState(() {
      _resultat = resultat;
      if (resultat.correcte) {
        _nombreDeReussites++;
      } else {
        _ratees.add(exercice);
      }
    });
  }

  void _suivant() {
    setState(() {
      _index++;
      _resultat = null;
      _controleur.clear();
    });
  }

  Future<void> _terminer() async {
    final score = ((_nombreDeReussites / _exercices.length) * 100).round();
    await ProgressService.enregistrerResultatLecon(
      leconId: '${widget.lecon.id}_phrases',
      score: score,
      type: widget.lecon.id.startsWith('deck-') ? 'paquet' : 'lecon',
    );
    await UserService.enregistrerActivite();
    if (mounted) Navigator.of(context).pop();
  }

  /// Le texte anglais à écouter pour l'exercice en cours, s'il y en a un
  /// de disponible tout de suite (la question si elle est déjà en
  /// anglais, sinon la réponse une fois validée).
  String? _texteAnglaisAEcouter(_ExercicePhrase exercice) {
    if (!exercice.cibleAnglais) return exercice.question;
    if (_resultat != null) return exercice.reponsesAcceptees.first;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final termine = _index >= _exercices.length;
    return Scaffold(
      appBar: AppBar(title: Text(widget.lecon.titre)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: termine ? _ecranRecap() : _ecranQuestion(),
      ),
    );
  }

  Widget _ecranQuestion() {
    final exercice = _exercices[_index];
    final resultat = _resultat;
    final texteAEcouter = _texteAnglaisAEcouter(exercice);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Phrase ${_index + 1} / ${_exercices.length} · ${exercice.consigne}',
          style: const TextStyle(color: AppColors.texteSecondaire),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.carteBordure),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                exercice.question,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              if (texteAEcouter != null)
                IconButton(
                  tooltip: 'Écouter en anglais',
                  icon: const Icon(Icons.volume_up, color: AppColors.bleuPrincipal),
                  onPressed: () => TtsService.lire(texteAEcouter),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controleur,
          enabled: resultat == null,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Ta traduction',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            if (resultat == null) _valider();
          },
        ),
        if (resultat != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: resultat.correcte ? AppColors.succesFond : AppColors.erreurFond,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              resultat.correcte
                  ? (resultat.message ?? 'Correct !')
                  : 'Pas tout à fait. Réponse possible : ${exercice.reponsesAcceptees.first}',
              style: TextStyle(
                color: resultat.correcte ? AppColors.succesTexte : AppColors.erreurTexte,
              ),
            ),
          ),
          if (resultat.conseilMajuscule != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bleuPrincipal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                resultat.conseilMajuscule!,
                style: const TextStyle(color: AppColors.bleuFonce),
              ),
            ),
          ],
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: resultat == null ? _valider : _suivant,
          child: Text(resultat == null ? 'Valider' : 'Suivant'),
        ),
      ],
    );
  }

  Widget _ecranRecap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          _ratees.isEmpty ? Icons.emoji_events : Icons.flag,
          size: 48,
          color: AppColors.orange,
        ),
        const SizedBox(height: 12),
        Text(
          '$_nombreDeReussites / ${_exercices.length} phrases correctes',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        if (_ratees.isNotEmpty)
          Expanded(
            child: ListView(
              children: [
                for (final exercice in _ratees)
                  Card(
                    child: ListTile(
                      title: Text(exercice.question),
                      subtitle: Text(exercice.reponsesAcceptees.join(' / ')),
                    ),
                  ),
              ],
            ),
          )
        else
          const Spacer(),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: _terminer, child: const Text('Terminer')),
      ],
    );
  }
}
