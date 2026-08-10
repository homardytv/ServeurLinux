# Procès-verbal des tests SSH — 10 août 2026

## Périmètre

Tests effectués depuis ce dépôt vers la cible SSH configurée localement. Aucun
test n'utilise `sudo`, ne modifie la configuration du serveur ou ne conserve de
fichier temporaire après son contrôle.

| Test | Résultat | Preuve synthétique |
|---|---|---|
| Réseau et identité | Réussi | Résolution, port 22, clé d'hôte et identité validés |
| Identité et version | Réussi | Utilisateur, nom d'hôte et Ubuntu 24.04.1 LTS conformes |
| Diagnostic système | Réussi | Uptime, mémoire et espace disque lus sans erreur |
| Service et journaux SSH | Réussi | Service `ssh` actif, extrait de 20 lignes lisible |
| Écriture réversible | Réussi | Fichier `/tmp` créé, lu, contrôlé en `0600`, supprimé et absent |
| Transfert `scp` réversible | Réussi | Code `0`, SHA-256 identique, deux copies supprimées |
| Cible indisponible simulée | Réussi | Port 23 de la cible inaccessible comme attendu |
| Identité invalide | Réussi | Refus local du client SSH, code `255` |
| Droits insuffisants | Réussi | Lecture de `/etc/shadow` refusée, code distant `1` et erreur séparée |

## Conclusion

Les commandes autorisées par le périmètre initial sont contrôlées, non
interactives et traçables par métadonnées locales sans secrets. Le test d'une
opération privilégiée reste hors périmètre tant qu'aucune liste blanche
`NOPASSWD` précise n'a été définie et validée.
