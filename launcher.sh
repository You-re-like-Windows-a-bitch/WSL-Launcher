#!/bin/bash

# WSL Launcher amélioré — liste dynamique des distributions (installables via `wsl --install -d`)

# Emplacement du fichier de log
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_PATH="$SCRIPT_DIR/launcher.log"

# Fonction pour écrire dans les logs
write_log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_line="${timestamp} [${level}] ${message}"
    echo "$log_line" | tee -a "$LOG_PATH"
}

write_log "=== Nouvelle session de lancement WSL ==="

# Fonction pour récupérer les distributions en ligne
get_online_distros() {
    write_log "Récupération des distributions disponibles via 'wsl --list --online'..."
    
    local raw_output
    raw_output=$(wsl --list --online 2>&1)
    local exit_code=$?
    
    if [ $exit_code -ne 0 ] || [ -z "$raw_output" ]; then
        write_log "Impossible de récupérer la liste en ligne (commande wsl --list --online a échoué)." "WARN"
        return 1
    fi
    
    # Traiter le output
    local -A dict
    local counter=1
    local line_num=0
    
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        
        # Ignorer les lignes d'en-tête / aide
        if [[ $line =~ ^(NAME|NOM|FRIENDLY|FRIENDLY\ NAME|INSTALLER|AIDE|HELP|USAGE|UTILISATION) ]]; then
            continue
        fi
        if [[ $line =~ ^[-]{2,} ]]; then
            continue
        fi
        if [[ $line =~ ^(Voici\ la\ liste|Pour\ installer|Use\ wsl\ --install) ]]; then
            continue
        fi
        
        # Trim la ligne
        line=$(echo "$line" | xargs)
        [ -z "$line" ] && continue
        
        # Extraire ID et friendly name
        local id_candidate=$(echo "$line" | awk '{print $1}')
        local friendly_candidate=$(echo "$line" | cut -d' ' -f2- || echo "$id_candidate")
        
        # Valider l'ID (caractères acceptés)
        if ! [[ $id_candidate =~ ^[A-Za-z0-9._-]+$ ]]; then
            continue
        fi
        
        # Éviter les doublons (simple vérification)
        local found=0
        for key in "${!dict[@]}"; do
            if [[ "${dict[$key]}" == *"id=$id_candidate"* ]]; then
                found=1
                break
            fi
        done
        [ $found -eq 1 ] && continue
        
        # Ajouter à la liste
        dict[$counter]="name=$friendly_candidate|id=$id_candidate"
        counter=$((counter + 1))
        
        # Limite raisonnable
        [ $counter -gt 200 ] && break
    done <<< "$raw_output"
    
    if [ ${#dict[@]} -eq 0 ]; then
        write_log "Aucune distribution analysée depuis la sortie en ligne." "WARN"
        return 1
    fi
    
    # Afficher la liste (pour récupération externe)
    for key in "${!dict[@]}"; do
        echo "${key}|${dict[$key]}"
    done | sort -t'|' -k1 -n
}

# Définir les distributions statiques (fallback)
declare -A STATIC_FALLBACK
STATIC_FALLBACK[1]="name=Ubuntu (latest)|id=Ubuntu"
STATIC_FALLBACK[2]="name=Ubuntu 22.04 LTS|id=Ubuntu-22.04"
STATIC_FALLBACK[3]="name=Debian|id=Debian"
STATIC_FALLBACK[4]="name=Kali Linux|id=kali-linux"
STATIC_FALLBACK[5]="name=Alpine Linux|id=Alpine"

# Fonction pour afficher le menu
show_menu() {
    local -n distros=$1
    
    clear
    
    # Définir les couleurs
    local c1='\033[0;36m'  # Cyan
    local c2='\033[0;37m'  # White
    local c3='\033[0;90m'  # Gray
    local yellow='\033[0;33m'  # Yellow
    local nc='\033[0m'  # No Color
    
    echo -e "${c1}------------------------------------------------------------${nc}"
    echo -e "${c1}             WSL MANAGER - Liste des Distributions${nc}"
    echo -e "${c1}------------------------------------------------------------${nc}"
    echo ""
    
    # Afficher les distributions (déjà triées)
    for entry in "${distros[@]}"; do
        local key=$(echo "$entry" | cut -d'|' -f1)
        local name=$(echo "$entry" | cut -d'|' -f2 | cut -d'=' -f2)
        
        printf "${c3}  [${yellow}%s${c3}] ${c2}%-25s${nc}\n" "$key" "$name"
    done
    
    echo ""
    echo -e "${c1}------------------------------------------------------------${nc}"
    echo -e "${c1}  [R] Rafraichir    [Q] Quitter${nc}"
    echo -e "${c1}------------------------------------------------------------${nc}"
    echo ""
}

# Vérifier si WSL est installé
if ! command -v wsl &> /dev/null; then
    write_log "WSL n'est pas installé sur ce système. Active-le d'abord !" "ERROR"
    echo "WSL n'est pas installé sur ce système. Active-le d'abord !"
    read -p "Appuyez sur Entrée pour quitter..."
    exit 1
fi

# Récupération initiale des distributions
declare -a distros
distro_output=$(get_online_distros)
if [ $? -eq 0 ] && [ -n "$distro_output" ]; then
    while IFS= read -r line; do
        distros+=("$line")
    done <<< "$distro_output"
else
    write_log "Utilisation de la liste statique de fallback." "WARN"
    for key in "${!STATIC_FALLBACK[@]}"; do
        distros+=("${key}|${STATIC_FALLBACK[$key]}")
    done
fi

# Boucle principale
while true; do
    show_menu distros[@]
    read -p "Choisis une option: " choice
    choice=$(echo "$choice" | tr '[:lower:]' '[:upper:]')
    
    if [ "$choice" = "Q" ]; then
        break
    fi
    
    if [ "$choice" = "R" ]; then
        write_log "Tentative de rafraîchissement de la liste en ligne..."
        distro_output=$(get_online_distros)
        if [ $? -eq 0 ] && [ -n "$distro_output" ]; then
            distros=()
            while IFS= read -r line; do
                distros+=("$line")
            done <<< "$distro_output"
            write_log "Liste en ligne rafraîchie (${#distros[@]} éléments)."
        else
            write_log "Impossible de rafraîchir la liste en ligne, conservation de la liste actuelle." "WARN"
            echo "Impossible de rafraîchir la liste en ligne."
        fi
        continue
    fi
    
    # Vérifier si le choix existe
    local found_distro=""
    local distro_id=""
    local distro_name=""
    
    for entry in "${distros[@]}"; do
        local key=$(echo "$entry" | cut -d'|' -f1)
        if [ "$key" = "$choice" ]; then
            distro_name=$(echo "$entry" | cut -d'|' -f2 | cut -d'=' -f2)
            distro_id=$(echo "$entry" | cut -d'|' -f3 | cut -d'=' -f2)
            found_distro=1
            break
        fi
    done
    
    if [ -z "$found_distro" ]; then
        echo "Option invalide, réessaie."
        sleep 1
        continue
    fi
    
    write_log "Option sélectionnée : $distro_name (Id: $distro_id)"
    
    # Vérifier si la distribution est déjà installée
    local installed_list
    installed_list=$(wsl --list --quiet 2>/dev/null)
    
    if echo "$installed_list" | grep -q "$distro_id"; then
        write_log "Distribution déjà installée - lancement de $distro_name"
        echo "Lancement de $distro_name..."
        wsl -d "$distro_id"
    else
        write_log "Début de l'installation de $distro_name (wsl --install -d $distro_id)"
        echo "Installation de $distro_name... (Cela peut prendre quelques minutes)"
        
        local output
        output=$(wsl --install -d "$distro_id" 2>&1)
        local exit_code=$?
        
        if [ -n "$output" ]; then
            while IFS= read -r line; do
                write_log "$line" "OUTPUT"
            done <<< "$output"
        fi
        
        if [ $exit_code -eq 0 ]; then
            write_log "Commande d'installation terminée avec succès. Attente que la distribution apparaisse dans la liste..."
            local timeout=1
            local elapsed=0
            
            while [ $elapsed -lt $timeout ]; do
                sleep 2
                elapsed=$((elapsed + 2))
                installed_list=$(wsl --list --quiet 2>/dev/null)
                
                if echo "$installed_list" | grep -q "$distro_id"; then
                    break
                fi
                
                if [ $((elapsed % 6)) -eq 0 ]; then
                    write_log "En attente que $distro_name apparaisse ($elapsed/$timeout s)"
                else
                    echo -n "."
                fi
            done
            
            installed_list=$(wsl --list --quiet 2>/dev/null)
            if echo "$installed_list" | grep -q "$distro_id"; then
                write_log "Installation terminée et distribution détectée - lancement"
                echo ""
                echo "Installation terminée !"
                wsl -d "$distro_id"
            else
                write_log "La distribution n'apparaît pas dans la liste après $timeout secondes." "ERROR"
                echo ""
                echo "L'installation s'est terminée mais la distribution n'apparaît pas dans la liste."
            fi
        else
            write_log "La commande d'installation a échoué (code $exit_code)." "ERROR"
            echo "Échec de l'installation (code $exit_code)."
            if [ -n "$output" ]; then
                echo "$output"
            fi
        fi
    fi
done

write_log "Fin de session."
