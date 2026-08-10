# Roadmap — Contrôle SSH du serveur Linux

Dernière mise à jour : 10 août 2026
Source : [`_docs/plan-action.md`](_docs/plan-action.md)
État global : **cadrage technique terminé, diagnostic SSH à poursuivre**

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
| SSH | Port 22 inaccessible lors du premier test |
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

- [ ] Vérifier si `openssh-server` est installé sur Ubuntu.
- [ ] Vérifier l'état du service `ssh`.
- [ ] Vérifier le port d'écoute effectif.
- [ ] Vérifier le pare-feu Ubuntu.
- [ ] Installer ou démarrer OpenSSH si nécessaire, après confirmation car cette action utilise `sudo`.
- [ ] Tester le port SSH depuis Windows.
- [ ] Confirmer que le nom d'hôte pointe toujours vers la bonne machine.

Commandes de diagnostic Ubuntu, sans modification :

```bash
dpkg -s openssh-server | grep Status
systemctl status ssh --no-pager
ss -lnt | grep ':22'
```

Critère de passage : le test TCP vers le port SSH réussit depuis Windows.

## M2 — Préparer le dépôt

Objectif : stocker la configuration locale sans exposer de secret.

- [ ] Adapter `AGENTS.md` en conservant les règles locales existantes.
- [ ] Ajouter `.env.example` avec des valeurs fictives.
- [ ] Ajouter `.env` au fichier `.gitignore`.
- [ ] Documenter les variables `IP_LINUX`, `SSH_USER`, `SSH_KEY` et éventuellement `SSH_PORT`.
- [ ] Utiliser `serveur-nino-HP-Compaq-8200-Elite-SFF-PC` comme valeur d'hôte afin de tolérer un changement de bail DHCP.
- [ ] Vérifier qu'aucun secret ni aucune clé privée n'est suivi par Git.

Critère de passage : la configuration est documentée et aucun secret n'est versionné.

## M3 — Configurer l'authentification SSH

Objectif : établir une connexion par clé, non interactive et limitée au compte existant.

- [ ] Générer ou sélectionner une clé Ed25519 dédiée.
- [ ] Installer uniquement la clé publique dans `~/.ssh/authorized_keys` sur Ubuntu.
- [ ] Vérifier les permissions de `~/.ssh` et `authorized_keys`.
- [ ] Enregistrer puis vérifier l'empreinte de la clé d'hôte Ubuntu.
- [ ] Tester la connexion avec `BatchMode=yes` et un délai court.
- [ ] Vérifier à distance l'identité avec `whoami` et `hostname`.
- [ ] Confirmer qu'aucun mot de passe n'est demandé.

⚠️ Ne pas désactiver durablement la vérification de la clé d'hôte avec `StrictHostKeyChecking=no`.

Critère de passage : une commande de lecture seule s'exécute par SSH sans interaction.

## M4 — Mettre en place les garde-fous

Objectif : encadrer les commandes exécutées par les agents.

- [ ] Vérifier la connectivité et le port avant chaque connexion.
- [ ] Lire et traiter le code retour, la sortie standard et l'erreur de chaque commande.
- [ ] Interdire les commandes interactives.
- [ ] Exiger une confirmation explicite avant chaque action sensible.
- [ ] Refuser toute commande nécessitant `sudo` dans le périmètre initial.
- [ ] Définir une sauvegarde et un retour arrière avant modification de fichier.
- [ ] Définir une journalisation ne contenant aucun secret.
- [ ] ⏳ Si nécessaire plus tard, concevoir des règles `NOPASSWD` limitées à une liste blanche précise.

Critère de passage : les règles d'exécution et de confirmation sont documentées et testables.

## M5 — Effectuer les tests progressifs

Objectif : valider le contrôle distant du moins risqué au plus sensible.

- [ ] Test réseau : résolution du nom et port SSH.
- [ ] Test d'identité : `whoami`, `hostname` et version du système.
- [ ] Test de diagnostic : uptime, RAM et espace disque.
- [ ] Test de lecture : état d'un service et extrait limité de journaux.
- [ ] Test d'écriture réversible dans un emplacement autorisé.
- [ ] Test de transfert d'un fichier par `scp`.
- [ ] Test des erreurs : cible indisponible, mauvaise clé et droits insuffisants.
- [ ] ⏳ Test d'une opération privilégiée seulement après définition d'une liste blanche.
- [ ] Consigner les résultats dans un procès-verbal de tests.

Critère de passage : tous les tests autorisés réussissent et les échecs sont correctement signalés.

## M6 — Finaliser l'exploitation

Objectif : rendre la solution maintenable et révocable.

- [ ] Documenter les commandes usuelles.
- [ ] Documenter le dépannage réseau et SSH.
- [ ] Documenter la révocation et la rotation de la clé.
- [ ] Tester la suppression de l'accès SSH de l'agent.
- [ ] Prévoir une revue périodique des droits, journaux et versions d'OpenSSH.
- [ ] Reporter toute prise en charge multi-machine après validation de la cible actuelle.

Critère de clôture : accès opérationnel, documenté, contrôlé et révocable.

## Prochaine action

Récupérer sur Ubuntu le résultat des trois commandes de diagnostic du jalon M1 afin d'expliquer pourquoi le port 22 est inaccessible.

## Journal de suivi

### 10 août 2026

- [x] Périmètre technique établi : une cible Ubuntu de test, sur le LAN local de la Bbox.
- [x] Compte SSH identifié : `serveur-nino`.
- [x] Résolution du nom d'hôte Ubuntu validée depuis Windows.
- [x] Test initial du port TCP 22 réalisé depuis Windows : échec, diagnostic OpenSSH en attente.
- [x] Décision prise : aucune commande `sudo` n'est automatisée dans le périmètre initial.
