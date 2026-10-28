import 'package:flutter/material.dart';

import '../../services/user_service.dart';

/// Ouvre une fenêtre pour saisir un code ami et envoyer la demande.
/// Affiche directement l'erreur dans la fenêtre si le code est invalide.
Future<void> ouvrirAjoutAmi(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _AjouterAmiDialog(),
  );
}

class _AjouterAmiDialog extends StatefulWidget {
  const _AjouterAmiDialog();

  @override
  State<_AjouterAmiDialog> createState() => _AjouterAmiDialogState();
}

class _AjouterAmiDialogState extends State<_AjouterAmiDialog> {
  final _controleur = TextEditingController();
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await UserService.envoyerDemandeAmi(_controleur.text);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande d\'ami envoyée !')),
        );
      }
    } catch (erreur) {
      // En temps normal, UserService renvoie une UserServiceException
      // avec un message clair. Si on arrive ici avec autre chose (une
      // erreur Firestore, par exemple), on l'affiche telle quelle plutôt
      // que de cacher l'information derrière un message vague.
      debugPrint('Ajout ami : erreur reçue : $erreur');
      setState(() {
        _erreur = erreur is UserServiceException ? erreur.message : '$erreur';
      });
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un ami'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Demande à ton ami son code et saisis-le ici :'),
          const SizedBox(height: 12),
          TextField(
            controller: _controleur,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Code ami',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _envoyer(),
          ),
          if (_erreur != null) ...[
            const SizedBox(height: 8),
            Text(_erreur!, style: const TextStyle(color: Color(0xFFB42318))),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _enCours ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _enCours ? null : _envoyer,
          child: _enCours
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Envoyer'),
        ),
      ],
    );
  }
}
