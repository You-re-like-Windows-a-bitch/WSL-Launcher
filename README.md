# 🚀 WSL Launcher

![Stars](https://img.shields.io/github/stars/You-re-like-Windows-a-bitch/WSL-Launcher?style=for-the-badge&color=yellow)
![Commits](https://img.shields.io/github/commit-activity/m/You-re-like-Windows-a-bitch/WSL-Launcher?style=for-the-badge&color=blue)
![Issues](https://img.shields.io/github/issues/You-re-like-Windows-a-bitch/WSL-Launcher?style=for-the-badge&color=orange)
![Forks](https://img.shields.io/github/forks/You-re-like-Windows-a-bitch/WSL-Launcher?style=for-the-badge&color=808080)
![Last Commit](https://img.shields.io/github/last-commit/You-re-like-Windows-a-bitch/WSL-Launcher?style=for-the-badge&color=blue)

> **Un gestionnaire WSL élégant et intuitif pour installer et lancer les distributions Linux directement depuis PowerShell.**
> _Exemple : Télécharge, installe et lance Ubuntu en 3 clics !_

---

## 🧐 Aperçu

WSL Launcher est un script PowerShell qui simplifie la gestion de Windows Subsystem for Linux (WSL). Fini de taper des commandes complexes : il suffit de sélectionner une distribution dans un menu coloré et le script s'occupe du reste !

```
    ╔═══════════════════════════════════════════════════════════════╗
    ║       🐧 WSL Launcher - Gestionnaire de Distributions       ║
    ╚═══════════════════════════════════════════════════════════════╝

     1 | Ubuntu (latest) [Ubuntu]
     2 | Debian GNU/Linux [Debian]
     3 | Kali Linux Rolling [kali-linux]
     ...

    ╔═══════════════════════════════════════════════════════════════╗
    ║ Options:                                                      ║
    ║  [R] Rafraichir  [Q] Quitter                                 ║
    ╚═══════════════════════════════════════════════════════════════╝
```

## ✨ Fonctionnalités

- ✅ **Liste dynamique des distributions** : Récupère automatiquement les distributions disponibles depuis WSL.
- ✅ **Installation automatique** : Installe la distribution choisie en un seul clic.
- ✅ **Détection intelligente** : Vérifie si la distribution est déjà installée et la lance directement.
- ✅ **Interface colorée** : Menu élégant avec couleurs et emojis pour une meilleure lisibilité.
- ✅ **Logging complet** : Enregistre toutes les actions dans `launcher.log` pour le débogage.
- ✅ **Fallback automatique** : Si la récupération en ligne échoue, utilise une liste statique.
- ✅ **Barre de progression** : Affiche la progression pendant l'installation et l'attente.

## 🛠 Tech Stack

| Technologie                                                                        | Usage                            |
| :--------------------------------------------------------------------------------- | :------------------------------- |
| ![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue?style=flat-square) | Script principal pour Windows    |
| ![Bash](https://img.shields.io/badge/Bash-4.0+-green?style=flat-square)            | Script alternatif pour Linux/Mac |
| ![WSL](https://img.shields.io/badge/WSL-2.0+-purple?style=flat-square)             | Gestion des distributions Linux  |
| ![UTF-8](https://img.shields.io/badge/Encoding-UTF--8-green?style=flat-square)     | Logging et sortie colorée        |

## 🚀 Installation & Lancement

### Pour Windows (PowerShell)

#### 1. **Cloner le projet**

```bash
git clone https://github.com/You-re-like-Windows-a-bitch/WSL-Launcher.git
cd WSL-Launcher
```

#### 2. **Vérifier que WSL est installé**

```powershell
wsl --version
```

Si vous n'avez pas WSL, installez-le avec :

```powershell
wsl --install
```

#### 3. **Lancer le script PowerShell**

Ouvrez **PowerShell en tant qu'Administrateur** et exécutez :

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\launcher.ps1
```

Ou en une seule ligne :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\launcher.ps1"
```

### Pour Linux/Mac (Bash)

#### 1. **Cloner le projet**

```bash
git clone https://github.com/You-re-like-Windows-a-bitch/WSL-Launcher.git
cd WSL-Launcher
```

#### 2. **Rendre le script exécutable**

```bash
chmod +x launcher.sh
```

#### 3. **Lancer le script Bash**

```bash
./launcher.sh
```

> ⚠️ **Note** : Le script bash nécessite que WSL 2.0+ soit installé sur votre système Windows et accessible via la commande `wsl`.

## 📖 Utilisation

### Version PowerShell vs Bash

| Critère      | PowerShell              | Bash                    |
| ------------ | ----------------------- | ----------------------- |
| Plateforme   | Windows (natif)         | Linux, Mac, WSL         |
| Installation | Aucune dépendance       | Bash 4.0+ requis        |
| Couleurs     | ✅ Complètes            | ✅ Complètes            |
| Logging      | ✅ Oui (`launcher.log`) | ✅ Oui (`launcher.log`) |
| Performance  | Rapide                  | Très rapide             |
| Utilisation  | `.\launcher.ps1`        | `./launcher.sh`         |

### Sélectionner une distribution

1. Le script affiche une liste numérotée de toutes les distributions disponibles
2. Tapez le numéro correspondant et appuyez sur Entrée
3. Si la distribution n'est pas installée, le script la télécharge et l'installe automatiquement
4. Une fois l'installation terminée, la distribution se lance directement

### Options du menu

- **[Numéro]** : Sélectionner une distribution
- **R** : Rafraîchir la liste en ligne
- **Q** : Quitter le script

### Exemple

```powershell
PS C:\WSL-Launcher> .\launcher.ps1

    Distribution sélectionnée : Ubuntu 22.04 LTS

    Installation de Ubuntu 22.04 LTS en cours...
       (Cela peut prendre quelques minutes)

    Verification (60/$timeout s)...
    Installation terminee !
    Lancement de Ubuntu 22.04 LTS...
```

## 📋 Logs

Tous les événements sont enregistrés dans `launcher.log` au même emplacement que le script :

```
2026-03-17 14:23:45 [INFO] === Nouvelle session de lancement WSL ===
2026-03-17 14:23:46 [INFO] Recuperation des distributions disponibles...
2026-03-17 14:23:50 [INFO] Option selectionnee : Ubuntu 22.04 LTS (Id: Ubuntu-22.04)
2026-03-17 14:23:51 [INFO] Installation de Ubuntu 22.04 LTS en cours...
```

Consultez le log en cas de problème :

```powershell
Get-Content .\launcher.log -Tail 50
```

## 🤝 Contribution

Les contributions sont les bienvenues ! Voici comment aider :

1. **Forkez le projet**

   ```bash
   git clone https://github.com/You-re-like-Windows-a-bitch/WSL-Launcher.git
   ```

2. **Créez votre branche**

   ```bash
   git checkout -b feature/AmazingFeature
   ```

3. **Committez vos changements**

   ```bash
   git commit -m 'Add some AmazingFeature'
   ```

4. **Pushez vers la branche**

   ```bash
   git push origin feature/AmazingFeature
   ```

5. **Ouvrez une Pull Request**

### Idées pour les contributions

- 🎨 Améliorer l'interface (nouveaux emojis, mise en page, etc.)
- 🐛 Corriger des bugs
- 📚 Améliorer la documentation
- 🚀 Ajouter de nouvelles fonctionnalités (gestion des versions, suppression, etc.)

## 👤 Auteur

**You-re-like-Windows-a-bitch**
![Follow](https://img.shields.io/github/followers/You-re-like-Windows-a-bitch?label=Follow%20Me&style=social)

---

## 📄 Licence

Ce projet est sous licence MIT.

![GitHub License](https://img.shields.io/github/license/You-re-like-Windows-a-bitch/WSL-Launcher?style=flat-square&color=blue)

---

## ⚡ Troubleshooting

### "WSL n'est pas installé"

```powershell
wsl --install
# Redémarrez votre ordinateur après l'installation
```

### "Impossible de récupérer la liste en ligne"

Le script utilisera la liste statique de fallback. Vérifiez votre connexion internet.

### "La distribution n'apparaît pas dans la liste"

Attendez quelques secondes après l'installation. Si le problème persiste, consultez `launcher.log`.

### "Erreur d'exécution du script"

Assurez-vous que PowerShell fonctionne en tant qu'Administrateur :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\launcher.ps1"
```

---

**Merci d'utiliser WSL Launcher ! 🎉**
