# Roadmap — Contrôle SSH du serveur Linux

Dernière mise à jour : 11 août 2026
Source : [`_docs/plan-action.md`](_docs/plan-action.md)
État global : **accès SSH opérationnel, garde-fous et tests validés ; révocation en attente**

## Légende

- [x] Terminé
- [ ] À faire
- ⏳ En attente d'une décision ou d'un prérequis
- ⚠️ Point de vigilance

## Situation actuelle

| Élément | État |
|---|---|
| Cible | Ubuntu 24.04.1 LTS — `serveur-nino-HP-Compaq-8200-Elite-SFF-PC` |
| Utilisateur | `serveur-nino` |
| Réseau | LAN Bbox `192.168.1.0/24` |
| Windows | `192.168.1.9/24`, interface `Ethernet 2` |
| Ubuntu | `192.168.1.162/24`, interface `eno1`, adresse DHCP |
| Résolution locale | Nom d'hôte résolu correctement depuis Windows |
| SSH | OpenSSH actif et port 22 accessible depuis Windows |
| Sudo | Accès complet pour `serveur-nino`, mais aucune automatisation privilégiée autorisée |
| Hamachi | Hors périmètre initial |

## M0 — Cadrage

Objectif : fixer le cadre technique et les règles de sécurité.

- [x] Identifier la distribution et la version Linux.
- [x] Identifier la machine, le compte utilisateur et ses droits `sudo`.
- [x] Identifier le réseau, les interfaces et les adresses actuelles.
- [x] Limiter le périmètre initial à une machine de test.
- [x] Choisir Codex comme premier agent.
- [x] Imposer une confirmation avant toute action sensible.
- [x] Interdire pour l'instant l'automatisation des commandes `sudo`.
- [ ] ⏳ Définir les opérations que l'agent devra réaliser.
- [ ] ⏳ Classer ces opérations : autorisées, sensibles ou interdites.
- [ ] ⏳ Choisir le niveau de journalisation.
- [ ] ⏳ Identifier les autres agents à prendre en charge.

Critère de passage : les opérations initiales et leur niveau de sensibilité sont validés.

## M1 — Rendre SSH disponible

Objectif : obtenir un serveur SSH actif et joignable depuis Windows.

- [x] Vérifier si `openssh-server` est installé sur Ubuntu.
- [x] Vérifier l'état du service `ssh`.
- [x] Vérifier le port d'écoute effectif.
- [ ] Vérifier le pare-feu Ubuntu.
- [x] Installer ou démarrer OpenSSH si nécessaire, après confirmation car cette action utilise `sudo`.
- [x] Tester le port SSH depuis Windows.
- [x] Confirmer que le nom d'hôte pointe toujours vers la bonne machine.

Commandes de diagnostic Ubuntu, sans modification :

```bash
dpkg -s openssh-server | grep Status
systemctl status ssh --no-pager
ss -lnt | grep ':22'
```

Critère de passage : le test TCP vers le port SSH réussit depuis Windows.

## M2 — Préparer le dépôt

Objectif : stocker la configuration locale sans exposer de secret.

- [x] Adapter `AGENTS.md` en conservant les règles locales existantes.
- [x] Ajouter `.env.example` avec des valeurs fictives.
- [x] Ajouter `.env` au fichier `.gitignore`.
- [x] Documenter les variables `IP_LINUX`, `SSH_USER`, `SSH_KEY` et éventuellement `SSH_PORT`.
- [x] Utiliser `serveur-nino-HP-Compaq-8200-Elite-SFF-PC` comme valeur d'hôte afin de tolérer un changement de bail DHCP.
- [x] Vérifier qu'aucun secret ni aucune clé privée n'est suivi par Git.

Critère de passage : la configuration est documentée et aucun secret n'est versionné.

## M3 — Configurer l'authentification SSH

Objectif : établir une connexion par clé, non interactive et limitée au compte existant.

- [x] Générer ou sélectionner une clé Ed25519 dédiée.
- [x] Installer uniquement la clé publique dans `~/.ssh/authorized_keys` sur Ubuntu.
- [x] Vérifier les permissions de `~/.ssh` et `authorized_keys`.
- [x] Enregistrer puis vérifier l'empreinte de la clé d'hôte Ubuntu.
- [x] Tester la connexion avec `BatchMode=yes` et un délai court.
- [x] Vérifier à distance l'identité avec `whoami` et `hostname`.
- [x] Confirmer qu'aucun mot de passe n'est demandé.

⚠️ Ne pas désactiver durablement la vérification de la clé d'hôte avec `StrictHostKeyChecking=no`.

Critère de passage : une commande de lecture seule s'exécute par SSH sans interaction.

## M4 — Mettre en place les garde-fous

Objectif : encadrer les commandes exécutées par les agents.

- [x] Vérifier la connectivité et le port avant chaque connexion.
- [x] Lire et traiter le code retour, la sortie standard et l'erreur de chaque commande.
- [x] Interdire les commandes interactives.
- [x] Exiger une confirmation explicite avant chaque action sensible.
- [x] Refuser toute commande nécessitant `sudo` dans le périmètre initial.
- [x] Définir une sauvegarde et un retour arrière avant modification de fichier.
- [x] Définir une journalisation ne contenant aucun secret.
- [ ] ⏳ Si nécessaire plus tard, concevoir des règles `NOPASSWD` limitées à une liste blanche précise.

Critère de passage : les règles d'exécution et de confirmation sont documentées et testables.

## M5 — Effectuer les tests progressifs

Objectif : valider le contrôle distant du moins risqué au plus sensible.

- [x] Test réseau : résolution du nom et port SSH.
- [x] Test d'identité : `whoami`, `hostname` et version du système.
- [x] Test de diagnostic : uptime, RAM et espace disque.
- [x] Test de lecture : état d'un service et extrait limité de journaux.
- [x] Test d'écriture réversible dans un emplacement autorisé.
- [x] Test de transfert d'un fichier par `scp`.
- [x] Test des erreurs : cible indisponible, mauvaise clé et droits insuffisants.
- [ ] ⏳ Test d'une opération privilégiée seulement après définition d'une liste blanche.
- [x] Consigner les résultats dans un procès-verbal de tests.

Critère de passage : tous les tests autorisés réussissent et les échecs sont correctement signalés.

## M6 — Finaliser l'exploitation

Objectif : rendre la solution maintenable et révocable.

- [x] Documenter les commandes usuelles.
- [x] Documenter le dépannage réseau et SSH.
- [x] Documenter la révocation et la rotation de la clé.
- [ ] ⏳ Tester la suppression de l'accès SSH de l'agent (reporté : accès de secours à définir).
- [x] Prévoir une revue périodique des droits, journaux et versions d'OpenSSH.
- [ ] Reporter toute prise en charge multi-machine après validation de la cible actuelle.

Critère de clôture : accès opérationnel, documenté, contrôlé et révocable.

## Configuration RustDesk

- [x] RustDesk 1.3.9 vérifié actif sur la cible.
- [x] Autostart utilisateur créé dans `~/.config/autostart/rustdesk.desktop`.
- [x] Commande configurée : `/usr/bin/rustdesk --tray`.
- [ ] Valider le lancement après une déconnexion puis reconnexion graphique.
- ⚠️ Le lancement avant connexion reste hors périmètre : il nécessiterait une configuration privilégiée.

## Prochaine action

Test de révocation reporté. Lorsqu'il sera repris, définir et valider un accès
de secours et le retour arrière, puis demander une confirmation explicite avant
toute modification distante.

## Journal de suivi

### 11 août 2026

- [x] Vérification de démarrage non intrusive réussie : résolution, port SSH et
  identité `serveur-nino` validés ; aucune modification distante effectuée.
- [ ] ⏳ Test de révocation maintenu en attente par décision utilisateur : accès
  de secours et retour arrière à définir avant confirmation explicite.

- [x] Clôture de la zone par défaut effectuée : contexte compacté et gestion
  des zones confirmée pour `start [zone]` et `close [zone]`.

### 10 août 2026

- [x] Gestion locale des zones ajoutée : `zone.md` définit les zones par défaut
  et `config` ; `start [zone]` et `close [zone]` restent strictement limités à
  la zone résolue, sans repli implicite.

- [x] Périmètre technique établi : une cible Ubuntu de test, sur le LAN local de la Bbox.
- [x] Compte SSH identifié : `serveur-nino`.
- [x] Résolution du nom d'hôte Ubuntu validée depuis Windows.
- [x] Test initial du port TCP 22 réalisé depuis Windows : échec, diagnostic OpenSSH en attente.
- [x] Décision prise : aucune commande `sudo` n'est automatisée dans le périmètre initial.
- [x] OpenSSH Server activé et configuré pour démarrer automatiquement sur Ubuntu.
- [x] Port TCP 22 accessible depuis Windows via `serveur-nino-HP-Compaq-8200-Elite-SFF-PC` (`192.168.1.162`).
- [x] Dépôt préparé avec des règles SSH, un modèle de configuration et l'exclusion des secrets et clés privées.
- [x] Authentification SSH non interactive validée avec une clé Ed25519 dédiée.
- [x] Clé d'hôte Ed25519 enregistrée avec l'empreinte `SHA256:Ylo+rwu1QjOdn/cd1vb8SCG/a3q8WdlBVsxwWiytphI`.
- [x] Test de contrôle distant réussi : Firefox lancé sur la session graphique locale Ubuntu.
- [x] Vérification de connexion SSH intégrée à la commande de démarrage.
- [x] Firefox fermé après le test de contrôle graphique distant.
- [x] Contexte essentiel compacté dans `_context/infos.md` lors de la clôture.
- [x] Exécution SSH standardisée dans `_scripts/Invoke-SshCommand.ps1` : délai,
  flux séparés, code retour, refus de `sudo` et des outils interactifs usuels.
- [x] Tests validés : succès `0`, erreur distante `1`, délai dépassé `124` et
  identité Ubuntu 24.04.1 LTS conforme.
- [x] Protocole de confirmation et plan de sauvegarde/retour arrière ajoutés à
  `_docs/execution-ssh.md` et contrôlés par le script d'exécution.
- [x] Journal local JSONL sans secrets ajouté ; il ne conserve que des métadonnées
  et l'empreinte SHA-256 de la commande.
- [x] Tests M5 de diagnostic et de lecture réussis : ressources système saines,
  service `ssh` actif et extrait limité de son journal lisible sans `sudo`.
- [x] Faux positif corrigé dans le filtre interactif : `journalctl -u ssh` est
  autorisé, tandis qu'un exécutable interactif en position de commande reste bloqué.
- [x] Test d'écriture réversible validé dans `/tmp` : création, lecture,
  permissions `0600`, suppression et contrôle indépendant d'absence réussis.
- [x] Test de transfert `scp` réversible validé : transfert non interactif,
  empreinte SHA-256 identique et suppression contrôlée des deux copies.
- [x] Tests d'erreurs validés : port simulé fermé, identité invalide (`255`) et
  droits insuffisants (code distant `1`) ; procès-verbal ajouté.
- [x] Guide d'exploitation M6 ajouté : commandes usuelles, dépannage,
  révocation/rotation et revue périodique.
- [x] Test de révocation reporté à une session ultérieure par décision de
  l'utilisateur, dans l'attente d'un accès de secours validé.
