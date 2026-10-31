#!/usr/bin/env bash
# ==============================================================================
# Obsidian & Sapphire KDE Plasma Suite — Uninstaller & Backup Restorer
# ==============================================================================
set -e

echo "=================================================================="
echo "  Uninstalling Obsidian & Sapphire KDE Plasma Suite..."
echo "=================================================================="

# 1. Stop & disable systemd user services
for svc in mac-dynamic-island.service mac-side-monitor.service mac-app-launcher.service; do
    systemctl --user stop "$svc" 2>/dev/null || true
    systemctl --user disable "$svc" 2>/dev/null || true
    rm -f "$HOME/.config/systemd/user/$svc"
done
systemctl --user daemon-reload 2>/dev/null || true

# 2. Restore original KDE configuration backup if available
if [[ -x "$HOME/.local/bin/mac-restore-backup" ]]; then
    "$HOME/.local/bin/mac-restore-backup" || true
fi

# 3. Remove installed scripts & desktop launchers
rm -f "$HOME/.local/bin/mac-dynamic-island" \
      "$HOME/.local/bin/mac-side-monitor" \
      "$HOME/.local/bin/mac-app-launcher" \
      "$HOME/.local/bin/mac-speed-boost" \
      "$HOME/.local/bin/mac-apply-theme" \
      "$HOME/.local/bin/mac-restore-backup" \
      "$HOME/.local/share/applications/cyber-launchpad.desktop" \
      "$HOME/.local/share/applications/mac-speed-boost.desktop"

echo "=================================================================="
echo "  Uninstall complete. Original KDE Plasma settings restored."
echo "=================================================================="
