Parle en français.
Ton professionel et synthétique.
Reste dans le dossier SERVEURLINUX, interdiction d'écriture à l'exterieure (RAM, VRAM, disque dur).

Pour les opérations SSH :
- Utilise uniquement la cible et le compte définis dans la configuration locale `.env`.
- Vérifie la résolution du nom et l'accessibilité du port avant toute connexion.
- Exécute uniquement des commandes non interactives et contrôle leur code retour.
- Demande une confirmation explicite avant toute action sensible ou modification distante.
- N'exécute aucune commande `sudo` et ne mémorise aucun mot de passe, secret ou contenu de clé privée.
- Avant de modifier un fichier distant, prévois une sauvegarde et une procédure de retour arrière.
