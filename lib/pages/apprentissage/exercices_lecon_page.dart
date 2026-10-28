import 'package:flutter/material.dart';

import '../../modeles/contenu.dart';
import '../../theme/app_colors.dart';
import 'cartes_page.dart';
import 'mini_lecon_page.dart';
import 'phrases_page.dart';

/// La leçon propose plusieurs exercices : cartes, phrases à traduire, et
/// parfois une mini-leçon. Cette page les liste, chacun ouvrant son écran.
class ExercicesLeconPage extends StatelessWidget {
  const ExercicesLeconPage({super.key, required this.lecon});

  final Lecon lecon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lecon.titre)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${lecon.niveau} · ${lecon.cartes.length} mots',
            style: const TextStyle(color: AppColors.texteSecondaire),
          ),
          const SizedBox(height: 16),
          _TuileExercice(
            icone: Icons.style,
            titre: 'Cartes',
            sousTitre: '${lecon.cartes.length} cartes à retourner',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => CartesPage(lecon: lecon)),
            ),
          ),
          if (lecon.phrases.isNotEmpty) ...[
            const SizedBox(height: 12),
            _TuileExercice(
              icone: Icons.translate,
              titre: 'Phrases à traduire',
              sousTitre: '${lecon.phrases.length} phrases, anglais et français',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => PhrasesPage(lecon: lecon)),
              ),
            ),
          ],
          if (lecon.miniLecon != null) ...[
            const SizedBox(height: 12),
            _TuileExercice(
              icone: Icons.school,
              titre: 'Mini-leçon',
              sousTitre: 'La règle, des exemples, puis un petit quiz',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MiniLeconPage(lecon: lecon),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TuileExercice extends StatelessWidget {
  const _TuileExercice({
    required this.icone,
    required this.titre,
    required this.sousTitre,
    required this.onTap,
  });

  final IconData icone;
  final String titre;
  final String sousTitre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.bleuPrincipal.withValues(alpha: 0.12),
          child: Icon(icone, color: AppColors.bleuPrincipal),
        ),
        title: Text(titre, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(sousTitre),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
