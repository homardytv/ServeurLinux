# Plan d'action — Contrôle d'un PC Linux par agent IA via SSH

## 1. Objectif

Mettre en place, depuis ce projet Windows, un contrôle fiable et sécurisé d'une machine Linux au moyen du protocole [ai-ssh-control](https://github.com/ServOMorph/ai-ssh-control), puis valider son fonctionnement sur un périmètre de commandes défini.

Statut : **cadrage technique initial terminé — périmètre fonctionnel à définir ultérieurement**.

## 2. Périmètre retenu

| Élément | Décision |
|---|---|
| Machine cible | `serveur-nino-HP-Compaq-8200-Elite-SFF-PC`, sous Ubuntu 24.04.1 LTS |
| Environnement | Test |
| Réseau | Windows et Ubuntu connectés en Ethernet au LAN Bbox `192.168.1.0/24` |
| Agents | Codex au départ ; choix des autres agents reporté |
| Opérations | À définir ultérieurement |
| Confirmation | Obligatoire avant chaque action sensible |
| Compte SSH dédié | Non ; compte existant `serveur-nino`, autorisé à exécuter `(ALL : ALL) ALL` avec `sudo` |
| Commandes privilégiées | Non automatisées tant qu'une liste `sudo` restreinte n'a pas été définie |
| Administration Bbox | Non accessible ; aucune réservation DHCP possible |
| Nombre de cibles | Une |

### Paramètres réseau observés

| Élément | Valeur |
|---|---|
| Windows | Interface `Ethernet 2`, adresse `192.168.1.9/24` |
| Ubuntu | Interface `eno1`, adresse DHCP `192.168.1.162/24` |
| Nom résolu depuis Windows | `serveur-nino-HP-Compaq-8200-Elite-SFF-PC` → `192.168.1.162` |
| Passerelle | Bbox `192.168.1.254` |
| Réseau principal | `192.168.1.0/24` |
| Réseau secondaire Ubuntu | Interface Hamachi `ham0`, adresse `25.38.146.28/8`, hors périmètre initial |

### Décisions encore nécessaires

1. Définir ultérieurement la liste des autres agents autorisés et adapter leurs fichiers d'instructions.
2. Définir ultérieurement la liste des opérations attendues et leur niveau de sensibilité.
3. Choisir le niveau de journalisation souhaité.
4. Étudier ultérieurement des règles `sudo` non interactives limitées à une liste blanche, uniquement si le besoin est confirmé.
5. Rendre le service SSH accessible sur le port retenu ; le test initial du port 22 a échoué.

## 3. Architecture cible proposée

- Agent IA exécuté sur Windows dans ce dépôt.
- Paramètres de connexion stockés localement et exclus de Git.
- Clé SSH Ed25519 dédiée au projet.
- Compte Linux existant `serveur-nino` ; son accès `sudo` complet ne devra pas être rendu globalement non interactif.
- Réseau local Bbox utilisé pour joindre la cible ; Windows résout actuellement le nom d'hôte Ubuntu, ce qui évite de dépendre directement du bail DHCP.
- Vérification de la clé d'hôte SSH plutôt que désactivation permanente de son contrôle.
- Commandes non interactives, avec délai d'expiration et analyse systématique du code retour.
- Transfert de fichiers par `scp` seulement après préparation et validation locale.

## 4. Phases de réalisation

### Phase 0 — Cadrage

- Considérer le compte SSH et le réseau comme identifiés.
- Reporter le choix des autres agents autorisés.
- Reporter la définition détaillée des opérations jusqu'à l'expression du besoin.
- Définir ensuite les commandes autorisées, sensibles et interdites.
- Définir les critères de réussite et la procédure de retour arrière.
- Valider les contraintes de sécurité et de traçabilité.

Livrable : périmètre validé et matrice d'autorisations.

### Phase 1 — Préparation du dépôt

- Adapter les instructions `AGENTS.md` sans supprimer les règles locales existantes.
- Ajouter un modèle de configuration sans secret, par exemple `.env.example`.
- Vérifier que le fichier contenant les valeurs réelles est ignoré par Git.
- Documenter les variables nécessaires : hôte, port, utilisateur et chemin de clé.
- Configurer une cible unique et éviter une abstraction multi-machine inutile à ce stade.

Livrable : structure locale documentée, sans secret versionné.

### Phase 2 — Sécurisation de la cible Linux

- Vérifier l'état du serveur OpenSSH et sa configuration.
- Diagnostiquer l'échec initial de connexion TCP au port 22 : paquet serveur absent, service arrêté, autre port d'écoute ou pare-feu.
- Utiliser le compte SSH existant `serveur-nino`, qui possède actuellement un accès `sudo` complet.
- Configuration observée : Ubuntu `192.168.1.162/24`, Windows `192.168.1.9/24`, passerelle Bbox `192.168.1.254`.
- Ne pas configurer arbitrairement une adresse statique sans connaître la plage DHCP de la Bbox, afin d'éviter un conflit d'adresses.
- Utiliser en priorité le nom d'hôte `serveur-nino-HP-Compaq-8200-Elite-SFF-PC`, dont la résolution depuis Windows a été validée.
- Installer une clé publique dédiée et désactiver l'authentification par mot de passe si compatible avec les autres usages.
- Restreindre si possible les droits `sudo` aux opérations qui seront retenues.
- Ne jamais stocker ni transmettre le mot de passe `sudo` à l'agent ; si l'automatisation privilégiée devient nécessaire, créer uniquement des règles `NOPASSWD` ciblées sur des commandes précisément validées.
- Limiter l'écoute SSH à l'interface ou au réseau Ethernet concerné lorsque la topologie le permet.
- Enregistrer et vérifier l'empreinte de la clé d'hôte SSH.

Livrable : accès SSH minimal et vérifiable.

### Phase 3 — Initialisation de la connexion

- Renseigner la configuration locale réelle.
- Renseigner `IP_LINUX=serveur-nino-HP-Compaq-8200-Elite-SFF-PC` ; malgré son nom historique, cette variable accepte ici le nom d'hôte résolu.
- Avant chaque session, vérifier que ce nom se résout et correspond à la cible attendue.
- Tester la résolution du nom ou l'adresse IP et le port SSH ; ne pas dépendre uniquement du ping, parfois filtré.
- Tester l'authentification en mode non interactif avec un délai court.
- Contrôler l'identité et les droits effectifs de l'utilisateur distant.
- Confirmer qu'aucune saisie de mot de passe ou validation interactive n'est requise.

Livrable : connexion non interactive fonctionnelle.

### Phase 4 — Garde-fous d'exécution

- Implémenter un enchaînement standard : contrôle de connectivité, commande, code retour, sortie standard et erreur.
- Exiger une confirmation avant toute action sensible.
- Refuser les commandes nécessitant `sudo` tant qu'aucune règle non interactive restreinte n'a été définie et validée.
- Classer au minimum comme sensibles : suppression ou écrasement de données, modification système, installation ou mise à jour de paquets, changement du pare-feu ou de SSH, arrêt/redémarrage d'un service, redémarrage ou arrêt de la machine et modification des comptes ou permissions.
- Interdire les outils interactifs et encadrer les commandes longues.
- Mettre en place une journalisation sans secrets.
- Définir une stratégie de sauvegarde avant modification d'un fichier distant.

Livrable : procédure d'exécution sûre et auditable.

### Phase 5 — Tests progressifs

1. Lecture seule : identité, nom d'hôte, uptime, mémoire et espace disque.
2. Diagnostic : état d'un service et lecture limitée de journaux.
3. Écriture réversible : dépôt d'un fichier temporaire dans un emplacement autorisé, contrôle puis suppression.
4. Gestion de service : redémarrage d'un service de test avec validation préalable.
5. Test d'échec : cible indisponible, mauvaise clé, droits insuffisants et commande en erreur.

Livrable : procès-verbal de tests et anomalies restantes.

### Phase 6 — Mise en service et exploitation

- Valider les critères d'acceptation.
- Documenter les commandes usuelles et la procédure de dépannage.
- Prévoir la rotation/révocation de la clé SSH.
- Réviser périodiquement les droits, journaux et versions d'OpenSSH.
- Ajouter les autres machines seulement après validation de la première cible.

Livrable : guide d'exploitation et procédure de révocation.

## 5. Critères d'acceptation initiaux

- Aucun secret ni clé privée n'est suivi par Git.
- La connexion fonctionne sans interaction et échoue rapidement si la cible est indisponible.
- La clé d'hôte distante est vérifiée.
- Le compte distant ne dispose que des droits nécessaires.
- Chaque action affiche son résultat et son code retour.
- Chaque action sensible est décrite puis confirmée explicitement avant exécution.
- La révocation de l'accès est documentée et testable.

## 6. Points à ne pas reprendre tels quels du protocole amont

- Ne pas conserver `StrictHostKeyChecking=no` en exploitation : enregistrer et vérifier la clé d'hôte.
- Ne pas ouvrir directement l'accès SSH à `root` sauf justification exceptionnelle.
- Ne pas considérer l'échec d'un ping comme une preuve suffisante d'indisponibilité : tester également le port SSH.
- Ne pas mémoriser une clé privée ou un secret dans une mémoire d'agent ; conserver uniquement leur emplacement local protégé.
