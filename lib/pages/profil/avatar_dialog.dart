import 'package:flutter/material.dart';

import '../../theme/app_avatars.dart';

/// Ouvre une fenêtre avec les avatars possibles, et renvoie l'identifiant
/// choisi (ou null si l'utilisateur annule).
Future<String?> choisirAvatar(BuildContext context, String avatarActuel) {
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Choisir un avatar'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final entree in AppAvatars.icones.entries)
              _TuileAvatar(
                id: entree.key,
                icone: entree.value,
                selectionne: entree.key == avatarActuel,
                onTap: () => Navigator.of(context).pop(entree.key),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      );
    },
  );
}

class _TuileAvatar extends StatelessWidget {
  const _TuileAvatar({
    required this.id,
    required this.icone,
    required this.selectionne,
    required this.onTap,
  });

  final String id;
  final IconData icone;
  final bool selectionne;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final couleurPrincipale = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selectionne
              ? couleurPrincipale.withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border.all(
            color: selectionne ? couleurPrincipale : const Color(0xFFE3E6EF),
            width: selectionne ? 2 : 1,
          ),
        ),
        child: Icon(icone, color: couleurPrincipale),
      ),
    );
  }
}
