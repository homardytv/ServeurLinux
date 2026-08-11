`majAgent <zone>` met à jour le rôle d'une zone.

1. Lis `zone.md` et résous exactement l'argument ; absent ou inconnu : cite les
   zones et arrête, sans repli ni accès à une autre zone.
2. Dans la seule zone résolue, analyse tous les fichiers textuels pertinents :
   informations, roadmap, documentation, sources, configuration et structure.
   Ignore les binaires, dépendances générées, secrets et fichiers hors zone.
3. Cherche le fichier `role*.md` dans le dossier d'informations de la zone ;
   absent ou multiple : indique l'erreur et ne modifie rien.
4. Réécris ce rôle pour qu'il soit concis, spécifique à la zone et exploitable :
   objectif, technologies/contraintes vérifiées, priorités, validations et
   garde-fous. N'invente ni matériel, accès, secret ou exigence non observés ;
   les règles globales de sécurité restent prioritaires.
5. Rapporte les éléments retenus, les hypothèses et le diff. Toute action autre
   que cette mise à jour locale exige l'autorisation adaptée.
