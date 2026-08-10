# Exécution standardisée des commandes SSH

Le script `_scripts/Invoke-SshCommand.ps1` constitue le point d'entrée local
pour les commandes distantes autorisées. Il ne modifie pas la cible par
lui-même : la commande fournie détermine la nature de l'action.

## Garanties

- lecture de la cible et du compte uniquement depuis `.env` ;
- vérification DNS et TCP avant la connexion ;
- vérification stricte de la clé d'hôte ;
- authentification sans interaction avec `BatchMode=yes` ;
- pseudo-terminal désactivé et entrée standard fermée ;
- délai d'exécution réglable, limité à 300 secondes ;
- refus de `sudo` et des outils interactifs usuels ;
- capture séparée de la sortie standard et de l'erreur standard ;
- restitution du code retour SSH ou de la commande distante.

La commande est transportée en UTF-8/Base64 puis décodée en mémoire sur Linux.
Cela évite que l'analyse de la ligne de commande Windows altère ses guillemets ;
aucun fichier distant n'est créé par ce mécanisme.

Les contrôles automatiques ne remplacent pas l'analyse de la commande. Toute
écriture ou action sensible doit être décrite, confirmée explicitement et
accompagnée, si elle touche un fichier, d'une sauvegarde et d'un retour arrière.

## Confirmation et modification distante

Le paramètre `-ActionType` vaut `ReadOnly` par défaut. Dans ce mode, le script
refuse les marqueurs connus d'écriture, de gestion de service, de paquets, de
comptes ou de redirection vers un fichier.

Une action sensible exige impérativement les éléments suivants avant son
exécution :

1. Une demande décrivant la commande, son effet et la cible exacte.
2. Une confirmation explicite de l'utilisateur dans cette conversation.
3. Une référence non secrète à cette confirmation passée au script avec
   `-ConfirmationReference`.
4. Pour tout fichier distant, la sauvegarde, la vérification de sauvegarde et
   la commande de retour arrière décrites dans le plan ci-dessous.

Exemple de forme, à utiliser seulement après confirmation explicite :

```powershell
& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
    -File '.\_scripts\Invoke-SshCommand.ps1' `
    -CommandBase64 $commandBase64 `
    -ActionType Sensitive `
    -ConfirmationReference 'confirmation-utilisateur-2026-08-10'
```

La référence est une trace locale ; elle ne remplace jamais la confirmation
réelle de l'utilisateur. Elle ne doit contenir ni mot de passe, ni clé, ni
jeton.

### Plan obligatoire pour un fichier distant

| Élément à définir avant exécution | Exigence |
|---|---|
| Fichier cible | Chemin absolu et propriétaire identifiés |
| Sauvegarde | Chemin de copie datée sur le même hôte et vérification de son existence |
| Modification | Commande précise, sans `sudo`, et effet attendu |
| Contrôle | Lecture ou test après écriture, avec résultat attendu |
| Retour arrière | Commande précise de restauration depuis la sauvegarde |
| Nettoyage | Moment et condition de suppression de la sauvegarde, après validation |

Si une seule de ces informations manque, l'action n'est pas prête à être
soumise à confirmation.

## Utilisation

Commande de lecture seule :

```powershell
$result = & powershell.exe -NoProfile -NonInteractive `
    -ExecutionPolicy Bypass `
    -File '.\_scripts\Invoke-SshCommand.ps1' `
    -Command 'whoami; hostname'
$processExitCode = $LASTEXITCODE
```

La dérogation `ExecutionPolicy Bypass` ne vaut que pour ce sous-processus et ne
modifie pas la stratégie d'exécution Windows. La sortie formatée contient tous
les champs du résultat ci-dessous.

PowerShell 5.1 peut altérer les guillemets d'une valeur transmise après
`-File`. Pour une commande complexe, encoder d'abord sa chaîne complète :

```powershell
$command = 'printf "sortie\n"; printf "erreur\n" >&2; false'
$commandBase64 = [Convert]::ToBase64String(
    [Text.Encoding]::UTF8.GetBytes($command)
)
& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
    -File '.\_scripts\Invoke-SshCommand.ps1' `
    -CommandBase64 $commandBase64
```

Le résultat contient :

| Champ | Signification |
|---|---|
| `Status` | `Success`, `RemoteCommandError`, `SshError` ou `Timeout` |
| `ExitCode` | Code de la commande distante ; `255` désigne une erreur SSH |
| `StandardOutput` | Sortie standard, conservée séparément |
| `StandardError` | Erreur standard, conservée séparément |
| `StartedAt`, `FinishedAt`, `DurationMs` | Mesures locales d'exécution |

Le script se termine avec le même code que SSH. Un dépassement du délai renvoie
le code local `124`. Une erreur de validation préalable déclenche une erreur
PowerShell et aucune connexion SSH n'est tentée.

## Journalisation locale

Chaque commande effectivement lancée ajoute une ligne JSON à
`_logs/ssh-execution.jsonl`, fichier exclu de Git. Le journal contient
uniquement : horodatage UTC, statut, code retour, durée, type d'action,
indication de confirmation et empreinte SHA-256 de la commande. Il n'enregistre
ni commande en clair, ni sortie distante, ni erreur distante, ni donnée de
configuration ou secret. Le champ `LogWritten` du résultat indique si l'ajout a
réussi.

## Politique initiale

- Autorisé sans confirmation : diagnostic strictement en lecture seule.
- Confirmation explicite obligatoire : écriture, suppression, transfert,
  modification de configuration, gestion de service ou de compte.
- Interdit : `sudo`, commande interactive, contournement de la clé d'hôte et
  demande de mot de passe.

La liste des outils interactifs bloqués est une défense supplémentaire et ne
peut pas être exhaustive. Seul un nom d'outil placé en début de commande ou
après un séparateur shell est bloqué, afin de ne pas confondre les arguments
comme `journalctl -u ssh` avec l'exécutable `ssh`. La revue humaine de la
commande reste obligatoire.

## Validation du 10 août 2026

| Test | Résultat attendu | Résultat observé |
|---|---|---|
| Identité et version | Lecture seule réussie | Code `0`, Ubuntu 24.04.1 LTS |
| Commande distante en erreur | Flux séparés | Code `1`, `sortie` et `erreur` séparées |
| Dépassement du délai | Arrêt local contrôlé | Statut `Timeout`, code `124` |
| Commande avec `sudo` | Refus avant connexion | Refus local |
| Outil interactif `top` | Refus avant connexion | Refus local |
| Diagnostic système | Uptime, RAM et disque lisibles | Code `0`, lecture seule |
| Service et journaux SSH | Service actif et extrait borné lisible | Code `0`, `ssh` actif |
| Écriture réversible `/tmp` | Créer, lire, contrôler `0600`, supprimer | Code `0`, absence contrôlée |
| Transfert `scp` réversible | Transférer, comparer SHA-256, supprimer | Code `0`, empreintes identiques |
