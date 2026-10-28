import 'package:flutter/material.dart';

import '../../modeles/contenu.dart';
import '../../services/progress_service.dart';
import '../../services/tts_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';

/// La mini-leçon : d'abord la règle et des exemples, puis un petit quiz
/// (3 à 5 questions à choix multiples).
class MiniLeconPage extends StatefulWidget {
  const MiniLeconPage({super.key, required this.lecon});

  final Lecon lecon;

  @override
  State<MiniLeconPage> createState() => _MiniLeconPageState();
}

class _MiniLeconPageState extends State<MiniLeconPage> {
  bool _quizCommence = false;
  int _index = 0;
  int? _choixSelectionne;
  bool _valide = false;
  int _nombreDeReussites = 0;

  MiniLecon get _miniLecon => widget.lecon.miniLecon!;

  void _choisir(int indexChoix) {
    if (_valide) return;
    setState(() => _choixSelectionne = indexChoix);
  }

  void _valider() {
    if (_choixSelectionne == null) return;
    setState(() {
      _valide = true;
      if (_choixSelectionne == _miniLecon.qcm[_index].bonneReponseIndex) {
        _nombreDeReussites++;
      }
    });
  }

  void _suivant() {
    setState(() {
      _index++;
      _choixSelectionne = null;
      _valide = false;
    });
  }

  Future<void> _terminer() async {
    final score = ((_nombreDeReussites / _miniLecon.qcm.length) * 100).round();
    await ProgressService.enregistrerResultatLecon(
      leconId: '${widget.lecon.id}_minilecon',
      score: score,
      type: widget.lecon.id.startsWith('deck-') ? 'paquet' : 'lecon',
    );
    await UserService.enregistrerActivite();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lecon.titre)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: !_quizCommence
            ? _ecranRegle()
            : (_index >= _miniLecon.qcm.length ? _ecranRecap() : _ecranQuestion()),
      ),
    );
  }

  Widget _ecranRegle() {
    return ListView(
      children: [
        Text(
          'La règle',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(_miniLecon.regle, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 24),
        Text(
          'Exemples',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        for (final exemple in _miniLecon.exemples)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.carteBordure),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      exemple,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Écouter',
                    icon: const Icon(Icons.volume_up, color: AppColors.bleuPrincipal),
                    onPressed: () => TtsService.lire(exemple),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => setState(() => _quizCommence = true),
          child: const Text('Commencer le quiz'),
        ),
      ],
    );
  }

  Widget _ecranQuestion() {
    final question = _miniLecon.qcm[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Question ${_index + 1} / ${_miniLecon.qcm.length}',
          style: const TextStyle(color: AppColors.texteSecondaire),
        ),
        const SizedBox(height: 12),
        Text(
          question.question,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < question.choix.length; i++)
          _ChoixQcm(
            texte: question.choix[i],
            selectionne: _choixSelectionne == i,
            bonneReponse: _valide && i == question.bonneReponseIndex,
            mauvaiseReponseChoisie: _valide && _choixSelectionne == i && i != question.bonneReponseIndex,
            onTap: () => _choisir(i),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _valide
              ? _suivant
              : (_choixSelectionne == null ? null : _valider),
          child: Text(_valide ? 'Suivant' : 'Valider'),
        ),
      ],
    );
  }

  Widget _ecranRecap() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _nombreDeReussites == _miniLecon.qcm.length ? Icons.emoji_events : Icons.school,
          size: 48,
          color: AppColors.orange,
        ),
        const SizedBox(height: 12),
        Text(
          '$_nombreDeReussites / ${_miniLecon.qcm.length} bonnes réponses',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        OutlinedButton(onPressed: _terminer, child: const Text('Terminer')),
      ],
    );
  }
}

class _ChoixQcm extends StatelessWidget {
  const _ChoixQcm({
    required this.texte,
    required this.selectionne,
    required this.bonneReponse,
    required this.mauvaiseReponseChoisie,
    required this.onTap,
  });

  final String texte;
  final bool selectionne;
  final bool bonneReponse;
  final bool mauvaiseReponseChoisie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color fond = Colors.white;
    Color bordure = AppColors.carteBordure;
    if (bonneReponse) {
      fond = AppColors.succesFond;
      bordure = AppColors.succesTexte;
    } else if (mauvaiseReponseChoisie) {
      fond = AppColors.erreurFond;
      bordure = AppColors.erreurTexte;
    } else if (selectionne) {
      bordure = AppColors.bleuPrincipal;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: fond,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: bordure, width: selectionne ? 2 : 1),
          ),
          child: Text(texte),
        ),
      ),
    );
  }
}
