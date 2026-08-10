# Informations essentielles

## État

- M1 à M5 sont validés dans le périmètre non privilégié ; M4 est terminé.
- M6 est documenté ; la connexion SSH a été revalidée le 11 août 2026.
- Le test de révocation reste reporté par décision utilisateur, faute d'accès de secours validé.
- RustDesk 1.3.9 est configuré pour démarrer à la prochaine ouverture de session graphique de `serveur-nino`.
- Les commandes `start [zone]` et `close [zone]` résolvent strictement leur zone dans `zone.md`, sans repli implicite.
- La vérification de connexion via `_commands/start.md` est obligatoire avant toute session SSH.

## Cible et accès

- Cible unique : Ubuntu 24.04.1 LTS, `serveur-nino-HP-Compaq-8200-Elite-SFF-PC`.
- Compte distant : `serveur-nino` ; port SSH : `22` ; DHCP observé : `192.168.1.162`.
- Configuration locale : `.env` ; clé d'hôte vérifiée : `.ssh_known_hosts`.
- Autostart RustDesk : `/home/serveur-nino/.config/autostart/rustdesk.desktop`, commande `/usr/bin/rustdesk --tray`.

## Règles

- Aucun `sudo`, aucune commande interactive, aucune désactivation de la vérification de clé d'hôte.
- Toute modification distante exige une confirmation explicite, une sauvegarde et un retour arrière documentés.
- Aucun lancement avant connexion utilisateur : cette configuration nécessiterait des privilèges hors périmètre.
- Ne jamais versionner ni consigner de secret ou clé privée.

## Livrables

- `_scripts/Invoke-SshCommand.ps1` : exécution non interactive, délai, flux séparés, refus de `sudo` et journalisation sans secrets.
- `_docs/execution-ssh.md`, `_docs/proces-verbal-tests.md` et `_docs/exploitation-ssh.md` : politique, tests et exploitation.
- `zone.md` : registre des zones par défaut et `config`.
- `CONFIG/_contextConfig/infosConfig.md` : contexte de la configuration RustDesk.

## Reprise

- Valider RustDesk après une déconnexion puis reconnexion graphique ; le témoin de l'état initial absent est conservé pour le retour arrière.
- Pour le test de révocation, définir d'abord un accès de secours valide, la sauvegarde et le retour arrière ; demander ensuite confirmation explicite.
- Les opérations privilégiées restent hors périmètre sans liste blanche `NOPASSWD` validée.
- La zone par défaut utilise `_context/infos.md` et `roadmap.md` ; `config` utilise son contexte dédié et une roadmap optionnelle.
