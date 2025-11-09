---
title: "Solarized Theme + Darkman: Automatic Light/Dark Switching Across Your Entire Workflow"
tags: [solarized, darkman, theming, linux, terminal, gtk, rofi, neovim, awesome, automation]
categories: blog
background-image: awesome.jpg
series: keyboard-driven-development
series_title: "Keyboard-Driven Development"
series_order: 8
excerpt: "How I use Solarized colors and Darkman to automatically switch between light and dark themes across 15+ applications—terminal, WM, GTK apps, rofi menus, and more—based on time of day or manual toggle."
---

## Why Solarized + Darkman?

Working on a laptop means varying light conditions throughout the day. Reading code in sunlight on a dark theme is eye-straining; working late at night on a light theme is also uncomfortable. Rather than manually toggling each application, I use **Solarized** (a carefully-calibrated color palette) with **Darkman** (a theme manager daemon) to **automatically switch all applications between light and dark modes based on geolocation or time**.

The result: A seamless, cohesive visual experience that adapts to my environment without requiring any manual intervention.

---

## What is Solarized?

**Solarized** is a precision color scheme with two variants:
- **Solarized Light** — Warm, low-contrast light palette optimized for daylight reading
- **Solarized Dark** — Cool, low-contrast dark palette optimized for night coding

Key characteristics:
- **16 carefully-chosen colors** (base16 palette) designed for syntax highlighting
- **Accent colors** that work as both foreground and background
- **Precision contrast** tuned for reduced eye strain in any lighting condition
- **Cross-platform support** — available for nearly every terminal, editor, and application

The colors are based on CIELAB color space theory and have been refined over years to maximize readability without sacrificing aesthetics.

### **Solarized Palette**

```
Base colors (Light variant):
- Base03 (background):     #fdf6e3 (warm white)
- Base02 (secondary bg):   #eee8d5 (off-white)
- Base01 (comments):       #93a1a1 (light gray)
- Base00 (secondary fg):   #839496 (medium gray)
- Base0 (content):         #657b83 (dark gray)
- Base1 (secondary content): #586e75 (darker gray)
- Base2 (primary fg):      #073642 (dark blue-green)
- Base3 (foreground):      #002b36 (very dark blue-green)

Accent colors:
- red, orange, yellow, green, cyan, blue, violet, magenta
```

The beauty of Solarized is that **the same accent colors work perfectly in both light and dark variants**, ensuring visual consistency across theme switches.

---

## What is Darkman?

**Darkman** is a lightweight systemd timer + service that manages light/dark theme switching across your entire system. It:

- **Monitors time of day** (or geolocation via GeoClue) and triggers theme changes
- **Executes custom scripts** when switching themes via systemd units
- **Integrates with D-Bus** for IPC with applications
- **Works with any WM/DE** (X11, Wayland, standalone tiling WMs)
- **Zero configuration** for basic usage; fully customizable via shell scripts

Darkman is perfect for keyboard-driven workflows because it's:
- **Systemd-based** (runs as user service timer, no background daemon)
- **Scriptable** (everything is shell scripts)
- **Event-driven** (reacts to time changes via systemd timer)
- **Non-intrusive** (no window managers, panels, or indicators)

---

## Architecture: Darkman + Solarized Integration

### **Configuration Structure**

Darkman stores configuration and theme scripts in two locations:

**Config directory** (for settings):
```
~/.config/darkman/
└── config.yaml                    # Geolocation settings
```

**Theme scripts directory**:
```
~/.local/share/light-mode.d/       # Scripts to run on light mode
├── set-alacritty-theme.sh         # Terminal color scheme
├── set-awesomewm-icons-theme.sh   # WM theme + SVG/PNG recoloring
├── set-gtk-theme.sh               # GTK2/3 theme switching
├── set-rofi-theme.sh              # Application menu themes
├── set-neovim-theme.sh            # Editor colorscheme
├── set-tmux-theme.sh              # Terminal multiplexer colors
├── set-ranger-theme.sh            # File manager colors
├── set-zathura-theme.sh           # PDF viewer colors
├── set-sioyek-theme.sh            # Scientific paper reader
├── set-broot-theme.sh             # Terminal navigator
├── set-git-delta-theme.sh         # Git diff syntax highlighting
├── set-chromium-theme.sh          # Browser theme
├── set-dircolors.sh               # `ls` color output
├── set-termshark-theme.sh         # Packet analyzer
└── set-wiki-theme.sh              # Wiki viewer

~/.local/share/dark-mode.d/        # Mirror of light-mode.d
└── [identical structure with dark variants]
```

**Source directory** (GitHub-managed):
```
~/.config/darkman/                 # Git-tracked source
├── light-mode.d/                  # Symlinked to ~/.local/share/light-mode.d
└── dark-mode.d/                   # Symlinked to ~/.local/share/dark-mode.d
```

To set up symlinks:
```bash
ln -s ~/.config/darkman/light-mode.d ~/.local/share/light-mode.d
ln -s ~/.config/darkman/dark-mode.d ~/.local/share/dark-mode.d
```

This allows you to **version-control scripts in `~/.config/darkman/`** while Darkman reads from **`~/.local/share/`** (the XDG standard location).

### **How It Works**

1. **Darkman systemd timer** runs at scheduled intervals (calculated from geolocation + sunrise/sunset)
2. **Monitors time** (or geolocation + sunrise/sunset times)
3. **At threshold time** (e.g., 6:00 AM → light, 6:00 PM → dark):
   - Systemd timer triggers `darkman.service`
   - Executes `/usr/bin/darkman apply light` or `darkman apply dark`
   - Runs all scripts from `~/.local/share/light-mode.d/` or `dark-mode.d/`
4. **Each script** updates configuration files or sends signals to applications
5. **Applications reload** or respond to signals automatically

---

## Configuration: Time-Based Theme Switching

All Darkman configuration is stored in [`~/.config/darkman/`](https://github.com/ragu-manjegowda/config/tree/master/.config/darkman).

### **config.yaml**

```yaml
# Geolocation coordinates (North Pole)
lat: 90
lng: 0
usegeoclue: false  # Manual lat/lng instead of GeoClue daemon
```

Darkman calculates sunrise/sunset times from coordinates, then:
- Switches to **light mode at sunrise** (e.g., 6:00 AM)
- Switches to **dark mode at sunset** (e.g., 6:00 PM)

You can also manually toggle (no systemd timer needed):
```bash
darkman apply light
darkman apply dark
darkman toggle
```

---

## The Scripts: Switching 15+ Applications

### **1. Terminal Emulator (Alacritty)**

```bash
#!/bin/zsh
alacritty_config_path="$HOME/.config/alacritty/alacritty.toml"
sed -i -e "s#solarized_dark#solarized_light#g" $alacritty_config_path

export BAT_THEME="Solarized (light)"
```

**What it does**:
- Updates Alacritty config to use Solarized Light colorscheme
- Sets `BAT_THEME` for `bat` (cat replacement) syntax highlighting

**Result**: Terminal colors instantly switch on next application launch, or reload Alacritty for immediate effect.

### **2. Window Manager Icons & Colors (AwesomeWM)**

```bash
#!/bin/bash

# Recolor SVG icons: swap Solarized base03 (light bg) with base2 (dark fg)
for i in $(find $HOME/.config/awesome/ -name "*.svg"); do
    sed -i -e "s/fill:#eee8d5/fill:#073642/" $i
    sed -i -e 's/fill="#eee8d5"/fill="#073642"/' $i
done

# Recolor PNG icons using ImageMagick
for i in $(find $HOME/.config/awesome/ -name "*.png" \
            -not -path "*/widget/vpn/icons/*" \
            -not -path "*/configuration/user-profile/*" \
            -not -path "*/library/*" \
            -not -path "*/widget/playerctl/*"); do
    magick $i -fill "#073642" -colorize 100% $i
done

# Update theme Lua config
config_path="$HOME/.config/awesome/theme/init.lua"
sed -i -e "s/-dark-/-light-/" $config_path

# Notify user to reload AwesomeWM
notify-send -u critical -a awesome \
    -i ~/.config/awesome/theme/icons/awesome.svg "Reload awesome to load light theme"
```

**What it does**:
- **SVG recoloring**: Uses `sed` to swap hex color codes in icon files
- **PNG recoloring**: Uses ImageMagick's `-colorize` to tint all PNG icons
- **Theme config**: Updates Lua theme file to toggle `-dark-` ↔ `-light-`
- **Notification**: Sends D-Bus notification reminding user to reload AwesomeWM (Super+Control+r)

**Result**: All WM icons and panels switch colors; user reloads WM to see changes live.

### **3. GTK Theme (Global Application Look)**

```bash
#!/bin/zsh

gtk2_config_path="$HOME/.gtkrc-2.0"
gtk3_config_path="$HOME/.config/gtk-3.0/settings.ini"
icon_config_path="$HOME/.icons/default/index.theme"
xdg_config_path="$HOME/.config/xsettingsd/xsettingsd.conf"

# Switch theme names
sed -i -e "s#DarkGreen#LightBlue#g" $gtk2_config_path
sed -i -e "s#Solarized-Dark-Green-Numix#Solarized-FLAT-Blue#g" $gtk2_config_path

sed -i -e "s#DarkGreen#LightBlue#g" $gtk3_config_path
sed -i -e "s#Solarized-Dark-Green-Numix#Solarized-FLAT-Blue#g" $gtk3_config_path

# Switch cursor themes (must use precise regex to avoid duplication)
sed -i -e 's/"Numix-Cursor"/"Numix-Cursor-Light"/g' $gtk2_config_path
sed -i -e 's/Numix-Cursor$/Numix-Cursor-Light/g' $gtk3_config_path
sed -i -e 's/Numix-Cursor$/Numix-Cursor-Light/g' $icon_config_path

# Reload GTK settings daemon
if ! pgrep -x "xsettingsd" > /dev/null; then
    xsettingsd &
else
    killall -HUP xsettingsd
fi

# Force cursor theme update (workaround for some apps)
if command -v lxappearance &> /dev/null; then
    lxappearance &
    sleep 0.2
    killall lxappearance
fi
```

**What it does**:
- **GTK2/3 theme switching**: Updates color scheme names in config files
- **Icon theme switching**: Changes icon set (dark vs. light variants)
- **Cursor theme switching**: Updates mouse cursor appearance
- **Signal reload**: Sends HUP to `xsettingsd` to reload X11 settings
- **Workaround for cursor**: Opens/closes lxappearance to force root window cursor update

**Result**: All GTK applications (file managers, settings, etc.) instantly switch themes; no restart needed.

### **4. Application Launcher (Rofi)**

```bash
#!/bin/zsh

rofi_config_path="$HOME/.config/rofi/config.rasi"
sed -i -e "s#-dark-#-light-#g" $rofi_config_path

# Update all rofi menu variants (app menu, calculator, emoji picker, etc.)
for config in $(find $HOME/.config/awesome/configuration/rofi -name "rofi.rasi"); do
    sed -i -e "s#-dark#-light#g" "$config"
done
```

**What it does**:
- Updates main rofi config to switch to light theme
- Updates all AwesomeWM-specific rofi menu configs (app launcher, calculator, emoji menu, clock, etc.)

**Result**: All rofi menus instantly switch to light variant on next invocation.

### **5. Text Editors (Neovim)**

```bash
#!/bin/zsh

neovim_config_path="$HOME/.config/nvim/init.lua"
sed -i -e "s#Solarized-dark#Solarized-light#g" $neovim_config_path
```

**What it does**:
- Updates Neovim colorscheme setting in Lua config
- Neovim detects config change and reloads (or reload via `:e` in editor)

**Result**: Editor syntax highlighting switches to light Solarized palette.

### **6. Terminal Multiplexer (Tmux)**

```bash
#!/bin/zsh

tmux_config_path="$HOME/.config/tmux/tmux.conf"
sed -i -e "s#source.*solarized.*#source-file ~/.config/tmux/themes/light.conf#" $tmux_config_path
```

**Result**: Tmux status line and window colors switch on next session or `tmux source ~/.config/tmux/tmux.conf`.

### **7. Additional Applications**

Similar scripts exist for:
- **Ranger** (terminal file manager) — Color scheme in `~/.config/ranger/colorschemes/`
- **Zathura** (PDF viewer) — Color configuration in `~/.config/zathura/zathurarc`
- **Sioyek** (scientific paper reader) — Theme switching
- **Broot** (terminal navigator) — Color schemes
- **Git Delta** (diff viewer) — Syntax highlighting themes
- **Chromium** (browser) — GTK theme applies automatically
- **Dircolors** (`ls` output) — Color palette for terminal listings
- **Termshark** (packet analyzer) — UI color scheme

---

## Real-World Workflow

### **Scenario: Working Through the Day**

**6:00 AM** (sunrise):
- Darkman detects sunrise time
- Executes all scripts in `~/.config/darkman/light-mode.d/`
- Terminal, icons, GTK apps, rofi menus, editor all switch to Solarized Light
- You notice your coffee spilling on a suddenly bright desktop and laugh ☀️

**2:00 PM** (midday, coding in sunlight):
- Terminal, code editor, file manager all use light theme
- Reduced eye strain in bright office/outdoor light
- Solarized Light colors are optimized for high-contrast reading

**6:00 PM** (sunset):
- Darkman detects sunset time
- Executes all scripts in `~/.config/darkman/dark-mode.d/`
- Everything switches to Solarized Dark
- Reduced blue light for evening/night work
- 🌙 More comfortable for late-night coding sessions

**Manual Toggle**:
```bash
darkman toggle
```
Instantly switches everything if you need to override the time-based schedule.

---

## Advanced Features

### **Per-Application Customization**

Each script can do complex logic:
- **ImageMagick recoloring**: Transform PNGs from dark to light
- **SVG color swapping**: Parse and update fill/stroke colors
- **Signal sending**: Use `notify-send` for D-Bus notifications
- **Daemon control**: Start/restart services with proper checks (`pgrep`)
- **File parsing**: Use `sed` to update TOML, YAML, INI, Lua, shell config files

### **Idempotency & Safety**

Scripts are **idempotent** — running them multiple times has same effect as running once:
```bash
# Safe to run repeatedly; won't duplicate cursor names
sed -i -e 's/Numix-Cursor$/Numix-Cursor-Light/g' $gtk3_config_path
```

### **Custom Triggers**

Beyond time-based switching, you can manually integrate with:
- **Geolocation daemon** (GeoClue) for automatic sunrise/sunset
- **System events** (battery low → force dark mode to save power)
- **Manual scripts** to toggle with keyboard shortcuts

---

## Integration with Keyboard-Driven Workflow

### **Darkman + AwesomeWM**

The notification from `set-awesomewm-icons-theme.sh` reminds you to reload AwesomeWM:

```bash
notify-send -u critical -a awesome \
    -i ~/.config/awesome/theme/icons/awesome.svg \
    "Reload awesome to load light theme"
```

Then simply press `Super+Control+r` (AwesomeWM reload) and the WM instantly switches themes without restarting or losing any windows.

### **Darkman + Neovim**

Neovim config watches for theme changes. You can add an autocommand:

```lua
-- In ~/.config/nvim/init.lua
vim.o.background = 'light'  -- or 'dark'

-- Auto-reload colorscheme on config change
vim.cmd.colorscheme('solarized')
```

Or manually reload with `:colorscheme solarized` in editor.

---

## Advantages Over Manual Theme Switching

| Aspect | Manual Switching | Darkman + Solarized |
|--------|-----------------|-------------------|
| **Frequency** | Every 12 hours = 2x/day | Automatic |
| **Applications covered** | Manual per-app | 15+ apps, one command |
| **Consistency** | Easy to miss an app | All synchronized |
| **Eye strain** | High (wrong theme for lighting) | Minimized (theme matches environment) |
| **Configuration** | Scattered across dotfiles | Centralized in `~/.config/darkman/` |
| **Integration with workflow** | Interrupts focus | Invisible, automatic |

---

## Setting Up Your Own Darkman Setup

### **Installation**

```bash
# Arch Linux
sudo pacman -S darkman

# Other distros: check your package manager (Fedora, Debian, etc.)
```

### **Basic Configuration**

1. **Create `~/.config/darkman/config.yaml`**:
   ```yaml
   lat: YOUR_LATITUDE
   lng: YOUR_LONGITUDE
   usegeoclue: false
   ```

2. **Create theme scripts** in `~/.config/darkman/light-mode.d/` and `~/.config/darkman/dark-mode.d/`

3. **Create symlinks** so Darkman can find the scripts (XDG standard location):
   ```bash
   mkdir -p ~/.local/share/
   ln -s ~/.config/darkman/light-mode.d ~/.local/share/light-mode.d
   ln -s ~/.config/darkman/dark-mode.d ~/.local/share/dark-mode.d
   ```

4. **Enable the systemd timer**:
   ```bash
   systemctl --user enable --now darkman.timer
   systemctl --user status darkman.timer
   ```

5. **Test theme switching**:
   ```bash
   darkman toggle
   ```

### **Debugging**

```bash
# Check systemd timer status
systemctl --user status darkman.timer
systemctl --user list-timers darkman.timer

# View systemd service logs
journalctl --user -u darkman.service -f

# Manually trigger light mode
darkman apply light

# Manually trigger dark mode
darkman apply dark

# Check symlinks are correct
ls -la ~/.local/share/light-mode.d
ls -la ~/.local/share/dark-mode.d
```

---

## Why This Matters for Keyboard-Driven Development

Darkman exemplifies keyboard-driven philosophy:
- **No mouse/UI**: Everything is daemon + shell scripts
- **Event-driven**: Reacts to time, not polling
- **Scriptable**: You own and control the behavior
- **Zero distractions**: Invisible, automatic theme adaptation
- **Focused workflow**: Never manually toggle themes again

Combined with Solarized's precision color theory, you get a desktop environment that **adapts to your work environment** while staying **completely out of your way**.

---

## Conclusion

Solarized + Darkman creates a **cohesive, adaptive visual experience** across your entire terminal-first workflow. Rather than fighting your environment's lighting, your desktop automatically optimizes for it.

The beauty is in the **simplicity**: geolocation coordinates, shell scripts, and a few hundred lines of `sed` commands give you a professional, polished theme switching system that's:
- ✅ Completely automatic
- ✅ Works across 15+ applications
- ✅ Respects your keyboard-driven philosophy
- ✅ Infinitely customizable

Set it up once, then forget about it. Your desktop will just *look right* all day long.

---

{% include series_nav.html %}

