#!/usr/bin/env bash
# ==============================================================================
# Obsidian & Sapphire KDE Plasma Suite — Universal Installer
# Compatible with KDE Plasma 5 & 6 across Debian/Ubuntu/Kali, Arch, Fedora, openSUSE
# ==============================================================================
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_CHOICE="blue"
SKIP_DEPS=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --icons)
            ICON_CHOICE="${2:-blue}"
            shift 2
            ;;
        --no-deps)
            SKIP_DEPS=1
            shift
            ;;
        -h|--help)
            cat <<EOF
Obsidian & Sapphire KDE Plasma Installer

Usage:
  ./install.sh [options]

Options:
  --icons <blue|purple|dracula|candy>   Choose icon pack variant (default: blue)
  --no-deps                             Skip distro package manager dependency check
  -h, --help                            Show this help message
EOF
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

echo "=================================================================="
echo "  Obsidian & Sapphire — KDE Plasma Desktop Suite Installer"
echo "=================================================================="

# ------------------------------------------------------------------------------
# 1. Dependency Check & Cross-Distro Package Installation
# ------------------------------------------------------------------------------
check_deps() {
    local missing=0
    command -v git >/dev/null 2>&1 || missing=1
    command -v curl >/dev/null 2>&1 || missing=1
    python3 -c "import PyQt6" >/dev/null 2>&1 || missing=1
    return $missing
}

if [[ "$SKIP_DEPS" -eq 0 ]]; then
    if ! check_deps; then
        echo "[1/7] Installing system dependencies..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update -y
            sudo apt-get install -y git curl python3 python3-pyqt6 python3-dbus lm-sensors playerctl pulseaudio-utils brightnessctl libnotify-bin
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -Sy --needed --noconfirm git curl python python-pyqt6 python-dbus lm_sensors playerctl libpulse brightnessctl libnotify
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y git curl python3 python3-pyqt6 python3-dbus lm_sensors playerctl pulseaudio-utils brightnessctl libnotify
        elif command -v zypper >/dev/null 2>&1; then
            sudo zypper install -y git curl python3 python3-qt6 python3-dbus-python sensors playerctl pulseaudio-utils brightnessctl libnotify-tools
        else
            echo "  [!] Could not detect package manager. Please ensure python3-pyqt6, git, and lm-sensors are installed."
        fi
    else
        echo "[1/7] Core dependencies (Python3 + PyQt6, git, curl) already satisfied."
    fi
else
    echo "[1/7] Skipping dependency installation (--no-deps)."
fi

# ------------------------------------------------------------------------------
# 2. Backup Existing User KDE Configuration
# ------------------------------------------------------------------------------
BACKUP_DIR="$HOME/.config/kde-backup-pre-mac"
if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "[2/7] Backing up current KDE Plasma configuration to $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    for f in kdeglobals kwinrc kcminputrc kscreenlockerrc plasmarc plasmashellrc plasma-org.kde.plasma.desktop-appletsrc; do
        [[ -f "$HOME/.config/$f" ]] && cp -a "$HOME/.config/$f" "$BACKUP_DIR/"
    done
else
    echo "[2/7] Existing backup preserved at $BACKUP_DIR."
fi

# ------------------------------------------------------------------------------
# 3. Install Upstream Base Themes (WhiteSur KDE + Cursors + Tela Circle Icons)
# ------------------------------------------------------------------------------
echo "[3/7] Checking base KDE Plasma themes & icon packs..."
mkdir -p "$HOME/.local/share/plasma/desktoptheme" \
         "$HOME/.local/share/aurorae/themes" \
         "$HOME/.local/share/color-schemes" \
         "$HOME/.local/share/icons" \
         "$HOME/.icons" \
         "$HOME/.local/share/wallpapers" \
         "$HOME/.local/bin" \
         "$HOME/.local/share/applications" \
         "$HOME/.config/systemd/user"

TMP_BUILD="$(mktemp -d /tmp/obsidian-sapphire-build.XXXXXX)"
trap 'rm -rf "$TMP_BUILD"' EXIT

if [[ ! -d "$HOME/.local/share/plasma/desktoptheme/WhiteSur-dark" ]]; then
    echo "  -> Fetching WhiteSur-kde base plasma style..."
    git clone --depth=1 https://github.com/vinceliuice/WhiteSur-kde.git "$TMP_BUILD/WhiteSur-kde"
    (cd "$TMP_BUILD/WhiteSur-kde" && ./install.sh --sharp)
fi

if [[ ! -d "$HOME/.local/share/icons/WhiteSur-cursors" ]]; then
    echo "  -> Fetching WhiteSur-cursors..."
    git clone --depth=1 https://github.com/vinceliuice/WhiteSur-cursors.git "$TMP_BUILD/WhiteSur-cursors"
    mkdir -p "$HOME/.local/share/icons/WhiteSur-cursors"
    cp -r "$TMP_BUILD/WhiteSur-cursors/dist/"* "$HOME/.local/share/icons/WhiteSur-cursors/"
fi
ln -sfn "$HOME/.local/share/icons/WhiteSur-cursors" "$HOME/.icons/WhiteSur-cursors"

if [[ ! -d "$HOME/.local/share/icons/Tela-circle-blue-dark" ]]; then
    echo "  -> Fetching Tela-circle-icon-theme (blue, purple, dracula)..."
    git clone --depth=1 https://github.com/vinceliuice/Tela-circle-icon-theme.git "$TMP_BUILD/Tela-circle-icon-theme"
    (cd "$TMP_BUILD/Tela-circle-icon-theme" && ./install.sh blue purple dracula)
fi

if [[ "$ICON_CHOICE" == "candy" && ! -d "$HOME/.local/share/icons/candy-icons" ]]; then
    echo "  -> Fetching candy-icons..."
    git clone --depth=1 https://github.com/EliverLara/candy-icons.git "$HOME/.local/share/icons/candy-icons"
fi

# ------------------------------------------------------------------------------
# 4. Install Obsidian & Sapphire Assets (Colors, Aurorae, Icons, Wallpaper)
# ------------------------------------------------------------------------------
echo "[4/7] Installing Obsidian & Sapphire custom assets (Zero Apple Logos)..."

# Color Scheme
cp -f "$REPO_DIR/assets/color-schemes/ObsidianSapphire.colors" "$HOME/.local/share/color-schemes/ObsidianSapphire.colors"

# Custom Right-Side Small Sapphire/Indigo/Rose Window Buttons (Aurorae)
mkdir -p "$HOME/.local/share/aurorae/themes/WhiteSur-dark"
cp -f "$REPO_DIR/assets/aurorae/WhiteSur-dark/"* "$HOME/.local/share/aurorae/themes/WhiteSur-dark/"

# Custom Sapphire Bento Launcher Icon & Apple Logo Removal
cp -f "$REPO_DIR/assets/icons/cyber-launchpad.svg" "$HOME/.local/share/icons/cyber-launchpad.svg"
for theme_dir in "$HOME/.local/share/plasma/desktoptheme"/WhiteSur*; do
    if [[ -d "$theme_dir/icons" ]]; then
        cp -f "$REPO_DIR/assets/icons/start.svg" "$theme_dir/icons/start.svg"
    fi
done
rm -rf "$HOME/.local/share/icons/WhiteSur" "$HOME/.local/share/icons/WhiteSur-dark" "$HOME/.local/share/icons/WhiteSur-light"

# Generate Obsidian & Sapphire Wallpaper
python3 "$REPO_DIR/assets/wallpapers/generate-wallpaper.py" "$HOME/.local/share/wallpapers/Obsidian-Sapphire.png"

# ------------------------------------------------------------------------------
# 5. Install Scripts & Desktop Entries
# ------------------------------------------------------------------------------
echo "[5/7] Installing Obsidian & Sapphire binaries & desktop launchers..."
for script in mac-dynamic-island mac-side-monitor mac-app-launcher mac-speed-boost mac-apply-theme mac-restore-backup; do
    cp -f "$REPO_DIR/bin/$script" "$HOME/.local/bin/$script"
    chmod +x "$HOME/.local/bin/$script"
done

cat > "$HOME/.local/share/applications/cyber-launchpad.desktop" <<EOF
[Desktop Entry]
Name=All Applications
Comment=Open Floating Centered App Launcher
Exec=$HOME/.local/bin/mac-app-launcher --toggle
Icon=$HOME/.local/share/icons/cyber-launchpad.svg
Type=Application
Categories=System;Utility;
Terminal=false
StartupNotify=false
EOF

cat > "$HOME/.local/share/applications/mac-speed-boost.desktop" <<EOF
[Desktop Entry]
Name=KDE Speed Boost
Comment=Optimize KWin, Baloo, RAM cache and Plasma responsiveness
Exec=$HOME/.local/bin/mac-speed-boost
Icon=speedometer
Type=Application
Categories=System;Utility;
Terminal=false
EOF

# ------------------------------------------------------------------------------
# 6. Install & Start Systemd User Services
# ------------------------------------------------------------------------------
echo "[6/7] Configuring systemd user services (Dynamic Island, Side Monitor, App Launcher)..."
cp -f "$REPO_DIR/systemd/mac-dynamic-island.service" "$HOME/.config/systemd/user/"
cp -f "$REPO_DIR/systemd/mac-side-monitor.service" "$HOME/.config/systemd/user/"
cp -f "$REPO_DIR/systemd/mac-app-launcher.service" "$HOME/.config/systemd/user/"

systemctl --user daemon-reload
systemctl --user enable mac-dynamic-island.service mac-side-monitor.service mac-app-launcher.service
systemctl --user restart mac-dynamic-island.service mac-side-monitor.service mac-app-launcher.service

# ------------------------------------------------------------------------------
# 7. Apply Theme, Layout & Speed Boost
# ------------------------------------------------------------------------------
echo "[7/7] Applying Obsidian & Sapphire KDE layout, theme, and speed boost..."
"$HOME/.local/bin/mac-apply-theme" --icons "$ICON_CHOICE"

echo ""
echo "=================================================================="
echo "  Obsidian & Sapphire KDE Suite Installed Successfully!"
echo "  - Change icon variant anytime: ~/.local/bin/mac-apply-theme --icons <blue|purple|dracula|candy>"
echo "  - Uninstall & restore backup:  ./uninstall.sh"
echo "=================================================================="
