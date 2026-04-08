# org-better-agenda

A self-contained Emacs package providing a custom `org-agenda` view with opinionated sorting, highlighting, and faces.

## Features

- **7-day agenda** starting today, with all-day events sorted before timed entries
- **"Must do" section** — tasks with a DEADLINE or SCHEDULED date, sorted by earliest date
- **"When I have time" section** — tasks without any date
- Deadline/scheduled dates shown as human-readable prefixes (e.g. `Deadline: 4 April`)
- Custom faces for timed entries, all-day events, deadline dates, and scheduled dates
- Integrates with `org-modern` for styling
- **Multilingual** — English and Norwegian Bokmål built in
- Keybindings in agenda mode: `d` (deadline), `s` (schedule), `\` (set tags), `T` (toggle tags)

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

;; Norwegian Bokmål
(setq org-better-agenda-language 'no)
```

Affected by this setting:

| Element | `en` | `no` |
|---|---|---|
| Date prefixes | `Deadline: 4 April` | `Frist: 4. april` |
| Scheduled prefix | `Scheduled: 14 April` | `Planlagt: 14. april` |
| Calendar day names | `Wednesday` | `Onsdag` |
| Calendar month names | `April` | `april` |
| Current-time indicator | `◀ now ──────────` | `◀ nå ──────────` |
| "Must do" header | `Must do` | `Nødvendige gjøremål` |
| "When I have time" header | `When I have time` | `Når jeg har tid/lyst` |

## Keybindings

These are set in `org-agenda-mode-map` when the package loads.

| Key | Command |
|---|---|
| `d` | Set deadline (`org-agenda-deadline`) |
| `s` | Schedule (`org-agenda-schedule`) |
| `\` | Set tags (`org-agenda-set-tags`) |
| `T` | Toggle tag display and refresh |
