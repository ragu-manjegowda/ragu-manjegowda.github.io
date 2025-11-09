---
title: "Neovim as the Development Core: Fast, Extensible, and Keyboard-Driven"
tags: [neovim, vim, productivity, linux, mac, workflow, lsp, lua, treesitter]
categories: blog
background-image: nvim.jpg
series: keyboard-driven-development
series_title: "Keyboard-Driven Development"
series_order: 5
excerpt: "Deep technical dive into my Neovim configuration: lazy.nvim, native LSP with Blink.cmp, Treesitter syntax parsing, git integration, and keymaps aligned with Colemak Mod-DH. Every plugin, colorscheme tweak, and autocmd documented."
---

This post continues my *Keyboard-Driven Development* series — a deep technical dive into the configuration, plugins, and design principles that power my Neovim setup.

In previous posts, we talked about how my **Kinesis Advantage 360**, **Colemak Mod-DH layout**, and **tmux setup** form the physical and terminal layers of my environment.  
Now, we're moving to the heart of it all — **Neovim** — the editor that powers everything I write, code, or edit.

This is a **technical deep-dive** that captures every detail of my configuration: from Lua module architecture to LSP diagnostics configuration to plugin-specific tweaks. If you want to understand *exactly* how my Neovim environment works, this post is for you.

---

## Why Neovim?

I started with Vim years ago and gradually migrated to Neovim when it became clear that it was evolving faster, cleaner, and with modern extensibility in mind.

Neovim fits perfectly into my philosophy of *keyboard-driven development* because:

- **Modal editing**: Every action can be performed without leaving the home row  
- **Composability**: The modal editing model (normal, insert, visual, command) keeps my hands efficient  
- **Integration**: Works seamlessly with tmux, zsh, and my Colemak layout  
- **Hackability**: Fully scriptable and automatable via Lua — everything can be customized to my exact workflow  

Over time, my Neovim configuration has evolved into not just a text editor, but my **complete development IDE** — handling code editing, debugging, git workflows, and terminal integration all from the keyboard.

---

## Guiding Principles

I follow a few core principles that keep my configuration minimal yet powerful:

- **Discoverability**: Every plugin/mapping should be discoverable and documented  
- **Performance first**: Startup time should be instant; even remote servers should feel snappy  
- **Muscle memory**: Key mappings align with my Colemak-DH layout and tmux prefix logic (`Space` as leader)  
- **Portability**: Must work identically on Linux and macOS with minimal system dependencies  
- **Error recovery**: Graceful error handling prevents the entire config from breaking if one module fails  

---

## Configuration Architecture

My Neovim configuration uses a modular Lua-based architecture:

```
~/.config/nvim/
├── init.lua                      # Main entry point with error handling
├── lua/user/
│   ├── bootstrap.lua            # lazy.nvim initialization
│   ├── plugins-table.lua        # Plugin declarations
│   ├── options.lua              # Global vim options
│   ├── keymaps.lua              # All keybindings
│   ├── autocommands.lua         # Autocommands & user functions
│   ├── colorscheme.lua          # Solarized Spring theme configuration
│   ├── lspconfig.lua            # LSP setup with diagnostics
│   ├── treesitter.lua           # Treesitter syntax parsing
│   ├── telescope.lua            # Fuzzy finder configuration
│   ├── [40+ plugin config files]
│   └── utils.lua                # Shared utilities
├── queries/markdown/folds.scm   # Custom Treesitter query for Markdown
└── tests/                       # Integration tests for major features
```

Each module follows this pattern:
```lua
local M = {}
M.meta = { desc = "...", needs_setup = true }
function M.setup() ... end
return M
```

Error handling at the top level ensures that if a single module fails to load, the editor still boots:

```lua
local res, utils = pcall(require, "user.utils")
if not res then
    vim.notify("Error loading user.utils", vim.log.levels.ERROR)
    return
end
```

---

## Plugin Management: lazy.nvim

I use [lazy.nvim](https://github.com/folke/lazy.nvim) for declarative plugin management with aggressive lazy-loading.

lazy.nvim provides:
- **Lazy-loading on events**: Plugins load only when their trigger events fire
- **Dependency resolution**: Automatic plugin ordering and initialization
- **Performance**: Startup time stays under 50ms even with 60+ plugins
- **Build steps**: Automatic compilation of plugins like Treesitter

The plugin specifications are centralized in `lua/user/plugins-table.lua`, which returns a large Lua table defining all plugins, their dependencies, and load conditions.

---

## Options & Core Settings

My `options.lua` configures 40+ vim options that define editor behavior:

```lua
-- Indentation & Formatting
tabstop = 4, softtabstop = 4, shiftwidth = 4  -- 4-space indents
expandtab = true, smartindent = true          -- Convert tabs to spaces
shiftround = true                             -- Round indent to shiftwidth multiple

-- Search & Highlighting  
ignorecase = true, smartcase = true           -- Case-insensitive by default, smart when uppercase
hlsearch = true, inccommand = "split"         -- Show live preview of `:s///` replacements

-- Display
cursorline = true, colorcolumn = "80"         -- Highlight cursor line & 80-char column
number = true, relativenumber = true          -- Line numbers + relative offsets
list = true, listchars = "lead:⋅"            -- Show leading whitespace as dots
wrap = false                                  -- Don't wrap long lines

-- UI Behavior
splitbelow = true, splitright = true          -- New splits go down/right
scrolloff = 5, sidescrolloff = 5             -- 5-line padding when scrolling
completeopt = "menuone,noselect"              -- Better autocomplete behavior
laststatus = 3                                -- Global statusline (not per-window)

-- Performance
updatetime = 300                              -- Faster completion & CursorHold events
undofile = true, undodir = ~/.../undodir      -- Persistent undo across sessions
undolevels = 10000                            # Unlimited undo history
```

The options are split into two categories:
- `set_options()` - Direct vim.api calls
- `append_options()` - Appending to comma-separated lists (e.g., `diffopt`, `iskeyword`)

---

## Colorscheme: Solarized Spring

I use a customized **Solarized Spring** variant with transparent background and selective styling:

```lua
solarized.setup {
    transparent = { enabled = true },
    styles = {
        comments = { italic = true, bold = false },
        functions = { italic = true },
        variables = { italic = false },
    },
    on_highlights = function(colors, _)
        return {
            -- Completion menu highlighting
            BlinkCmpKindConstant = { fg = colors.red },
            BlinkCmpKindField = { fg = colors.violet },
            BlinkCmpMenuSelection = { fg = colors.base02, bg = colors.green },
            
            -- Telescope search results
            TelescopeMatching = { fg = colors.base02, bg = colors.cyan },
            TelescopeSelection = { fg = colors.orange, bg = colors.base02, bold = true },
            
            -- Git signs
            GitSignsAddLnInline = { fg = colors.green, bold = true },
            GitSignsChangeLnInline = { fg = colors.blue, bold = true },
            GitSignsDeleteLnInline = { fg = colors.red, bold = true },
            
            -- Markdown headings
            MarkviewHeading1 = { fg = colors.red, bold = true },
            MarkviewHeading2 = { fg = colors.green, bold = true },
            MarkviewHeading3 = { fg = colors.yellow, bold = true },
        }
    end
}
```

The transparent background allows the terminal colors to show through, creating visual continuity with tmux.

---

## Keymaps: Colemak-Aligned Bindings

My keymaps are strategically designed around Colemak Mod-DH ergonomics:

```lua
-- Leader key: Space
vim.g.mapleader = " "

-- Disable arrow keys to enforce hjkl navigation
M.keymap("n", "<Up>", "<Nop>")
M.keymap("n", "<Down>", "<Nop>")
M.keymap("n", "<Left>", "<Nop>")
M.keymap("n", "<Right>", "<Nop>")

-- Window resizing with Ctrl+Arrow
M.keymap("n", "<C-Up>", ":resize -2<CR>")
M.keymap("n", "<C-Down>", ":resize +2<CR>")
M.keymap("n", "<C-Left>", ":vertical resize -2<CR>")
M.keymap("n", "<C-Right>", ":vertical resize +2<CR>")

-- Delete without yanking (preserve clipboard)
M.keymap("n", "<leader>d", '"_d')  -- Delete into black hole register
M.keymap("n", "x", '"_x')           -- Delete char without yank
M.keymap("v", "<leader>d", '"_d')  -- Visual delete without yank

-- Keep search results centered on screen
M.keymap("n", "n", "nzzzv")         -- Next search result, center + unfold
M.keymap("n", "N", "Nzzzv")         -- Previous search result
M.keymap("n", "J", "mzJ`z")        -- Join lines, keep position

-- Jump to mark on vertical moves
M.keymap("n", "j", function()
    if vim.v.count > 0 then
        return "m'" .. vim.v.count .. "j"  -- Set mark before large jumps
    end
    return "j"
end, { expr = true })
```

**Leader sequences:**
- `<leader>ff` - Find files (Telescope)
- `<leader>fg` - Live grep (Telescope)  
- `<leader>fb` - Switch buffers (Telescope)
- `<leader>ls` - LSP symbols (Telescope)
- `<leader>lf` - LSP format current buffer
- `<leader>gs` - Git stage hunk
- `<leader>gb` - Git blame line

---

## LSP Configuration: Native Language Support

Neovim's native LSP client (`nvim-lspconfig`) provides IDE-level features without external dependencies.

```lua
-- Setup LSP on_attach keymap callbacks
vim.api.nvim_create_augroup("lsp attach", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
    group = "lsp attach",
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        
        -- Define keymaps only for attached LSP clients
        if client:supports_method("textDocument/formatting") then
            vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format, { buffer = args.buf })
        end
        
        if client:supports_method("textDocument/declaration") then
            vim.keymap.set("n", "<leader>lD", vim.lsp.buf.declaration, { buffer = args.buf })
        end
    end,
})

-- Diagnostic display configuration
local signs = {
    Error = "󰅚",
    Hint = "󰌶",
    Info = "󰋼",
    Warn = "󰀪"
}

for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- LSP diagnostic config
vim.diagnostic.config({
    update_in_insert = false,
    virtual_text = {
        prefix = "●",
        spacing = 2,
        format = function(diagnostic)
            return string.format("%s [%s]", diagnostic.message, diagnostic.source)
        end,
    },
    severity_sort = true,
    float = {
        focusable = true,
        style = "rounded",
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
    }
})
```

**Supported languages:** Lua, Python, TypeScript, Go, Rust, C/C++, Bash, and more via Mason.

---

## Treesitter: Structured Syntax Analysis

Treesitter provides incremental parsing for ~50 languages, enabling:
- **Smarter syntax highlighting** than regex-based approaches
- **Structural code navigation** (`]m`, `[m` for next/prev function)
- **Intelligent text objects** (`af`/`if` for function, `ac`/`ic` for class)
- **Consistent folding expressions**

```lua
require("nvim-treesitter.configs").setup {
    ensure_installed = {
        "bash", "c", "cmake", "cpp", "css", "dockerfile", "go",
        "html", "javascript", "json", "lua", "markdown", "python",
        "regex", "rust", "toml", "yaml", "vim"
    },
    highlight = {
        enable = true,
        disable = function(_, bufnr)
            -- Disable highlighting in very large files
            return vim.bo[bufnr].filetype == "BigFile"
        end,
        additional_vim_regex_highlighting = false,
    },
    textobjects = {
        select = {
            enable = true,
            keymaps = {
                ["af"] = "@function.outer",
                ["if"] = "@function.inner",
                ["ac"] = "@class.outer",
                ["ic"] = "@class.inner",
            },
        },
        move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
                ["]m"] = "@function.outer",
                ["]c"] = "@class.outer",
            },
            goto_previous_start = {
                ["[m"] = "@function.outer",
                ["[c"] = "@class.outer",
            },
        },
    },
    incremental_selection = {
        enable = true,
        keymaps = {
            init_selection = "<M-/>",      -- Alt+/ to start selection
            node_incremental = "<M-/>",    -- Expand to parent
            node_decremental = "<BS>",     -- Contract to child
        },
    },
}

-- Use Treesitter for folding expressions
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

-- Setup LSP semantic token highlighting fallbacks
local links = {
    ["@lsp.type.namespace"] = "@namespace",
    ["@lsp.type.class"] = "@type",
    ["@lsp.type.function"] = "@function",
    ["@lsp.type.parameter"] = "@parameter",
}

for newgroup, oldgroup in pairs(links) do
    vim.api.nvim_set_hl(0, newgroup, { link = oldgroup, default = true })
end
```

---

## Autocommands: Workflow Automation

My `autocommands.lua` contains 20+ autocommands that automate repetitive tasks:

```lua
-- Quick-fix window manipulation
vim.api.nvim_create_user_command("QFGrep", function(args)
    local all = vim.fn.getqflist()
    for i = #all, 1, -1 do
        local item = all[i]
        if not (vim.fn.bufname(item.bufnr):match(args.args) or item.text:match(args.args)) then
            table.remove(all, i)
        end
    end
    vim.fn.setqflist(all)
end, { nargs = "*" })

-- Auto-highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
    group = "highlight_yank",
    callback = function()
        vim.highlight.on_yank { timeout = 300 }
    end,
})

-- Auto-format on save (if LSP supports it)
vim.api.nvim_create_autocmd("BufWritePre", {
    group = "lsp_format",
    callback = function(ev)
        if vim.lsp.get_active_clients({ bufnr = ev.buf })[1] then
            vim.lsp.buf.format({ async = false })
        end
    end,
})

-- Auto-set filetype for custom extensions
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*.bazel",
    command = "set filetype=starlark",
})
```

---

## Plugin Ecosystem: Beyond the Core

My full plugin suite includes 60+ carefully selected plugins:

**Terminal & Shell:**
- `toggleterm.nvim` - Embedded terminal with Lua/shell integration
- `vim-floaterm` - Floating terminal

**Completion & Snippets:**
- `blink.cmp` - Modern completion engine
- `LuaSnip` - Snippet engine with VSCode snippet compatibility

**Navigation:**
- `telescope.nvim` - Fuzzy finder for files, grep, buffers
- `nvim-tree.lua` - File tree browser
- `which-key.nvim` - Keymap discovery menu
- `telescope-fzf-native.nvim` - FZF backend for faster searching

**Productivity:**
- `vim-fugitive` - Git command wrapper
- `gitsigns.nvim` - Git diff/blame in editor
- `diffview.nvim` - Side-by-side diff viewer
- `todo-comments.nvim` - Highlight TODO/FIXME/HACK comments

**UI & Aesthetics:**
- `bufferline.nvim` - Tabbar with buffer list
- `lualine.nvim` - Statusline with git info
- `indent-blankline.nvim` - Vertical indent guides
- `rainbow-delimiters.nvim` - Color-coded bracket pairs
- `smooth-cursor.nvim` - Smooth scrolling cursor

**Debugging & Testing:**
- `nvim-dap` - Debug adapter protocol client
- `nvim-dap-ui` - DAP UI frontend

**AI Integration:**
- `codecompanion.nvim` - Local LLM integration
- `neocodeium.nvim` - Codeium AI completion

---

## OSC52 Clipboard: Remote Copy/Paste

For seamless copy/paste across SSH sessions:

```lua
-- Enable OSC52 clipboard provider
vim.g.clipboard = {
    name = "OSC 52",
    copy = {
        ["+"] = require("vim.ui.clipboard.osc52").copy "+",
        ["*"] = require("vim.ui.clipboard.osc52").copy "*",
    },
    paste = {
        ["+"] = require("vim.ui.clipboard.osc52").paste "+",
        ["*"] = require("vim.ui.clipboard.osc52").paste "*",
    },
}
```

This allows copying text from Neovim on a remote server directly to your local clipboard via tmux's OSC52 support.

---

## Integration with tmux & Shell

Neovim, tmux, and zsh form an integrated development environment:

**Seamless navigation:**
```vim
" Map Ctrl+hjkl to switch between Neovim splits and tmux panes
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
" (tmux also maps <C-hjkl> to switch panes)
```

**Terminal integration with keymaps:**

```lua
-- Open shells in new tabs
utils.keymap("n", "<leader>zsh", ":tabnew term://zsh<CR>")
utils.keymap("n", "<leader>bash", ":tabnew term://bash -l<CR>")
```

Quick access to interactive shells without leaving the editor:
- `<leader>bash` - Open Bash in new tab (with login shell via `-l`)
- `<leader>zsh` - Open Zsh in new tab

Shell environment variables are inherited, and the working directory is synchronized with your current buffer location.

**Version control workflow:**

Fugitive keymaps (Git operations):
```lua
utils.keymap("n", "<leader>gst", "<cmd>tab G<CR>")
utils.keymap("n", "<leader>gfa", "<cmd>Git fetch --all --prune<CR>")
utils.keymap("n", "<leader>glog", "<cmd>GcLog!<Bar>cclose<Bar>tab copen<CR>")
utils.keymap("n", "<leader>glogf", "<cmd>tab Git log --oneline --decorate --graph -- %<CR>")
utils.keymap("n", "<leader>gpulla", "<cmd>Git pull --rebase --autostash<CR>")
```

Gitsigns keymaps (Hunk-level operations):
```lua
utils.keymap("n", "<leader>hp", gs.preview_hunk)
utils.keymap("n", "<leader>gbl", gs.toggle_current_line_blame)
utils.keymap("n", "]h", gs.nav_hunk("next"))
utils.keymap("n", "[h", gs.nav_hunk("prev"))
```

Git integration keymaps:
- `<leader>gst` - Open git status in new tab (Fugitive)
- `<leader>gfa` - Fetch all with prune (Fugitive)
- `<leader>glog` - Git log in quickfix tab (Fugitive)
- `<leader>glogf` - Git log for current file (Fugitive)
- `<leader>gpulla` - Pull with rebase and autostash (Fugitive)
- `<leader>hp` - Preview hunk changes (Gitsigns)
- `<leader>gbl` - Toggle current line blame (Gitsigns)
- `]h` / `[h` - Navigate between hunks (Gitsigns)

The tab-based workflow keeps your buffer layout intact while giving you quick access to shells and git operations whenever needed.

---

## Extending Vim Motions Beyond the Editor

The keyboard-driven philosophy extends far beyond Neovim. I use several applications that embrace vim-motion keybindings, creating a consistent interface across my entire workflow:

### **Ranger - Terminal File Manager**

Ranger replaces GUI file managers entirely. Browse directories, preview files, and manage your filesystem without touching the mouse. The preview pane shows file contents with syntax highlighting via Neovim integration.

📁 **[Configuration](https://github.com/ragu-manjegowda/config/tree/master/.config/ranger)**

### **Neomutt - Terminal Email Client**

Neomutt integrates with Neovim as the default editor for composing emails. Threading, MIME handling, and GPG encryption are all keyboard-driven.

📧 **[Configuration](https://github.com/ragu-manjegowda/config/tree/master/.config/neomutt)**

### **Sioyek - PDF Viewer**

Sioyek replaces PDF.js with a vim-native workflow. Blazing fast navigation through research papers and documentation without GUI chrome.

📄 **[Configuration](https://github.com/ragu-manjegowda/config/tree/master/.config/sioyek)**

### **Newsboat - RSS Feed Reader**

Stay updated with RSS feeds entirely in the terminal. Organize feeds with tags, mark articles as read, and open links in your browser—all keyboard-driven.

📰 **[Configuration](https://github.com/ragu-manjegowda/config/tree/master/.config/newsboat)**

### **Surfingkeys - Browser Extension**

Surfingkeys brings vim motions to Firefox/Chrome. Browse websites without touching the mouse. Open links, manage tabs, and navigate history—all through keyboard shortcuts.

🌐 **[Configuration](https://github.com/ragu-manjegowda/config/tree/master/.config/misc/surfingkeys)**

### **Unified Workflow**

These applications create a seamless ecosystem:
- **Ranger** → Find files
- **Ranger** → Open files in **Neovim** for editing
- **Neomutt** → Read emails with Neovim for composition
- **Newsboat** → Subscribe to RSS feeds
- **Newsboat** → Open articles in **Surfingkeys**-enabled browser
- **Surfingkeys** → Research papers → **Sioyek** for reading
- **Sioyek** → Extract links → **Neovim** for notes

Every tool speaks the same language: vim motions. Muscle memory built in one application transfers instantly to another. No context switching, no relearning shortcuts. Just consistency.

---

## Testing & Quality Assurance

My configuration includes comprehensive test coverage using **plenary.nvim** and **Busted** (Lua testing framework).

### Test Suites

The configuration includes 10 test modules covering all major components:

```bash
tests/
├── minimal_init.lua                # Test environment bootstrap
├── run_all_tests.sh               # Test runner script
├── test_core_behavior.lua         # Core options & keymaps
├── test_lsp_behavior.lua          # LSP setup & diagnostics
├── test_telescope_behavior.lua    # Fuzzy finder integration
├── test_treesitter_behavior.lua   # Syntax parsing & folding
├── test_git_behavior.lua          # Git integration (Fugitive/Gitsigns)
├── test_dap_behavior.lua          # Debugging integration
├── test_ui_behavior.lua           # UI components & statusline
└── test_utils_behavior.lua        # Utility functions
```

### Running Tests

```bash
# Run all tests
cd ~/.config/nvim/tests
./run_all_tests.sh

# Run specific test file
nvim --headless \
  -u ./minimal_init.lua \
  -c "lua require('plenary.busted').run('./test_core_behavior.lua')" \
  -c "qa!"
```

### Test Coverage

Tests verify:
- **Core Behavior**: Line numbers, spell checking, undo breaks, file saving
- **LSP Integration**: Language server attachment, diagnostic display, code actions
- **Telescope**: File search, grep, buffer switching, git commands
- **Treesitter**: Syntax highlighting, incremental selection, text objects
- **Git Workflows**: Hunk navigation, blame display, git status
- **DAP Support**: Debugger initialization, breakpoint handling
- **UI Components**: Statusline updates, buffer management, window management
- **Utilities**: Working directory detection, path resolution, error handling

### Test Environment

The `minimal_init.lua` provides a lightweight test environment:
- Loads full Neovim configuration
- Auto-installs plenary.nvim and lazy.nvim if needed
- Sets up mapleader and essential options
- Disables unnecessary plugins (netrw) for faster tests
- Minimal file handling (no swap, backup, writebackup)

### Example Test

```lua
describe("Core Neovim Behavior", function()
    before_each(function()
        require("user.keymaps").setup()
        require("user.options").setup()
        require("user.autocommands").setup()
    end)

    describe("Line Numbers", function()
        it("should display line numbers in new buffers", function()
            vim.cmd("new")
            assert.is_true(vim.wo.number, "Line numbers should be enabled")
            assert.is_true(vim.wo.relativenumber, "Relative line numbers should be enabled")
            vim.cmd("bdelete!")
        end)
    end)
end)
```

---

## Performance Metrics

My configuration achieves excellent performance:

- **Startup time**: ~30-40ms (including all plugins)
- **First keystroke**: <10ms
- **Completion latency**: ~5-10ms with Blink.cmp
- **Syntax highlighting**: Instant with Treesitter
- **Search speed**: <100ms for projects with 10k+ files

Measured with:
```vim
:StartupTime              " Shows plugin load times
:profile start /tmp/log   " Profile arbitrary commands
:profile dump             " View profiling results
```

---

## Repository & Configuration Files

The complete configuration including all 60+ plugins, keymaps, and test files is available on GitHub:

📦 **[github.com/ragu-manjegowda/config/.config/nvim](https://github.com/ragu-manjegowda/config/tree/master/.config/nvim)**

Key files:
- **[init.lua](https://github.com/ragu-manjegowda/config/blob/master/.config/nvim/init.lua)** - Entry point
- **[lua/user/options.lua](https://github.com/ragu-manjegowda/config/blob/master/.config/nvim/lua/user/options.lua)** - Global options
- **[lua/user/keymaps.lua](https://github.com/ragu-manjegowda/config/blob/master/.config/nvim/lua/user/keymaps.lua)** - All keybindings
- **[lua/user/plugins-table.lua](https://github.com/ragu-manjegowda/config/blob/master/.config/nvim/lua/user/plugins-table.lua)** - Plugin declarations
- **[tests/](https://github.com/ragu-manjegowda/config/tree/master/.config/nvim/tests)** - Integration tests

---

## Summary

Neovim is the core of my keyboard-driven development environment — a fully customizable, lightning-fast editor that integrates seamlessly with tmux, zsh, and my Colemak Mod-DH layout.

Through careful architectural design, strategic plugin selection, and meticulous configuration of every detail — from colorscheme tweaks to LSP diagnostics to autocommands — I've built an environment where the tools disappear and only the work remains.

Every keystroke serves a purpose. Every plugin earns its place. Every configuration option aligns with my workflow.

That's the power of Neovim.

---

{% include series_nav.html %}
