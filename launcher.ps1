# Configuration des distributions disponibles
$distros = @{
    "1" = @{ Name = "Debian"; Id = "Debian" }
    "2" = @{ Name = "Ubuntu 22.04 LTS"; Id = "Ubuntu-22.04" }
    "3" = @{ Name = "Kali Linux"; Id = "kali-linux" }
    "4" = @{ Name = "Ubuntu 24.04 LTS"; Id = "Ubuntu-24.04" }
}

function Show-Menu {
    Clear-Host
    Write-Host "--- Gestionnaire WSL ---" -ForegroundColor Cyan
    foreach ($key in $distros.Keys | Sort-Object) {
        Write-Host "$($key) : $($distros[$key].Name)"
    }
    Write-Host "Q : Quitter"
    Write-Host "------------------------"
}


if (!(Get-Command "wsl" -ErrorAction SilentlyContinue)) {
    Write-Host "WSL n'est pas installé sur ce système. Active-le d'abord !" -ForegroundColor Red
    pause
    exit
}

while ($true) {
    Show-Menu
    $choice = Read-Host "Choisis une option"

    if ($choice -eq "Q") { break }

    if ($distros.ContainsKey($choice)) {
        $selected = $distros[$choice]
        

        $installed = wsl --list --quiet
        if ($installed -like "*$($selected.Id)*") {
            Write-Host "Lancement de $($selected.Name)..." -ForegroundColor Green
            wsl -d $selected.Id
        } else {
            Write-Host "Installation de $($selected.Name)... (Cela peut prendre quelques minutes)" -ForegroundColor Yellow
            wsl --install -d $selected.Id
            Write-Host "Installation terminée !" -ForegroundColor Green
            wsl -d $selected.Id
        }
    } else {
        Write-Host "Option invalide, réessaie." -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
}