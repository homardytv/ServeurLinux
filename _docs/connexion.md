# Vérification de connexion SSH

Ce document définit le contrôle à réaliser à chaque lancement de
`_commands/start.md`. Il est strictement en lecture seule côté Linux : il ne
lance aucune application, n'écrit aucun fichier distant et n'utilise pas
`sudo`.

## Prérequis locaux

- Le fichier `.env` existe et définit `IP_LINUX`, `SSH_USER`, `SSH_KEY` et
  `SSH_PORT`.
- La clé privée pointée par `SSH_KEY` est présente localement et reste ignorée
  par Git.
- La clé d'hôte de la cible est présente dans `.ssh_known_hosts`.

## Procédure à exécuter depuis `ServeurLinux`

```powershell
$config = @{}
Get-Content -LiteralPath '.env' | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith('#')) {
        $pair = $line.Split('=', 2)
        $config[$pair[0].Trim()] = $pair[1].Trim()
    }
}

foreach ($name in 'IP_LINUX', 'SSH_USER', 'SSH_KEY', 'SSH_PORT') {
    if (-not $config.ContainsKey($name) -or -not $config[$name]) {
        throw "Variable manquante dans .env : $name"
    }
}

$hostName = $config['IP_LINUX']
$sshUser = $config['SSH_USER']
$sshPort = [int]$config['SSH_PORT']
$keyPath = $config['SSH_KEY']
if (-not [IO.Path]::IsPathRooted($keyPath)) {
    $keyPath = Join-Path (Get-Location) $keyPath
}

if (-not (Test-Path -LiteralPath $keyPath -PathType Leaf)) {
    throw "Clé SSH introuvable : $keyPath"
}
if (-not (Test-Path -LiteralPath '.ssh_known_hosts' -PathType Leaf)) {
    throw 'Fichier .ssh_known_hosts introuvable.'
}

$address = Resolve-DnsName -Name $hostName -Type A -ErrorAction Stop |
    Select-Object -First 1 -ExpandProperty IPAddress
if (-not (Test-NetConnection -ComputerName $hostName -Port $sshPort -InformationLevel Quiet -WarningAction SilentlyContinue)) {
    throw "Port SSH inaccessible : $hostName`:$sshPort"
}

$identity = & ssh.exe -i $keyPath -p $sshPort `
    -o 'KexAlgorithms=curve25519-sha256' `
    -o 'IdentitiesOnly=yes' `
    -o 'StrictHostKeyChecking=yes' `
    -o 'UserKnownHostsFile=.ssh_known_hosts' `
    -o 'BatchMode=yes' `
    -o 'ConnectTimeout=8' `
    "$sshUser@$hostName" 'whoami; hostname'
if ($LASTEXITCODE -ne 0) {
    throw 'Authentification SSH non interactive échouée.'
}

$identity = @($identity | Where-Object { $_.Trim() })
if ($identity.Count -ne 2 -or $identity[0] -ne $sshUser -or $identity[1] -ne $hostName) {
    throw "Identité distante inattendue : $($identity -join ', ')"
}

[pscustomobject]@{
    Hote = $hostName
    Adresse = $address
    PortSSH = $sshPort
    Utilisateur = $identity[0]
    Machine = $identity[1]
    Etat = 'Connexion SSH validée'
} | Format-List
```

## Interprétation

- `Connexion SSH validée` : la connexion peut être utilisée pour des actions
  autorisées par `AGENTS.md` et confirmées si elles sont sensibles.
- Toute erreur : arrêter le lancement, rapporter le message exact et ne pas
  contourner la vérification de clé d'hôte.
