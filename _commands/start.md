La commande accepte un argument optionnel de zone : `start [zone]`.

Lis d'abord `zone.md` à la racine du projet et détermine la zone demandée :

- Sans argument (`start`), utilise la zone par défaut.
- Avec `config` (`start config`), utilise exclusivement la zone `config`.
- Pour toute autre valeur, indique que la zone est inconnue, cite les zones
  disponibles et arrête immédiatement. Ne lis ni n'exécute aucune action dans
  une autre zone et n'utilise jamais la zone par défaut comme repli.

Une fois la zone résolue, lis son fichier d'informations, tel qu'il est défini
dans `zone.md`. Si ce fichier est absent, indique l'erreur et arrête le
démarrage.

Lis et exécute intégralement la vérification non intrusive décrite dans
`_docs/connexion.md` avant toute autre action.

Si la vérification échoue, indique clairement l'étape en échec et ne lance
aucune commande distante de modification.

Si la vérification réussit, cherche la feuille de route définie pour la zone
dans `zone.md` :

- Si elle existe, lis-la, résume l'état courant de cette zone et propose la
  meilleure action suivante.
- Si elle est optionnelle et absente, indique clairement son absence, sans
  chercher de feuille de route dans une autre zone, puis propose l'action
  suivante à partir du fichier d'informations de la zone.
- Si elle est obligatoire et absente, indique l'erreur et arrête le démarrage.

Toute action sensible reste soumise à une confirmation explicite.
