#!/bin/bash

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_PATH="$SCRIPT_DIR/launcher.log"

# Couleurs
C_CYAN='\033[0;36m'
C_WHITE='\033[0;37m'
C_GRAY='\033[0;90m'
C_YELLOW='\033[0;33m'
C_GREEN='\033[0;32m'
C_RED='\033[0;31m'
NC='\033[0m'

# Nettoyage des sorties Windows (UTF-16/Retours chariots)
clean_wsl_output() {
    tr -d '\000\r'
}

get_online_distros() {
    local raw_output
    raw_output=$(wsl.exe --list --online 2>&1 | clean_wsl_output)
    
    local counter=1
    echo "$raw_output" | while read -r line; do
        line=$(echo "$line" | xargs)
        # Filtre les lignes d'aide et les headers
        [[ -z "$line" || "$line" =~ ^(NAME|Nom|FRIENDLY|---|\[|\ |Installation|La\ liste) ]] && continue
        
        local id=$(echo "$line" | awk '{print $1}')
        local name=$(echo "$line" | cut -d' ' -f2-)
        [ -z "$name" ] && name="$id"
        
        if [[ "$id" =~ ^[A-Za-z0-9._-]+$ && ! "$id" =~ "wsl" ]]; then
            echo "${counter}|${name}|${id}"
            ((counter++))
        fi
    done
}

show_menu() {
    clear
    echo -e "${C_CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${C_CYAN}║            🐧 WSL MANAGER - Distributions                ║${NC}"
    echo -e "${C_CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    for entry in "$@"; do
        local k=$(echo "$entry" | cut -d'|' -f1)
        local n=$(echo "$entry" | cut -d'|' -f2)
        printf "  ${C_GRAY}[${C_YELLOW}%s${C_GRAY}] ${C_WHITE}%-30s${NC}\n" "$k" "$n"
    done
    echo ""
    echo -e "${C_CYAN}────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${C_YELLOW}[R]${NC} Rafraîchir   ${C_RED}[Q]${NC} Quitter"
    echo -e "${C_CYAN}────────────────────────────────────────────────────────────${NC}"
}

# --- INIT ---
distros=()
mapfile -t distros < <(get_online_distros)

while true; do
    show_menu "${distros[@]}"
    read -p " 👉 Choix : " choice
    choice=$(echo "$choice" | tr '[:lower:]' '[:upper:]')

    [[ "$choice" == "Q" ]] && break
    if [[ "$choice" == "R" ]]; then
        mapfile -t distros < <(get_online_distros)
        continue
    fi

    selected_line=$(printf "%s\n" "${distros[@]}" | grep "^$choice|")
    if [[ -n "$selected_line" ]]; then
        d_name=$(echo "$selected_line" | cut -d'|' -f2)
        d_id=$(echo "$selected_line" | cut -d'|' -f3)

        # Vérifier si installée
        is_installed=$(wsl.exe --list --quiet | clean_wsl_output | grep -xw "$d_id")

        if [[ -n "$is_installed" ]]; then
            echo -e "${C_GREEN}🚀 Lancement de $d_name...${NC}"
            wsl.exe -d "$d_id"
        else
            echo -e "${C_YELLOW}⏳ Installation de $d_name...${NC}"
            echo -e "${C_GRAY}(Une fenêtre Windows peut apparaître)${NC}"
            
            # Utilisation de cmd.exe pour forcer l'installation au niveau OS
            cmd.exe /c "wsl.exe --install -d $d_id"
            
            echo ""
            echo -e "${C_GREEN}✅ Processus d'installation lancé/terminé.${NC}"
            echo -e "${C_GRAY}Appuie sur Entrée pour rafraîchir le menu.${NC}"
            read
        fi
    else
        echo -e "${C_RED}Option invalide.${NC}"
        sleep 1
    fi
done