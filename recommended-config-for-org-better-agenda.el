;;; recommended-config-for-org-better-agenda.el --- Recommended Org-Better-Agenda config -*- lexical-binding: t; -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; Optional but recommended user configuration for org-better-agenda.
;; Load this after org-better-agenda to get opinionated capture templates,
;; keybindings, and Everforest-style colors.
;; Alternatively, copy this into your init file to make changes as you see fit.

;;; Code:

;;; Capture templates

(defun org-better-agenda--read-timestamp (&optional repeater prompt)
  "Prompt for a date and return an active timestamp string.
If REPEATER (e.g. \"+1w\") is non-nil, embed it inside the brackets.
PROMPT overrides the minibuffer prompt string."
  (let ((time (org-read-date nil t nil (or prompt "Date: "))))
    (concat "<" (format-time-string "%Y-%m-%d %a" time)
            (if repeater (concat " " repeater) "")
            ">")))

(defcustom org-better-agenda-inbox-file "~/inbox.org"
  "Path to the org inbox file used by the recommended capture templates."
  :type 'file
  :group 'org-better-agenda)

(add-to-list 'org-agenda-files org-better-agenda-inbox-file)

(with-eval-after-load 'org-capture
  (dolist (template
           `(("t" "Todo" entry
              (file+headline ,org-better-agenda-inbox-file "Tasks")
              "* TODO %?\n")
             ("d" "Todo with deadline" entry
              (file+headline ,org-better-agenda-inbox-file "Tasks")
              (function ,(lambda ()
                           (concat "* TODO %?\nDEADLINE: "
                                   (org-better-agenda--read-timestamp nil "Deadline: ")
                                   "\n"))))
             ("s" "Scheduled todo" entry
              (file+headline ,org-better-agenda-inbox-file "Tasks")
              (function ,(lambda ()
                           (concat "* TODO %?\nSCHEDULED: "
                                   (org-better-agenda--read-timestamp nil "Scheduled: ")
                                   "\n"))))
             ;; Note: DEADLINE and SCHEDULED must be on the same line (separated
             ;; by a space) for org to parse them as planning info.  On separate
             ;; lines, org treats the second as a plain active timestamp in the
             ;; entry body, which breaks agenda rendering.
             ("b" "Scheduled todo with deadline" entry
              (file+headline ,org-better-agenda-inbox-file "Tasks")
              (function ,(lambda ()
                           (let ((deadline (org-better-agenda--read-timestamp nil "Deadline: "))
                                 (scheduled (org-better-agenda--read-timestamp nil "Scheduled: ")))
                             (concat "* TODO %?\nDEADLINE: " deadline
                                     " SCHEDULED: " scheduled "\n")))))
             ("e" "Event" entry
              (file+headline ,org-better-agenda-inbox-file "Events")
              (function ,(lambda ()
                           (concat "* %?\n" (org-better-agenda--read-timestamp nil "Event: ") "\n"))))
             ("w" "Weekly event" entry
              (file+headline ,org-better-agenda-inbox-file "Events")
              (function ,(lambda ()
                           (concat "* %?\n" (org-better-agenda--read-timestamp "+1w" "Weekly: ") "\n"))))
             ("m" "Monthly event" entry
              (file+headline ,org-better-agenda-inbox-file "Events")
              (function ,(lambda ()
                           (concat "* %?\n" (org-better-agenda--read-timestamp "+1m" "Monthly: ") "\n"))))
             ("y" "Yearly event" entry
              (file+headline ,org-better-agenda-inbox-file "Events")
              (function ,(lambda ()
                           (concat "* %?\n" (org-better-agenda--read-timestamp "+1y" "Yearly: ") "\n"))))))
    (add-to-list 'org-capture-templates template t)))

;;; Keybindings

(with-eval-after-load 'org-agenda
  (define-key org-agenda-mode-map (kbd "d") #'org-agenda-deadline)
  (define-key org-agenda-mode-map (kbd "s") #'org-agenda-schedule)
  (define-key org-agenda-mode-map (kbd "e") #'org-agenda-date-prompt)
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
