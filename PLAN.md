# Neovim → AAA IDE Konfiguration

## Context

`~/.config/nvim` ist aktuell komplett leer — es gibt keine bestehende Konfiguration, auf der aufgebaut werden könnte. Ziel ist eine professionelle, VS-Code/PyCharm-ebenbürtige Neovim-Konfiguration für Python, Rust, CSS, HTML, JavaScript/TypeScript und C/C++, mit vollem LSP/Linting/Formatting, Debugging (DAP), grafischem Git/Docker (via eingebettete TUI-Tools), Fuzzy Search, einem VS-Code-artigen Command Palette + zentrierter Kommandozeile + Start-Dashboard, sauber strukturierten `<Space>`-Kommandos und einer selbstgebauten, umfangreichen Settings-UI ("Konfigurationsmaske"). Diese Entscheidungen wurden im Vorgespräch mit dem Nutzer bereits getroffen (siehe unten) — der Plan setzt sie um, ohne sie erneut zur Debatte zu stellen.

**Umgebung (geprüft):** macOS (Darwin), Neovim v0.12.4, Homebrew vorhanden. Bereits installiert: `fd`, `ripgrep`, `lazygit`, `lazydocker`, `node`, `git`, Python (3.13/3.14), Rust/`rust-analyzer`. Volles Xcode.app vorhanden → `clang`/`make` verfügbar (kein `cmake` nötig).

**Getroffene Entscheidungen (aus Rückfragen):**

- Zentriertes Eingabefeld: **alle drei** — Command Palette, zentrierte Kommandozeile, Start-Dashboard
- Grafisches Git/Docker: **TUI-Tools eingebettet** (lazygit/lazydocker im Floating-Terminal)
- Debugging: **volles DAP-Setup** für die 4 tatsächlich debugfähigen Sprachen (Python, Rust, C/C++, JavaScript/TypeScript) — CSS und HTML haben kein Debug-Adapter-Protokoll, dafür stehen dort LSP-Diagnostics/Formatting/Linting im Vordergrund
- Colorscheme: **wählbar**, mind. Catppuccin, Tokyonight, Gruvbox, Kanagawa + ein GitHub-Farbschema
- Settings-UI: **umfangreich** (pro-Sprache-Toggles, Keymap-Übersicht, UI-Layout-Optionen)
- Externe Tools: **Checkliste mit Homebrew-Befehlen** im Plan

**Geflaggte Annahme:** "Git-Farbschema" wird als `projekt0n/github-nvim-theme` interpretiert (GitHub-Style-Theme). Falls etwas anderes gemeint war, bitte vor Phase 2 korrigieren.

## Verzeichnisstruktur

```
~/.config/nvim/
├── init.lua                      -- Entry point: require-Reihenfolge + lazy.nvim bootstrap
├── lazy-lock.json                -- von lazy.nvim generiert, wird committed
├── lua/
│   ├── config/
│   │   ├── options.lua           -- vim.opt / vim.g Basis-Editor-Settings
│   │   ├── keymaps.lua           -- zentrale Keymap-Spec-Tabelle (single source of truth)
│   │   ├── autocmds.lua          -- yank-highlight, LspAttach, format-on-save Hook, etc.
│   │   └── lazy.lua              -- lazy.nvim bootstrap + setup("plugins")
│   ├── plugins/
│   │   ├── ui.lua                -- Colorschemes, lualine, bufferline, indent-blankline,
│   │   │                            alpha, noice+nui+notify, fidget, web-devicons
│   │   ├── editor.lua            -- treesitter, autopairs, flash, todo-comments, trouble,
│   │   │                            persistence, colorizer, ts-context-commentstring
│   │   ├── completion.lua        -- blink.cmp + friendly-snippets
│   │   ├── lsp.lua               -- mason, mason-lspconfig, mason-tool-installer, lspconfig,
│   │   │                            lazydev, rustaceanvim, pro-Sprache Server-Setup
│   │   ├── formatting.lua        -- conform.nvim
│   │   ├── linting.lua           -- nvim-lint (nur hadolint/shellcheck/markdownlint)
│   │   ├── telescope.lua         -- telescope + fzf-native + ui-select
│   │   ├── neotree.lua           -- neo-tree.nvim + volle Datei-Op-Keymaps
│   │   ├── palette.lua           -- legendary.nvim + which-key.nvim
│   │   ├── git.lua                -- gitsigns.nvim
│   │   ├── terminal.lua          -- toggleterm.nvim + lazygit/lazydocker Terminal-Instanzen
│   │   └── dap.lua               -- nvim-dap, dap-ui, dap-virtual-text, mason-nvim-dap
│   └── settings/
│       ├── state.lua             -- persistierter JSON-State (get/set/save/appliers-Registry)
│       ├── ui.lua                -- nui.nvim Floating-Window ("Konfigurationsmaske")
│       └── init.lua              -- Glue-Modul, früh in init.lua geladen
```

`lua/settings/state.lua` hat **keine Plugin-Abhängigkeiten** (nur `vim.fn.json_encode/decode` + `stdpath('data')`), damit es schon vor `lazy.setup()` geladen werden kann — das ist nötig, damit z.B. das gespeicherte Colorscheme direkt beim Start ohne Flackern angewendet wird. `lua/settings/ui.lua` hängt von `nui.nvim` ab und wird lazy geladen (erst bei `<leader>cs`).

## Prerequisites-Checkliste (Phase 0)

```
brew install ripgrep fd            # Telescope: rg für live_grep, fd für find_files
brew install lazygit lazydocker    # externe TUIs im Floating-Terminal
brew install node                  # mason: pyright/basedpyright, ts_ls, eslint,
                                    # vscode-langservers-extracted, prettier, js-debug-adapter
xcode-select --install             # clang/cc/make (bereits via Xcode.app vorhanden)
# NICHT nötig: cmake (fzf-native baut per `make`)
# NICHT nötig: Python/Rust-Toolchains separat installieren (bereits vorhanden)
# Alle LSP-Server/Formatter/Linter/DAP-Adapter installiert mason.nvim selbst, innerhalb Neovim
```

Verifikation: `rg --version`, `fd --version`, `lazygit --version`, `lazydocker --version`, `node -v`, `cc --version`.

## Keymap-Schema (`<leader>` = Space)

| Prefix             | Gruppe                                     | Beispiele                                                                                                                                    |
| ------------------ | ------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `<leader>f`        | Find (Telescope)                           | `ff` Dateien · `fg` Live-Grep · `fb` Buffers · `fr` Recent · `fh` Help · `fk` Keymaps · `fd` Diagnostics                                     |
| `<leader>g`        | Git                                        | `gg` LazyGit-Float · `gs` Stage Hunk · `gr` Reset Hunk · `gp` Preview Hunk · `gb` Blame Toggle · `gl` Commits · `gB` Branches                |
| `<leader>D`        | Docker (bewusste Ausnahme, da `d` = Debug) | `Dd` LazyDocker-Float                                                                                                                        |
| `<leader>d`        | Debug (DAP)                                | `db` Breakpoint · `dB` Conditional BP · `dc` Continue · `di`/`do`/`dO` Step In/Over/Out · `du` DAP-UI Toggle · `dt` Terminate                |
| `<leader>l`        | LSP/Code                                   | `la` Code Action · `lr` Rename · `lf` Format · `li` Inlay Hints Toggle · `ls`/`lS` Symbols                                                   |
| `<leader>x`        | Diagnostics/Trouble                        | `xx` Trouble Toggle · `xd` Buffer Diagnostics · `xt` TODO-Liste                                                                              |
| `<leader>e`        | Explorer (neo-tree)                        | `ee` Toggle · `ef` Reveal File · `eg` Git-Status-View (Datei-Ops `a/d/r/c/x/p/y` sind neo-trees eigene Buffer-Local-Keys, per `?` einsehbar) |
| `<leader>c`        | Config/Settings                            | `cs` **Konfigurationsmaske öffnen** · `cp` `:Lazy` · `cm` `:Mason` · `cl` `:checkhealth`                                                     |
| `<leader>t`        | Terminal                                   | `tt` Float-Shell · `th`/`tv` Split                                                                                                           |
| `<leader>b`        | Buffers                                    | `bb` Picker · `bd` Delete (layout-erhaltend) · `bo` Close Others                                                                             |
| `<leader>w`        | Window                                     | `ws`/`wv` Split · `wd` Close · `wo` Only                                                                                                     |
| `<leader><leader>` | **Command Palette** (legendary.nvim)       | durchsuchbare Liste aller Keymaps/Commands                                                                                                   |

Passiv, ohne Keymap: zentrierte `:`/`/`-Kommandozeile (noice.nvim), Start-Dashboard bei leerem `nvim`-Start (alpha-nvim). Neovim-0.11-Builtins (`grn`, `gra`, `grr`, `gri`, `gO`, `gs`) bleiben unangetastet; `<leader>l` ist eine zusätzliche, Telescope-gestützte Ebene ohne Kollision.

## Plugin-Auswahl (Kernbegründungen)

- **Plugin-Manager**: `folke/lazy.nvim`
- **LSP-Kern**: `mason.nvim` + `mason-lspconfig.nvim` + `mason-tool-installer.nvim` (deckt auch Nicht-LSP-Tools wie `stylua`/`hadolint` ab) + `nvim-lspconfig` + `folke/lazydev.nvim` (Lua-Editing dieser Config selbst)
- **Python**: `basedpyright` (aktiver gepflegter Fork, bessere Inlay Hints) + `ruff` als natives LSP (Linting + Import-Organisation, passt zu den globalen Ruff/120-Zeichen-Standards)
- **Rust**: `mrcjkb/rustaceanvim` statt reinem lspconfig — verdrahtet `rust-analyzer` automatisch, liefert Cargo-Runnables als Code-Lens und generiert DAP-Configs für codelldb automatisch (spart viel Handarbeit in Phase 7)
- **CSS/HTML**: `cssls`, `html` (vscode-langservers-extracted)
- **JS/TS**: `ts_ls` + `eslint`-LSP
- **C/C++**: `clangd` (Hinweis: profitiert von `compile_commands.json`, wird nicht automatisiert)
- **Docker**: `dockerls` + `docker_compose_language_service`
- **Formatting**: `stevearc/conform.nvim` (ruff_format, rustfmt, prettier, clang-format, stylua)
- **Linting-Ergänzung**: `mfussenegger/nvim-lint` nur für Linter ohne guten LSP-Modus (hadolint, shellcheck, markdownlint) — Python/JS/TS-Linting läuft über LSP-Diagnostics
- **Completion**: `saghen/blink.cmp` (eigene Snippet-Engine) + `rafamadriz/friendly-snippets` als Snippet-Bibliothek
- **Fuzzy Search**: `telescope.nvim` + `telescope-fzf-native.nvim` (`build = "make"`) + `telescope-ui-select.nvim`
- **Explorer**: `neo-tree.nvim` (deps: plenary, nui, web-devicons)
- **Command Palette**: `mrjones2014/legendary.nvim`, gespeist aus derselben Keymap-Tabelle wie `which-key.nvim` (`extensions.which_key.auto_register = true`)
- **Zentrierte Kommandozeile**: `folke/noice.nvim` + `nui.nvim` + `nvim-notify`
- **Start-Dashboard**: `goolord/alpha-nvim` (bewusst statt snacks.nvim-Dashboard, um Redundanz mit bereits gewählten Einzel-Plugins zu vermeiden), verdrahtet mit `persistence.nvim` (Session-Restore) und Telescope
- **Git**: `gitsigns.nvim` (Inline-Hunks/Blame) + `lazygit` via `toggleterm.nvim`-Float
- **Docker**: `lazydocker` via `toggleterm.nvim`-Float
- **DAP**: `nvim-dap` + `nvim-dap-ui` (+`nvim-nio`) + `nvim-dap-virtual-text` + `mason-nvim-dap.nvim` (installiert `debugpy`, `codelldb`, `js-debug-adapter`) + `nvim-dap-python`
- **UI**: `lualine.nvim`, `bufferline.nvim`, `indent-blankline.nvim` (v3), `fidget.nvim` (LSP-Progress; noice's eigene Progress-View wird deaktiviert, um Doppelanzeige zu vermeiden), `nvim-web-devicons`
- **Colorschemes**: `catppuccin/nvim`, `folke/tokyonight.nvim`, `ellisonleao/gruvbox.nvim`, `rebelot/kanagawa.nvim`, `projekt0n/github-nvim-theme`
- **Weitere "AAA-Feel"-Ergänzungen**: `nvim-autopairs`, `nvim-ts-context-commentstring` (native `gc`/`gcc` bleibt, kein `Comment.nvim` nötig), `flash.nvim` (moderne Jump-Motions), `todo-comments.nvim`, `trouble.nvim`, `persistence.nvim`, `nvim-colorizer.lua` (gepflegter Fork), `mini.bufremove`
- **Bewusst weggelassen**: `dressing.nvim` (redundant zu telescope-ui-select + noice)

## Settings-UI ("Konfigurationsmaske")

- `lua/settings/state.lua`: reines Datenmodul (kein Plugin-Dep), Schema u.a. `colorscheme`+Variante, `background_transparency`, `format_on_save` (global + pro Dateityp), `diagnostics_virtual_text`, `inlay_hints`, `indent_guides`, `relativenumber`, pro-Sprache `enabled`-Flags (python/rust/css/html/javascript/cpp/docker), `bufferline_visible`, `statusline_style`. Plugin-Module registrieren beim eigenen Setup ihre Seiteneffekt-Funktion in `state.appliers[key]`; `state.set(key, val)` ruft den Applier auf und persistiert.
- `lua/settings/ui.lua`: `nui.nvim`-Layout mit Sektionen (Appearance, LSP/Formatting/Linting pro Sprache, Diagnostics/Inlay Hints, UI-Layout, Keymaps). `j/k` navigieren, `Enter`/`Space` togglen, `Tab` wechselt Sektion. Die Keymap-Sektion **delegiert an legendary.nvim's eigenen Picker** statt Suche neu zu bauen.
- Persistenz: `stdpath('data')/nvim_settings.json` (nicht im Config-Verzeichnis, analog zu mason/lazy), `pcall`-geschütztes Laden mit Fallback auf Defaults, Speichern bei jeder Änderung + `VimLeavePre`.
- Erreichbar über `<leader>cs`, `:Settings`-Command, Palette-Eintrag, Dashboard-Button.

## Build-Reihenfolge

**Status (laufende Umsetzung):**

- ✅ Phase 0: alle Prerequisites bereits via Homebrew vorhanden (rg, fd, lazygit, lazydocker, node, cc/make, git, python3, rustc, cargo, rust-analyzer) — kein Install nötig. `PLAN.md` liegt im Repo, `git init` + Initial-Commit erledigt.
- ✅ Phase 1: `init.lua`, `lua/config/{options,keymaps,autocmds,lazy}.lua`, `lua/settings/{state,init}.lua` stehen, Boot-Sanity-Check (`nvim --headless`) läuft fehlerfrei durch.
- 🔄 Phase 2 (in Arbeit): `lua/util/theme.lua` (Runtime-Colorscheme-Switching, lebt bewusst außerhalb von `lua/plugins/`, da lazy.nvim's `{import="plugins"}` jede Datei dort als Plugin-Spec interpretiert) steht; `lua/plugins/ui.lua` (5 Colorschemes, lualine, bufferline, indent-blankline, alpha, noice+nui+notify, fidget, which-key) folgt als nächstes.

0. **Prerequisites & Bootstrap** — Homebrew-Checkliste, `init.lua`+`lazy.lua` Grundgerüst, leeres `:Lazy` prüfen
1. **Core Options/Keymaps** — `options.lua`, `keymaps.lua` (leere Tabelle+Loop), `autocmds.lua`, noch ohne Plugins
2. **Colorscheme + UI-Shell** — 5 Themes, lualine, bufferline, indent-blankline, alpha, noice+notify, fidget, which-key; `settings/state.lua` entsteht hier (vor `lazy.setup()` geladen)
3. **Treesitter + Editor-Tooling** — Parser für alle Zielsprachen, autopairs, flash, todo-comments, trouble, persistence, colorizer
4. **LSP + Completion + Formatting + Linting** — alle Server/Formatter/Linter aus der Liste, `LspAttach`-Autocmd, Format-on-Save-Hook (state-gated)
5. **Fuzzy-Finder + Explorer + Command Palette** — telescope+fzf-native, neo-tree, legendary
6. **Git + Docker Terminal-Integration** — gitsigns, toggleterm mit 3 Terminal-Instanzen (shell/lazygit/lazydocker)
7. **DAP-Debugging** — nvim-dap-Stack, Adapter pro Sprache (debugpy/codelldb/js-debug-adapter)
8. **Konfigurationsmaske** — vollständiges `state.lua`-Schema + `ui.lua`, Verdrahtung an `<leader>cs`/Command/Palette/Dashboard
9. **Politur/Verifikation** — Which-Key-Gruppen auf Kollisionen prüfen, `lazy-lock.json` committen (git init falls gewünscht), volle Verifikation

## Verifikation

| Bereich         | Prüfung                                                                                                                                     |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| Bootstrap       | `nvim` startet fehlerfrei, `:Lazy` zeigt alle Plugins installiert, `:Lazy check` sauber                                                     |
| Health          | `:checkhealth` (treesitter, mason, telescope, noice)                                                                                        |
| LSP pro Sprache | `.py`/`.rs`/`.c`/`.ts`/`.css`/`.html`/`Dockerfile` öffnen, `:LspInfo` zeigt Attach, Diagnostics bei Fehler, `<leader>la` zeigt Code Actions |
| Formatting      | Datei mit schlechter Formatierung speichern → conform.nvim korrigiert automatisch                                                           |
| Completion      | Tippen zeigt LSP- und Snippet-Vorschläge (blink.cmp)                                                                                        |
| Fuzzy Search    | `<leader>ff`/`fg`/`fb` liefern schnell Ergebnisse (fzf-native kompiliert korrekt)                                                           |
| Explorer        | `<leader>ee`, Datei anlegen/umbenennen/löschen/kopieren/verschieben testen                                                                  |
| Command Palette | `<leader><leader>` öffnet legendary, Suche + Ausführung funktioniert                                                                        |
| Zentrierte UI   | `:`/`/` erscheinen zentriert; `nvim` ohne Argumente zeigt Dashboard                                                                         |
| Git             | Hunks in Sign-Column bei bearbeiteter Datei; `<leader>gg` öffnet LazyGit-Float, Stage/Commit funktioniert                                   |
| Docker          | `<leader>Dd` öffnet LazyDocker-Float                                                                                                        |
| DAP             | Pro Sprache: Breakpoint setzen, `<leader>dc`, dap-ui zeigt Scopes/Watches/Call-Stack, Step-Befehle funktionieren                            |
| Settings-UI     | `<leader>cs` öffnet Formular, jede Kategorie togglen, nach Neustart Persistenz prüfen, Keymap-Sektion öffnet legendary-Picker               |

### Kritische Dateien

- `~/.config/nvim/init.lua`
- `~/.config/nvim/lua/config/keymaps.lua`
- `~/.config/nvim/lua/settings/state.lua`
- `~/.config/nvim/lua/settings/ui.lua`
- `~/.config/nvim/lua/plugins/lsp.lua`
- `~/.config/nvim/lua/plugins/dap.lua`
