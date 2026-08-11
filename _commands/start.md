`start [zone]` :

1. Lis `zone.md` (`zone : dossier — infos ; roadmap`). Sans argument, résous
   `défaut` ; sinon, la correspondance doit être exacte. Zone inconnue : cite
   les zones et arrête, sans repli ni accès à une autre zone.
2. Dans la seule zone résolue, lis le fichier d'informations ; absent : erreur
   et arrêt. S'il contient un unique `role*.md` dans son dossier, lis-le et
   applique ce rôle pour la zone, sans déroger aux règles globales de sécurité.
   Aucun rôle : poursuis ; plusieurs rôles : indique l'ambiguïté et arrête.
3. Avant toute autre action, lis et exécute intégralement la vérification non
   intrusive de `_docs/connexion.md`. Échec : indique l'étape et n'exécute
   aucune modification distante.
4. Si elle réussit, traite la roadmap de la zone : présente → lis, résume et
   propose l'action prioritaire ; optionnelle absente → signale-le et propose
   l'action depuis les informations ; obligatoire absente → erreur et arrêt.

Toute action sensible exige une confirmation explicite.
