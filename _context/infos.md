# Informations essentielles

## État

- Accès SSH non privilégié validé ; M1 à M5 sont validés et M6 est documenté.
- RustDesk 1.3.9 est actif ; son autostart utilisateur est créé et vérifié.
- Les zones `défaut`, `config` et `arduino` sont définies ; un rôle optionnel peut être chargé par zone.

## Accès et règles

- Cible : Ubuntu 24.04.1 LTS `serveur-nino-HP-Compaq-8200-Elite-SFF-PC`, compte `serveur-nino`, SSH 22.
- La configuration SSH reste locale dans `.env` et ne peut être lue que pour la vérification SSH conforme ; la clé d'hôte est dans `.ssh_known_hosts`.
- Avant SSH : résolution du nom et port ; commandes non interactives, sans `sudo` ni contournement de clé d'hôte.
- Toute modification distante exige confirmation explicite, sauvegarde et procédure de retour arrière.

## Livrables réemployables

- Vérification SSH, exécution encadrée, tests M1–M5 et documentation d'exploitation sont disponibles.
- Autostart RustDesk : `/home/serveur-nino/.config/autostart/rustdesk.desktop`, commande `/usr/bin/rustdesk --tray`, permissions `600`.

## Blocages et prochaine action

- Roblox n'est pas pris en charge sous Linux ; aucune installation distante n'a été menée.
- Valider RustDesk après une déconnexion puis reconnexion graphique.
- Le test de révocation SSH reste reporté jusqu'à validation d'un accès de secours et d'un retour arrière.
