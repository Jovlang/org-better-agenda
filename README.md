# org-better-agenda

Emacs package providing a custom `org-agenda` view with opinionated sorting, highlighting, and faces.

## Features

- **7-day agenda** starting today, with all-day events sorted before timed entries
- **"Must do" section** — tasks with a DEADLINE or SCHEDULED date, sorted by earliest date
- **"When I have time" section** — tasks without any date
- Deadline/scheduled dates shown as human-readable prefixes (e.g. `Deadline: 4 April`)
- Custom faces for timed entries, all-day events, deadline dates, and scheduled dates
- Integrates with `org-modern` for styling
- **Multilingual** — English, Norwegian, Italian, and German built in
- Keybindings in agenda mode: `d` (deadline), `s` (schedule), `\` (set tags), `T` (toggle tags), `L` (cycle language)

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

Affected by this setting:

| Element | `en` | `no` | `it` |
|---|---|---|---|
| Date prefixes | `Deadline: 4 April` | `Frist: 4. april` | `Scadenza: 4 aprile` |
| Scheduled prefix | `Scheduled: 14 April` | `Planlagt: 14. april` | `Pianificato: 14 aprile` |
| Calendar day names | `Wednesday` | `Onsdag` | `Mercoledì` |
| Calendar month names | `April` | `april` | `aprile` |
| Current-time indicator | `◀ now ──────────` | `◀ nå ──────────` | `◀ adesso ──────────` |
| "Must do" header | `Must do` | `Nødvendige gjøremål` | `Da fare` |
| "When I have time" header | `When I have time` | `Når jeg har tid/lyst` | `Quando ho tempo` |

## Keybindings

These are set in `org-agenda-mode-map` when the package loads.

| Key | Command |
|---|---|
| `d` | Set deadline (`org-agenda-deadline`) |
| `s` | Schedule (`org-agenda-schedule`) |
| `\` | Set tags (`org-agenda-set-tags`) |
| `T` | Toggle tag display |
| `L` | Cycle through available languages |

## Recommended colors

These face settings work well with [Everforest](https://github.com/sainnhe/everforest)-style themes:

```emacs-lisp
(with-eval-after-load 'org-modern
  (set-face-attribute 'org-modern-tag          nil :foreground "#abc"))

(with-eval-after-load 'org-agenda
  (set-face-attribute 'org-agenda-date-today   nil :foreground "#E69875" :weight 'bold   :underline nil)
  (set-face-attribute 'org-agenda-date         nil :foreground "#83C092" :weight 'normal)
  (set-face-attribute 'org-agenda-date-weekend nil :foreground "#D699B6" :weight 'normal)
  (set-face-attribute 'org-agenda-structure    nil :foreground "#DBBC7F" :weight 'bold   :height 1.05)
  (set-face-attribute 'org-time-grid           nil :foreground "#3D4F56" :weight 'normal)
  (set-face-attribute 'org-agenda-current-time nil :foreground "#E69875" :weight 'bold)
  (set-face-attribute 'org-upcoming-deadline   nil :foreground "#E67E80" :weight 'normal)
  (set-face-attribute 'org-scheduled-today     nil :foreground "#A7C080" :weight 'normal))

(with-eval-after-load 'org-better-agenda
  (set-face-attribute 'org-better-agenda-time-face           nil :foreground "#7FBBB3" :weight 'bold   :slant 'normal)
  (set-face-attribute 'org-better-agenda-allday-face         nil :foreground "#DBBC7F" :weight 'normal :slant 'italic)
  (set-face-attribute 'org-better-agenda-deadline-date-face  nil :foreground "#E67E80" :weight 'bold)
  (set-face-attribute 'org-better-agenda-scheduled-date-face nil :foreground "#7FBBB3" :weight 'bold))
```

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
