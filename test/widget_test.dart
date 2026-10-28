// Test très simple : on vérifie que l'application démarre et affiche
// bien la page d'accueil "Home".

import 'package:flutter_test/flutter_test.dart';

import 'package:mon_anglais/main.dart';

void main() {
  testWidgets('L\'application démarre sur la page Home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MonAnglaisApp());

    // Le titre "Home" doit apparaître (dans la barre du haut et le contenu).
    expect(find.text('Home'), findsWidgets);

    // Les 4 onglets doivent être visibles.
    expect(find.text('Jeux'), findsOneWidget);
    expect(find.text('Perso'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
  });
}
