[CmdletBinding(DefaultParameterSetName = 'PlainText')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'PlainText')]
    [ValidateNotNullOrEmpty()]
    [string]$Command,

    [Parameter(Mandatory = $true, ParameterSetName = 'Base64')]
    [ValidateNotNullOrEmpty()]
    [string]$CommandBase64,

    [ValidateSet('ReadOnly', 'Sensitive')]
    [string]$ActionType = 'ReadOnly',

    [AllowEmptyString()]
    [string]$ConfirmationReference = '',

    [ValidateRange(1, 300)]
    [int]$TimeoutSeconds = 15
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PSCmdlet.ParameterSetName -eq 'Base64') {
    try {
        $Command = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($CommandBase64))
    }
    catch {
        throw 'Commande refusée : CommandBase64 ne contient pas une valeur Base64 valide.'
    }
    if (-not $Command) {
        throw 'Commande refusée : la commande décodée est vide.'
    }
}

function ConvertTo-NativeArgument {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    if ($Value.Length -gt 0 -and $Value -notmatch '[\s"]') {
        return $Value
    }

    $builder = New-Object System.Text.StringBuilder
    [void]$builder.Append('"')
    $backslashes = 0

    foreach ($character in $Value.ToCharArray()) {
        if ($character -eq '\') {
            $backslashes++
            continue
        }

        if ($character -eq '"') {
            [void]$builder.Append(('\' * (($backslashes * 2) + 1)))
            [void]$builder.Append('"')
        }
        else {
            [void]$builder.Append(('\' * $backslashes))
            [void]$builder.Append($character)
        }
        $backslashes = 0
    }

    [void]$builder.Append(('\' * ($backslashes * 2)))
    [void]$builder.Append('"')
    return $builder.ToString()
}

function Write-ExecutionResult {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Status,

        [AllowNull()]
        [Nullable[int]]$ExitCode,

        [AllowEmptyString()]
        [string]$StandardOutput = '',

        [AllowEmptyString()]
        [string]$StandardError = '',

        [Parameter(Mandatory = $true)]
        [datetime]$StartedAt,

        [Parameter(Mandatory = $true)]
        [datetime]$FinishedAt
    )

    $logWritten = Write-ExecutionLog -Status $Status -ExitCode $ExitCode `
        -StartedAt $StartedAt -FinishedAt $FinishedAt

    [pscustomobject]@{
        Status = $Status
        ExitCode = $ExitCode
        ActionType = $ActionType
        ConfirmationRecorded = -not [string]::IsNullOrWhiteSpace($ConfirmationReference)
        LogWritten = $logWritten
        StandardOutput = $StandardOutput.TrimEnd("`r", "`n")
        StandardError = $StandardError.TrimEnd("`r", "`n")
        StartedAt = $StartedAt
        FinishedAt = $FinishedAt
        DurationMs = [math]::Round(($FinishedAt - $StartedAt).TotalMilliseconds)
    }
}

# Ces contrôles complètent, sans remplacer, la classification humaine d'une action.
if ($Command -match '(?i)(^|[;&|()\s])sudo(?=$|[;&|()\s])') {
    throw 'Commande refusée : sudo est interdit dans le périmètre initial.'
}

if ($ActionType -eq 'Sensitive' -and [string]::IsNullOrWhiteSpace($ConfirmationReference)) {
    throw 'Commande refusée : une référence de confirmation explicite est requise pour une action sensible.'
}

$sensitiveMarkers = @(
    '(^|[;&|()\s])(rm|mv|cp|touch|mkdir|rmdir|chmod|chown|install|tee|dd|truncate|useradd|userdel|usermod|groupadd|groupdel|mount|umount|reboot|shutdown)(?=$|[;&|()\s])',
    '(^|[;&|()\s])(apt|apt-get|dpkg)(?=$|[;&|()\s])',
    '(^|[;&|()\s])systemctl\s+(start|stop|restart|reload|enable|disable|mask|unmask)(?=$|[;&|()\s])',
    '(^|[;&|()\s])sed\s+[^;&|()\r\n]*\s-i(?=$|[;&|()\s])',
    '(^|[;&|()\s])passwd(?=$|[;&|()\s])',
    '(?<!\d)>{1,2}(?![&|])'
)
if ($ActionType -eq 'ReadOnly' -and ($sensitiveMarkers | Where-Object { $Command -match "(?i)$_" })) {
    throw 'Commande refusée en mode ReadOnly : marqueur d''action sensible détecté. Classifiez-la en Sensitive et fournissez une référence de confirmation.'
}

$interactiveTools = 'vi|vim|nano|emacs|less|more|top|htop|man|passwd|ssh|sftp|ftp|telnet'
if ($Command -match "(?i)(^|[;&|()]\s*)($interactiveTools)(?=$|[;&|()\s])") {
    throw "Commande refusée : outil potentiellement interactif détecté ($($Matches[2]))."
}

$config = @{}
Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\.env') | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith('#')) {
        $pair = $line.Split('=', 2)
        if ($pair.Count -eq 2) {
            $config[$pair[0].Trim()] = $pair[1].Trim()
        }
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
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if (-not [IO.Path]::IsPathRooted($keyPath)) {
    $keyPath = Join-Path $projectRoot $keyPath
}
$knownHostsPath = Join-Path $projectRoot '.ssh_known_hosts'
$logDirectory = Join-Path $projectRoot '_logs'
$logPath = Join-Path $logDirectory 'ssh-execution.jsonl'

function Get-CommandHash {
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($Command)
        return ([BitConverter]::ToString($sha256.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha256.Dispose()
    }
}

function Write-ExecutionLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Status,

        [AllowNull()]
        [Nullable[int]]$ExitCode,

        [Parameter(Mandatory = $true)]
        [datetime]$StartedAt,

        [Parameter(Mandatory = $true)]
        [datetime]$FinishedAt
    )

    try {
        if (-not (Test-Path -LiteralPath $logDirectory -PathType Container)) {
            [void](New-Item -ItemType Directory -Path $logDirectory -Force)
        }

        $entry = [ordered]@{
            SchemaVersion = 1
            TimestampUtc = $FinishedAt.ToUniversalTime().ToString('o')
            Status = $Status
            ExitCode = $ExitCode
            ActionType = $ActionType
            ConfirmationRecorded = -not [string]::IsNullOrWhiteSpace($ConfirmationReference)
            DurationMs = [math]::Round(($FinishedAt - $StartedAt).TotalMilliseconds)
            CommandSha256 = Get-CommandHash
        }
        Add-Content -LiteralPath $logPath -Value ($entry | ConvertTo-Json -Compress) -Encoding UTF8
        return $true
    }
    catch {
        Write-Warning "Journalisation locale impossible : $($_.Exception.Message)"
        return $false
    }
}

if (-not (Test-Path -LiteralPath $keyPath -PathType Leaf)) {
    throw "Clé SSH introuvable : $keyPath"
}
if (-not (Test-Path -LiteralPath $knownHostsPath -PathType Leaf)) {
    throw "Fichier de clés d'hôte introuvable : $knownHostsPath"
}

[void](Resolve-DnsName -Name $hostName -Type A -ErrorAction Stop |
    Select-Object -First 1 -ExpandProperty IPAddress)
if (-not (Test-NetConnection -ComputerName $hostName -Port $sshPort -InformationLevel Quiet -WarningAction SilentlyContinue)) {
    throw "Port SSH inaccessible : $hostName`:$sshPort"
}

$sshPath = (Get-Command ssh.exe -ErrorAction Stop).Source
$encodedCommand = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Command))
$remoteCommand = "printf %s $encodedCommand|base64 -d|sh"
$arguments = @(
    '-i', $keyPath,
    '-p', $sshPort.ToString(),
    '-T',
    '-o', 'KexAlgorithms=curve25519-sha256',
    '-o', 'IdentitiesOnly=yes',
    '-o', 'StrictHostKeyChecking=yes',
    '-o', "UserKnownHostsFile=$knownHostsPath",
    '-o', 'BatchMode=yes',
    '-o', 'ConnectTimeout=8',
    "$sshUser@$hostName",
    $remoteCommand
)

$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.FileName = $sshPath
$processInfo.Arguments = (($arguments | ForEach-Object { ConvertTo-NativeArgument -Value $_ }) -join ' ')
$processInfo.UseShellExecute = $false
$processInfo.CreateNoWindow = $true
$processInfo.RedirectStandardInput = $true
$processInfo.RedirectStandardOutput = $true
$processInfo.RedirectStandardError = $true

$process = New-Object System.Diagnostics.Process
$process.StartInfo = $processInfo
$startedAt = Get-Date

try {
    if (-not $process.Start()) {
        throw 'Le processus SSH n''a pas pu être démarré.'
    }

    # Une entrée standard fermée empêche toute attente de saisie distante.
    $process.StandardInput.Close()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()

    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        $process.Kill()
        $process.WaitForExit()
        $finishedAt = Get-Date
        $stdout = $stdoutTask.GetAwaiter().GetResult()
        $stderr = $stderrTask.GetAwaiter().GetResult()
        Write-ExecutionResult -Status 'Timeout' -ExitCode $null `
            -StandardOutput $stdout -StandardError $stderr `
            -StartedAt $startedAt -FinishedAt $finishedAt
        exit 124
    }

    $finishedAt = Get-Date
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    $exitCode = $process.ExitCode

    if ($exitCode -eq 0) {
        $status = 'Success'
    }
    elseif ($exitCode -eq 255) {
        $status = 'SshError'
    }
    else {
        $status = 'RemoteCommandError'
    }

    Write-ExecutionResult -Status $status -ExitCode $exitCode `
        -StandardOutput $stdout -StandardError $stderr `
        -StartedAt $startedAt -FinishedAt $finishedAt
    exit $exitCode
}
finally {
    $process.Dispose()
}
