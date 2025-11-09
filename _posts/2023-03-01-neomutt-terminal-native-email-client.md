---
title: "NeoMutt: Terminal-Native Email for the Keyboard-Driven Developer"
tags: [neomutt, email, terminal, productivity, linux, mu, mbsync, msmtp, oauth2, imap, vim]
categories: blog
background-image: neomutt.jpg
series: keyboard-driven-development
series_title: "Keyboard-Driven Development"
series_order: 6
excerpt: "A deeply technical dive into configuring NeoMutt with mbsync, msmtp, mu indexing, Vim integration, multi-account workflows, and keyboard-centric navigation — building an entirely terminal-native email system."
---

## Why NeoMutt in 2025?

After optimizing my coding and window management workflows with [Neovim](/blog/neovim-as-the-development-core.html), [tmux](/blog/tmux-for-keyboard-driven-development.html), and the [Kinesis Advantage360](/blog/kinesis-advantage360-pro-my-setup-workflow.html), I wanted email to feel identical — fast, efficient, and entirely keyboard-driven.

**NeoMutt** achieves this. It's a modern fork of Mutt that brings:
- **OAuth2 and XOAUTH2** support for modern mail providers
- **IMAP IDLE** for real-time notifications
- **Native Maildir synchronization** via mbsync
- **Full-text search indexing** with mu/notmuch
- **MIME attachment handling** with custom viewers
- **Sidebar and threading** for hierarchical mail organization
- **Scriptable hooks** for complex workflows

Most importantly: **zero mouse dependency** and seamless integration with the broader terminal ecosystem.

---

## System Architecture

NeoMutt is actually an orchestration layer on top of specialized Unix tools:

```
IMAP Servers ←→ mbsync ←→ ~/.mail/ (Maildir)
                            ↑
                    NeoMutt (UI + IMAP client)
                            ↓
                  mu (full-text indexing)
                            ↓
                  ~/.cache/mu (Xapian DB)

Compose → msmtp → SMTP Servers
```

Each component is independently tested, upgradeable, and scriptable:

| Layer | Component | Purpose | Config |
|-------|-----------|---------|--------|
| **UI** | **NeoMutt** | Email client, folder browsing, message display, compose UI | `~/.config/neomutt/neomuttrc` |
| **Sync** | **mbsync** | Bi-directional IMAP ↔ Maildir sync with expunge handling | `~/.mbsyncrc` |
| **Send** | **msmtp** | SMTP submission with OAuth2 and per-account routing | `~/.msmtprc` |
| **Search** | **mu** | Full-text indexing (Xapian backend), sub-millisecond search | `~/.config/mu/mu4e-context.el` or inline config |
| **Security** | **GPG** | Credential storage, PGP signing, mail encryption | `~/.authinfo.gpg`, `~/.config/neomutt/gpg.rc` |

### Storage Architecture

Mail is stored in Maildir format under `~/.mail/`:

```
~/.mail/
├── personal/
│   ├── INBOX/
│   │   ├── cur/        (read messages)
│   │   ├── new/        (newly arrived)
│   │   └── tmp/        (transient state)
│   ├── Sent/
│   ├── Drafts/
│   ├── Trash/
│   └── Archive/
│       ├── 2024/
│       └── 2025/
└── work/
    ├── INBOX/
    ├── Sent/
    ├── Trash/
    └── Archive/
```

Each message is a single file (unique UUID + flags suffix), enabling atomic operations and zero corruption.

---

## Core Configuration: neomuttrc

My `~/.config/neomutt/neomuttrc` is modular and extensible. Key sections:

### 1. **Polling and Responsiveness**

```mutt
set timeout              = 5       # Artificial key press after 5s
set mail_check           = 10      # Check for new mail every 10s
set sleep_time           = 0       # No artificial delay (fast UI)
set ts_enabled           = yes     # Terminal status line support
set pager_read_delay     = 3       # Mark as read after 3s view
set mark_old             = no      # Unread stays unread until viewed
```

This ensures NeoMutt stays responsive and doesn't interfere with concurrent mbsync operations.

### 2. **Threading and Sorting**

```mutt
set use_threads          = reverse # Reverse-threaded view (newest first)
set sort                 = last-date-received
set sort_aux             = reverse-last-date-received
set narrow_tree          = yes     # Compact thread indicators
set sort_re              = yes     # Thread based on Reply-To regex
set reply_regexp         = "^(([Rr][Ee]?(\[[0-9]+\])?: *)?(\[[^]]+\] *)?)*"
set collapse_all         = yes
set uncollapse_new       = no
```

This creates a clean, collapsible thread view without visual clutter.

### 3. **Composing with Neovim**

```mutt
set editor = "nvim +/^$ +nohlsearch \
              -c 'set spell spelllang=en_us fo+=aw' \
              -c 'set noautoindent filetype=mail wm=0 tw=0 digraph nolist' \
              -c 'set comments+=nb:> enc=utf-8'"
```

When composing, Neovim opens with:
- Cursor positioned after headers (`+/^$`)
- Spell-check enabled
- Proper mail formatting (no auto-indent, no wrapping)
- UTF-8 encoding
- Reply quoting recognized

### 4. **Pager Configuration**

```mutt
set smart_wrap           = yes     # Wrap at word boundaries
set wrap                 = 90      # Preferred width
set text_flowed          = yes     # RFC 3676 format=flowed
set tilde                = yes     # Show ~ for empty lines (vi-style)
set quote_regexp         = "^( {0,4}[>|:#%]| {0,4}[a-z0-9]+[>|]+)+"
unset markers            # Don't show + for wrapped lines
set pager_stop           = yes     # Don't advance to next message at end of pager
```

### 5. **HTML and Calendar Rendering**

```mutt
set mailcap_path         = "$XDG_CONFIG_HOME/neomutt/mailcap"

auto_view text/calendar
auto_view application/ics
auto_view text/html
alternative_order text/calendar application/ics text/html text/plain text/enriched
```

My `mailcap` file configures:
- HTML → browser or lynx
- Calendar (.ics) → mutt-ical.py (custom Python renderer)
- Attachments → appropriate system applications

### 6. **Security and Encryption**

```mutt
set ssl_force_tls        = yes     # Require TLS for all connections
set imap_keepalive       = 900     # 15-minute IMAP keepalive

source "$XDG_CONFIG_HOME/neomutt/gpg.rc"
```

Pulls in GPG integration for:
- Automatic PGP signature verification
- Mail signing and encryption
- Credential decryption via `gpg --decrypt ~/.authinfo.gpg`

### 7. **Multi-Account Abstraction**

```mutt
source $XDG_CONFIG_HOME/neomutt/accounts/work/outlook-offline

macro index,pager i1 '<sync-mailbox><enter-command>source \
    $XDG_CONFIG_HOME/neomutt/accounts/work/outlook<enter>\
    <change-folder>!<enter>;<check-stats>' "switch to outlook - online"

macro index,pager i2 '<sync-mailbox><enter-command>source \
    $XDG_CONFIG_HOME/neomutt/accounts/work/outlook-offline<enter>\
    <change-folder>!<enter>;<check-stats>' "switch to outlook - offline"

macro index,pager i3 '<sync-mailbox><enter-command>source \
    $XDG_CONFIG_HOME/neomutt/accounts/personal/raghudarshan<enter>\
    <change-folder>!<enter>;<check-stats>' "switch to personal - online"
```

Accounts are modular. Pressing `i1`, `i2`, or `i3` syncs the current folder, sources a new account config (which redefines `account-hook`, `from`, `smtp_url`, `imap_user`, etc.), and switches to that account's inbox.

### 8. **Aliases and Auto-Creation**

```mutt
set display_filter       = $XDG_CONFIG_HOME/neomutt/create-alias.sh
set alias_file           = $XDG_CONFIG_HOME/neomutt/aliases
set sort_alias           = alias
set reverse_alias        = yes
source "cat $alias_file 2> /dev/null |"
```

Whenever I send an email, `create-alias.sh` automatically extracts the recipient and adds it to `aliases` for future tab-completion.

---

## Keyboard Bindings: bindings.mutt

Bindings are **vi-motion-centric** and heavily inspired by Vim:

### Navigation

```mutt
bind index gg              first-entry          # Go to first message
bind index G               last-entry           # Go to last message
bind index j               next-entry           # Down
bind index k               previous-entry       # Up
bind pager j               next-line            # Scroll down in message
bind pager k               previous-line        # Scroll up in message
bind index,pager zz        current-middle       # Center current message
bind index,pager zt        current-top          # Move to top
bind index,pager zb        current-bottom       # Move to bottom
```

### Thread Collapsing

```mutt
bind index h               collapse-thread      # Collapse current thread
bind index l               collapse-thread      # Uncollapse (same binding, toggle)
bind index D               delete-thread        # Delete entire thread
bind index U               undelete-thread      # Restore thread
bind index zR              collapse-all         # Collapse all threads
```

### Paging

```mutt
bind index,pager \Cf      next-page            # Ctrl+F → page down
bind index,pager \Cb      previous-page        # Ctrl+B → page up
bind index,pager \Cu      half-up              # Ctrl+U → half page up
bind index,pager \Cd      half-down            # Ctrl+D → half page down
```

### Sidebar Toggle and Navigation

```mutt
macro index b '<enter-command>toggle sidebar_visible<enter><refresh>'
macro pager b '<enter-command>toggle sidebar_visible<enter><redraw-screen>'
bind index,pager \Ck      sidebar-prev         # Ctrl+K → prev folder
bind index,pager \Cj      sidebar-next         # Ctrl+J → next folder
bind index,pager \Co      sidebar-open         # Ctrl+O → open folder
```

### Custom Macros

```mutt
# Open links in message with urlscan
macro index,pager ,ol \
"<enter-command>unset wait_key<enter>\
<pipe-message>urlscan -d -w 80<Enter>\
" "call urlscan to open links"

# Move message to folder
macro index,pager ,mf ":set auto_tag=yes<enter><save-message>?<toggle-mailboxes>" \
    "move to..."

# Set message priority to high
macro compose ,sp \
"<enter-command>my_hdr X-Priority: 1<enter>\
<enter-command>my_hdr Importance: high<enter>\
" "Set priority/importance to high"

# View HTML email in browser (calls Python script)
macro index,pager ,of \
"<enter-command>unset wait_key<enter>\
<pipe-message>~/.local/share/venv/bin/python ~/.config/neomutt/viewmailattachments.py 2> /dev/null\n &<enter>\
" "View HTML email in browser"

# Mark all as read
macro index,pager \cr "<tag-pattern>.<enter><tag-prefix><clear-flag>N<untag-pattern>.<enter>"
```

---

## OAuth2 and Modern Authentication

Modern mail providers require OAuth2. NeoMutt supports this via `XOAUTH2` authentication mechanism in mbsync, with tokens stored in encrypted `~/.authinfo.gpg`.

### mbsync Setup

Your `~/.mbsyncrc` would contain:

```
IMAPAccount work
Host imap.gmail.com
User your-email@gmail.com
AuthMechs XOAUTH2
PassCmd "gpg --quiet --for-your-eyes-only --decrypt ~/.authinfo.gpg | grep 'password' | cut -d' ' -f2"
SSLType IMAPS
CertificateFile /etc/ssl/certs/ca-certificates.crt
```

### msmtp Setup

Your `~/.msmtprc` would contain:

```
account work
host smtp.gmail.com
port 587
auth oauthbearer
from your-email@gmail.com
user your-email@gmail.com
passwordeval "gpg --quiet --for-your-eyes-only --decrypt ~/.authinfo.gpg | grep 'password' | cut -d' ' -f2"
tls on
tls_starttls on
```

The `PassCmd` / `passwordeval` decrypts the token on-demand, keeping credentials safe at rest.

---

## Synchronization: mbsync + goimapnotify

To manually sync all accounts:

```bash
mbsync -a
```

To sync specific account:

```bash
mbsync work
```

To sync and expunge deleted messages:

```bash
mbsync -a --all
```

**Automatic Sync with goimapnotify:**

Rather than polling via cron, I use **goimapnotify** to monitor IMAP servers in real-time. When new mail arrives, it triggers `mbsync` immediately.

Configuration is stored in `~/.config/imapnotify/`, with per-account IMAP IDLE monitoring:

```bash
goimapnotify &
```

This provides instant mail sync without the overhead of polling intervals, ensuring emails appear in NeoMutt as soon as they arrive on the server.

---

## Full-Text Search: mu

After syncing, index messages for search:

```bash
mu index
```

Search syntax in NeoMutt:

```mutt
# Example macro to search recent emails with specific subject
macro index s "<shell-escape>mu find date:7d.. subject:meeting\n" "Search recent meetings"
```

mu query syntax:
- `from:alice` — From Alice
- `subject:bug` — Subject contains "bug"
- `date:7d..` — Last 7 days
- `size:1M..10M` — Attachment size range
- `flag:draft` — Draft messages
- `is:unread` — Unread messages

---

## Extending Vim Motions Beyond NeoMutt

Within NeoMutt workflows, I use:
- **Vim editor** for composing (with mail-specific settings)
- **urlscan** for extracting and opening links
- **Custom Python scripts** (`viewmailattachments.py`, `mutt-ical.py`, `render-calendar-attachment.py`) for rendering complex MIME types
- **tmux panes** for side-by-side reference

---

## Integration with Keyboard-Driven Workflows

NeoMutt fits into the larger terminal ecosystem:

- **Keybind consistency** – Same `j/k` navigation as Vim, Ranger, Newsboat, and Sioyek
- **Background sync** – mbsync runs in parallel without blocking the UI
- **Script hooks** – Custom actions on folder change, message receipt, etc.
- **XDG_CONFIG_HOME** – All config under `~/.config/neomutt` (not legacy `~/.mutt`)

---

## Final Thoughts

NeoMutt exemplifies what "keyboard-driven" means: **complete control without abstraction**. Every operation is a keystroke or macro away. Email becomes another tool in the terminal workflow, not a browser distraction.

The combination of mbsync, msmtp, mu, and NeoMutt creates a **reproducible, auditable, and infinitely customizable email system** — one that scales from a single account to dozens without any UI bloat.

It's not nostalgia for terminal tools; it's pragmatism. When email is keyboard-native and fully integrated, it stops being work and becomes part of the flow.

See my [config repository](https://github.com/ragu-manjegowda/config/tree/master/.config/neomutt) for the full implementation.

---

{% include series_nav.html %}
