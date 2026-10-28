// Tests du service de correction des phrases à traduire (voir
// lib/services/correction_service.dart).

import 'package:flutter_test/flutter_test.dart';
import 'package:mon_anglais/services/correction_service.dart';

void main() {
  group('Réponse strictement identique', () {
    test('est acceptée sans aucun message', () {
      final resultat = CorrectionService.corriger(
        saisie: "He's Italian.",
        reponsesAcceptees: ["He's Italian."],
        cibleAnglais: true,
      );
      expect(resultat.correcte, isTrue);
      expect(resultat.message, isNull);
    });
  });

  group('Majuscules, ponctuation et espaces : ne font pas perdre de points', () {
    test('minuscules et sans point final', () {
      final resultat = CorrectionService.corriger(
        saisie: 'are you engineers',
        reponsesAcceptees: ['Are you engineers?'],
        cibleAnglais: true,
      );
      expect(resultat.correcte, isTrue);
    });

    test('espaces multiples et majuscules partout', () {
      final resultat = CorrectionService.corriger(
        saisie: '  IT   ISN\'T   MY BOOK  ',
        reponsesAcceptees: ["It isn't my book."],
        cibleAnglais: true,
      );
      expect(resultat.correcte, isTrue);
    });
  });

  group('Formes contractées anglaises (le bug signalé)', () {
    test("'He is Italian' est accepté pour 'He's Italian.'", () {
      final resultat = CorrectionService.corriger(
        saisie: 'He is Italian',
        reponsesAcceptees: ["He's Italian."],
        cibleAnglais: true,
      );
      expect(resultat.correcte, isTrue);
      expect(resultat.message, contains("He's Italian"));
    });

    test("'He's Italian' (forme contractée) ne déclenche pas de message", () {
      final resultat = CorrectionService.corriger(
        saisie: "He's Italian",
        reponsesAcceptees: ["He's Italian."],
        cibleAnglais: true,
      );
      expect(resultat.correcte, isTrue);
      expect(resultat.message, isNull);
    });

    test("'It is not my book' est accepté pour \"It isn't my book.\"", () {
      final resultat = CorrectionService.corriger(
        saisie: 'It is not my book',
        reponsesAcceptees: ["It isn't my book."],
        cibleAnglais: true,
      );
      expect(resultat.correcte, isTrue);
    });

    test("'They are not late' est accepté pour \"They aren't late.\"", () {
      final resultat = CorrectionService.corriger(
        saisie: 'They are not late',
        reponsesAcceptees: ["They aren't late."],
        cibleAnglais: true,
      );
      expect(resultat.correcte, isTrue);
    });

    test("'I will be in a meeting' est accepté pour \"I'll be in a meeting.\"", () {
      final resultat = CorrectionService.corriger(
        saisie: 'I will be in a meeting at 3 p.m.',
        reponsesAcceptees: ["I'll be in a meeting at 3 p.m."],
        cibleAnglais: true,
      );
      expect(resultat.correcte, isTrue);
    });

    test("'has got' : \"He's got two brothers\" accepté pour \"He has got two brothers.\"", () {
      final resultat = CorrectionService.corriger(
        saisie: "He's got two brothers",
        reponsesAcceptees: ['He has two brothers.', "He's got two brothers."],
        cibleAnglais: true,
      );
      expect(resultat.correcte, isTrue);
    });

    test("'cannot' et \"can't\" sont équivalents", () {
      final resultat = CorrectionService.corriger(
        saisie: 'We cannot come',
        reponsesAcceptees: ["We can't come."],
        cibleAnglais: true,
      );
      expect(resultat.correcte, isTrue);
    });
  });

  group('Plusieurs réponses acceptées', () {
    test('une réponse alternative différente de la principale est signalée', () {
      final resultat = CorrectionService.corriger(
        saisie: 'We often eat out',
        reponsesAcceptees: ['We often go to the restaurant.', 'We often eat out.'],
        cibleAnglais: true,
      );
      expect(resultat.correcte, isTrue);
      expect(resultat.message, contains('We often go to the restaurant'));
    });

    test('la réponse principale ne déclenche pas de message', () {
      final resultat = CorrectionService.corriger(
        saisie: 'We often go to the restaurant',
        reponsesAcceptees: ['We often go to the restaurant.', 'We often eat out.'],
        cibleAnglais: true,
      );
      expect(resultat.correcte, isTrue);
      expect(resultat.message, isNull);
    });
  });

  group('Petites fautes de frappe (une lettre, mot de plus de 4 lettres)', () {
    test("'Itlian' pour 'Italian' est compté juste, avec un avertissement", () {
      final resultat = CorrectionService.corriger(
        saisie: 'He is Itlian',
        reponsesAcceptees: ["He's Italian."],
        cibleAnglais: true,
      );
      expect(resultat.correcte, isTrue);
      expect(resultat.message, contains('orthographe'));
    });

    test('une lettre remplacée par une autre sur un mot long est tolérée', () {
      final resultat = CorrectionService.corriger(
        saisie: 'My flighy is delayed',
        reponsesAcceptees: ['My flight is delayed.'],
        cibleAnglais: true,
      );
      expect(resultat.correcte, isTrue);
    });

    test('une faute sur un mot court (4 lettres ou moins) reste fausse', () {
      // "the" (3 lettres) mal écrit : pas de tolérance.
      final resultat = CorrectionService.corriger(
        saisie: 'I am teh student',
        reponsesAcceptees: ['I am the student.'],
        cibleAnglais: true,
      );
      expect(resultat.correcte, isFalse);
    });

    test('deux lettres différentes sur le même mot restent fausses', () {
      final resultat = CorrectionService.corriger(
        saisie: 'He is Itlanin',
        reponsesAcceptees: ["He's Italian."],
        cibleAnglais: true,
      );
      expect(resultat.correcte, isFalse);
    });
  });

  group('Conseil de majuscule (nationalités, langues, jours, mois)', () {
    test('nationalité sans majuscule : accepté, avec un conseil', () {
      final resultat = CorrectionService.corriger(
        saisie: 'he is italian',
        reponsesAcceptees: ["He's Italian."],
        cibleAnglais: true,
      );
      expect(resultat.correcte, isTrue);
      expect(resultat.conseilMajuscule, contains('Italian'));
    });

    test('nationalité avec majuscule : pas de conseil', () {
      final resultat = CorrectionService.corriger(
        saisie: 'He is Italian',
        reponsesAcceptees: ["He's Italian."],
        cibleAnglais: true,
      );
      expect(resultat.correcte, isTrue);
      expect(resultat.conseilMajuscule, isNull);
    });

    test('pas de conseil de majuscule quand la cible est le français', () {
      final resultat = CorrectionService.corriger(
        saisie: 'il est italien',
        reponsesAcceptees: ['Il est italien.'],
        cibleAnglais: false,
      );
      expect(resultat.correcte, isTrue);
      expect(resultat.conseilMajuscule, isNull);
    });
  });

  group('Réponses fausses : doivent rester fausses', () {
    test('une phrase complètement différente est refusée', () {
      final resultat = CorrectionService.corriger(
        saisie: 'She is a doctor',
        reponsesAcceptees: ["He's Italian."],
        cibleAnglais: true,
      );
      expect(resultat.correcte, isFalse);
    });

    test('un mot manquant (nombre de mots différent) est refusé', () {
      final resultat = CorrectionService.corriger(
        saisie: 'My flight delayed',
        reponsesAcceptees: ['My flight is delayed.'],
        cibleAnglais: true,
      );
      expect(resultat.correcte, isFalse);
    });

    test('une réponse vide est refusée', () {
      final resultat = CorrectionService.corriger(
        saisie: '',
        reponsesAcceptees: ["He's Italian."],
        cibleAnglais: true,
      );
      expect(resultat.correcte, isFalse);
    });
  });
}
