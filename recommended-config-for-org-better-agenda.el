;;; recommended-config-for-org-better-agenda.el --- Recommended keybindings and colors -*- lexical-binding: t; -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Optional but recommended user configuration for org-better-agenda.
;; Load this after org-better-agenda to get opinionated capture templates,
;; keybindings, and Everforest-style colors.
;; Alternatively, copy this into your init file to make changes as you see fit.

;;; Code:

;;; Capture templates

(defcustom org-better-agenda-inbox-file "~/inbox.org"
  "Path to the org inbox file used by the recommended capture templates."
  :type 'file
  :group 'org-better-agenda)

(add-to-list 'org-agenda-files org-better-agenda-inbox-file)

(with-eval-after-load 'org-capture
  (dolist (template
           `(("t" "Todos")
             ("tt" "Todo" entry
              (file+headline ,org-better-agenda-inbox-file "Tasks")
              "* TODO %?\n")
             ("td" "Todo with deadline" entry
              (file+headline ,org-better-agenda-inbox-file "Tasks")
              "* TODO %?\nDEADLINE: %^t\n")
             ("ts" "Scheduled todo" entry
              (file+headline ,org-better-agenda-inbox-file "Tasks")
              "* TODO %?\nSCHEDULED: %^t\n")
             ;; Note: Org expects DEADLINE before SCHEDULED for correct agenda rendering.
             ("tb" "Scheduled todo with deadline" entry
              (file+headline ,org-better-agenda-inbox-file "Tasks")
              "* TODO %?\nDEADLINE: %^t\nSCHEDULED: %^t\n")

             ("e" "Events")
             ("ee" "Event" entry
              (file+headline ,org-better-agenda-inbox-file "Events")
              "* %?\n%^t\n")
             ("er" "Recurring event" entry
              (file+headline ,org-better-agenda-inbox-file "Events")
              "* %?\n%^t +1w\n")))
    (add-to-list 'org-capture-templates template t)))

;;; Keybindings

(with-eval-after-load 'org-agenda
  (define-key org-agenda-mode-map (kbd "d") #'org-agenda-deadline)
  (define-key org-agenda-mode-map (kbd "s") #'org-agenda-schedule)
  (define-key org-agenda-mode-map (kbd "\\") #'org-agenda-set-tags)
  (define-key org-agenda-mode-map (kbd "T") #'org-better-agenda-toggle-tags)
  (define-key org-agenda-mode-map (kbd "L") #'org-better-agenda-toggle-language))

;;; Everforest-style colors

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
  (set-face-attribute 'org-imminent-deadline   nil :foreground "#E67E80" :weight 'bold)
  (set-face-attribute 'org-scheduled-today     nil :foreground "#A7C080" :weight 'normal))

(with-eval-after-load 'org-better-agenda
  (set-face-attribute 'org-better-agenda-time-face           nil :foreground "#7FBBB3" :weight 'bold   :slant 'normal)
  (set-face-attribute 'org-better-agenda-allday-face         nil :foreground "#DBBC7F" :weight 'normal :slant 'italic)
  (set-face-attribute 'org-better-agenda-deadline-date-face  nil :foreground "#E67E80" :weight 'bold)
  (set-face-attribute 'org-better-agenda-scheduled-date-face nil :foreground "#7FBBB3" :weight 'bold))

(provide 'recommended-config-for-org-better-agenda)
;;; recommended-config-for-org-better-agenda.el ends here
