# Plan: `swmcc.todo`, my to-do list as a herdr plugin

*Written 15 Nov 2026. Load this into a fresh workspace and build it from here.*

> **Built.** This is the original plan, kept for the reasoning behind it. The build moved
> on from it: there's a 3×3 cards view, `/` searches titles and `l` searches labels (not
> bodies), `s` is SkillfulGorilla, `w` is a new 🏢 work side, and adding has a label
> picker. The [README](README.md) describes what it does now.

## Goal

My to-do list (the open issues on **swmcc/todo**) in a big herdr popup over the workspace. I can pop it up whenever I want, search it with `/`, add to it and tick things off without leaving the terminal.

Done looks like this: `herdr plugin link ~/Code/herdr-todo`, then "Todo: show my list" opens a 90% popup. `/` searches across titles, labels and bodies, and single keys finish, add and open tasks. It refreshes by itself.

## What already exists (don't rebuild it)

- **The `todo` CLI** at `~/bin/todo` (source in `~/Code/todo/bin/todo`). It already does everything I need: `todo`, `todo ls home|biz|<label>`, `todo home "title" [labels]`, `todo biz "title" [labels]`, `todo done N ["note"]`, `todo show N`, `todo web [N]`, `todo labels`. **The plugin wraps this CLI. It never calls the GitHub API itself.**
- **Label conventions** are in `~/.claude/skills/todo/SKILL.md`. There are two top labels (🏠 domestic, 🦍 skillfulgorilla) and short names for the rest.
- **A worked plugin** to copy the shape from: `~/Code/herdr-sightline/herdr-plugin.toml`. Note from Sightline: **herdr plugins can't run background daemons**, so the pane's own command has to do the refreshing.

## Decisions

- **New repo `~/Code/herdr-todo`**, plugin id `swmcc.todo`, macOS and Linux.
- **A popup, not a split.** `placement = "popup"`, `width`/`height = "90%"`. ✅ It works on 0.9.1, set in the manifest, even though the CLI's `--placement` flag doesn't list it.
- **A popup swallows every key, herdr's prefix (`ctrl-a`) included.** So the popup must always have a way out. `q` quits when not searching, `ctrl-c` always quits, and if fzf or `gh` dies, the script exits so the popup closes. There's no hanging "press a key" screen.
- **Actions have no terminal** (`tty` says "not a tty"), so they can't prompt. "Todo: add" opens a second small popup entrypoint (`add`, about 60×10). Inside the list, `n` and `x` prompt in the list's own terminal via fzf `execute`. Actions run with cwd at the plugin root and get `HERDR_PLUGIN_CONTEXT_JSON`.
- **Action contexts** are `global`, `workspace`, `tab`, `pane` and `selection`. Use `global` so the list opens from anywhere. Invoke as `herdr plugin action invoke swmcc.todo.show`.
- **POSIX `sh` plus fzf, no build step.** fzf does the search, keybindings, preview and reload. Needs `brew install fzf` and a recent fzf for `change-nth`, `show-input`/`hide-input` and `rebind`/`unbind`. Check `fzf --version` at startup and print one clear line if it's missing or too old.
- **One machine-readable command in the CLI:** add `todo ls --tsv` to `~/Code/todo`. It prints one line per issue: `number<TAB>side<TAB>title<TAB>labels<TAB>body`, with the body flattened to one line. The plugin reads from that, so the CLI stays the only thing that talks to GitHub.
- **Refresh every 60 seconds**, configurable with `TODO_REFRESH`. fzf has no timer, so start fzf with `--listen`. A loop inside the pane's own process posts `reload` to it, and it dies with the pane. That's not a daemon.
- **Find the CLI** in this order: `todo` on the PATH, then `~/Code/todo/bin/todo`. If neither exists, print one line saying so. Never crash the pane.

## Keymap

The popup opens with search off, so single letters are commands. `/` starts a search, like vim. That's the only vim-ish bit: the letters are unbound and the input is shown. `esc` ends the search and keeps the filter.

| Key | Does |
|---|---|
| arrows | move |
| `/` | search; fzf syntax works: `dev 'urgent`, `!low`, `^#3` |
| `s` | cycle the search scope: all → title → labels → body (`change-nth`), shown in the prompt |
| `h` / `b` / `a` | show home / business / all |
| `enter` | `todo show N` in the preview |
| `x` | done (prompts for an optional note) |
| `n` | add a new task |
| `o` | open in the browser (`todo web N`) |
| `r` | refresh now |
| `q` / `esc` | close the popup (`esc` only when not searching) |

## Layout

```text
herdr-todo/
  herdr-plugin.toml
  bin/
    todo-pane      # finds todo + fzf, runs fzf with the keymap and the reload loop
    todo-add       # prompts for title, home/biz, labels (run from fzf via execute)
    todo-done      # prompts for an optional note, then todo done N
    todo-cli       # finds the todo CLI (PATH, then ~/Code/todo/bin/todo) and execs it
  README.md
  Makefile         # make link / make unlink / make lint
```

## herdr-plugin.toml (draft)

```toml
id = "swmcc.todo"
name = "Todo"
version = "0.1.0"
min_herdr_version = "0.9.1"   # raise if popup needs it
description = "My to-do list (swmcc/todo), searchable in a popup"
platforms = ["macos", "linux"]

[[panes]]
id = "list"
title = "Todo"
placement = "popup"
width = "90%"
height = "90%"
command = ["bin/todo-pane"]

[[actions]]
id = "show"
title = "Todo: show my list"
contexts = ["global"]
command = ["herdr", "plugin", "pane", "open", "--plugin", "swmcc.todo", "--entrypoint", "list", "--focus"]

[[panes]]
id = "add"
title = "Todo: add"
placement = "popup"
width = 60
height = 10
command = ["bin/todo-add"]

[[actions]]
id = "add"
title = "Todo: add"
contexts = ["global"]
command = ["herdr", "plugin", "pane", "open", "--plugin", "swmcc.todo", "--entrypoint", "add", "--focus"]

[[actions]]
id = "web"
title = "Todo: open in browser"
contexts = ["global"]
command = ["bin/todo-cli", "web"]
```

Done lives inside the popup (`x`), so it doesn't need its own action.

## Steps

1. **Check the plugin API before writing code.** Confirm these things:
   - whether 0.9.1 supports `placement = "popup"` with `width`/`height`, or whether herdr needs upgrading
   - which action `contexts` exist (I need workspace or global)
   - whether a popup really gets Esc and every other key, so fzf's bindings work
   - whether an action can prompt for input, or whether add needs its own small popup
2. **`todo ls --tsv` in `~/Code/todo`:** add it, test it and commit it there.
3. **`bin/todo-cli`:** find the CLI and exec it with the arguments.
4. **`bin/todo-pane`:**
   - check for fzf
   - start fzf with `--delimiter '\t'` and `--with-nth` showing `#N title labels`, so side and body stay hidden but searchable
   - preview with `todo show {1}`
   - add the keymap above and the `--listen` reload loop
   - when `gh` fails, show a quiet "offline, retrying" header, never a stack of errors
5. **`bin/todo-add` / `bin/todo-done`:** prompts, then `todo home|biz ...` or `todo done N "note"`, then reload fzf.
6. **Link and try it:** `herdr plugin link ~/Code/herdr-todo`, then `herdr plugin list`. Invoke the actions and try every key. Check the logs with `herdr plugin log swmcc.todo`.
7. **Polish:** put urgent tasks first, show 🏠 and 🦍 in the list, and show the mode (NORMAL or SEARCH) and the scope in the prompt.
8. **README and Makefile:** what it is, the install command (with `brew install fzf`), the keymap and `TODO_REFRESH`.
9. **Lint:** run `shellcheck bin/*`. Commit with emoji messages. Push only when I say so.

## Out of scope

- Editing labels or comments from herdr. Use `todo tag`, `todo note` or `todo web`. (These could become keys later.)
- Handing a to-do to an agent, like herdr-board and herdr-symphony do. That's a nice v2: "Todo: give this to an agent" opens a worktree and an agent seeded with the issue.
- Notifications. Notify Router is already installed if I want them later.

## Open questions

- [x] Does 0.9.1 support popup? Yes.
- [x] Can an action prompt for input? No, so add gets its own small popup.
- [x] Which context should "show my list" use? `global`.
- [x] Do all keys reach the popup? Yes. The probe saw letters, Enter, ctrl keys, Esc (`1b`), `/` (`2f`) and the arrows (`1b 5b 42`).
