---
title: "Solarized Theme + Darkman: Automatic Light/Dark Switching Across Your Entire Workflow"
tags: [solarized, darkman, theming, linux, terminal, gtk, rofi, neovim, awesome, automation]
categories: blog
image: /images/awesome.jpg
banner: /images/banners/day-night.svg
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
Solarized base colors, from lightest to darkest:
- base3:   #fdf6e3    light background
- base2:   #eee8d5    light secondary background / icon ink on dark panels
- base1:   #93a1a1
- base0:   #839496
- base00:  #657b83
- base01:  #586e75
- base02:  #073642    dark secondary background / icon ink on light panels
- base03:  #002b36    dark background

Accent colors:
- red, orange, yellow, green, cyan, blue, violet, magenta
```

The beauty of Solarized is that **the same accent colors work perfectly in both light and dark variants**, ensuring visual consistency across theme switches.

---

## What is Darkman?

**Darkman** runs as a user service. It switches modes at sunrise and sunset using configured coordinates or GeoClue, and I can override it with `darkman toggle`. Darkman decides *when* to switch; each application decides *how* to apply the change.

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
├── set-gtk-theme.sh               # GTK settings + desktop color-scheme preference
├── set-rofi-theme.sh              # Application menu themes
├── set-vim-theme.sh               # Editor colorscheme
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

1. At sunrise, sunset, or a manual toggle, Darkman runs the executable hooks for the selected mode.
2. My GTK hook writes `prefer-light` or `prefer-dark` to the `color-scheme` key in the `org.gnome.desktop.interface` GSettings schema.
3. AwesomeWM listens to that key through Gio and repaints the running desktop. It doesn't need its own Darkman hook.
4. Other applications still use their own mechanisms. For example, the Rofi hook edits its configuration for the next menu invocation.

<figure class="layer-image-wrapper">
  <picture>
    <source media="(prefers-reduced-motion: no-preference)" srcset="{{ '/images/darkman-workspace-theme-switch.gif' | relative_url }}" width="1152" height="768">
    <img src="{{ '/images/darkman-workspace-themes.webp' | relative_url }}" width="1152" height="404" loading="lazy" alt="The same AwesomeWM workspace in Solarized Dark and Light, with Alacritty on the left and a PDF open in Sioyek on the right.">
  </picture>
  <figcaption class="layer-caption">I ran <code>darkman set light</code>, then <code>darkman set dark</code> in the background. Watch the top bar, the terminal background, and the PDF page: all three change without reopening either window. <a href="{{ '/images/darkman-workspace-theme-switch.gif' | relative_url }}">Open the GIF.</a></figcaption>
</figure>

---

## Configuration: Time-Based Theme Switching

All Darkman configuration is stored in [`~/.config/darkman/`](https://github.com/ragu-manjegowda/config/tree/master/.config/darkman).

### **config.yaml**

```yaml
# Example coordinates; replace with yours
lat: 45
lng: 0
usegeoclue: false  # Manual lat/lng instead of GeoClue daemon
```

Darkman calculates sunrise/sunset times from coordinates, then:
- Switches to **light mode at sunrise** (e.g., 6:00 AM)
- Switches to **dark mode at sunset** (e.g., 6:00 PM)

You can also select a mode explicitly or toggle the current one:
```bash
darkman set light
darkman set dark
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

**Result**: On my setup, the open Alacritty window picks up the new colors without a restart, as the recording shows.

### **2. Window Manager Icons & Colors (AwesomeWM)**

**November 2026 update:** I removed the hook that rewrote AwesomeWM's icons and asked me to reload. The running WM now reads the desktop preference directly. In [`theme/init.lua`](https://github.com/ragu-manjegowda/config/blob/master/.config/awesome/theme/init.lua), I keep one `Gio.Settings` object alive through LGI. Once the schema and key have been checked, the same callback handles startup and later changes:

```lua
settings = Gio.Settings.new_full(schema, nil, nil)
local function changed()
    apply(settings:get_string('color-scheme'))
end
settings.on_changed['color-scheme'] = changed
changed()
```

`prefer-light` selects Solarized Light. For `prefer-dark`, `default`, or a missing schema or key, my config uses Solarized Dark. When the variant changes, `apply` loads the palette into `beautiful` and calls `theme.bindings.refresh()`. The top bar, open panels, and notifications repaint without polling or restarting AwesomeWM.

The icons follow the palette without changing the files in Git. My [`theme.symbolic` imagebox](https://github.com/ragu-manjegowda/config/blob/master/.config/awesome/theme/symbolic.lua) maps the designated SVG foreground (`#073642` in the source) to the current foreground, leaving accents such as warning colors alone. For monochrome PNGs it tints the alpha mask in memory. I use ordinary imageboxes for application icons, photos, and album art so they keep their original colors.

### **3. GTK Theme (Global Application Look)**

My [light-mode GTK hook](https://github.com/ragu-manjegowda/config/blob/master/.config/darkman/light-mode.d/set-gtk-theme.sh) still updates GTK settings, icon and cursor themes, and XSettings. This excerpt shows the part that publishes the preference AwesomeWM reads:

```sh
if ! pgrep -x gsettings > /dev/null; then
    gsettings set org.gnome.desktop.interface icon-theme "Solarized-FLAT-Blue"
    gsettings set org.gnome.desktop.interface gtk-theme "NumixSolarizedLightBlue"
fi
gsettings set org.gnome.desktop.interface color-scheme "prefer-light"
```

The dark-mode hook writes `prefer-dark` instead. The last write belongs **outside** the guard: even a read-only `gsettings monitor` matches `pgrep -x gsettings`. Putting it inside would mean that watching the switch to debug it could prevent the switch itself.

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

vim_config_path="$HOME/.config/nvim/lua/user/colorscheme.lua"
sed -i -e "s#background=dark#background=light#g" "$vim_config_path"
```

Unlike the AwesomeWM listener, this hook edits a file. The next Neovim session starts with the selected background.

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
- The light-mode hooks run; the GTK hook publishes `prefer-light`
- The top bar and its symbolic icons switch to Solarized Light, even if the info center is open
- You notice your coffee spilling on a suddenly bright desktop and laugh ☀️

**2:00 PM** (midday, coding in sunlight):
- Terminal, code editor, file manager all use light theme
- Reduced eye strain in bright office/outdoor light
- Solarized Light colors are optimized for high-contrast reading

**6:00 PM** (sunset):
- Darkman detects sunset time
- Executes all scripts in `~/.config/darkman/dark-mode.d/`
- The GTK hook publishes `prefer-dark`; AwesomeWM repaints with Solarized Dark
- Reduced blue light for evening/night work
- 🌙 More comfortable for late-night coding sessions

**Manual Toggle**:
```bash
darkman toggle
```
This takes the same path as a scheduled switch. AwesomeWM repaints immediately; applications whose hooks only edit files may not pick up the change until their next launch.

---

## Advanced Features

### **Per-Application Customization**

Each script can do complex logic:
- **Desktop preference**: Publish one GSettings value for listeners instead of rewriting their assets
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

To see the difference, leave the info center open when the mode switches. Its background and cards change together, and the mail icon changes foreground without losing its unread indicator. There's no reload shortcut to press. The [AwesomeWM setup post]({% post_url 2021-10-20-awesomewm-keyboard-driven-event-first-setup %}#live-theme-changes) shows how I bind widgets to theme roles.

### **Darkman + Neovim**

For an already-open editor, I can use `:set background=light` or `:set background=dark` without waiting for a new session.

---

## Advantages Over Manual Theme Switching

| Aspect | Manual Switching | Darkman + Solarized |
|--------|-----------------|-------------------|
| **Frequency** | Every 12 hours = 2x/day | Automatic |
| **Applications covered** | Manual per-app | 15+ apps, one command |
| **Consistency** | Easy to miss an app | All synchronized |
| **Eye strain** | High (wrong theme for lighting) | Minimized (theme matches environment) |
| **Configuration** | Choose a mode separately in each app | Darkman selects the mode; each app owns its palette |
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

2. **Create executable theme scripts** in `~/.config/darkman/light-mode.d/` and `~/.config/darkman/dark-mode.d/`. To drive the AwesomeWM setup above, the light hook only needs to run `gsettings set org.gnome.desktop.interface color-scheme prefer-light`; use `prefer-dark` in the dark hook.

3. **Create symlinks** so Darkman can find the scripts (XDG standard location):
   ```bash
   mkdir -p ~/.local/share/
   ln -s ~/.config/darkman/light-mode.d ~/.local/share/light-mode.d
   ln -s ~/.config/darkman/dark-mode.d ~/.local/share/dark-mode.d
   ```

4. **Enable the user service**:
   ```bash
   systemctl --user enable --now darkman.service
   ```

5. **Test theme switching**:
   ```bash
   darkman toggle
   ```

### **Debugging**

```bash
# Is the service running, and which mode did it choose?
systemctl --user status darkman.service
darkman get
journalctl --user -u darkman.service -f

# Did the GTK hook publish the matching desktop preference?
gsettings get org.gnome.desktop.interface color-scheme

# Leave this running; use 'darkman toggle' in another terminal
gsettings monitor org.gnome.desktop.interface color-scheme

# Check symlinks are correct
ls -la ~/.local/share/light-mode.d
ls -la ~/.local/share/dark-mode.d
```

---

## Why This Matters for Keyboard-Driven Development

Darkman exemplifies keyboard-driven philosophy:
- **No mouse/UI**: One command switches modes; AwesomeWM receives the change directly
- **Event-driven**: Reacts to time, not polling
- **Scriptable**: You own and control the behavior
- **Zero distractions**: Invisible, automatic theme adaptation
- **Focused workflow**: Never manually toggle themes again

Combined with Solarized's precision color theory, you get a desktop environment that **adapts to your work environment** while staying **completely out of your way**.

---

## Conclusion

Solarized + Darkman creates a **cohesive, adaptive visual experience** across your entire terminal-first workflow. Rather than fighting your environment's lighting, your desktop automatically optimizes for it.

The useful split is between choosing a mode and drawing it. Darkman and its hooks handle the first part. AwesomeWM owns the second, so changing the mode doesn't require changing a single tracked icon or interrupting the session.

---

{% include series_nav.html %}

