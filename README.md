# Neovim IDE

Eine vollständige Neovim-Konfiguration für Python, Rust, CSS, HTML, JavaScript/TypeScript
und C/C++ — mit LSP, Formatting, Linting, Debugging (DAP), grafischem Git/Docker,
Fuzzy Search, Command Palette und einer eigenen Settings-UI.

Der ursprüngliche Implementierungsplan steht in [`PLAN.md`](./PLAN.md).

## Voraussetzungen

```sh
brew install ripgrep fd lazygit lazydocker node
xcode-select --install   # clang/make für Treesitter + telescope-fzf-native
```

Python- und Rust-Toolchains werden als bereits vorhanden vorausgesetzt. Alle
LSP-Server, Formatter, Linter und DAP-Adapter installiert `mason.nvim` beim
ersten Start automatisch (dauert je nach Verbindung ein paar Minuten).

Für die Claude-Code-Integration (`<leader>a`) muss die `claude`-CLI bereits
lokal installiert und eingeloggt sein — das Plugin verbindet sich nur damit,
liefert die CLI selbst nicht mit.

## Leader-Key: `<Space>`

| Prefix             | Gruppe              | Wichtigste Befehle                                                                                             |
| ------------------ | ------------------- | -------------------------------------------------------------------------------------------------------------- |
| `<leader>a`        | AI                  | `ac` Claude Code (Toggle) · `af` Fokus · `as` Selektion senden (visueller Modus)                               |
| `<leader>f`        | Find                | `ff` Dateien · `fg` Live-Grep · `fb` Buffers · `fr` Recent · `fk` Keymaps                                      |
| `<leader>g`        | Git                 | `gg` LazyGit · `gs`/`gr`/`gp` Hunk stage/reset/preview · `gb` Blame                                            |
| `<leader>D`        | Docker              | `Dd` LazyDocker                                                                                                |
| `<leader>d`        | Debug (DAP)         | `db` Breakpoint · `dc` Continue · `di`/`do`/`dO` Step · `du` DAP-UI                                            |
| `<leader>l`        | LSP/Code            | `la` Code Action · `lr` Rename · `lf` Format · `li` Inlay Hints · `lI` Diagnostics-Stil                        |
| `<leader>x`        | Diagnostics         | `xx` Trouble · `xd` Buffer-Diagnostics · `xt` TODOs                                                            |
| `<leader>e`        | Explorer            | `ee` Toggle/Close · `ef` Reveal · `q`/`Esc` schließt das Explorer-Fenster · `?` in neo-tree für alle Datei-Ops |
| `<leader>c`        | Config              | `cs` **Settings-UI** · `cp` Lazy · `cm` Mason · `cl` checkhealth                                               |
| `<leader>t`        | Terminal            | `tt` Float · `th`/`tv` Split                                                                                   |
| `<leader>b`        | Buffers             | `bb` Pick · `bd` Delete                                                                                        |
| `<leader>w`        | Window              | `ws`/`wv` Split · `wd` Close                                                                                   |
| `<leader>W`        | **Window-Mode**     | Kein Halten nötig: `h/j/k/l` bewegen, `+`/`-`/`</>` resizen, `q`/`Esc` verlässt den Modus                      |
| `<leader><leader>` | **Command Palette** | Alle Keymaps durchsuchbar (legendary.nvim)                                                                     |

`<C-h>`/`<C-j>`/`<C-k>`/`<C-l>` wechseln immer zwischen Fenstern, auch mit
Fokus im Explorer (neo-tree) oder in anderen Plugin-Fenstern — kein Leader
nötig.

Vollständige, kommentierte Liste: [`lua/config/keymaps.lua`](./lua/config/keymaps.lua).
`<leader>fk` bzw. die Command Palette zeigen sie auch live im Editor.

### Mac-Shortcuts (`Cmd`/`<D-...>`)

Zusätzlich zu den Leader-Keymaps oben gibt es eine Reihe von `Cmd`-Kurzbefehlen
(`M.mac` in `lua/config/keymaps.lua`), z. B. `Cmd+S` Speichern, `Cmd+W` Buffer
schließen, `Cmd+P` Dateisuche, `Cmd+O` Projekt öffnen, `Cmd+B` Buffer wechseln,
`Cmd+R` Debuggen starten. Sie funktionieren mit dem Terminal Ghostty ohne
weitere Konfiguration — mit Ausnahme von `Cmd+W`, wofür Ghosttys eigene
Standardbelegung (`super+w=close_surface`) freigegeben werden musste (siehe
Kommentar in `~/Library/Application Support/com.mitchellh.ghostty/config`).

## Settings-UI ("Konfigurationsmaske")

`<leader>cs` öffnet ein Floating-Fenster mit sechs Tabs (`Tab`/`Shift-Tab` oder
`1`-`6` zum Wechseln): Colorscheme (+Variante), Transparenz,
Diagnostics/Inlay-Hints/Indent-Guides, Format-on-Save (global + pro Dateityp),
die 7 Sprach-Toggles (LSP+Format+Lint) und UI-Layout-Optionen. Alles wird
persistiert unter `~/.local/share/nvim/nvim_settings.json` und beim nächsten Start
automatisch wiederhergestellt.

## Zeilenlänge (Linting/Formatierung)

Statt der Tool-eigenen Defaults gilt in diesem Setup fest, unabhängig vom
Projekt:

| Dateityp                 | Tool                             | Limit | Wo konfiguriert                                                    |
| ------------------------ | -------------------------------- | ----- | ------------------------------------------------------------------ |
| Markdown                 | `markdownlint`                   | 150   | `.markdownlint.json` (per `--config`-Flag erzwungen)               |
| Python                   | `ruff format`/`ruff check --fix` | 120   | `lua/plugins/formatting.lua` (`--line-length`, per `append_args`)  |
| JS/TS/CSS/HTML/JSON/YAML | `prettier`                       | 120   | `lua/plugins/formatting.lua` (`--print-width`, per `prepend_args`) |

Die Werte werden per CLI-Flag erzwungen und gewinnen damit über eine eventuell
vorhandene `pyproject.toml`/`.prettierrc` des jeweiligen Projekts. ESLint hat
keine `max-len`-Regel aktiv, dort gibt es also ohnehin kein Zeilenlängen-Limit.

## Projekte & Python-Venvs

- `<leader>fp` / `Cmd+O` öffnet einen Picker über bekannte Projektverzeichnisse
  (Liste in `lua/util/projects.lua`, `M.roots` selbst erweitern). Auswahl wechselt
  das Arbeitsverzeichnis und lädt die zugehörige `persistence.nvim`-Session.
- Python-Projekte: `venv-selector.nvim` erkennt `.venv`/Poetry/uv-Umgebungen beim
  Öffnen einer `.py`-Datei automatisch; manuell wählbar über `<leader>lv` /
  `:VenvSelect`. Der Debug-Adapter selbst bleibt auf Masons eigener
  `debugpy`-Installation, nur das debuggte Programm läuft im Projekt-Venv
  (`lua/plugins/dap.lua`).
- Die aktive Venv wird (wie in VS Code/PyCharm) in der Statuszeile angezeigt,
  sobald eine erkannt wurde (`lua/util/venv.lua`).

## Verifikation

- `:checkhealth` — Gesamtstatus aller Subsysteme
- `:Lazy` — Plugin-Status · `:Mason` — installierte LSP/Format/Lint/DAP-Tools
- Eine Datei je Sprache öffnen und `:LspInfo` prüfen
