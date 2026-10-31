# Obsidian & Sapphire — KDE Plasma Desktop Suite

![KDE Plasma 5 & 6](https://img.shields.io/badge/KDE_Plasma-5_%26_6-3B82F6?style=for-the-badge&logo=kde&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-Universal-1E293B?style=for-the-badge&logo=linux&logoColor=white)
![Python](https://img.shields.io/badge/Python_3-PyQt6-2563EB?style=for-the-badge&logo=python&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-10B981?style=for-the-badge)

A cohesive, zero-lag **Obsidian (`#0D1017`) & Sapphire (`#3B82F6`)** desktop experience for **KDE Plasma**, featuring an interactive **Dynamic Island**, a **Right-Side Sticky Hardware & Thermal Monitor**, a **Floating Centered App Launcher** with full session/power controls, **Windows-style right-side compact window buttons**, **KDE Speed Boost optimizations**, and **100% zero Apple logos**.

---

## ✨ Key Features

1. **Interactive Dynamic Island (`mac-dynamic-island`)**
   - Sits cleanly at the top center of the primary screen.
   - **Compact Mode**: Live media indicator, equalizer visualizer, and active CPU/RAM/GPU telemetry summary.
   - **Expanded Mode** (Click to toggle): Media playback controls (`Prev`, `Play/Pause`, `Next`), interactive **Volume** & **Brightness** sliders, and 1-click quick actions (**Speed Boost**, **Screenshot**, **Toggle Side Monitor**, **Lock Screen**).
   - Engineered with single-step geometry transitions (no X11 pixmap thrashing or KWin freezes).

2. **Right-Side Sticky Hardware & Thermal Monitor (`mac-side-monitor`)**
   - Docked vertically along the right screen edge with a collapsible mini-pill tab (`‹` / `›`).
   - Universal hardware auto-detection across **AMD, Intel, and NVIDIA** setups:
     - **CPU**: Utilization `%`, live clock speed (`GHz`), and package temperature (`°C` via `k10temp`, `coretemp`, `zenpower`, or thermal zones).
     - **GPU**: Utilization `%`, core clock (`MHz`), and temperature (`°C` via `nvidia-smi` or `/sys/class/drm/card*/device/hwmon` for AMD/Intel).
     - **RAM**: Utilization `%` and `Used / Total GB`.
     - **Disk / Swap**: NVMe/SSD composite temperature (`°C`) and active swap usage.
   - Dynamic Sapphire-to-Rose thermal bar coloring when temperatures cross `65°C` / `80°C`.

3. **Floating Centered App Launcher (`mac-app-launcher`)**
   - Opens **dead-center horizontally**, floating right above the bottom dock when clicking the **All Applications** dock icon.
   - Instant search bar (`Enter` launches top result, `Esc` or clicking outside dismisses).
   - Category filter pills: `All Apps`, `★ Pinned`, `Development`, `Internet`, `System`, `Utilities`, and `Security & Kali`.
   - **Bottom System & Power Footer Bar**:
     - Quick system shortcuts: `⚙ Settings`, `📁 Files`, `>_ Terminal`, `📊 Activity`.
     - Session & power controls: `🌙 Sleep`, `🔒 Lock`, `⇥ Log Out`, `↻ Restart`, and `⏻ Power Off` with **inline confirmation** to prevent accidental shutdowns.

4. **Windows-Style Right-Side Compact Window Controls (`IAX`)**
   - Window buttons (`Minimize`, `Maximize`, `Close`) placed on the **right side** (`ButtonsOnRight=IAX`) across all KDE and GTK applications.
   - Custom `13×13px` geometric SVG buttons with permanently visible crisp inner symbols (`—`, `□`, `✕`) in cohesive **Slate/Indigo**, **Sapphire Blue**, and **Crimson Rose**.

5. **Zero Apple Logos + Tela Circle Icon Pack**
   - Automatically installs `Tela-circle-blue-dark` (plus `purple` and `dracula` variants) and replaces all upstream Apple logos with a custom **Sapphire Bento Grid** icon.

6. **KDE Speed Boost (`mac-speed-boost`)**
   - Tunes KWin compositing (`AnimationSpeed=1`, `LatencyPolicy=ExtremelyLow`), disables heavy background blur/translucency lag, and disables `baloo_file` indexing overhead.

---

## 🚀 Quick Installation

Works out-of-the-box on **Debian / Ubuntu / Kali / KDE neon**, **Arch / Manjaro / EndeavourOS**, **Fedora**, and **openSUSE**:

```bash
git clone https://github.com/infant06/obsidian-sapphire-kde.git
cd obsidian-sapphire-kde
chmod +x install.sh uninstall.sh
./install.sh
```

### Installer Options

```bash
# Install with default Tela-circle-blue-dark icons:
./install.sh

# Or choose a specific icon variant during install:
./install.sh --icons purple
./install.sh --icons dracula
./install.sh --icons candy

# Skip package manager check if dependencies are already installed:
./install.sh --no-deps
```

---

## 🛠️ Post-Install Commands & Customization

All utilities are installed into `~/.local/bin/`:

| Command | Description |
| :--- | :--- |
| `~/.local/bin/mac-app-launcher --toggle` | Toggle the Floating Centered App Launcher |
| `~/.local/bin/mac-side-monitor` | Run or toggle the Right-Side Sticky Hardware Monitor |
| `~/.local/bin/mac-speed-boost` | Apply full KDE Plasma & KWin speed optimizations |
| `~/.local/bin/mac-apply-theme --icons <variant>` | Switch icon theme (`blue`, `purple`, `dracula`, `candy`) and re-sync layout |
| `./uninstall.sh` | Stop services and restore your pre-installation KDE backup (`~/.config/kde-backup-pre-mac`) |

### Systemd User Services

The three desktop widgets run as lightweight `systemd --user` services and start automatically on login:

```bash
systemctl --user status mac-dynamic-island.service
systemctl --user status mac-side-monitor.service
systemctl --user status mac-app-launcher.service
```

---

## 📁 Repository Structure

```text
obsidian-sapphire-kde/
├── install.sh                         # Universal one-step installer (apt/pacman/dnf/zypper)
├── uninstall.sh                       # Clean uninstaller & KDE config backup restorer
├── bin/
│   ├── mac-dynamic-island             # Top-center interactive Dynamic Island (PyQt6)
│   ├── mac-side-monitor               # Right-side sticky CPU/GPU/RAM/Temp monitor (PyQt6)
│   ├── mac-app-launcher               # Floating centered app launcher + power bar (PyQt6)
│   ├── mac-speed-boost                # KDE & KWin performance optimizer
│   ├── mac-apply-theme                # Dynamic KDE Plasma panel, dock & theme configurator
│   └── mac-restore-backup             # Restores ~/.config/kde-backup-pre-mac
├── assets/
│   ├── aurorae/WhiteSur-dark/         # Custom right-side 13px Sapphire/Indigo/Rose window buttons
│   ├── color-schemes/                 # ObsidianSapphire.colors KDE color scheme
│   ├── icons/                         # Custom Sapphire Bento launcher & start SVG icons
│   └── wallpapers/                    # Resolution-independent Obsidian & Sapphire wallpaper generator
└── systemd/                           # Portable systemd --user service units (%h/.local/bin/...)
```

---

## 📄 License

Released under the [MIT License](LICENSE).
