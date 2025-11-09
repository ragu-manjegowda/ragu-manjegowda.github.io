---
title: "My tmux Setup: A Terminal Multiplexer for Keyboard-Driven Development"
tags: [tmux, terminal, workflow, productivity, linux, mac]
categories: blog
background-image: tmux.png
series: keyboard-driven-development
series_title: "Keyboard-Driven Development"
series_order: 4
excerpt: "How I use tmux—with nested sessions, OSC52 clipboard integration, and a curated set of plugins—to build a fast, reproducible, and entirely keyboard-driven terminal workflow."
---

In this post of the *[Keyboard-Driven Development](/blog/keyboard-driven-development-why-i-built-it.html)* series, I'll dive deep into my tmux setup — a meticulously engineered terminal multiplexer configuration that serves as the backbone of my development workflow across local and remote environments.

This isn't just about basic tmux usage. I've built a comprehensive system that includes:
- **Advanced OSC52 clipboard integration** with custom yank scripts
- **Sophisticated nested session management** for seamless local/remote workflows  
- **Custom Solarized theming** with dynamic status indicators
- **Cross-platform battery monitoring** with visual charge indicators
- **Vim-integrated copy modes** with rectangle selection support
- **Automated session persistence** and restoration

My complete configuration lives at:  
📂 [`~/.config/tmux/`](https://github.com/ragu-manjegowda/config/tree/master/.config/tmux) — **447 lines** of carefully tuned tmux configuration

---

## Why tmux?

When working with multiple projects, servers, and terminals, I found that normal terminal tabs just didn’t scale.  
I wanted something that could:

- Survive SSH disconnections  
- Re-attach to existing sessions  
- Work identically across **Linux** and **macOS**  
- Let me **navigate, resize, copy, and script** — all from the keyboard  

tmux checked all those boxes, and more.

But out-of-the-box tmux is very barebones. So I built my own setup, evolving over years into what I now call my **workflow anchor**.

---

## Foundation: Terminal & Display Configuration

### **Core Performance Settings**

```bash
# Eliminate input lag for vim/neovim
    set-option -sg escape-time 250

# Enable focus events for better vim integration  
    set-option -g focus-events on

# True color support with proper terminfo
    set-option -g default-terminal "tmux-256color"

# Terminal capability overrides for RGB and OSC52 support
    set-option -sa terminal-overrides ",xterm*:RGB,alacritty*:RGB,xterm*:Ms=\\E]52;c%p1%.0s;%p2%s\\7"
```

### **Key Timing & Behavior**

```bash
# Extend repeat timeout for resize operations
set-option -g repeat-time 1000

# Disable mouse completely - pure keyboard workflow
set-option -g mouse OFF

# Extended key support for complex nested scenarios
set -s extended-keys on
```

### **Session & Window Indexing**

```bash
# Start window/pane numbering at 1 (not 0) for easier keyboard access
set-option -g base-index 1
set-option -g pane-base-index 1

# Prevent automatic window renaming
set-option -g allow-rename off

# Extended history buffer
set-option -g history-limit 20000

# Custom history file location
set-option -g history-file $HOME/.config/tmux/.tmux_history
```

**Why these settings matter:**
- **`escape-time 250`**: Reduces vim mode-switching delay from default 500ms
- **RGB overrides**: Ensures true color support across different terminal emulators
- **Extended keys**: Critical for nested tmux scenarios and complex key bindings

---

## Advanced Nested Session Architecture

### **The Challenge: tmux-in-tmux**

Working with remote servers requires running tmux locally (host) and remotely (guest). Without proper configuration, key conflicts make this painful. My solution creates distinct control planes:

```bash
# Enable extended key sequences for modifier combinations
    set -s extended-keys on

# Alt+\ sends prefix to inner (remote) tmux session
    bind-key -N "prefix for nested tmux" -n "M-\\" send-prefix
```

### **Workflow Integration**

This creates a clean mental model:
- **<kbd>Ctrl</kbd>+<kbd>B</kbd>**: Controls local tmux (host)
- **<kbd>Alt</kbd>+<kbd>\</kbd>**: Controls remote tmux (guest)

Both accessible via **Kinesis keyboard macros** defined in my ZMK configuration:

```c
// From my keyboard firmware
Tmux_Host: Tmux_Host {
    compatible = "zmk,behavior-macro";
    bindings = <&kp LC(B)>;
    display-name = "TMUX Host";
};

Tmux_Guest: Tmux_Guest {
    compatible = "zmk,behavior-macro"; 
    bindings = <&kp LA(BACKSLASH)>;
    display-name = "TMUX Guest";
};
```

### **Copy Integration Across Nested Sessions**

The real power emerges in copy mode. Both sessions can access the same clipboard pipeline:

```bash
# Host session copy
Tmux_Host_Copy: Tmux_Host_Copy {
    bindings = <&kp LC(B) &kp LEFT_BRACKET>;
    display-name = "TMUX Host Copy";
};

# Guest session copy  
Tmux_Guest_Copy: Tmux_Guest_Copy {
    bindings = <&kp LA(BACKSLASH) &kp LEFT_BRACKET>;
    display-name = "TMUX Guest Copy";
};
```

This eliminates the cognitive overhead of "which tmux am I in?" — the keyboard handles the routing automatically.

---

## Advanced OSC52 Clipboard Architecture

### **The Problem: Remote Copy/Paste**

Standard clipboard integration breaks when SSH'ing into remote machines. OSC52 (Operating System Command 52) solves this by encoding clipboard data into terminal escape sequences that traverse the connection back to your local terminal.

### **Core tmux Configuration**

```bash
# Enable built-in clipboard support
    set-option -g set-clipboard on

# Allow escape sequence passthrough for OSC52
    set-option -g allow-passthrough on

# Terminal overrides ensuring OSC52 support across terminal types
set-option -sa terminal-overrides ",xterm*:Ms=\\E]52;c%p1%.0s;%p2%s\\7"
```

### **Custom Yank Script Implementation**

Rather than rely on plugins, I use a custom `yank` script based on the excellent work by **Suraj N. Kurapati** ([sunaku](https://github.com/sunaku)), with my own modifications for multi-target clipboard handling:

```bash
#!/bin/sh
# ~/.config/tmux/yank - Multi-target clipboard handler
#
# Written in 2014 by Suraj N. Kurapati <https://github.com/sunaku>
# Also documented at https://sunaku.github.io/tmux-yank-osc52.html
# Modified in 2024 by Ragu Manjegowda <https://github.com/ragu-manjegowda>

input=$( cat "$@" )
input() { printf %s "$input" ;}
known() { command -v "$1" >/dev/null ;}
maybe() { known "$1" && input | "$@" ;}
alive() { known "$1" && "$@" >/dev/null 2>&1 ;}

# X11 clipboard (local desktop)
test -n "$DISPLAY" && alive xhost && {
  maybe xsel -i -b || maybe xclip -sel c
}

# OSC52 terminal sequence
printf_escape() {
  esc=$1
  # Handle tmux passthrough wrapper
  test -n "$TMUX" -o -z "${TERM##screen*}" && esc="\033Ptmux;\033$esc\033\\"
  printf "$esc"
}

len=$( input | wc -c ) max=74994

# Warn if exceeding OSC52 limits (100KB total, ~75KB usable)
test "$len" -gt $max && echo "$0: input is $(( len - max )) bytes too long" >&2

# Send OSC52 sequence with base64-encoded content
printf_escape "\033]52;c;$( input | head -c $max | base64 | tr -d '\r\n' )\a"
```

### **Advanced Copy Mode Bindings**

```bash
# Vim-style copy mode with multiple yank behaviors
setw -g mode-keys vi
set-option -g status-keys vi

# Unbind default and create custom visual selection
unbind-key -T copy-mode-vi v
bind-key -T copy-mode-vi 'v' send-keys -X begin-selection
bind-key -T copy-mode-vi 'C-v' send -X begin-selection \; send -X rectangle-toggle

# Multiple yank modes with different behaviors
    bind-key -T copy-mode-vi 'y' send-keys -X copy-pipe \
        '$HOME/.config/tmux/yank > #{pane_tty}'

bind-key -T copy-mode-vi 'Y' send-keys -X copy-pipe-and-cancel \
    '$HOME/.config/tmux/yank > #{pane_tty}; tmux paste-buffer -p'

# Interactive buffer selection with yank integration
bind-key -N "Choose previously copied text from menu" y choose-buffer 'run-shell \
    "tmux save-buffer -b \"%%%\" - | $HOME/.config/tmux/yank > #{pane_tty}"'
```

### **URL Extraction Integration**

```bash
# Extract and open URLs from current buffer
bind-key -N "Choose urls from buffer" u capture-pane \; \
    save-buffer /tmp/tmux-buffer \; new-window -n \
    "urlview" '$SHELL -c "urlscan < /tmp/tmux-buffer"'
```

**Result:** Copy text anywhere in nested tmux → instantly available in local clipboard, supporting rectangle selection, buffer history, and URL extraction.

---

## Intelligent Pane & Window Management

### **Intuitive Resize Bindings**

```bash
# Repeatable pane resizing with directional keys  
bind-key -r -T prefix < resize-pane -L
bind-key -r -T prefix - resize-pane -D
bind-key -r -T prefix + resize-pane -U
bind-key -r -T prefix > resize-pane -R

# Quick configuration reload during development
    bind-key -N "reload source file" r source-file ~/.config/tmux/tmux.conf \; \
        display-message "Reloaded source file!"
```

The `-r` flag enables **repeat mode** — after the initial prefix, you can repeatedly hit resize keys without re-pressing <kbd>Ctrl</kbd>+<kbd>B</kbd>.

---

## Status Bar and Visual Design

I use a **Solarized** theme for consistency across Vim, terminal, and tmux.

Here’s a sample of how my status bar is structured:

- **Left:** system name and session  
- **Right:** time, date, prefix indicator, zoom status  
- **Center:** open windows  

Color codes and Unicode icons add a pleasant visual rhythm:

    set -g @session_icon " "
    set -g @time_icon    " "
    set -g @date_icon    " "
    set -g @blue         "#268bd2"
    set -g @base02       "#073642"

The result is a clean, focused UI that gives me just enough information — never distraction.

---

## Alert & Activity Configuration

```bash
# Activity monitoring (disabled for focus)
setw -g monitor-activity off
set-option -g visual-activity on

# Pane indicators with high-contrast colors
set-option -g display-panes-colour yellow
set-option -g display-panes-active-colour magenta

# 24-hour clock mode
set-option -g clock-mode-colour orange
set-option -g clock-mode-style 24
```

---

## Remote Development Integration

The seamless integration between local and remote environments is achieved through:

### **Unified Clipboard Pipeline**
OSC52 sequences traverse SSH connections, making remote copy operations indistinguishable from local ones.

### **Consistent Key Bindings**
Nested prefix keys eliminate mode confusion — <kbd>Ctrl</kbd>+<kbd>B</kbd> always controls the local session, <kbd>Alt</kbd>+<kbd>\</kbd> always controls remote sessions.

### **Session Persistence**
Both local and remote sessions benefit from automatic persistence, allowing seamless disconnection/reconnection workflows.

The result: **location-transparent terminal multiplexing** where local and remote development feel identical.

---

## Advanced Plugin Architecture

### **Session Persistence System**

```bash
# tmux-resurrect: Saves and restores sessions
    set-option -g @resurrect-dir '~/.cache/tmux/session-restore'
set-option -g @resurrect-capture-pane-contents 'on'

# tmux-continuum: Automatic session saving  
    set-option -g @continuum-save-interval '15'

# Load plugins
    run-shell ~/.config/tmux/plugins/tmux-resurrect/resurrect.tmux
    run-shell ~/.config/tmux/plugins/tmux-continuum/continuum.tmux
```

### **Fuzzy Navigation Integration**

```bash  
# tmux-fuzzback: fzf-powered history and pane navigation
set-option -g @fuzzback-bind f
set-option -g @fuzzback-popup 1
set-option -g @fuzzback-popup-size '90%'

    run-shell ~/.config/tmux/plugins/tmux-fuzzback/fuzzback.tmux
```

**Result:** Sessions automatically persist every 15 minutes, survive reboots, and restore exact pane contents. Fuzzy search enables instant navigation through session history.

---

## Technical Architecture Summary

My tmux setup represents **447 lines** of configuration optimized for:

- **Cross-platform compatibility** (Linux, macOS)
- **Nested session workflows** with distinct control planes
- **Advanced clipboard integration** via OSC52 and custom yank scripts  
- **Sophisticated visual theming** with Solarized consistency
- **Automated persistence** and session restoration
- **Vim-integrated workflows** throughout

The configuration transforms tmux from a basic terminal multiplexer into a comprehensive development environment that scales from local development to complex remote server management.

---

{% include series_nav.html %}
