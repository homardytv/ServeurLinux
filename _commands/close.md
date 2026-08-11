`close` n'accepte aucun argument.

1. Lis `zone.md` (`zone : dossier — infos ; roadmap`) et identifie l'unique
   zone concernée par la demande, la session ou les modifications locales ;
   ignore `zone.md` et les changements hors zone. Zéro ou plusieurs candidates
   : ne modifie rien, indique-les et demande laquelle clôturer. Jamais de
   repli ; ensuite, n'accède qu'à cette zone.
2. Lis son fichier d'informations ; absent : erreur et arrêt. Traite sa
   roadmap : présente → mets-la à jour avec les faits de session ; optionnelle
   absente → signale-le, ne la crée pas ; obligatoire absente → erreur et arrêt.
3. Réécris les informations (pas de journal, ≤40 lignes) comme contexte de
   reprise : état, accès/prérequis valides, règles propres à la zone,
   livrables réemployables, blocages/décisions et une prochaine action. La
   roadmap porte le suivi des actions. Supprime historique, dates, sorties,
   diagnostics ponctuels, essais terminés, détails inutiles, doublons et
   actions déjà dans la roadmap ; reporte-y tout fait nouveau.
4. Ne consigne aucun secret (`.env`, mot de passe, clé privée, jeton). Si Git
   est disponible et configuré, ne prépare, valide ou pousse que les fichiers
   de la zone et `zone.md` s'il a changé ; sinon, signale l'absence de commit
   et de push.
