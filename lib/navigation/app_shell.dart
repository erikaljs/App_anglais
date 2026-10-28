import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import '../pages/jeux_page.dart';
import '../pages/perso_page.dart';
import '../pages/profil_page.dart';

/// Largeur à partir de laquelle on bascule vers la navigation "grand écran"
/// (NavigationRail) au lieu de la barre en bas. Voir CLAUDE.md.
const _largeurEcranLarge = 800.0;

/// Largeur maximale du contenu sur grand écran, pour ne pas que les pages
/// s'étalent sur toute la largeur d'un écran d'ordinateur.
const _largeurMaxContenu = 900.0;

/// Un onglet de la navigation : son titre, ses icônes et la page associée.
class _Onglet {
  const _Onglet({
    required this.titre,
    required this.icone,
    required this.iconeSelectionnee,
    required this.page,
  });

  final String titre;
  final IconData icone;
  final IconData iconeSelectionnee;
  final Widget page;
}

/// "Coquille" de l'application : affiche la page de l'onglet choisi, avec
/// la navigation adaptée à la taille de l'écran (bas pour un téléphone,
/// sur le côté pour un écran large comme un PC).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _indexSelectionne = 0;

  // La liste des 4 onglets, dans l'ordre demandé : Home, Jeux, Perso, Profil.
  static const _onglets = [
    _Onglet(
      titre: 'Home',
      icone: Icons.home_outlined,
      iconeSelectionnee: Icons.home,
      page: HomePage(),
    ),
    _Onglet(
      titre: 'Jeux',
      icone: Icons.sports_esports_outlined,
      iconeSelectionnee: Icons.sports_esports,
      page: JeuxPage(),
    ),
    _Onglet(
      titre: 'Perso',
      icone: Icons.folder_outlined,
      iconeSelectionnee: Icons.folder,
      page: PersoPage(),
    ),
    _Onglet(
      titre: 'Profil',
      icone: Icons.person_outline,
      iconeSelectionnee: Icons.person,
      page: ProfilPage(),
    ),
  ];

  void _choisirOnglet(int index) {
    setState(() => _indexSelectionne = index);
  }

  @override
  Widget build(BuildContext context) {
    final largeurEcran = MediaQuery.of(context).size.width;
    final ecranLarge = largeurEcran >= _largeurEcranLarge;
    final ongletActuel = _onglets[_indexSelectionne];

    // Le contenu de la page, centré et limité en largeur sur grand écran.
    final contenu = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _largeurMaxContenu),
        child: ongletActuel.page,
      ),
    );

    if (ecranLarge) {
      // Écran large (PC, tablette en largeur) : navigation sur le côté.
      return Scaffold(
        appBar: AppBar(title: Text(ongletActuel.titre)),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _indexSelectionne,
              onDestinationSelected: _choisirOnglet,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final onglet in _onglets)
                  NavigationRailDestination(
                    icon: Icon(onglet.icone),
                    selectedIcon: Icon(onglet.iconeSelectionnee),
                    label: Text(onglet.titre),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: contenu),
          ],
        ),
      );
    }

    // Écran étroit (téléphone) : navigation en bas.
    return Scaffold(
      appBar: AppBar(title: Text(ongletActuel.titre)),
      body: contenu,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexSelectionne,
        onDestinationSelected: _choisirOnglet,
        destinations: [
          for (final onglet in _onglets)
            NavigationDestination(
              icon: Icon(onglet.icone),
              selectedIcon: Icon(onglet.iconeSelectionnee),
              label: onglet.titre,
            ),
        ],
      ),
    );
  }
}
