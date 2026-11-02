#!/usr/bin/env bash
# ==============================================================================
# Obsidian & Sapphire KDE Plasma Suite — Installer
# Windows 11 layout & shortcuts, touchpad gestures, Laser Flow live wallpaper,
# real desktop terminal, Dynamic Island, side hardware monitor, app launcher.
#
# Order: 1) install ALL packages  2) back up config  3) copy files  4) apply
# ==============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_CHOICE="blue"
SKIP_DEPS=0
WITH_GESTURES=1

usage() {
    cat <<EOF
Obsidian & Sapphire KDE Plasma Installer

Usage: ./install.sh [options]

  --icons <blue|purple|dracula>   Tela-circle icon variant (default: blue)
  --no-deps                       Skip package installation (you install them yourself)
  --no-gestures                   Do not set up touchpad gestures (libinput-gestures)
  -h, --help                      Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --icons) ICON_CHOICE="${2:-blue}"; shift 2 ;;
        --no-deps) SKIP_DEPS=1; shift ;;
        --no-gestures) WITH_GESTURES=0; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

if [[ $EUID -eq 0 ]]; then
    echo "Run this as your normal user (not root). It will ask for sudo when needed."
    exit 1
fi

step() { echo; echo "[$1/7] $2"; }
echo "=================================================================="
echo "  Obsidian & Sapphire — KDE Plasma Desktop Suite Installer"
echo "=================================================================="

# ------------------------------------------------------------------------------
# 1. Packages — installed BEFORE any file is copied, so a failure leaves the
#    desktop untouched.
# ------------------------------------------------------------------------------
step 1 "Installing required packages..."
if [[ "$SKIP_DEPS" -eq 1 ]]; then
    echo "  Skipped (--no-deps)."
elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y \
        git curl python3 python3-pyqt6 python3-dbus \
        lm-sensors playerctl pulseaudio-utils brightnessctl libnotify-bin \
        libkf6config-bin qdbus-qt6 x11-xserver-utils xdotool wmctrl \
        konsole kde-spectacle plasma-systemmonitor fastfetch fonts-firacode \
        qml6-module-org-kde-plasma-plasma5support libplasma5support6 \
        qml6-module-org-kde-kquickcontrols \
        libinput-tools
elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --needed --noconfirm \
        git curl python python-pyqt6 python-dbus \
        lm_sensors playerctl libpulse brightnessctl libnotify \
        kconfig qt6-tools xorg-xrandr xdotool wmctrl \
        konsole spectacle plasma-systemmonitor fastfetch ttf-fira-code \
        plasma5support kdeclarative libinput
elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y \
        git curl python3 python3-pyqt6 python3-dbus \
        lm_sensors playerctl pulseaudio-utils brightnessctl libnotify \
        kf6-kconfig qt6-qttools xrandr xdotool wmctrl \
        konsole spectacle plasma-systemmonitor fastfetch fira-code-fonts \
        plasma5support libinput-utils
elif command -v zypper >/dev/null 2>&1; then
    sudo zypper install -y \
        git curl python3 python3-qt6 python3-dbus-python \
        sensors playerctl pulseaudio-utils brightnessctl libnotify-tools \
        kconfig6 qt6-tools-qdbus xrandr xdotool wmctrl \
        konsole spectacle plasma6-systemmonitor fastfetch fira-code-fonts \
        plasma6-plasma5support libinput-tools
else
    echo "  [!] Unknown package manager. Install manually: python3-pyqt6, python3-dbus, xdotool,"
    echo "      wmctrl, konsole, fastfetch, Fira Code font, plasma5support QML module, libinput-tools."
    read -r -p "  Continue anyway? [y/N] " ans; [[ "$ans" =~ ^[Yy]$ ]] || exit 1
fi

# Touchpad gestures need libinput-gestures (not packaged on most distros) and the input group
if [[ "$SKIP_DEPS" -eq 0 && "$WITH_GESTURES" -eq 1 ]]; then
    if ! command -v libinput-gestures >/dev/null 2>&1; then
        echo "  -> Installing libinput-gestures from GitHub..."
        TMP_G="$(mktemp -d)"
        git clone --depth=1 https://github.com/bulletmark/libinput-gestures.git "$TMP_G/lg"
        (cd "$TMP_G/lg" && sudo ./libinput-gestures-setup install)
        rm -rf "$TMP_G"
    fi
    if ! id -nG "$USER" | tr ' ' '\n' | grep -qx input; then
        sudo gpasswd -a "$USER" input
        NEED_RELOGIN=1
    fi
fi

# Icon theme (fetched from upstream; only if missing)
if [[ ! -d "$HOME/.local/share/icons/Tela-circle-blue-dark" && ! -d /usr/share/icons/Tela-circle-blue-dark ]]; then
    echo "  -> Fetching Tela-circle icon theme..."
    TMP_I="$(mktemp -d)"
    git clone --depth=1 https://github.com/vinceliuice/Tela-circle-icon-theme.git "$TMP_I/tela"
    (cd "$TMP_I/tela" && ./install.sh blue purple dracula)
    rm -rf "$TMP_I"
fi

# ------------------------------------------------------------------------------
# 2. Back up current configuration (only on first install)
# ------------------------------------------------------------------------------
step 2 "Backing up current KDE configuration..."
BACKUP_DIR="$HOME/.config/kde-backup-pre-mac"
if [[ ! -d "$BACKUP_DIR" ]]; then
    mkdir -p "$BACKUP_DIR"
    for f in kdeglobals kwinrc kwinrulesrc kcminputrc kglobalshortcutsrc kscreenlockerrc klaunchrc \
             ksplashrc baloofilerc plasmarc plasmashellrc plasma-org.kde.plasma.desktop-appletsrc \
             touchpadxlibinputrc; do
        [[ -f "$HOME/.config/$f" ]] && cp -a "$HOME/.config/$f" "$BACKUP_DIR/$f.bak"
    done
    echo "  Saved to $BACKUP_DIR"
else
    echo "  Existing backup kept at $BACKUP_DIR"
fi

# ------------------------------------------------------------------------------
# 3. Copy assets
# ------------------------------------------------------------------------------
step 3 "Installing colour scheme, wallpaper, terminal & fastfetch configs..."
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/.local/share/icons" \
         "$HOME/.local/share/color-schemes" "$HOME/.local/share/plasma/wallpapers" \
         "$HOME/.local/share/konsole" "$HOME/.config/fastfetch" "$HOME/.config/autostart" \
         "$HOME/.config/systemd/user"

cp -f "$REPO_DIR/assets/color-schemes/ObsidianSapphire.colors" "$HOME/.local/share/color-schemes/"
cp -f "$REPO_DIR/assets/icons/cyber-launchpad.svg" "$HOME/.local/share/icons/"

WP="$HOME/.local/share/plasma/wallpapers/org.infant06.laserflow"
rm -rf "$WP"
cp -a "$REPO_DIR/assets/wallpaper/org.infant06.laserflow" "$WP"
chmod +x "$WP/contents/code/sysinfo.sh"

cp -f "$REPO_DIR/assets/konsole/DesktopTerm.profile" "$REPO_DIR/assets/konsole/DesktopTerm.colorscheme" \
      "$HOME/.local/share/konsole/"
cp -f "$REPO_DIR/assets/fastfetch/desktop.jsonc" "$HOME/.config/fastfetch/"
if [[ "$WITH_GESTURES" -eq 1 ]]; then
    cp -f "$REPO_DIR/assets/gestures/libinput-gestures.conf" "$HOME/.config/libinput-gestures.conf"
fi

# ------------------------------------------------------------------------------
# 4. Scripts & launchers
# ------------------------------------------------------------------------------
step 4 "Installing scripts and launchers..."
for script in mac-dynamic-island mac-side-monitor mac-app-launcher mac-speed-boost \
              mac-apply-theme mac-win11-shortcuts mac-restore-backup desktop-terminal desk-fetch; do
    install -m 755 "$REPO_DIR/bin/$script" "$HOME/.local/bin/$script"
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
Comment=Optimize KWin, Baloo and Plasma responsiveness
Exec=$HOME/.local/bin/mac-speed-boost
Icon=speedometer
Type=Application
Categories=System;Utility;
Terminal=false
EOF

cat > "$HOME/.config/autostart/desktop-terminal.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Desktop Terminal
Comment=Real terminal inside the Laser Flow wallpaper
Exec=/bin/sh -c 'sleep 4; \$HOME/.local/bin/desktop-terminal'
Icon=utilities-terminal
X-KDE-autostart-phase=2
EOF

# ------------------------------------------------------------------------------
# 5. Systemd user services
# ------------------------------------------------------------------------------
step 5 "Installing systemd user services..."
cp -f "$REPO_DIR/systemd/"*.service "$HOME/.config/systemd/user/"
systemctl --user daemon-reload

# ------------------------------------------------------------------------------
# 6. Touchpad
# ------------------------------------------------------------------------------
step 6 "Configuring touchpad (tap-to-click, natural scroll, gestures)..."
TP=$(grep -E '^N: Name=".*[Tt]ouchpad"' /proc/bus/input/devices 2>/dev/null | head -1 | sed -E 's/^N: Name="(.*)"/\1/')
if [[ -n "$TP" ]]; then
    kwriteconfig6 --file touchpadxlibinputrc --group "$TP" --key tapToClick true
    kwriteconfig6 --file touchpadxlibinputrc --group "$TP" --key naturalScroll true
    echo "  Touchpad: $TP"
else
    echo "  No touchpad found; skipped."
fi
if [[ "$WITH_GESTURES" -eq 1 ]] && command -v libinput-gestures-setup >/dev/null 2>&1; then
    libinput-gestures-setup autostart >/dev/null 2>&1 || true
    [[ "${NEED_RELOGIN:-0}" -eq 0 ]] && libinput-gestures-setup restart >/dev/null 2>&1 || true
fi

# ------------------------------------------------------------------------------
# 7. Apply
# ------------------------------------------------------------------------------
step 7 "Applying theme, layout, shortcuts and wallpaper..."
"$HOME/.local/bin/mac-apply-theme" --icons "$ICON_CHOICE"

echo
echo "=================================================================="
echo "  Obsidian & Sapphire installed."
[[ "${NEED_RELOGIN:-0}" -eq 1 ]] && echo "  -> Log out and back in to enable touchpad gestures."
echo "  Re-apply anytime:   ~/.local/bin/mac-apply-theme --icons <blue|purple|dracula>"
echo "  Uninstall/restore:  ./uninstall.sh"
echo "=================================================================="
