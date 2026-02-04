---
title: "NeoMutt: Terminal-Native Email for the Keyboard-Driven Developer"
tags: [neomutt, email, terminal, productivity, linux, notmuch, mbsync, msmtp, oauth2, imap, vim]
categories: blog
background-image: neomutt.jpg
series: keyboard-driven-development
series_title: "Keyboard-Driven Development"
series_order: 6
excerpt: "A deeply technical dive into configuring NeoMutt with mbsync, msmtp, notmuch indexing, Vim integration, multi-account workflows, and keyboard-centric navigation — building an entirely terminal-native email system."
---

## Why NeoMutt in 2025?

After optimizing my coding and window management workflows with [Neovim](/blog/neovim-as-the-development-core.html), [tmux](/blog/tmux-for-keyboard-driven-development.html), and the [Kinesis Advantage360](/blog/kinesis-advantage360-pro-my-setup-workflow.html), I wanted email to feel identical — fast, efficient, and entirely keyboard-driven.

**NeoMutt** achieves this. It's a modern fork of Mutt that brings:
- **OAuth2 and XOAUTH2** support for modern mail providers (Office365, Gmail)
- **Dual-mode operation** — online (IMAP direct) and offline (local Maildir)
- **Native Maildir synchronization** via mbsync
- **Full-text search indexing** with notmuch
- **MIME attachment handling** with custom viewers
- **Sidebar and threading** for hierarchical mail organization
- **Scriptable hooks** for complex workflows

Most importantly: **zero mouse dependency** and seamless integration with the broader terminal ecosystem.

---

## System Architecture

My setup supports **four account modes** — two accounts (work and personal), each with online and offline variants:

| Account | Key | Mode | Receiving | Sending | Searching |
|---------|-----|------|-----------|---------|-----------|
| outlook | `i1` | Online | IMAP direct to Office365 | SMTP direct | IMAP server-side |
| outlook-offline | `i2` | Offline | mbsync → Maildir | msmtp | notmuch (local) |
| gmail             | `i3` | Online | IMAP direct to Gmail | SMTP direct | IMAP server-side |
| gmail-offline | `i4` | Offline | mbsync → Maildir | msmtp | notmuch (local) |

### Online Mode Architecture

```mermaid
┌─────────────┐     IMAP/SMTP     ┌──────────────┐
│   NeoMutt   │◄─────────────────►│ Mail Server  │
│             │                   │ (O365/Gmail) │
└─────────────┘                   └──────────────┘
```

- Always up-to-date, no local storage needed
- Requires network connection
- Search limited to single folder (server-side)

### Offline Mode Architecture

```mermaid
┌─────────────┐              ┌─────────────┐     IMAP     ┌──────────────┐
│   NeoMutt   │◄────────────►│   Maildir   │◄────────────►│ Mail Server  │
│             │              │   (local)   │    mbsync    │ (O365/Gmail) │
└─────────────┘              └─────────────┘              └──────────────┘
       │                           │
       ▼                           ▼
┌─────────────┐              ┌─────────────┐
│   msmtp     │───SMTP──────►│ Mail Server │
└─────────────┘              └─────────────┘
       │
       ▼
┌─────────────┐
│  notmuch    │ (full-text search index)
└─────────────┘
```

- Fast local access, works offline for reading
- Cross-folder search with folder names displayed
- Requires storage space and periodic sync

### Component Overview

| Layer | Component | Purpose | Config Location |
|-------|-----------|---------|-----------------|
| **UI** | NeoMutt | Email client, folder browsing, compose | [`neomuttrc`](https://github.com/ragu-manjegowda/config/blob/master/.config/neomutt/neomuttrc) |
| **Sync** | mbsync | Bi-directional IMAP ↔ Maildir sync | [`mbsyncrc`](https://github.com/ragu-manjegowda/config/blob/master/.config/imapnotify/mbsyncrc) |
| **Send** | msmtp | SMTP submission with OAuth2 | [`msmtprc_outlook`](https://github.com/ragu-manjegowda/config/blob/master/.config/neomutt/accounts/work/msmtprc_outlook) |
| **Search** | notmuch | Full-text indexing (Xapian backend) | `.notmuch-config` in maildir |
| **Security** | GPG | Credential encryption | `pass.gpg`, `gpg.rc` |
| **Auth** | OAuth2 | Modern authentication for O365/Gmail | `mutt_oauth2_*.py` scripts |

---

## Directory Structure

```mermaid
~/.config/neomutt/
├── neomuttrc                    # Main configuration
├── bindings.mutt                # Keyboard bindings
├── styles.muttrc                # Status bar formats, icons
├── colors-custom.muttrc         # Color scheme (Solarized)
├── mailcap                      # MIME type handlers
├── gpg.rc                       # GPG integration
├── aliases                      # Auto-generated address book
├── headers                      # Custom email headers
│
├── accounts/
│   ├── work/
│   │   ├── outlook              # Online IMAP config
│   │   ├── outlook-offline      # Offline Maildir config
│   │   ├── mbsyncrc_outlook     # mbsync configuration
│   │   ├── msmtprc_outlook      # SMTP configuration
│   │   ├── mutt_oauth2_outlook.py
│   │   ├── TOKEN_FILENAME_outlook
│   │   ├── update-mailboxes.sh  # Sync folder list
│   │   └── setup-offline.sh     # Initialize offline mode
│   │
│   └── personal/
│       ├── gmail                # Online IMAP config
│       ├── gmail-offline        # Offline Maildir config
│       ├── mbsyncrc_gmail
│       ├── msmtprc_gmail
│       ├── mutt_oauth2_gmail.py
│       ├── TOKEN_FILENAME_gmail
│       ├── update-mailboxes.sh
│       └── setup-offline.sh
│
├── maildir/
│   ├── outlook/                 # Work maildir storage
│   │   ├── Inbox/
│   │   │   ├── cur/             # Read messages
│   │   │   ├── new/             # Newly arrived
│   │   │   └── tmp/             # Transient state
│   │   ├── Sent Items/
│   │   ├── Drafts/
│   │   └── .notmuch-config      # notmuch configuration
│   │
│   └── gmail/                   # Personal maildir storage
│       ├── Inbox/
│       ├── [Gmail]/
│       │   ├── Sent Mail/
│       │   ├── Drafts/
│       │   └── Trash/
│       └── .notmuch-config
│
├── scripts/
│   ├── fzf-notmuch-search.sh    # Fuzzy search with fzf
│   └── sync-notmuch-flags.sh    # Sync maildir flags ↔ notmuch tags
│
├── cache/                       # Header and body caches
├── create-alias.sh              # Auto-create aliases from sent mail
├── mutt-ical.py                 # Calendar invite handler
├── render-calendar-attachment.py
└── viewmailattachments.py       # HTML email viewer
```

---

## Core Configuration

### Main Config: neomuttrc

The [`neomuttrc`](https://github.com/ragu-manjegowda/config/blob/master/.config/neomutt/neomuttrc) orchestrates all components:

#### Polling and Responsiveness

```muttrc
set timeout             = 5       # Artificial key press after 5s
set mail_check          = 10      # Check for new mail every 10s
set sleep_time          = 0       # No artificial delay (fast UI)
set ts_enabled          = yes     # Terminal status line support
set pager_read_delay    = 3       # Mark as read after 3s view
set mark_old            = no      # Unread stays unread until viewed
```

#### Threading and Sorting

```muttrc
set use_threads         = reverse # Reverse-threaded view (newest first)
set sort                = last-date-received
set narrow_tree         = yes     # Compact thread indicators
set sort_re             = yes     # Thread based on Reply-To regex
set reply_regexp        = "^(([Rr][Ee]?(\[[0-9]+\])?: *)?(\[[^]]+\] *)?)*"
set collapse_all        = yes     # Start with threads collapsed
set uncollapse_new      = no      # Don't auto-expand for new messages
```

#### Composing with Neovim

```muttrc
set editor = "nvim +/^$ +nohlsearch \
              -c 'set spell spelllang=en_us fo+=aw' \
              -c 'set noautoindent filetype=mail wm=0 tw=0 digraph nolist' \
              -c 'set comments+=nb:> enc=utf-8'"
```

When composing, Neovim opens with:
- Cursor positioned after headers (`+/^$`)
- Spell-check enabled
- Proper mail formatting (no auto-indent, no wrapping)
- UTF-8 encoding and reply quoting recognized

#### Pager Configuration

```muttrc
set smart_wrap          = yes     # Wrap at word boundaries
set wrap                = 90      # Preferred width
set text_flowed         = yes     # RFC 3676 format=flowed
set tilde               = yes     # Show ~ for empty lines (vi-style)
set quote_regexp        = "^( {0,4}[>|:#%]| {0,4}[a-z0-9]+[>|]+)+"
unset markers                     # Don't show + for wrapped lines
set pager_stop          = yes     # Don't advance to next message at end
```

#### HTML and Calendar Rendering

```muttrc
set mailcap_path        = "$XDG_CONFIG_HOME/neomutt/mailcap"

auto_view text/calendar
auto_view application/ics
auto_view text/html
alternative_order text/calendar application/ics text/html text/plain text/enriched
```

The [`mailcap`](https://github.com/ragu-manjegowda/config/blob/master/.config/neomutt/mailcap) file routes MIME types to appropriate handlers:

```mailcap
# HTML rendering with w3m
text/html; w3m -v -F -o display_link_number=1 -I %{charset} -T text/html -dump; copiousoutput

# Calendar invites via custom Python script
text/calendar; python $XDG_CONFIG_HOME/neomutt/render-calendar-attachment.py %s; copiousoutput
application/ics; python $XDG_CONFIG_HOME/neomutt/render-calendar-attachment.py %s; copiousoutput

# PDFs with zathura
application/pdf; zathura 2> /dev/null '%s'

# Images with firefox
image/*; firefox %s &
```

#### Sidebar Configuration

```muttrc
set sidebar_visible     = no      # Hidden by default, toggle with 'b'
set sidebar_width       = 30
set mail_check_stats              # Show unread/total counts
set sidebar_short_path  = yes     # Show short folder names
set sidebar_delim_chars = "/"
set sidebar_folder_indent = yes   # Indent subfolders
set sidebar_indent_string = '  '  # Two spaces per level
set sidebar_next_new_wrap = yes
```

#### Auto-Generated Aliases

```muttrc
set display_filter      = $XDG_CONFIG_HOME/neomutt/create-alias.sh
set alias_file          = $XDG_CONFIG_HOME/neomutt/aliases
set sort_alias          = alias
set reverse_alias       = yes
source "cat $alias_file 2> /dev/null |"
```

The [`create-alias.sh`](https://github.com/ragu-manjegowda/config/blob/master/.config/neomutt/create-alias.sh) script automatically extracts recipients and adds them to the alias file for future tab-completion.

---

## Multi-Account Switching

Account switching is handled via macros in [`neomuttrc`](https://github.com/ragu-manjegowda/config/blob/master/.config/neomutt/neomuttrc):

```muttrc
# Default account on startup
source $XDG_CONFIG_HOME/neomutt/accounts/work/outlook-offline

# Disable 'i' to allow 'i1', 'i2', etc. macros
bind index,pager i noop

macro index,pager i1 '<sync-mailbox><enter-command>source \
    $XDG_CONFIG_HOME/neomutt/accounts/work/outlook<enter>\
    <change-folder>!<enter>;<check-stats>' "switch to outlook - online"

macro index,pager i2 '<sync-mailbox><enter-command>source \
    $XDG_CONFIG_HOME/neomutt/accounts/work/outlook-offline<enter>\
    <change-folder>!<enter>;<check-stats>' "switch to outlook - offline"

macro index,pager i3 '<sync-mailbox><enter-command>source \
    $XDG_CONFIG_HOME/neomutt/accounts/personal/gmail<enter>\
    <change-folder>!<enter>;<check-stats>' "switch to gmail - online"

macro index,pager i4 '<sync-mailbox><enter-command>source \
    $XDG_CONFIG_HOME/neomutt/accounts/personal/gmail-offline<enter>\
    <change-folder>!<enter>;<check-stats>' "switch to gmail - offline"
```

Each account config redefines:
- `folder` (IMAP URL or local Maildir path)
- `from`, `realname`
- `spoolfile`, `record`, `postponed`, `trash`
- `sendmail` or `smtp_url`
- `mailboxes` (folder list)
- notmuch settings (for offline modes)

---

## Account Configuration Deep Dive

### Online Account Example (Gmail)

From [`gmail`](https://github.com/ragu-manjegowda/config/blob/master/.config/neomutt/accounts/personal/gmail):

```muttrc
# Source encrypted credentials
source "gpg -dq --no-emit-version --for-your-eyes-only \
    ~/.config/neomutt/pass_gmail.gpg |"

set my_user     = "$my_username"
set imap_pass   = "$my_password"
set realname    = "$my_name"
set from        = "$my_email"
set imap_user   = "$from"

# IMAP settings
set folder      = "imaps://imap.gmail.com:993"
set spoolfile   = "+INBOX"
set record      = "+[Gmail]/Sent Mail"
set postponed   = "+[Gmail]/Drafts"
set trash       = "+[Gmail]/Trash"

# OAuth2 authentication
set imap_authenticators = "oauthbearer:xoauth2"
set smtp_authenticators = ${imap_authenticators}
set imap_oauth_refresh_command = "$XDG_CONFIG_HOME/neomutt/accounts/personal/mutt_oauth2_gmail.py \
    $XDG_CONFIG_HOME/neomutt/accounts/personal/TOKEN_FILENAME_gmail"
set smtp_oauth_refresh_command = ${imap_oauth_refresh_command}

# SMTP settings
set smtp_url    = "smtps://$from@smtp.gmail.com:465"
set smtp_pass   = "$imap_pass"

# Security
set ssl_force_tls = "yes"
set ssl_starttls  = "yes"

# Clear notmuch settings (no local maildir in online mode)
unset nm_default_url
unset nm_config_file
```

### Offline Account Example (Outlook)

From [`outlook-offline`](https://github.com/ragu-manjegowda/config/blob/master/.config/neomutt/accounts/work/outlook-offline):

```muttrc
# Source encrypted credentials
source "gpg -dq --no-emit-version --for-your-eyes-only \
    ~/.config/neomutt/pass.gpg |"

set my_user     = "$my_username"
set realname    = "$my_name"
set from        = "$my_email"

# Local Maildir (synced via mbsync)
set folder      = $XDG_CONFIG_HOME/neomutt/maildir/outlook
set mbox_type   = Maildir
set spoolfile   = "+Inbox"
set record      = "+Sent Items"
set postponed   = "+Drafts"
set trash       = "+Deleted Items"

# SMTP via msmtp (separate from IMAP)
set sendmail    = "msmtp -C $XDG_CONFIG_HOME/neomutt/accounts/work/msmtprc_outlook -a outlook"

# Notmuch search configuration
set nm_default_url  = "notmuch://$HOME/.config/neomutt/maildir/outlook"
set nm_config_file  = "$HOME/.config/neomutt/maildir/outlook/.notmuch-config"
set nm_query_type   = messages

# Notmuch search macro
macro index \\ "<vfolder-from-query>" "search mails using notmuch"

# Fuzzy search with fzf
macro index | "\
<enter-command>unset wait_key<enter>\
<shell-escape>$XDG_CONFIG_HOME/neomutt/scripts/fzf-notmuch-search.sh \
$HOME/.config/neomutt/maildir/outlook/.notmuch-config<enter>\
<enter-command>set wait_key<enter>\
<enter-command>source /tmp/neomutt-fzf-cmd.muttrc<enter>" \
"fuzzy search query with fzf"

# Manual sync macro
macro index o "<enter-command>unset wait_key<enter> \
<shell-escape>~/.config/imapnotify/notify.sh && \
notify-send -u normal -a neomutt \
-i ~/.config/neomutt/neomutt.svg \"Emails synchronized!\" &<enter> \
<enter-command>set wait_key=yes<enter>" \
"run mbsync to sync outlook"
```

---

## Keyboard Bindings

The [`bindings.mutt`](https://github.com/ragu-manjegowda/config/blob/master/.config/neomutt/bindings.mutt) file defines **vi-motion-centric** keybindings:

### Navigation

```muttrc
bind attach,browser,index   gg      first-entry      # Go to first
bind attach,browser,index   G       last-entry       # Go to last
bind index                  j       next-entry       # Down
bind index                  k       previous-entry   # Up
bind pager                  j       next-line        # Scroll down
bind pager                  k       previous-line    # Scroll up
bind pager                  gg      top              # Top of message
bind pager                  G       bottom           # Bottom of message
```

### Thread Management

```muttrc
bind index      h       collapse-thread     # Collapse current thread
bind index      l       collapse-thread     # Toggle (same binding)
bind index      D       delete-thread       # Delete entire thread
bind index      U       undelete-thread     # Restore thread
bind index      zR      collapse-all        # Collapse all threads
bind index      zz      current-middle      # Center current message
bind index      zt      current-top         # Move to top
bind index      zb      current-bottom      # Move to bottom
```

### Page Scrolling

```muttrc
bind attach,browser,pager,index     \CF     next-page       # Ctrl+F
bind attach,browser,pager,index     \CB     previous-page   # Ctrl+B
bind attach,browser,pager,index     \Cu     half-up         # Ctrl+U
bind attach,browser,pager,index     \Cd     half-down       # Ctrl+D
```

### Sidebar

```muttrc
macro index     b   '<enter-command>toggle sidebar_visible<enter><refresh>'
macro pager     b   '<enter-command>toggle sidebar_visible<enter><redraw-screen>'
bind index,pager    \Ck     sidebar-prev        # Ctrl+K
bind index,pager    \Cj     sidebar-next        # Ctrl+J
bind index,pager    \Co     sidebar-open        # Ctrl+O
```

### Custom Macros

```muttrc
# Open links with urlscan
macro index,pager ,ol \
"<enter-command>unset wait_key<enter>\
<pipe-message>urlscan -d -w 80<Enter>" "call urlscan to open links"

# Move message to folder
macro index ,mf ":set auto_tag=yes<enter><save-message>?<toggle-mailboxes>" "move to..."

# Set high priority
macro compose ,sp \
"<enter-command>my_hdr X-Priority: 1<enter>\
<enter-command>my_hdr Importance: high<enter>" "Set priority to high"

# View HTML in browser
macro index,pager ,of \
"<enter-command>unset wait_key<enter>\
<pipe-message>python ~/.config/neomutt/viewmailattachments.py 2>/dev/null\n &<enter>" \
"View HTML email in browser"

# Mark all as read
macro index,pager \cr "<tag-pattern>.<enter><tag-prefix><clear-flag>N<untag-pattern>.<enter>"

# Go back to previous folder
macro index <BackSpace> "<change-folder>!!<enter>" "go back to previous folder"

# Save attachment to Downloads
macro attach s '<save-entry><kill-line>~/Downloads/<enter>a' "Save to ~/Downloads"
```

---

## OAuth2 Authentication

Modern mail providers (Office365, Gmail) require OAuth2. NeoMutt supports this via the `XOAUTH2` and `OAUTHBEARER` authentication mechanisms.

### The mutt_oauth2.py Script

The [`mutt_oauth2.py`](https://github.com/ragu-manjegowda/config/blob/master/.config/neomutt/accounts/personal/mutt_oauth2_gmail.py) script (originally from NeoMutt contrib) handles the OAuth2 flow. Each account has its own copy with provider-specific configuration.

#### Script Configuration

The script contains provider registrations with OAuth2 endpoints and client credentials:

```python
registrations = {
    'google': {
        'authorize_endpoint': 'https://accounts.google.com/o/oauth2/auth',
        'devicecode_endpoint': 'https://oauth2.googleapis.com/device/code',
        'token_endpoint': 'https://accounts.google.com/o/oauth2/token',
        'redirect_uri': 'urn:ietf:wg:oauth:2.0:oob',
        'imap_endpoint': 'imap.gmail.com',
        'smtp_endpoint': 'smtp.gmail.com',
        'sasl_method': 'OAUTHBEARER',
        'scope': 'https://mail.google.com/',
        'client_id': '<your-client-id>',
        'client_secret': '<your-client-secret>',
    },
    'microsoft': {
        'authorize_endpoint': 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize',
        'devicecode_endpoint': 'https://login.microsoftonline.com/common/oauth2/v2.0/devicecode',
        'token_endpoint': 'https://login.microsoftonline.com/common/oauth2/v2.0/token',
        'redirect_uri': 'https://login.microsoftonline.com/common/oauth2/nativeclient',
        'imap_endpoint': 'outlook.office365.com',
        'smtp_endpoint': 'smtp.office365.com',
        'sasl_method': 'XOAUTH2',
        'scope': ('offline_access https://outlook.office.com/IMAP.AccessAsUser.All '
                  'https://outlook.office.com/POP.AccessAsUser.All '
                  'https://outlook.office.com/SMTP.Send'),
        'client_id': '<your-client-id>',
        'client_secret': '<your-client-secret>',
    },
}
```

Token files are GPG-encrypted for security:

```python
ENCRYPTION_PIPE = ['gpg', '--encrypt', '--recipient', 'Your Name']
DECRYPTION_PIPE = ['gpg', '--decrypt', '--no-emit-version']
```

### Script Command-Line Options

```bash
mutt_oauth2.py [options] TOKENFILE

Options:
  -v, --verbose     Increase verbosity (show token info)
  -d, --debug       Enable debug output (show raw responses)
  -a, --authorize   Manually authorize new tokens (required first time)
  --authflow TYPE   Override authorization flow:
                      authcode          - Manual code entry
                      localhostauthcode - Local redirect (recommended)
                      devicecode        - Device code flow (for headless)
  -t, --test        Test IMAP/POP/SMTP endpoints after auth
```

### Initial Authorization (First Time Setup)

When running for the first time or with a new token file:

```bash
~/.config/neomutt/accounts/personal/mutt_oauth2_gmail.py \
    --verbose --authorize \
    ~/.config/neomutt/accounts/personal/TOKEN_FILENAME_gmail
```

**Interactive prompts:**

```
Available app and endpoint registrations: google microsoft
OAuth2 registration: google
Preferred OAuth2 flow ("authcode" or "localhostauthcode" or "devicecode"): localhostauthcode
Account e-mail address: your-email@gmail.com
```

**Authorization Flows:**

| Flow | Best For | How It Works |
|------|----------|--------------|
| `localhostauthcode` | Desktop with browser | Opens URL, starts local HTTP server, captures redirect automatically |
| `authcode` | Manual/fallback | Opens URL, you manually copy the code from browser address bar |
| `devicecode` | Headless/SSH | Shows a code to enter at microsoft.com/devicelogin or similar |

**Example with `localhostauthcode` (recommended):**

```bash
$ ~/.config/neomutt/accounts/personal/mutt_oauth2_gmail.py \
    --verbose --authorize \
    ~/.config/neomutt/accounts/personal/TOKEN_FILENAME_gmail

Available app and endpoint registrations: google microsoft
OAuth2 registration: google
Preferred OAuth2 flow ("authcode" or "localhostauthcode" or "devicecode"): localhostauthcode
Account e-mail address: user@gmail.com

https://accounts.google.com/o/oauth2/auth?client_id=...&scope=...&redirect_uri=http://localhost:8234/...

Visit displayed URL to authorize this application. Waiting......
NOTICE: Obtained new access token, expires 2025-02-02T15:30:00.
Access Token: ya29.a0AW...
```

Your browser opens, you authorize the app, and the script captures the token automatically.

### Token Refresh (Normal Operation)

Once authorized, the script automatically refreshes tokens when called:

```bash
# Just get a fresh access token (what NeoMutt calls)
~/.config/neomutt/accounts/personal/mutt_oauth2_gmail.py \
    ~/.config/neomutt/accounts/personal/TOKEN_FILENAME_gmail
```

Output (just the token):
```
ya29.a0AUMWg_JN59QF5SHWpcrwPa_XO1m3ya...
```

With `--verbose`:
```
NOTICE: Invalid or expired access token; using refresh token to obtain new access token.
NOTICE: Obtained new access token, expires 2025-02-02T16:30:00.
Access Token: ya29.a0AUMWg_JN59QF5SHWpcrwPa_XO1m3ya...
```

### Testing Authentication

After authorization, test all endpoints:

```bash
~/.config/neomutt/accounts/personal/mutt_oauth2_gmail.py \
    --verbose --test \
    ~/.config/neomutt/accounts/personal/TOKEN_FILENAME_gmail
```

Expected output:
```
IMAP authentication succeeded
POP authentication FAILED (does your account allow POP?): ...
SMTP authentication succeeded
```

(POP failure is expected if POP is disabled in your account settings)

### Re-Authorization

Re-run with `--authorize` when:
- Setting up on a new machine
- Refresh token has expired (typically 90 days for Microsoft, longer for Google)
- Authentication errors occur ("invalid_grant", "token expired")
- You see: `Perhaps refresh token invalid. Try running once with "--authorize"`

```bash
# Delete old token file and start fresh
rm ~/.config/neomutt/accounts/personal/TOKEN_FILENAME_gmail

# Re-authorize
~/.config/neomutt/accounts/personal/mutt_oauth2_gmail.py \
    --verbose --authorize \
    ~/.config/neomutt/accounts/personal/TOKEN_FILENAME_gmail
```

### How NeoMutt Uses the Script

In your account config:

```muttrc
set imap_authenticators = "oauthbearer:xoauth2"
set imap_oauth_refresh_command = "$XDG_CONFIG_HOME/neomutt/accounts/personal/mutt_oauth2_gmail.py \
    $XDG_CONFIG_HOME/neomutt/accounts/personal/TOKEN_FILENAME_gmail"
set smtp_oauth_refresh_command = ${imap_oauth_refresh_command}
```

NeoMutt calls the script whenever it needs to authenticate. The script:
1. Reads the encrypted token file
2. Checks if access token is still valid
3. If expired, uses refresh token to get a new access token
4. Outputs the access token to stdout
5. NeoMutt uses that token for IMAP/SMTP authentication

### Token File Security

The token file is GPG-encrypted and mode 0600:

```bash
$ ls -la ~/.config/neomutt/accounts/personal/TOKEN_FILENAME_gmail
-rw------- 1 ragu ragu 899 Feb  1 21:32 TOKEN_FILENAME_gmail

$ file ~/.config/neomutt/accounts/personal/TOKEN_FILENAME_gmail
TOKEN_FILENAME_gmail: GPG symmetrically encrypted data (AES256 cipher)
```

The script will refuse to run if file permissions are too open:
```
Token file has unsafe mode. Suggest deleting and starting over.
```

### Troubleshooting

**"Difficulty decrypting token file"**
- Ensure GPG agent is running: `gpg-agent --daemon`
- Set GPG_TTY: `export GPG_TTY=$(tty)`
- Check GPG key is available: `gpg --list-keys`

**"No refresh token. Run script with --authorize"**
- Token file exists but is empty/corrupt
- Delete and re-authorize

**"invalid_grant" or token errors**
- Refresh token expired
- Re-authorize with `--authorize`

**Script hangs**
- Waiting for GPG passphrase (check pinentry is working)
- Network timeout (check connectivity to OAuth endpoints)

### Obtaining OAuth2 Client Credentials

To use the script, you need OAuth2 client credentials. Fortunately, you can use publicly registered client IDs from well-known email clients.

#### Google (Gmail) - Using Thunderbird's Client ID

Thunderbird's Google OAuth2 credentials are public and work well:

```python
'google': {
    ...
    'client_id': '406964657835-aq8lmia8j95dhl1a2bvharmfk3t1hgqj.apps.googleusercontent.com',
    'client_secret': 'kSmqreRr0qwBWJgbf5Y-PjSU',
}
```

These are embedded in [Thunderbird's source code](https://searchfox.org/comm-central/source/mailnews/base/src/OAuth2Providers.sys.mjs) and widely used by terminal email clients.

#### Microsoft (Office365/Outlook) - Using Thunderbird's Client ID

For Microsoft, you can use Thunderbird's public Azure AD application. **No client secret is required** for this registration:

```python
'microsoft': {
    ...
    'client_id': '9e5f94bc-e8a4-4e73-b8be-63364c29d753',
    'client_secret': '',  # Not needed for Thunderbird's public client
}
```

**Important:** Your organization's Azure AD admin must approve this app for your tenant, granting at least:
- `IMAP.AccessAsUser.All`
- `SMTP.Send`
- `offline_access`

For detailed instructions on using Microsoft 365 IMAP/SMTP with OAuth2, see the excellent [UvA-FNWI/M365-IMAP](https://github.com/UvA-FNWI/M365-IMAP) repository.

**Using with mbsync:** In your `mbsyncrc`, you can reference the refresh token script:

```
IMAPAccount outlook
Host outlook.office365.com
User your-email@organization.com
PassCmd "python3 /path/to/refresh_token.py"
TLSType IMAPS
AuthMechs XOAUTH2
```

The `refresh_token.py` script (from the M365-IMAP repo) reads the stored refresh token, obtains a new access token, and prints it to stdout - exactly what mbsync expects.

#### Registering Your Own App (Alternative)

If you prefer to register your own Azure AD application:

1. Go to [Azure Portal](https://portal.azure.com/)
2. Navigate to **Azure Active Directory > App registrations**
3. Click **New registration**
4. Set redirect URI to `https://localhost:7598/` (for the M365-IMAP flow) or `https://login.microsoftonline.com/common/oauth2/nativeclient`
5. Under **API permissions**, add:
   - `IMAP.AccessAsUser.All`
   - `SMTP.Send`
   - `offline_access`
6. For public clients (no secret), enable **Allow public client flows** under **Authentication**

---

## Email Synchronization with mbsync

### mbsync Configuration

From [`mbsyncrc`](https://github.com/ragu-manjegowda/config/blob/master/.config/imapnotify/mbsyncrc) (Outlook example):

```
CopyArrivalDate yes

IMAPAccount outlook
Host outlook.office365.com
User user@outlook.com
PassCmd "$XDG_CONFIG_HOME/imapnotify/mutt_oauth2.py \
    $XDG_CONFIG_HOME/imapnotify/TOKEN_FILENAME"
TLSType IMAPS
AuthMechs XOAUTH2
Timeout 120
PipelineDepth 50

IMAPStore outlook-remote
Account outlook

MaildirStore outlook-local
Path ~/.config/neomutt/maildir/outlook/
Inbox ~/.config/neomutt/maildir/outlook/Inbox
SubFolders Verbatim

Channel outlook
Far :outlook-remote:
Near :outlook-local:
Patterns *
CopyArrivalDate yes
Create Both
Expunge Both
ExpireUnread yes
SyncState *
Sync Full
```

### Manual Sync Commands

```bash
# Sync all accounts
mbsync -a

# Sync specific account
mbsync -c ~/.config/imapnotify/mbsyncrc outlook

# List available mailboxes (without syncing)
mbsync -Vl -c ~/.config/imapnotify/mbsyncrc outlook
```

### Automatic Sync

The [`notify.sh`](https://github.com/ragu-manjegowda/config/blob/master/.config/imapnotify/notify.sh) script handles automatic synchronization:

```bash
#!/bin/bash
export NOTMUCH_CONFIG="$HOME/.config/neomutt/maildir/outlook/.notmuch-config"

~/.config/imapnotify/fetch-emails.py
echo "awesome.emit_signal('module::email:show', true)" | awesome-client
mbsync -V -c ~/.config/imapnotify/mbsyncrc -a
notmuch new
~/.config/neomutt/scripts/sync-notmuch-flags.sh "$NOTMUCH_CONFIG" \
    "$HOME/.config/neomutt/maildir/outlook" > /dev/null 2>&1
```

This is triggered by **goimapnotify** which monitors IMAP IDLE for real-time notifications.

---

## Full-Text Search with notmuch

### Configuration

Each maildir has a `.notmuch-config` file. After syncing, index messages:

```bash
NOTMUCH_CONFIG=~/.config/neomutt/maildir/outlook/.notmuch-config notmuch new
```

### Search Syntax in NeoMutt

Press `\` in offline mode to open notmuch search:

```
# Basic searches
from:alice
to:team@outlook.com
subject:meeting

# Date ranges
date:7d..           # Last 7 days
date:2024-01-01..   # Since Jan 1, 2024

# Folder filtering
folder:Inbox
folder:Team/Meetings

# Combined queries
from:boss AND date:1week.. AND folder:Inbox

# Unread/flagged
tag:unread
tag:flagged
```

### Fuzzy Search with fzf

Press `|` in offline mode for fuzzy search. The [`fzf-notmuch-search.sh`](https://github.com/ragu-manjegowda/config/blob/master/.config/neomutt/scripts/fzf-notmuch-search.sh) script provides:

**Format 1** - Fuzzy only:
```
priority release
```

**Format 2** - Fuzzy + filters:
```
"priority release" folder:Inbox date:1week..
```

The quoted portion is fuzzy-matched via fzf, the rest are notmuch filters.

### Flag Synchronization

The [`sync-notmuch-flags.sh`](https://github.com/ragu-manjegowda/config/blob/master/.config/neomutt/scripts/sync-notmuch-flags.sh) script keeps maildir flags (read/unread, flagged) in sync with notmuch tags:

```bash
~/.config/neomutt/scripts/sync-notmuch-flags.sh \
    ~/.config/neomutt/maildir/outlook/.notmuch-config \
    ~/.config/neomutt/maildir/outlook
```

---

## Styles and Visual Customization

### Status Bar Format

From [`styles.muttrc`](https://github.com/ragu-manjegowda/config/blob/master/.config/neomutt/styles.muttrc):

```muttrc
set ts_status_format = 'mutt %m messages%?n?, %n new?'
set pager_format = "%n %T %s%*  %{!%d %b · %H:%M} %?X? %X?%P"
set attach_format = "%u%D  %T%-75.75d %<T?&   > %5s · %m/%M"
set sidebar_format = '%D%* %<N?%N/>%S'
```

Account-specific status with Nerd Font icons:

```muttrc
set my_account = "$from (mbsync-imap)"
set status_format = "$my_account %D %?u? %u ?%?R? %R ?%?d? %d ?%?t? %t ?%?F? %F ?%?p? %p? "
```

Icons used:
-  — Unread count
-  — Read count
-  — Deleted count
-  — Tagged count
-  — Flagged count
-  — Postponed count

### Color Scheme

From [`colors-custom.muttrc`](https://github.com/ragu-manjegowda/config/blob/master/.config/neomutt/colors-custom.muttrc) (Solarized-based):

```muttrc
# General
color error         brightred       default
color indicator     white           black
color normal        blue            default
color status        white           brightmagenta

# Message index
color index         red             default     ~D  # deleted
color index         yellow          default     ~F  # flagged
color index         brightgreen     default     ~N  # unread
color index         magenta         default     ~Q  # replied

# Message body
color body          yellow          default     (https?|ftp)://...  # URLs
color quoted        blue            default
color quoted1       cyan            default
```

---

## Setting Up on a New Machine

### Prerequisites

```bash
# Arch Linux
paru -S neomutt isync msmtp notmuch pass gnupg w3m urlscan fzf
```

### Setup Scripts

Run the setup scripts for each account:

```bash
# Work (Outlook)
~/.config/neomutt/accounts/work/setup-offline.sh

# Personal (Gmail)
~/.config/neomutt/accounts/personal/setup-offline.sh
```

These scripts:
1. Create maildir directories
2. Authorize OAuth2 tokens
3. Run initial mbsync
4. Initialize notmuch database

### Update Mailbox Lists

After setup, sync the folder list from IMAP:

```bash
~/.config/neomutt/accounts/work/update-mailboxes.sh
~/.config/neomutt/accounts/personal/update-mailboxes.sh
```

---

## Quick Reference

### Account Switching

| Key | Account | Mode |
|-----|---------|------|
| `i1` | Work (Outlook) | Online IMAP |
| `i2` | Work (Outlook) | Offline Maildir |
| `i3` | Personal (Gmail) | Online IMAP |
| `i4` | Personal (Gmail) | Offline Maildir |

### Essential Keybindings

| Key | Action |
|-----|--------|
| `j/k` | Navigate messages |
| `gg/G` | First/last message |
| `h/l` | Collapse/expand thread |
| `zR` | Collapse all threads |
| `b` | Toggle sidebar |
| `Ctrl+j/k` | Navigate sidebar |
| `Ctrl+o` | Open sidebar folder |
| `\` | notmuch search (offline) |
| `\|` | Fuzzy fzf search (offline) |
| `o` | Manual sync (offline) |
| `,ol` | Open links with urlscan |
| `,of` | View HTML in browser |
| `,mf` | Move to folder |
| `r/R` | Reply/Reply-all |
| `Ctrl+r` | Mark all as read |

### Useful Commands

```bash
# Test OAuth token
~/.config/neomutt/accounts/work/mutt_oauth2_outlook.py \
    ~/.config/neomutt/accounts/work/TOKEN_FILENAME_outlook

# Manual sync
mbsync -c ~/.config/imapnotify/mbsyncrc outlook

# notmuch search from terminal
NOTMUCH_CONFIG=~/.config/neomutt/maildir/outlook/.notmuch-config \
    notmuch search "from:boss date:1week.."

# Sync flags
~/.config/neomutt/scripts/sync-notmuch-flags.sh \
    ~/.config/neomutt/maildir/outlook/.notmuch-config \
    ~/.config/neomutt/maildir/outlook
```

---

## Final Thoughts

NeoMutt exemplifies what "keyboard-driven" means: **complete control without abstraction**. Every operation is a keystroke or macro away. Email becomes another tool in the terminal workflow, not a browser distraction.

The combination of mbsync, msmtp, notmuch, and NeoMutt creates a **reproducible, auditable, and infinitely customizable email system** — one that scales from a single account to dozens without any UI bloat.

The dual-mode architecture (online + offline) provides flexibility: use online mode for quick checks when you need live data, switch to offline mode for blazing-fast cross-folder search and uninterrupted work sessions.

It's not nostalgia for terminal tools; it's pragmatism. When email is keyboard-native and fully integrated, it stops being work and becomes part of the flow.

See my [config repository](https://github.com/ragu-manjegowda/config/tree/master/.config/neomutt) for the full implementation.

---

{% include series_nav.html %}
