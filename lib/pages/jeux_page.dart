import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'jeux/memory_accueil_page.dart';
import 'jeux/words_accueil_page.dart';

/// Page des jeux : Words et Memory.
class JeuxPage extends StatelessWidget {
  const JeuxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TuileJeu(
          titre: 'Words',
          description: 'Trouve le mot caché dans la grille de lettres.',
          icone: Icons.extension,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const WordsAccueilPage()),
          ),
        ),
        const SizedBox(height: 12),
        _TuileJeu(
          titre: 'Memory',
          description: 'Retrouve les paires mot anglais / traduction française.',
          icone: Icons.grid_view,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const MemoryAccueilPage()),
          ),
        ),
      ],
    );
  }
}

class _TuileJeu extends StatelessWidget {
  const _TuileJeu({
    required this.titre,
    required this.description,
    required this.icone,
    required this.onTap,
  });

  final String titre;
  final String description;
  final IconData icone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.jeuxFond,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icone, color: AppColors.jeuxTexte),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(description, style: const TextStyle(color: AppColors.texteSecondaire)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
