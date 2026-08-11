# Informations essentielles — Configuration RustDesk

## État

- RustDesk 1.3.9 est installé sur la cible et était déjà en cours d'exécution.
- Le démarrage automatique est configuré pour la prochaine ouverture de session graphique de `serveur-nino`.
- La configuration a été contrôlée après écriture : fichier présent, contenu attendu et propriétaire conforme.

## Cible et accès

- Cible unique : Ubuntu 24.04.1 LTS, `serveur-nino-HP-Compaq-8200-Elite-SFF-PC`.
- Compte concerné : `serveur-nino`, avec une session graphique X11 active.
- Fichier d'autostart : `/home/serveur-nino/.config/autostart/rustdesk.desktop`.
- Commande exécutée à la connexion : `/usr/bin/rustdesk --tray`.

## Règles

- La vérification de connexion SSH reste obligatoire avant toute action distante.
- Aucun `sudo`, aucune commande interactive et aucune désactivation de la vérification de clé d'hôte.
- Toute modification distante exige une confirmation explicite et un plan de retour arrière.

## Suite

- Valider le démarrage de RustDesk après une déconnexion puis reconnexion graphique de `serveur-nino`.
- Le témoin de l'état initial absent est conservé dans le dossier d'autostart pour le retour arrière.
- Pour annuler, supprimer le fichier d'autostart et son témoin, après confirmation explicite.
