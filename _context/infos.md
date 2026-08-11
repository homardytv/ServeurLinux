# Informations essentielles

## État

- SSH non privilégié opérationnel ; M1 à M5 validés et M6 documenté.
- RustDesk 1.3.9 est actif ; son autostart utilisateur est créé et vérifié.
- Les zones `défaut`, `config` et `arduino` sont définies ; un rôle optionnel est chargé au démarrage.

## Cible et accès

- Ubuntu 24.04.1 LTS : `serveur-nino-HP-Compaq-8200-Elite-SFF-PC` ; compte `serveur-nino` ; SSH 22.
- La configuration SSH est locale (`.env`) ; clé d'hôte dans `.ssh_known_hosts`.
- Autostart RustDesk : `/home/serveur-nino/.config/autostart/rustdesk.desktop` ; `/usr/bin/rustdesk --tray` ; permissions `600`.

## Règles

- Respecter `AGENTS.md` ; ne jamais lire, versionner ou consigner de secret.
- Avant SSH : résolution et port ; commandes non interactives, sans `sudo` ni contournement de clé d'hôte.
- Toute modification distante exige confirmation, sauvegarde et retour arrière.

## Réalisé

- Vérification SSH, exécution encadrée, tests M1–M5 et documentation d'exploitation disponibles.
- `start`, `close` et `majAgent` utilisent le registre `zone.md` ; les rôles sont maintenables par zone.

## Blocage et prochaine action

- Révocation SSH reportée : accès de secours et retour arrière à valider.
- Prochaine action : valider RustDesk après déconnexion puis reconnexion graphique de `serveur-nino`.
