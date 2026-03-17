# WSL Launcher amélioré — liste dynamique des distributions (installables via `wsl --install -d`)

# Emplacement du fichier de log
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logPath = Join-Path $scriptDir 'launcher.log'

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "${timestamp} [${Level}] $Message"
    $line | Out-File -FilePath $logPath -Append -Encoding UTF8
    Write-Host $line
}

Write-Log "=== Nouvelle session de lancement WSL ==="

function Get-OnlineDistros {
    Write-Log "Récupération des distributions disponibles via 'wsl --list --online'..."
    $raw = & wsl --list --online 2>&1
    if ($LASTEXITCODE -ne 0 -or -not $raw) {
        Write-Log "Impossible de récupérer la liste en ligne (commande wsl --list --online a échoué)." 'WARN'
        return $null
    }

    # Joindre en texte unique, normaliser les retours chariot
    $text = ($raw -join "`n") -replace "`r", ""

    # Supprimer BOM et caractères de contrôle (sauf \n)
    $text = [System.Text.RegularExpressions.Regex]::Replace($text, "[\x00-\x09\x0B\x0C\x0E-\x1F\x7F]", "")
    $text = $text.Trim()

    # Split en lignes et trim
    $lines = $text -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

    $dict = @{}
    $i = 1

    foreach ($line in $lines) {
        # Ignorer lignes d'en-tête / aide (différentes langues possibles)
        if ($line -match '(?i)^(name|nom|friendly|friendly name|installer|aide|help|usage|utilisation)') { continue }
        if ($line -match '^-{2,}$') { continue }
        if ($line -match '(?i)^(?:Voici la liste|Pour installer|Use wsl --install)') { continue }

        # Extraire ID (premier token sans espace) et le reste comme friendly name
        if ($line -match '^\s*(\S+)\s+(.+)$') {
            $idCandidate = $matches[1].Trim()
            $friendlyCandidate = $matches[2].Trim()
        }
        elseif ($line -match '^\s*(\S+)\s*$') {
            $idCandidate = $matches[1].Trim()
            $friendlyCandidate = $idCandidate
        }
        else {
            continue
        }

        # Valider l'ID (caractères acceptés pour les IDs WSL)
        if (-not ($idCandidate -match '^[A-Za-z0-9._-]+$')) { continue }

        # Eviter doublons
        if ($dict.Values | Where-Object { $_.Id -eq $idCandidate }) { continue }

        $dict[$i.ToString()] = @{ Name = $friendlyCandidate; Id = $idCandidate }
        $i++

        # Limiter taille raisonnable pour l'affichage
        if ($i -gt 200) { break }
    }

    if ($dict.Count -eq 0) {
        Write-Log "Aucune distribution analysée depuis la sortie en ligne." 'WARN'
        return $null
    }

    return $dict
}

# Fallback statique (si --list --online ne marche pas)
$staticFallback = @{
    "1" = @{ Name = "Ubuntu (latest)"; Id = "Ubuntu" }
    "2" = @{ Name = "Ubuntu 22.04 LTS"; Id = "Ubuntu-22.04" }
    "3" = @{ Name = "Debian"; Id = "Debian" }
    "4" = @{ Name = "Kali Linux"; Id = "kali-linux" }
    "5" = @{ Name = "Alpine Linux"; Id = "Alpine" }
}

function Show-Menu($distros) {
    Clear-Host
    Write-Host "--- Gestionnaire WSL (liste dynamique) ---" -ForegroundColor Cyan
    foreach ($key in $distros.Keys | Sort-Object { [int]$_ }) {
        Write-Host "$($key) : $($distros[$key].Name) (Id: $($distros[$key].Id))"
    }
    Write-Host "R : Rafraîchir la liste en ligne"
    Write-Host "Q : Quitter"
    Write-Host "------------------------------------------"
}

# Vérifier si WSL est installé
if (!(Get-Command "wsl" -ErrorAction SilentlyContinue)) {
    Write-Log "WSL n'est pas installé sur ce système. Active-le d'abord !" 'ERROR'
    Write-Host "WSL n'est pas installé sur ce système. Active-le d'abord !" -ForegroundColor Red
    Pause
    exit
}

# Récupération initiale des distributions en ligne
$distros = Get-OnlineDistros
if (-not $distros) {
    Write-Log "Utilisation de la liste statique de fallback." 'WARN'
    $distros = $staticFallback
}

while ($true) {
    Show-Menu $distros
    $choice = (Read-Host "Choisis une option").Trim()
    if ($choice.ToUpper() -eq 'Q') { break }
    if ($choice.ToUpper() -eq 'R') {
        $new = Get-OnlineDistros
        if ($new) {
            $distros = $new
            Write-Log "Liste en ligne rafraîchie (${distros.Count} éléments)."
        }
        else {
            Write-Log "Impossible de rafraîchir la liste en ligne, conservation de la liste actuelle." 'WARN'
            Write-Host "Impossible de rafraîchir la liste en ligne." -ForegroundColor Yellow
        }
        continue
    }

    if ($distros.ContainsKey($choice)) {
        $selected = $distros[$choice]
        Write-Log "Option sélectionnée : $($selected.Name) (Id: $($selected.Id))"

        $installed = (wsl --list --quiet 2>$null) -join "`n"
        if ($installed -and $installed -match [regex]::Escape($selected.Id)) {
            Write-Log "Distribution déjà installée - lancement de $($selected.Name)"
            Write-Host "Lancement de $($selected.Name)..." -ForegroundColor Green
            wsl -d $selected.Id
        }
        else {
            Write-Log "Début de l'installation de $($selected.Name) (wsl --install -d $($selected.Id))"
            Write-Host "Installation de $($selected.Name)... (Cela peut prendre quelques minutes)" -ForegroundColor Yellow

            $output = & wsl --install -d $selected.Id 2>&1
            $exit = $LASTEXITCODE
            if ($output) { foreach ($line in $output) { Write-Log $line 'OUTPUT' } }

            if ($exit -eq 0) {
                Write-Log "Commande d'installation terminée avec succès. Attente que la distribution apparaisse dans la liste..."
                $timeout = 300; $elapsed = 0
                while ($elapsed -lt $timeout) {
                    Start-Sleep -Seconds 2
                    $elapsed += 2
                    $installed = (wsl --list --quiet 2>$null) -join "`n"
                    if ($installed -and $installed -match [regex]::Escape($selected.Id)) { break }
                    if ($elapsed % 6 -eq 0) { Write-Log "En attente que $($selected.Name) apparaisse ($elapsed/$timeout s)" }
                    else { Write-Host -NoNewline "." }
                }

                if ($installed -and $installed -match [regex]::Escape($selected.Id)) {
                    Write-Log "Installation terminée et distribution détectée - lancement"
                    Write-Host "\nInstallation terminée !" -ForegroundColor Green
                    wsl -d $selected.Id
                }
                else {
                    Write-Log "La distribution n'apparaît pas dans la liste après $timeout secondes." 'ERROR'
                    Write-Host "\nL'installation s'est terminée mais la distribution n'apparaît pas dans la liste." -ForegroundColor Red
                }
            }
            else {
                Write-Log "La commande d'installation a échoué (code $exit)." 'ERROR'
                Write-Host "Échec de l'installation (code $exit)." -ForegroundColor Red
                if ($output) { foreach ($line in $output) { Write-Host $line -ForegroundColor DarkRed } }
            }
        }
    }
    else {
        Write-Host "Option invalide, réessaie." -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
}

Write-Log "Fin de session."