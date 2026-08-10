# Informations essentielles

## État

- M1 à M5 sont validés dans le périmètre non privilégié ; M4 est terminé.
- M6 est documenté ; la connexion SSH a été revalidée le 11 août 2026.
- RustDesk 1.3.9 est actif et son autostart utilisateur a été créé puis contrôlé.
- Le test de révocation reste reporté par décision utilisateur, faute d'accès de secours validé.

## Cible et accès

- Cible unique : Ubuntu 24.04.1 LTS, `serveur-nino-HP-Compaq-8200-Elite-SFF-PC`.
- Compte distant : `serveur-nino` ; port SSH : `22` ; adresse DHCP observée : `192.168.1.162`.
- Configuration locale : `.env` ; clé d'hôte vérifiée : `.ssh_known_hosts`.
- Autostart RustDesk : `/home/serveur-nino/.config/autostart/rustdesk.desktop`, commande `/usr/bin/rustdesk --tray`, propriétaire `serveur-nino`, permissions `600`.
- Le témoin de l'état initial absent est conservé dans le dossier d'autostart pour le retour arrière.

## Règles

- Vérifier la résolution et le port avant chaque connexion SSH ; utiliser uniquement la cible et le compte définis dans `.env`.
- Aucun `sudo`, aucune commande interactive, aucune désactivation de la vérification de clé d'hôte.
- Toute modification distante exige une confirmation explicite, une sauvegarde et un retour arrière documentés.
- Ne jamais versionner ni consigner de secret ou clé privée.

## Éléments terminés

- Exécution SSH non interactive encadrée, tests M1 à M5 et documentation d'exploitation disponibles.
- Zones strictes définies dans `zone.md` ; la vérification de connexion est obligatoire au démarrage.
- Autostart RustDesk créé de manière réversible après confirmation et vérifié.

## Blocages et prochaine action

- Valider RustDesk après déconnexion puis reconnexion graphique de `serveur-nino`.
- Avant le test de révocation, définir un accès de secours valide et le retour arrière, puis demander confirmation explicite.
