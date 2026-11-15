# 📋 herdr-todo

**My to-do list, one keypress away, right beside my agents.**

A [herdr](https://herdr.dev) plugin that opens my to-do list (the open issues on
[swmcc/todo](https://github.com/swmcc/todo)) in a big popup. I can search it, flip
between a list and a grid of cards, add tasks, tick them off and get back to my agents
without leaving the terminal.

```text
╭─ 🔤 title ─────────────────────────────────────────────────────────────────────╮
│ 🔍 rails                                                              3/38     │
╰────────────────────────────────────────────────────────────────────────────────╯
╭─ 📋 Everything · 38 to do · 🔄 04:39 ──────────────────╮╭─ 📖 details ─────────╮
│ ▌ 🦍 #5   Deploy the Rails fix to staging   💻 dev  🔥 urgent ││ #5 Deploy the…  │
│   🏠 #4   Decide on the Rails 8.1.4.1 …     💻 dev  🔥 urgent ││ Open · 💻 dev   │
│   🦍 #3   Decide on the Rails 8.1.4.1 …     💻 dev  🔥 urgent ││ …               │
╰────────────────────────────────────────────────────────╯╰─────────────────────╯
  / title · l labels · v 🃏 cards · h 🏠 · s 🦍 · w 🏢 · a all · n new · x done …
```

## What you get

- **A popup over the workspace,** 90% of the screen. Press a key, look, press `q`, carry on.
- **Urgent first.** Tasks are ranked urgent, in progress, high, normal, waiting, then low.
- **Colour.** Every label is a pill in its own GitHub colour. 🏠 home, 🦍 SkillfulGorilla and
  🏢 work each have an icon, and card borders take the side's colour.
- **Two views.** A list with a details pane, or a 3×3 grid of cards. `v` swaps between them,
  and the popup reopens in whichever you used last.
- **Search that stays out of the way.** The popup opens with search off, so single letters
  are commands. `/` searches titles, `l` searches labels, and both filter as you type.
- **Always fresh.** It shows the last list instantly, fetches a new one in the background,
  then refreshes every 60 seconds while it's open.
- **Adding with a label picker.** Type a title, pick the side, then pick labels from a
  searchable list of coloured pills.
- **Fits the screen.** Moving between the laptop and a monitor reflows both views.

## Install

You need:

- [herdr](https://herdr.dev) 0.9.1 or later, on macOS or Linux
- [fzf](https://github.com/junegunn/fzf) (tested with 0.75): `brew install fzf`
- [gh](https://cli.github.com), logged in
- the [`todo` CLI](https://github.com/swmcc/todo), on your `PATH` or at `~/Code/todo/bin/todo`

Then link the plugin from a checkout:

```sh
git clone https://github.com/swmcc/herdr-todo ~/Code/herdr-todo
cd ~/Code/herdr-todo && make link
```

Open it with the **Todo: show my list** action, or from the shell:

```sh
herdr plugin action invoke swmcc.todo.show
```

### Shortcuts

Add these to `~/.config/herdr/config.toml`, then run `herdr server reload-config`:

```toml
[[keys.command]]
key = "prefix+d"
type = "plugin_action"
command = "swmcc.todo.show"
description = "my to-do list"

[[keys.command]]
key = "prefix+shift+a"
type = "plugin_action"
command = "swmcc.todo.add"
description = "add a to-do"
```

`prefix d` (for "do") opens the list and `prefix shift+a` adds a task without opening it.
Both keys are free in herdr's default keymap.

## Keys

Both views share the same keys, apart from moving around.

| Key | Does |
| --- | --- |
| `/` | search titles, filtering as you type |
| `l` | search labels: `l` then `dev low` finds tasks with both |
| `Esc` or `⏎` | while searching: stop and keep the filter |
| `c` | clear the filter |
| `h` / `s` / `w` / `a` | 🏠 home, 🦍 SkillfulGorilla, 🏢 work, or all |
| `v` | swap between the list and the cards |
| `n` | add a task |
| `x` | mark the selected task done (asks for an optional note) |
| `o` | open the selected task in the browser |
| `r` | refresh now |
| `q` / `Esc` | close the popup (`ctrl-c` always works) |

**List:** arrows move, `space` or `⏎` shows or hides the details pane.

**Cards:** arrows move between cards, `PgUp` and `PgDn` turn pages, and `⏎` opens the
whole task with its comments.

While searching, letters go into the search box, so press `Esc` before using a command key.

### Adding a task

`n` (or `prefix shift+a`) asks three things:

1. **What needs doing?** The title.
2. **Home, SkillfulGorilla or work?** `h`, `s` or `w`.
3. **Labels.** A list of every label as a coloured pill, with its description. Type to
   search, `tab` to pick as many as you like, `⏎` to add, `Esc` for no labels and `ctrl-c`
   to cancel the whole add.

## Settings

| Variable | Default | Does |
| --- | --- | --- |
| `TODO_REFRESH` | `60` | seconds between refreshes while the popup is open |
| `TODO_REPO` | `swmcc/todo` | the repo the `todo` CLI reads (passed straight through) |

## How it works

The plugin is a few POSIX `sh` scripts. It never calls GitHub itself: the `todo` CLI does,
and the plugin wraps it.

```text
herdr-plugin.toml   the popups (list, add) and the actions
bin/todo-pane       the list: fzf, plus the shared fetch, ranking and formatting
bin/todo-cards      the cards: draws the 3×3 grid and reads keys itself
bin/todo-add        title, side and label picker, then todo home|biz|work
bin/todo-done       optional note, then todo done N
bin/todo-cli        finds the todo CLI (PATH, then ~/Code/todo/bin/todo)
```

- `todo ls --tsv` gives one tab-separated line per open task: number, side, title, labels
  with their colours, and body. The plugin keeps the last one in herdr's plugin state
  directory, so the popup opens instantly and still shows something when you're offline.
- herdr plugins can't run background daemons, so the popup does its own refreshing: fzf's
  `every()` event in the list, and a one-second key timeout in the cards.
- fzf can only draw one column, so the cards are their own small screen. They share the
  cache, the ranking and the keys with the list.

## Troubleshooting

- **The popup ate my herdr keys.** A popup gets every key, herdr's prefix included. `q`,
  `Esc` or `ctrl-c` always closes it.
- **A task I just added isn't there.** The list refreshes in the background when the popup
  opens, so give it a second. `r` refreshes straight away.
- **"📴 offline, retrying"** in the title bar means `gh` couldn't reach GitHub. The last
  list stays up and the popup tries again at the next refresh.
- **Something else.** `herdr plugin log swmcc.todo` shows what the actions ran and printed.

## Development

```sh
make link    # link this checkout into herdr
make lint    # shellcheck bin/*
make unlink
```

Edits take effect the next time the popup opens, with no rebuild or reload needed.
