# Zones de travail

Ce fichier est la source de vérité des zones utilisables par la commande
`start`. Une zone ne donne accès qu'aux fichiers explicitement définis pour
elle. Il n'existe aucun repli vers la zone par défaut.

## Zone par défaut (sans nom)

- Dossier : `C:\Users\ninor\Desktop\tout\doc\autres\serveurs\ServeurLinux`
- Informations : `_context/infos.md`
- Feuille de route : `roadmap.md`

## Zone `config`

- Dossier : `C:\Users\ninor\Desktop\tout\doc\autres\serveurs\ServeurLinux\CONFIG`
- Informations : `_contextConfig/infosConfig.md`
- Feuille de route : `roadmap.md` (optionnelle)

Si le fichier de feuille de route optionnel est absent, la commande le signale
et poursuit uniquement avec les informations de la zone `config`.
