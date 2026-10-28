# Mon anglais — contexte du projet

Ce fichier décrit tout le projet. Lis-le en entier avant de commencer une tâche.

## Qui je suis et comment m'aider

Je m'appelle Erika et je débute en développement.
Réponds-moi en français, explique simplement ce que tu fais et pourquoi, étape par étape.
Travaille sur une seule étape du plan à la fois (voir « Plan de développement »). Ne commence pas l'étape suivante sans que je le demande.
Quand je dois faire quelque chose moi-même (console Firebase, connexion à un compte, commande interactive, test sur téléphone), arrête-toi et donne-moi des instructions numérotées, clic par clic.
À la fin de chaque étape, fais-moi un résumé : ce qui a été fait, les fichiers créés, ce que je dois tester et comment.

## Le projet

Un site pour apprendre l'anglais, utilisable sur PC, tablette et téléphone (iPhone compris) avec un simple lien. Nom provisoire : « Mon anglais ».

| Élément | Choix |
|---|---|
| Framework | Flutter Web, installable comme une appli (PWA) |
| Comptes et données | Firebase Auth + Cloud Firestore (offre gratuite Spark, pas de Cloud Functions) |
| Hébergement | GitHub Pages, repo erikaljs/App_anglais |
| Adresse du site | https://erikaljs.github.io/App_anglais/ |
| Mise en ligne | Automatique par GitHub Actions à chaque push sur main |

## Règles techniques

- Garder la stratégie d'URL par défaut de Flutter Web (avec #). Ne jamais utiliser usePathUrlStrategy : GitHub Pages renverrait des erreurs 404 au rechargement.
- Le build web se fait avec --base-href /App_anglais/ (déjà dans le workflow).
- Interface en français ; le contenu d'apprentissage est en anglais et en français.
- Responsive, téléphone d'abord (390 px de large) :
  - écran étroit : barre de navigation en bas ;
  - écran large (plus de 800 px) : navigation sur le côté (NavigationRail), contenu centré, largeur max ~900 px.
- Code simple et lisible pour une débutante : peu de dépendances, fichiers courts, commentaires en français sur les parties importantes.
- Gestion d'état simple : provider ou setState. Pas d'architecture complexe.
- Contenu officiel (leçons, cartes, phrases, mini-leçons) : fichiers JSON dans assets/contenu/, embarqués dans l'appli. Firestore sert seulement aux données des utilisateurs (comptes, progression, amis, paquets perso, chat, parties).
- Jamais de mot de passe stocké ou affiché en clair. La configuration Firebase web (firebase_options.dart) peut être publique, c'est normal ; la sécurité vient des règles Firestore.
- Après chaque modification : flutter analyze sans erreur, puis test avec flutter run -d chrome.
- Un commit git à la fin de chaque sous-étape, message clair en français.
- Ne fais jamais de git push, même si je dis oui ou si ça semble pratique : c'est toujours moi qui le fais. Un push met le site en ligne. À la fin de chaque étape, rappelle-moi simplement de taper git push moi-même dans le terminal, et dis-moi quoi vérifier ensuite dans l'onglet Actions de GitHub.

## Design (repris de la maquette)

- Police : Plus Jakarta Sans (package google_fonts).
- Couleurs :
  - bleu principal #2F5BEA, bleu foncé #16213E, fond #F5F6FA ;
  - cartes blanches, bordure #E3E6EF, texte secondaire #4A5470 ;
  - orange (série de jours, progression) #FF8A3D ;
  - succès : texte #0A6B53 sur #E2F4EE ; erreur : texte #B42318 sur #FDECEA.
- Couleurs des catégories (fond / texte) : Débutant #E6ECFD / #2348C7, Voyage #E2F4EE / #0A6B53, Sport #FDEBDD / #A8380B, Technique #EEE7FA / #5B33A6, Perso blanc / #16213E, Jeux #16213E / blanc.
- Coins arrondis de 14 à 20 px, boutons d'au moins 44 px de haut, pas d'emoji dans l'interface (icônes Material).
- Navigation : Home, Jeux, Perso, Profil.

## Fonctionnalités

### Comptes et amis

- Inscription et connexion avec pseudo + mot de passe. Firebase Auth exige un e-mail : on crée en coulisse pseudo@mon-anglais.local (pseudo en minuscules). L'utilisateur ne voit jamais cet e-mail.
- Pseudo : 3 à 20 caractères, lettres, chiffres et _. Unicité garantie par la collection pseudos/{pseudo}, écrite dans une transaction.
- À l'inscription, génération d'un code ami unique de 6 caractères (sans 0, O, 1, I), enregistré dans codesAmis/{code}.
- Page profil : pseudo, avatar (choix parmi quelques icônes), statistiques (série de jours, mots appris, duels gagnés), code ami avec bouton « Copier », bouton « Ajouter un ami » (saisie d'un code → demande → l'autre accepte ou refuse), liste d'amis.

### Home

- Une tuile par catégorie avec barre de progression, bouton « Reprendre » (dernière leçon), série de jours, mot du jour.
- Organisation : Catégorie → Leçon → Exercices. Statut de leçon : à faire / en cours / terminée, avec un score en %.

### Exercices (communs à toutes les catégories)

- Cartes : carte en anglais, un tap la retourne en français ; swipe droite = « je sais », swipe gauche = « à revoir », plus deux boutons équivalents. Écran récap en fin de série avec les cartes ratées et un bouton « Revoir les cartes ratées ».
- Phrase à traduire (EN → FR et FR → EN) : réponse tapée ou assemblée en touchant des mots proposés. Tolérance aux majuscules, à la ponctuation et aux espaces ; plusieurs réponses correctes possibles.
- Mini-leçon : explication courte (règle + exemples) puis 3 à 5 QCM.
- Répétition espacée : carte ratée → revient après 1 jour ; réussie → 3 jours, puis 7 jours.

### Catégories

Débutant, Voyage, Sport, Technique, Perso, Jeux.

### Perso et partage entre amis

- L'utilisateur crée ses paquets : nom, cartes (anglais / français), phrases à traduire. Il peut les modifier et les supprimer.
- Visibilité par paquet : amis (par défaut) ou privé.
- Sur le profil d'un ami : section « Ses paquets » avec ses paquets amis. Bouton « Ajouter à mes révisions » : c'est un lien vers le paquet (les modifications de l'ami sont visibles) ; la progression reste propre à chaque utilisateur. Option « Faire une copie » pour garder une version modifiable.
- Si le paquet repasse en privé, est supprimé, ou si l'amitié est retirée, il disparaît des révisions de l'ami.

### Jeux

- Words : grille 4 × 4 de lettres ; on touche les lettres pour former un mot du thème (Sport, Voyage, Technique, Mélange). Points = nombre de lettres × 2. La traduction française du mot trouvé s'affiche en bas.
  - Duel entre amis, au tour par tour (asynchrone) : celui qui défie choisit un minuteur par manche (30 s, 1 min, 2 min ou 3 min). 2 manches, nouvelle grille à chaque manche. L'ami joue ensuite ses 2 manches avec le même minuteur ; le meilleur total gagne.
  - Commencer par une version solo.
- Memory : paires mot anglais + traduction française, cartes face cachée.
  - Mode « même appareil » : chacun son tour, le plus de paires gagne.
  - Mode duel à distance : même grille pour les deux, avec minuteur ; gagnant = le plus rapide ou le moins de coups.

### Chat

- Uniquement entre amis, conversations à deux.
- Un message est supprimé 48 h après avoir été lu : à l'ouverture de la conversation, on enregistre vuLe et expireLe = vuLe + 48 h. L'appli masque immédiatement les messages expirés et les supprime au lancement. Un message non lu est conservé.
- Badge des messages non lus, boutons « Bloquer » et « Signaler ».
- Pendant une partie : bulle de chat flottante. Pendant une manche, uniquement des messages rapides (« Bien joué ! », « GG », « À toi ! », « Revanche ? ») car le minuteur continue ; chat complet entre les manches et en fin de partie.

### Mise en ligne et partage

- PWA : nom « Mon anglais », icône et couleurs dans web/manifest.json.
- QR code du lien du site, bouton « Inviter un ami » qui partage le lien et le code ami.
- Notifications plus tard (sur iPhone, seulement si le site est installé sur l'écran d'accueil).

## Données Firestore

| Collection | Champs principaux |
|---|---|
| users/{uid} | pseudo, codeAmi, avatar, xp, serieJours, derniereActivite, dateInscription, amis (liste d'uid), bloques (liste d'uid) |
| pseudos/{pseudo} | uid |
| codesAmis/{code} | uid |
| users/{uid}/progress/{id} | type (lecon ou paquet), refId, statut, score, prochaineRevision, derniereFois |
| friendRequests/{id} | de, vers, statut (en_attente, acceptee, refusee) |
| users/{uid}/decks/{id} | nom, visibilite (amis ou prive), cartes [{en, fr}], phrases [{fr, en}], misAJourLe |
| users/{uid}/decksSuivis/{id} | proprietaireId, paquetId, ajouteLe |
| conversations/{id} (id = les 2 uid triés, joints par _) | participants, dernierMessage, nonLus {uid: nombre} |
| conversations/{id}/messages/{id} | de, texte, envoyeLe, vuLe, expireLe |
| games/{id} | jeu (words ou memory), joueurs, theme, minuteur, grilles, scores, manche, statut, tourDe |

Règles de sécurité dans firestore.rules :

- chacun ne modifie que ses propres données ;
- un paquet est lisible par son propriétaire, ou par ses amis si visibilite == "amis" ;
- une conversation et ses messages ne sont lisibles que par ses deux participants ;
- une partie n'est modifiable que par ses joueurs.

## Contenu des leçons

- Source du vocabulaire : donnees/vocabulaire-anglais-A1-B2.xlsx, onglet « Tout le vocabulaire », colonnes : ID, Niveau, Module, Thème, Anglais, Français, Nature, Catégorie appli (Débutant, Voyage, Sport, Technique, Général). 955 mots.
- Source des cours : donnees/cours.md (20 modules A1 → B2 : leçons, pièges, exercices, corrigés), si présent.
- Un petit script dans outils/ convertit ces sources en JSON dans assets/contenu/. Format visé, un fichier par catégorie :

```json
{
  "id": "sport",
  "nom": "Sport",
  "lecons": [
    {
      "id": "sport-etirements",
      "titre": "Les étirements",
      "niveau": "A1",
      "cartes": [{ "en": "Stretch to the right", "fr": "Étirez-vous vers la droite" }],
      "phrases": [{ "fr": "Gardez le dos droit", "en": ["Keep your back straight"] }],
      "miniLecon": null
    }
  ]
}
```

## Mise en ligne (GitHub Actions)

Le fichier .github/workflows/deploy.yml doit contenir exactement ceci :

```yaml
name: Mise en ligne GitHub Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter build web --release --base-href /App_anglais/
      - uses: actions/upload-pages-artifact@v3
        with:
          path: build/web

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
```

Dans les réglages du repo GitHub : Settings → Pages → Source : GitHub Actions.

## Plan de développement

1. Bases du projet : projet Flutter (web), workflow de mise en ligne, thème, navigation responsive à 4 onglets, pages vides, manifest PWA, première mise en ligne.
2. Comptes et profil : Firebase relié, inscription / connexion pseudo + mot de passe, code ami, page profil, ajout d'amis par code, règles Firestore.
3. Cartes et contenu (MVP) : conversion du vocabulaire en JSON, écran de cartes (retournement + swipe), catégorie Sport remplie en premier, sauvegarde de la progression, barres sur la Home.
4. Phrases à traduire et mini-leçons : exercice de traduction, mini-leçons Débutant, catégories Voyage et Technique remplies.
5. Perso et partage : paquets perso, visibilité amis / privé, paquets d'un ami sur son profil, « Ajouter à mes révisions », « Faire une copie », audio (synthèse vocale, flutter_tts), série de jours.
6. Jeux : Words solo, puis duel avec minuteur et 2 manches, puis Memory.
7. Chat : conversations entre amis, suppression 48 h après lecture, badge non lus, bulle et messages rapides en partie.
8. Ouverture à tous : PWA soignée, QR code, bouton « Inviter un ami », tests avec des amis sur iPhone et Android.
