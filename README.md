# Org-Better-Agenda

Emacs package providing a custom `org-agenda` view with opinionated sorting, highlighting, and optional keybindings.

## Features

- **7-day agenda** starting today, with all-day events sorted before timed entries
- **"Must do" section** — tasks with a DEADLINE or SCHEDULED date, sorted by earliest date
- **"When I have time" section** — tasks without any date
- Deadline/scheduled dates shown as human-readable prefixes (e.g. `Deadline: 4 April`)
- Custom faces for timed entries, all-day events, deadline dates, and scheduled dates
- Integrates with `org-modern` for styling
- **Multilingual** — English, Norwegian, Italian, and German built in
- Optional recommended config with keybindings, Everforest colors, and capture templates

## Requirements

- Emacs 28+
- [org-mode](https://orgmode.org/)
- [org-modern](https://github.com/minad/org-modern)

## Installation

### Manual

Clone the repo and add it to your load path:

```emacs-lisp
(add-to-list 'load-path "/path/to/org-better-agenda")
(require 'org-better-agenda)
```

### use-package

```emacs-lisp
(use-package org-better-agenda
  :load-path "/path/to/org-better-agenda")
```

## Usage

```
M-x org-better-agenda
```

Or bind it to a key:

```emacs-lisp
(global-set-key (kbd "C-c a") #'org-better-agenda)
```

## Language

Set `org-better-agenda-language` before loading the package (or call
`org-better-agenda-setup` afterwards to apply the change):

```emacs-lisp
;; English (default)
(setq org-better-agenda-language 'en)

;; Norwegian
(setq org-better-agenda-language 'no)

;; Italian
(setq org-better-agenda-language 'it)

;; German
(setq org-better-agenda-language 'de)
```

## Recommended config

`recommended-config-for-org-better-agenda.el` is an optional companion file with opinionated defaults. Load it after the main package:

```emacs-lisp
(require 'recommended-config-for-org-better-agenda)
```

Or with use-package:

```emacs-lisp
(use-package recommended-config-for-org-better-agenda
  :load-path "/path/to/org-better-agenda"
  :after org-better-agenda)
```

Or copy it into your init file to make changes as you see fit.

It provides:

- **Keybindings** in `org-agenda-mode-map`
- **Everforest-style colors** for agenda faces
- **Capture templates** for todos and events

### Keybindings

| Key | Command |
|---|---|
| `d` | Set deadline (`org-agenda-deadline`) |
| `s` | Schedule (`org-agenda-schedule`) |
| `\` | Set tags (`org-agenda-set-tags`) |
| `T` | Toggle tag display |
| `L` | Cycle through available languages |

### Capture templates

Templates are added under two groups:

| Key | Description |
|---|---|
| `tt` | Todo |
| `td` | Todo with deadline |
| `ts` | Scheduled todo |
| `tb` | Todo with deadline and schedule |
| `ee` | Event |
| `er` | Recurring event (weekly) |

Captured entries go to the file set by `org-better-agenda-inbox-file` (default: `~/inbox.org`), which is also added to `org-agenda-files`. Set it before loading the recommended config to use a different path:

```emacs-lisp
(setq org-better-agenda-inbox-file "~/org/inbox.org")
```

### Colors

Face settings are tuned for [Everforest](https://github.com/sainnhe/everforest)-style themes.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
