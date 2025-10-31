# 🎨 Hyprland Arch Linux Dotfiles

A comprehensive, modular Arch Linux + Hyprland configuration with QuickShell, featuring Material You theming and complete Qt/Wayland integration.

## ✨ Features

- 🚀 **QuickShell** - Modern Qt6-based compositor
- 🎨 **Material You** - Dynamic color theming based on wallpapers
- 🪟 **Hyprland** - Tiling Wayland compositor
- 🎯 **Modular Installation** - Choose what you need
- 📦 **Universal Setup** - Works from minimal to full DE
- 🔒 **Secure Boot** - Optional sbctl integration
- 🎮 **Tablet Support** - OpenTabletDriver included
- 💾 **Auto-backup** - Preserves existing configs

## 📋 Requirements

- Arch Linux (or Arch-based distro)
- Internet connection
- `sudo` privileges
- (Optional) GNOME for GTK app dependencies

## 🚀 Quick Start

### Clone the Repository

```bash
git clone https://github.com/yourusername/dotfiles.git
cd dotfiles
chmod +x main.sh
./main.sh
```

### Installation Options

The installer presents 7 options:

1. **Fresh install** - No DE, just dependencies
2. **Install GNOME + Hyprland** - Full GNOME first, then Hyprland
3. **Use existing GNOME** - Keep GNOME, add Hyprland
4. **Packages only** - Install all packages without configs
5. **Configs only** - Copy dotfiles (assumes packages installed)
6. **Full automated** - Recommended for new systems
7. **Exit** - Cancel installation

## 📁 Project Structure

```
dotfiles/
├── main.sh                      # Main launcher
├── scripts/
│   ├── install_base_deps.sh     # GTK/Qt deps without GNOME bloat
│   ├── install_packages.sh      # Core Hyprland packages
│   ├── install_gnome.sh         # Optional GNOME installation
│   ├── cleanup_gnome.sh         # Remove GNOME default apps
│   ├── setup_optional.sh        # NVIDIA, tablets, security
│   └── user_setup.sh            # Copy configs & set permissions
├── config/                      # All .config files
│   ├── hypr/
│   ├── quickshell/
│   ├── rofi/
│   ├── matugen/
│   └── ...
├── local/                       # .local files
│   └── ...
├── sdata/
│   └── uv/
│       └── requirements.txt     # Python dependencies
└── README.md
```

## 🔧 What Gets Installed

### Base Dependencies (No GNOME)

Essential libraries for GTK/Qt apps without full desktop environment:

- **GTK**: gtk3, gtk4, adwaita-icon-theme
- **Qt**: qt5/qt6-base, qt6-wayland, qt6-declarative
- **Desktop Integration**: xdg-desktop-portal-{gtk,kde,hyprland}
- **Authentication**: polkit, gnome-keyring
- **Network**: NetworkManager, network-manager-applet
- **Codecs**: gstreamer plugins

### Core Hyprland Stack

- **Compositor**: hyprland, hypridle, hyprlock, hyprpaper
- **Shell**: quickshell (AUR)
- **Launcher**: rofi-wayland
- **Theming**: python-pywal, matugen, Material You colors
- **Tools**: wlogout, cliphist, brightnessctl

### Optional Components

- **NVIDIA drivers** (if detected)
- **OpenTabletDriver** (for drawing tablets)
- **KeePassXC** (password manager)
- **VeraCrypt** (disk encryption)
- **Secure Boot** (sbctl)
- **Additional apps** (Firefox, Kate, Dolphin, etc.)

## 🎨 Theming System

The config uses **Material You** theming:

1. **Wallpaper selection** → Automatically extracts colors
2. **matugen** → Generates color schemes
3. **kde-material-you-colors** → Applies to Qt apps
4. **pywal** → Applies to GTK apps

### Changing Wallpapers

```bash
# Interactive wallpaper picker
~/.config/quickshell/ii/scripts/colors/switchwall.sh --kdialog

# Random Konachan wallpaper
~/.config/quickshell/ii/scripts/colors/random_konachan_wall.sh
```

## ⚙️ Environment Variables

The following are automatically set in `~/.config/hypr/hyprland.conf`:

```bash
env = QT_QPA_PLATFORM,wayland
env = QT_QPA_PLATFORMTHEME,kde
env = XDG_MENU_PREFIX,plasma-
```

## 🔑 Default Keybindings

| Key Combo | Action |
|-----------|--------|
| `SUPER + Q` | Application launcher |
| `SUPER + Return` | Terminal |
| `SUPER + E` | File manager |
| `SUPER + W` | Close window |
| `SUPER + M` | Exit Hyprland |
| `SUPER + V` | Toggle floating |
| `SUPER + [1-9]` | Switch workspace |

## 🐍 Python Environment

A virtual environment is created at:
```
~/.local/state/quickshell/.venv
```

Includes:
- materialyoucolor
- Pillow
- opencv-python
- Additional dependencies from `sdata/uv/requirements.txt`

## 🔄 Updating

To update your dotfiles:

```bash
cd ~/dotfiles
git pull
./main.sh
# Select option 5 (configs only) to update without reinstalling packages
```

## 🆘 Troubleshooting

### QuickShell not starting

```bash
# Check if venv exists
ls ~/.local/state/quickshell/.venv

# Reinstall if missing
./scripts/install_packages.sh
```

### Missing fonts

```bash
# Rebuild font cache
fc-cache -f -v
```

### Qt apps look wrong

Ensure environment variables are set:
```bash
grep "QT_QPA" ~/.config/hypr/hyprland.conf
```

### Colors not applying

```bash
# Manually trigger color generation
~/.config/quickshell/ii/scripts/colors/applycolor.sh
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Credits

- [Hyprland](https://hyprland.org/)
- [QuickShell](https://github.com/outfoxxed/quickshell)
- [Material You Color](https://github.com/T-Dynamos/materialyoucolor-python)
- [Matugen](https://github.com/InioX/matugen)

## 📸 Screenshots

*Add your screenshots here*

## ⚠️ Disclaimer

This configuration is tailored to my personal workflow. Please review scripts before running them. Always backup your data before major system changes.

---

**Made with ❤️ for the Arch Linux community**
