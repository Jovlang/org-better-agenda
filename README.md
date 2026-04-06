# org-real-agenda

A self-contained Emacs package providing a custom `org-agenda` view with opinionated sorting, highlighting, and faces.

## Features

- **7-day agenda** starting today, with all-day events sorted before timed entries
- **"Must do" section** — tasks with a DEADLINE or SCHEDULED date, sorted by earliest date
- **"When I have time" section** — tasks without any date
- Deadline/scheduled dates shown as human-readable prefixes (e.g. `Deadline: 4 April`)
- Custom faces for timed entries, all-day events, deadline dates, and scheduled dates
- Integrates with `org-modern` for styling
- Keybindings in agenda mode: `d` (deadline), `s` (schedule), `\` (set tags)

## Requirements

- Emacs 28+
- [org-mode](https://orgmode.org/)
- [org-modern](https://github.com/minad/org-modern)

## Installation

### Manual

Clone the repo and add it to your load path:

```emacs-lisp
(add-to-list 'load-path "/path/to/org-real-agenda")
(require 'org-real-agenda)
```

### use-package

```emacs-lisp
(use-package org-real-agenda
  :load-path "/path/to/org-real-agenda")
```

## Usage

```
M-x org-real-agenda
```

Or bind it to a key:

```emacs-lisp
(global-set-key (kbd "C-c a") #'org-real-agenda)
```
