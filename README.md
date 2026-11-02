# Obsidian & Sapphire — KDE Plasma Desktop Suite

![KDE Plasma 6](https://img.shields.io/badge/KDE_Plasma-6-3B82F6?style=for-the-badge&logo=kde&logoColor=white)
![X11](https://img.shields.io/badge/Session-X11-1E293B?style=for-the-badge&logo=linux&logoColor=white)
![Python](https://img.shields.io/badge/Python_3-PyQt6-2563EB?style=for-the-badge&logo=python&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-10B981?style=for-the-badge)

A dark **Obsidian (`#0D1017`) & Sapphire (`#3B82F6`)** desktop for KDE Plasma 6 with a
**Windows 11 layout, shortcuts and touchpad gestures**, a **Laser Flow live wallpaper**
(port of [ReactBits Laser Flow](https://reactbits.dev/c/animations/laser-flow)) with a
**real terminal** inside it, plus a Dynamic Island, a side hardware monitor and an app launcher.

---

## Features

### Windows 11 taskbar
Single bottom panel: Start menu (Kickoff) and pinned apps centred; system tray, clock with date
and show-desktop button on the right.

### Windows 11 keyboard shortcuts

| Keys | Action |
| :--- | :--- |
| `Win` | Start menu |
| `Win+Tab` | Task View (Overview) |
| `Alt+Tab` | Switch apps |
| `Win+D` / `Win+M` | Show desktop / minimize all |
| `Win+←` / `Win+→` | Snap window left / right |
| `Win+↑` / `Win+↓` | Maximize / minimize |
| `Win+Ctrl+←/→` | Switch virtual desktop |
| `Win+E` | File manager |
| `Win+I` | Settings |
| `Win+R` | Run (KRunner) |
| `Win+L` | Lock |
| `Win+V` | Clipboard history |
| `Win+Shift+S` | Screenshot of a region |
| `Win+1…9` | Open pinned taskbar app |
| `Ctrl+Shift+Esc` | System Monitor |
| `Ctrl+Alt+T` | Terminal |

### Touchpad gestures (X11, via libinput-gestures)

| Gesture | Action |
| :--- | :--- |
| 3 fingers up | Task View |
| 3 fingers down | Show desktop |
| 3 fingers left / right | Switch apps |
| 3 fingers hold | Search (KRunner) |
| 4 fingers left / right | Switch virtual desktop |

Tap-to-click and natural scrolling are enabled. Edit `~/.config/libinput-gestures.conf` to change gestures.

### Laser Flow live wallpaper
A GPU shader port of ReactBits Laser Flow: a beam lands on a rounded card, spreads along its
edge and pours over the corners, with fog, dust and flow lines. Everything is adjustable in
**Right-click desktop → Configure Desktop and Wallpaper** (colour, beam, fog, card size, FPS,
render resolution). Defaults (24 fps, 50% resolution) keep GPU load moderate on integrated graphics.

### Real desktop terminal
A borderless Konsole window placed inside the wallpaper card. It starts at login, runs
**fastfetch** (Kali logo + live system info) and leaves you at your normal shell — click it and type.
It stays below other windows and out of the taskbar and Alt+Tab.
Restart it with `desktop-terminal` if you close it.

### Widgets (PyQt6, systemd user services)
- **Dynamic Island** (`mac-dynamic-island`): top-centre media controls, volume/brightness, quick actions.
- **Side monitor** (`mac-side-monitor`): CPU / GPU / RAM / disk usage and temperatures on the right edge.
- **App launcher** (`mac-app-launcher`): floating centred launcher with search, categories and power menu.

### Look
Breeze with the **ObsidianSapphire** colour scheme, **Tela-circle** icons, Breeze cursors and
window buttons on the right (minimize, maximize, close).

---

## Install

```bash
git clone https://github.com/infant06/obsidian-sapphire-kde.git
cd obsidian-sapphire-kde
./install.sh
```

The installer runs in this order, so a failed package install leaves your desktop untouched:

1. Installs **all** required packages (apt / pacman / dnf / zypper), libinput-gestures and the Tela icons.
2. Backs up your KDE config to `~/.config/kde-backup-pre-mac/` (first install only).
3. Copies the colour scheme, wallpaper plugin, Konsole profile and fastfetch config.
4. Installs scripts into `~/.local/bin/`.
5. Installs the systemd user services.
6. Configures the touchpad.
7. Applies the theme, taskbar, shortcuts, wallpaper and desktop terminal.

Log out and back in once afterwards (needed for touchpad gestures).

### Options

```bash
./install.sh --icons purple     # blue (default), purple, dracula
./install.sh --no-deps          # skip package installation
./install.sh --no-gestures      # skip touchpad gestures
```

---

## Commands

| Command | Description |
| :--- | :--- |
| `mac-apply-theme [--icons <variant>]` | Re-apply theme, taskbar, shortcuts, wallpaper and terminal placement |
| `mac-win11-shortcuts` | Re-apply only the Windows 11 shortcuts |
| `desktop-terminal` | Start the desktop terminal if it is not running |
| `desk-fetch` | Print the fastfetch summary |
| `mac-speed-boost` | Faster animations, disable Baloo indexing and splash screen |
| `mac-app-launcher --toggle` | Toggle the app launcher |
| `./uninstall.sh` | Stop everything, remove files and restore your backup |

---

## Notes

- Built and tested on **Kali Linux, KDE Plasma 6.6, X11**. On Wayland, use Plasma's built-in
  touchpad gestures instead of libinput-gestures.
- The terminal window position is calculated for the primary screen. If you change the card size
  in the wallpaper settings, adjust **System Settings → Window Management → Window Rules →
  Desktop terminal**, or re-run `mac-apply-theme`.
- If the panel ever disappears after resume (frozen vsync on some AMD laptops), run
  `xrandr --output eDP --rate 40.04; xrandr --output eDP --rate 60.06` and re-login.

---

## Repository structure

```text
obsidian-sapphire-kde/
├── install.sh                      # Packages first, then backup, files, apply
├── uninstall.sh                    # Remove everything and restore backup
├── bin/
│   ├── mac-apply-theme             # Theme, Win11 taskbar, wallpaper, terminal window rule
│   ├── mac-win11-shortcuts         # Windows 11 global shortcuts
│   ├── mac-speed-boost             # Plasma performance tweaks
│   ├── mac-restore-backup          # Restore ~/.config/kde-backup-pre-mac/*.bak
│   ├── desktop-terminal            # Launch the real terminal inside the wallpaper card
│   ├── desk-fetch                  # fastfetch with the desktop layout
│   ├── mac-dynamic-island          # Dynamic Island (PyQt6)
│   ├── mac-side-monitor            # Side hardware monitor (PyQt6)
│   └── mac-app-launcher            # App launcher (PyQt6)
├── assets/
│   ├── wallpaper/org.infant06.laserflow/   # Laser Flow Plasma wallpaper plugin
│   ├── konsole/                    # DesktopTerm profile + transparent colour scheme
│   ├── fastfetch/desktop.jsonc     # fastfetch layout for the desktop terminal
│   ├── gestures/                   # libinput-gestures config
│   ├── color-schemes/              # ObsidianSapphire.colors
│   └── icons/                      # Launcher icon
└── systemd/                        # systemd --user units for the widgets
```

## License

Released under the [MIT License](LICENSE), except the Laser Flow shader
(`assets/wallpaper/org.infant06.laserflow/contents/shaders/`), which is a port of
[ReactBits Laser Flow](https://github.com/DavidHDev/react-bits) © David Haz and remains under its
MIT + Commons Clause license.
