# WSL Launcher GUI — Interface graphique avec Windows Forms

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Configuration
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logPath = Join-Path $scriptDir 'launcher.log'

# Fonction de logging
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "${timestamp} [${Level}] $Message"
    $line | Out-File -FilePath $logPath -Append -Encoding UTF8
}

Write-Log "=== Nouvelle session WSL Launcher GUI ==="

# Fonction pour récupérer les distributions
function Get-OnlineDistros {
    Write-Log "Récupération des distributions disponibles..."
    $raw = & wsl --list --online 2>&1
    
    if ($LASTEXITCODE -ne 0 -or -not $raw) {
        Write-Log "Impossible de récupérer la liste en ligne." 'WARN'
        return @{
            "1" = @{ Name = "Ubuntu (latest)"; Id = "Ubuntu" }
            "2" = @{ Name = "Ubuntu 22.04 LTS"; Id = "Ubuntu-22.04" }
            "3" = @{ Name = "Debian"; Id = "Debian" }
            "4" = @{ Name = "Kali Linux"; Id = "kali-linux" }
            "5" = @{ Name = "Alpine Linux"; Id = "Alpine" }
        }
    }

    $text = ($raw -join "`n") -replace "`r", ""
    $text = [System.Text.RegularExpressions.Regex]::Replace($text, "[\x00-\x09\x0B\x0C\x0E-\x1F\x7F]", "")
    $lines = $text -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

    $dict = @{}
    $i = 1

    foreach ($line in $lines) {
        if ($line -match '(?i)^(name|nom|friendly|friendly name|installer|aide|help|usage|utilisation)') { continue }
        if ($line -match '^-{2,}$') { continue }
        if ($line -match '(?i)^(?:Voici la liste|Pour installer|Use wsl --install)') { continue }

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

        if (-not ($idCandidate -match '^[A-Za-z0-9._-]+$')) { continue }
        if ($dict.Values | Where-Object { $_.Id -eq $idCandidate }) { continue }

        $dict[$i.ToString()] = @{ Name = $friendlyCandidate; Id = $idCandidate }
        $i++

        if ($i -gt 200) { break }
    }

    if ($dict.Count -eq 0) {
        Write-Log "Aucune distribution trouvée, utilisation du fallback." 'WARN'
        return @{
            "1" = @{ Name = "Ubuntu (latest)"; Id = "Ubuntu" }
            "2" = @{ Name = "Ubuntu 22.04 LTS"; Id = "Ubuntu-22.04" }
            "3" = @{ Name = "Debian"; Id = "Debian" }
            "4" = @{ Name = "Kali Linux"; Id = "kali-linux" }
            "5" = @{ Name = "Alpine Linux"; Id = "Alpine" }
        }
    }

    return $dict
}

# Créer la fenêtre principale
$form = New-Object System.Windows.Forms.Form
$form.Text = "🐧 WSL Launcher"
$form.Size = New-Object System.Drawing.Size(600, 500)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# Titre
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "🐧 WSL Manager - Sélectionnez une distribution"
$titleLabel.Location = New-Object System.Drawing.Point(10, 10)
$titleLabel.Size = New-Object System.Drawing.Size(560, 30)
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::Cyan
$form.Controls.Add($titleLabel)

# ListBox pour les distributions
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10, 50)
$listBox.Size = New-Object System.Drawing.Size(560, 300)
$listBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$listBox.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
$listBox.ForeColor = [System.Drawing.Color]::White
$listBox.IntegralHeight = $false
$form.Controls.Add($listBox)

# Panel pour les boutons
$buttonPanel = New-Object System.Windows.Forms.Panel
$buttonPanel.Location = New-Object System.Drawing.Point(10, 360)
$buttonPanel.Size = New-Object System.Drawing.Size(560, 60)
$buttonPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.Controls.Add($buttonPanel)

# Bouton Installer/Lancer
$installBtn = New-Object System.Windows.Forms.Button
$installBtn.Text = "▶ Lancer / Installer"
$installBtn.Location = New-Object System.Drawing.Point(10, 10)
$installBtn.Size = New-Object System.Drawing.Size(160, 40)
$installBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$installBtn.ForeColor = [System.Drawing.Color]::White
$installBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$installBtn.FlatStyle = "Flat"
$buttonPanel.Controls.Add($installBtn)

# Bouton Rafraîchir
$refreshBtn = New-Object System.Windows.Forms.Button
$refreshBtn.Text = "🔄 Rafraîchir"
$refreshBtn.Location = New-Object System.Drawing.Point(180, 10)
$refreshBtn.Size = New-Object System.Drawing.Size(120, 40)
$refreshBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 180, 100)
$refreshBtn.ForeColor = [System.Drawing.Color]::White
$refreshBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$refreshBtn.FlatStyle = "Flat"
$buttonPanel.Controls.Add($refreshBtn)

# Bouton Quitter
$quitBtn = New-Object System.Windows.Forms.Button
$quitBtn.Text = "✕ Quitter"
$quitBtn.Location = New-Object System.Drawing.Point(310, 10)
$quitBtn.Size = New-Object System.Drawing.Size(100, 40)
$quitBtn.BackColor = [System.Drawing.Color]::FromArgb(200, 50, 50)
$quitBtn.ForeColor = [System.Drawing.Color]::White
$quitBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$quitBtn.FlatStyle = "Flat"
$buttonPanel.Controls.Add($quitBtn)

# Label de statut
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Prêt"
$statusLabel.Location = New-Object System.Drawing.Point(10, 430)
$statusLabel.Size = New-Object System.Drawing.Size(560, 30)
$statusLabel.ForeColor = [System.Drawing.Color]::LimeGreen
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.Controls.Add($statusLabel)

# Dictionnaire global pour les distributions
$script:distros = @{}
$script:selectedDistro = $null

# Fonction pour remplir la ListBox
function Update-DistroList {
    $script:distros = Get-OnlineDistros
    $listBox.Items.Clear()
    
    foreach ($key in ($script:distros.Keys | Sort-Object { [int]$_ })) {
        $item = $script:distros[$key]
        $listBox.Items.Add("[${key}] $($item.Name)")
    }
    
    $statusLabel.Text = "Liste mise à jour - $($listBox.Items.Count) distributions disponibles"
    $statusLabel.ForeColor = [System.Drawing.Color]::LimeGreen
}

# Événement du bouton Rafraîchir
$refreshBtn.Add_Click({
        $statusLabel.Text = "Rafraîchissement en cours..."
        $statusLabel.ForeColor = [System.Drawing.Color]::Yellow
        $form.Refresh()
    
        Update-DistroList
    })

# Événement du bouton Installer/Lancer
$installBtn.Add_Click({
        $selectedIndex = $listBox.SelectedIndex
    
        if ($selectedIndex -eq -1) {
            [System.Windows.Forms.MessageBox]::Show("Veuillez sélectionner une distribution.", "Erreur", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
    
        $selectedKey = @($script:distros.Keys | Sort-Object { [int]$_ })[$selectedIndex]
        $selected = $script:distros[$selectedKey]
    
        $statusLabel.Text = "Traitement de $($selected.Name)..."
        $statusLabel.ForeColor = [System.Drawing.Color]::Yellow
        $form.Refresh()
    
        Write-Log "Sélection : $($selected.Name) (Id: $($selected.Id))"
    
        # Vérifier si déjà installée
        $installed = (wsl --list --quiet 2>$null) -join "`n"
    
        if ($installed -and $installed -match [regex]::Escape($selected.Id)) {
            $statusLabel.Text = "Lancement de $($selected.Name)..."
            $statusLabel.ForeColor = [System.Drawing.Color]::LimeGreen
            Write-Log "Distribution déjà installée - lancement"
        
            # Lancer WSL dans une nouvelle fenêtre
            Start-Process wsl -ArgumentList "-d $($selected.Id)" -WindowStyle Normal
        
            $statusLabel.Text = "Prêt"
        }
        else {
            $result = [System.Windows.Forms.MessageBox]::Show(
                "La distribution $($selected.Name) n'est pas installée. Voulez-vous l'installer maintenant ?`n`nCela peut prendre plusieurs minutes.",
                "Installation",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
        
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                $statusLabel.Text = "Installation en cours de $($selected.Name)..."
                $statusLabel.ForeColor = [System.Drawing.Color]::Yellow
                $form.Refresh()
            
                Write-Log "Installation de $($selected.Name) (wsl --install -d $($selected.Id))"
            
                $output = & wsl --install -d $selected.Id 2>&1
                $exit = $LASTEXITCODE
            
                if ($exit -eq 0) {
                    $statusLabel.Text = "Installation terminée ! Attente de la détection..."
                    $form.Refresh()
                
                    # Attendre que la distribution apparaisse
                    $timeout = 120
                    $elapsed = 0
                
                    while ($elapsed -lt $timeout) {
                        Start-Sleep -Seconds 2
                        $elapsed += 2
                        $installed = (wsl --list --quiet 2>$null) -join "`n"
                    
                        if ($installed -and $installed -match [regex]::Escape($selected.Id)) {
                            $statusLabel.Text = "Installation réussie ! Lancement..."
                            $statusLabel.ForeColor = [System.Drawing.Color]::LimeGreen
                            $form.Refresh()
                        
                            Write-Log "Distribution détectée - lancement"
                            Start-Process wsl -ArgumentList "-d $($selected.Id)" -WindowStyle Normal
                        
                            $statusLabel.Text = "Prêt"
                            break
                        }
                    }
                
                    if ($elapsed -ge $timeout) {
                        $statusLabel.Text = "Timeout : la distribution n'a pas pu être détectée."
                        $statusLabel.ForeColor = [System.Drawing.Color]::Red
                        Write-Log "Timeout lors de l'installation" 'ERROR'
                    }
                }
                else {
                    $statusLabel.Text = "Échec de l'installation (code $exit)"
                    $statusLabel.ForeColor = [System.Drawing.Color]::Red
                    Write-Log "Installation échouée (code $exit)" 'ERROR'
                
                    [System.Windows.Forms.MessageBox]::Show("L'installation a échoué. Vérifiez les logs.", "Erreur", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            }
            else {
                $statusLabel.Text = "Installation annulée"
                $statusLabel.ForeColor = [System.Drawing.Color]::Yellow
            }
        }
    })

# Événement du bouton Quitter
$quitBtn.Add_Click({
        Write-Log "Fermeture de l'application"
        $form.Close()
    })

# Charger les distributions au démarrage
Update-DistroList

# Afficher la fenêtre
$form.ShowDialog() | Out-Null
