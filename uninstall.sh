#!/usr/bin/env bash
# ==============================================================================
# Obsidian & Sapphire KDE Plasma Suite — Uninstaller & Backup Restorer
# Packages installed by install.sh are left in place.
# ==============================================================================
set -euo pipefail

echo "=================================================================="
echo "  Uninstalling Obsidian & Sapphire KDE Plasma Suite..."
echo "=================================================================="

# 1. Stop desktop terminal and services
for w in $(xdotool search --classname '^desktopterm$' 2>/dev/null); do xdotool windowclose "$w" 2>/dev/null || true; done
for svc in mac-dynamic-island.service mac-side-monitor.service mac-app-launcher.service; do
    systemctl --user stop "$svc" 2>/dev/null || true
    systemctl --user disable "$svc" 2>/dev/null || true
    rm -f "$HOME/.config/systemd/user/$svc"
done
systemctl --user daemon-reload 2>/dev/null || true
command -v libinput-gestures-setup >/dev/null 2>&1 && libinput-gestures-setup stop >/dev/null 2>&1 || true

# 2. Restore the original KDE configuration (panels, shortcuts, window rules, theme)
if [[ -x "$HOME/.local/bin/mac-restore-backup" ]]; then
    "$HOME/.local/bin/mac-restore-backup" || true
fi

# 3. Remove installed files
rm -f "$HOME/.local/bin/"{mac-dynamic-island,mac-side-monitor,mac-app-launcher,mac-speed-boost,mac-apply-theme,mac-win11-shortcuts,mac-restore-backup,desktop-terminal,desk-fetch} \
      "$HOME/.local/share/applications/cyber-launchpad.desktop" \
      "$HOME/.local/share/applications/mac-speed-boost.desktop" \
      "$HOME/.config/autostart/desktop-terminal.desktop" \
      "$HOME/.local/share/konsole/DesktopTerm.profile" \
      "$HOME/.local/share/konsole/DesktopTerm.colorscheme" \
      "$HOME/.config/fastfetch/desktop.jsonc" \
      "$HOME/.local/share/icons/cyber-launchpad.svg"
rm -rf "$HOME/.local/share/plasma/wallpapers/org.infant06.laserflow"

echo "=================================================================="
echo "  Uninstall complete. Original KDE settings restored."
echo "  ~/.config/libinput-gestures.conf was kept; delete it if unwanted."
echo "=================================================================="
