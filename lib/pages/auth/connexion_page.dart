import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';

/// Écran affiché quand personne n'est connecté : permet de se connecter
/// ou de créer un compte, selon le mode choisi.
///
/// On n'a pas besoin de naviguer manuellement vers l'application après
/// une connexion réussie : main.dart écoute les changements de connexion
/// et affiche automatiquement l'écran suivant.
class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key});

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final _cleFormulaire = GlobalKey<FormState>();
  final _pseudoControleur = TextEditingController();
  final _motDePasseControleur = TextEditingController();

  bool _modeInscription = false;
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _pseudoControleur.dispose();
    _motDePasseControleur.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    if (!_cleFormulaire.currentState!.validate()) return;

    setState(() {
      _enCours = true;
      _erreur = null;
    });

    try {
      if (_modeInscription) {
        await AuthService.inscription(
          pseudo: _pseudoControleur.text,
          motDePasse: _motDePasseControleur.text,
        );
      } else {
        await AuthService.connexion(
          pseudo: _pseudoControleur.text,
          motDePasse: _motDePasseControleur.text,
        );
      }
    } catch (erreur) {
      // En temps normal, AuthService transforme toujours l'erreur en
      // AuthException avec un message clair. Si on arrive quand même ici
      // avec autre chose, on l'affiche telle quelle plutôt que de cacher
      // l'information derrière un message vague.
      debugPrint('Écran de connexion : erreur reçue : $erreur');
      setState(() {
        _erreur = erreur is AuthException ? erreur.message : '$erreur';
      });
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _cleFormulaire,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Mon anglais',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.bleuFonce,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _modeInscription ? 'Créer un compte' : 'Se connecter',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _pseudoControleur,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Pseudo',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valeur) {
                      final v = (valeur ?? '').trim();
                      if (v.length < 3 || v.length > 20) {
                        return '3 à 20 caractères';
                      }
                      if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(v)) {
                        return 'Lettres, chiffres et _ uniquement';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _motDePasseControleur,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _valider(),
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valeur) {
                      if ((valeur ?? '').length < 6) {
                        return '6 caractères minimum';
                      }
                      return null;
                    },
                  ),
                  if (_erreur != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.erreurFond,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _erreur!,
                        style: const TextStyle(color: AppColors.erreurTexte),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _enCours ? null : _valider,
                    child: _enCours
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _modeInscription
                                ? 'Créer mon compte'
                                : 'Se connecter',
                          ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _enCours
                        ? null
                        : () => setState(() {
                            _modeInscription = !_modeInscription;
                            _erreur = null;
                          }),
                    child: Text(
                      _modeInscription
                          ? 'J\'ai déjà un compte'
                          : 'Créer un compte',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
