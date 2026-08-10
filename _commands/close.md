La commande accepte un argument optionnel de zone : `close [zone]`.

Lis d'abord `zone.md` à la racine du projet et détermine la zone à clôturer :

- Sans argument (`close`), utilise la zone par défaut.
- Avec `config` (`close config`), utilise exclusivement la zone `config`.
- Pour toute autre valeur, indique que la zone est inconnue, cite les zones
  disponibles et arrête immédiatement. Ne lis, ne modifies et ne clôture rien
  dans une autre zone ; n'utilise jamais la zone par défaut comme repli.

Lis le fichier d'informations de la zone, défini dans `zone.md`. S'il est
absent, indique l'erreur et arrête la clôture.

Cherche ensuite la feuille de route définie pour cette zone dans `zone.md` :

- Si elle existe, lis-la puis mets-la à jour avec les résultats factuels de la
  session effectuée dans cette zone.
- Si elle est optionnelle et absente, indique son absence et ne crée aucun
  fichier de remplacement ; poursuis la clôture avec le seul fichier
  d'informations de la zone.
- Si elle est obligatoire et absente, indique l'erreur et arrête la clôture.

Mets à jour puis compacte le fichier d'informations de la zone : réécris le
document au lieu d'ajouter un journal. Conserve uniquement les informations
indispensables à la reprise de cette zone : état actuel, accès validé, règles
de sécurité, éléments terminés, blocages et prochaine action. Supprime les
détails devenus obsolètes, les sorties de commandes et les doublons.

Ne consigne jamais de mot de passe, clé privée, jeton, valeur de `.env` ou
autre secret. Le document doit rester concis (maximum 40 lignes).

Ensuite, vérifie si Git est disponible et configuré. Si c'est le cas, ne
prépare, ne valide et ne pousse que les modifications relevant de la zone
clôturée et de `zone.md` si celui-ci a été modifié. Si Git est indisponible ou
non configuré, indique clairement que le commit et le push n'ont pas été
effectués.
