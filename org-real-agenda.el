;;; org-real-agenda.el --- Custom org-agenda view -*- lexical-binding: t; -*-

;;; Commentary:
;; Self-contained custom agenda view with deadline/scheduled sorting,
;; all-day highlighting, and custom faces.
;; Requires org and org-agenda.  Integrates with org-modern if available.

;;; Code:

(require 'org)
(require 'org-agenda)
(require 'org-modern nil t)             ; soft dependency — used if present

;;; Date formatting

(defconst org-real-agenda-month-names
  ["" "January" "February" "March" "April" "May" "June"
   "July" "August" "September" "October" "November" "December"]
  "Month names for date formatting.")

(defun org-real-agenda-format-date (datestr)
  "Format Org DATESTR like <2026-04-04 Sat> as '4 April'.
Returns nil on any parse error so a bad timestamp never breaks the agenda."
  (when datestr
    (condition-case nil
        (let* ((ts (org-time-string-to-time datestr))
               (day (string-to-number (format-time-string "%d" ts)))
               (month (string-to-number (format-time-string "%m" ts))))
          (format "%d %s" day (aref org-real-agenda-month-names month)))
      (error nil))))

(defun org-real-agenda-entry-date-info ()
  "Return readable DEADLINE/SCHEDULED info for current entry."
  (let* ((deadline (org-entry-get nil "DEADLINE"))
         (scheduled (org-entry-get nil "SCHEDULED"))
         (parts
          (delq nil
                (list
                 (when deadline
                   (format "Deadline: %s" (org-real-agenda-format-date deadline)))
                 (when scheduled
                   (format "Scheduled: %s" (org-real-agenda-format-date scheduled)))))))
    (string-join parts " · ")))

;;; Sorting

(defun org-real-agenda-entry-earliest-date ()
  "Return earliest of DEADLINE and SCHEDULED for current entry, or nil."
  (let* ((deadline (org-entry-get nil "DEADLINE"))
         (scheduled (org-entry-get nil "SCHEDULED"))
         (times (mapcar #'org-time-string-to-time
                        (delq nil (list deadline scheduled)))))
    (when times
      (car (sort times #'time-less-p)))))

(defun org-real-agenda--marker-from-entry (entry)
  "Return Org marker from agenda ENTRY string."
  (or (get-text-property 0 'org-marker entry)
      (get-text-property 0 'org-hd-marker entry)))

(defun org-real-agenda-cmp-earliest-date (a b)
  "Compare agenda entries A and B by earliest relevant date."
  (let ((ma (org-real-agenda--marker-from-entry a))
        (mb (org-real-agenda--marker-from-entry b))
        ta tb)
    (setq ta
          (when (and ma (marker-buffer ma))
            (with-current-buffer (marker-buffer ma)
              (goto-char ma)
              (org-real-agenda-entry-earliest-date))))
    (setq tb
          (when (and mb (marker-buffer mb))
            (with-current-buffer (marker-buffer mb)
              (goto-char mb)
              (org-real-agenda-entry-earliest-date))))
    (cond
     ((and ta tb)
      (cond
       ((time-less-p ta tb) -1)
       ((time-less-p tb ta) 1)
       (t nil)))
     (ta -1)
     (tb 1)
     (t nil))))

(defun org-real-agenda-cmp-allday-first (a b)
  "Sort all-day agenda entries before timed entries."
  (let ((ta (get-text-property 0 'time-of-day a))
        (tb (get-text-property 0 'time-of-day b)))
    (cond
     ((and (null ta) (null tb)) nil)
     ((null ta) -1)
     ((null tb) 1)
     (t nil))))

;;; Agenda display settings and faces

(with-eval-after-load 'org-agenda
  (setq org-agenda-show-all-dates nil
        org-agenda-skip-scheduled-if-done t
        org-agenda-skip-deadline-if-done t
        org-agenda-scheduled-leaders '("" "")
        org-agenda-current-time-string "◀ now ──────────"
        org-agenda-block-separator ?─
        org-agenda-tags-column 45
        org-tags-column 0
        org-agenda-time-grid
        '((daily today require-timed)
          (800 1200 1600 2000)
          "  ·  "
          "────────────────")
        org-agenda-prefix-format
        '((agenda . "  %-12t% s")
          (todo   . " %i ")
          (tags   . " %i %(org-real-agenda-entry-date-info) ")
          (search . " %i ")))

  (define-key org-agenda-mode-map (kbd "d") #'org-agenda-deadline)
  (define-key org-agenda-mode-map (kbd "s") #'org-agenda-schedule)
  (define-key org-agenda-mode-map (kbd "\\") #'org-agenda-set-tags)

  (set-face-attribute 'org-agenda-date-today   nil :inherit 'warning                :foreground nil :weight 'bold   :underline nil)
  (set-face-attribute 'org-agenda-date         nil :inherit 'font-lock-keyword-face  :foreground nil :weight 'normal)
  (set-face-attribute 'org-agenda-date-weekend nil :inherit 'font-lock-constant-face :foreground nil :weight 'normal)
  (set-face-attribute 'org-agenda-structure    nil :inherit 'font-lock-builtin-face  :foreground nil :weight 'bold   :height 1.05)
  (set-face-attribute 'org-time-grid           nil :inherit 'shadow                  :foreground nil :weight 'normal)
  (set-face-attribute 'org-agenda-current-time nil :inherit 'warning                :foreground nil :weight 'bold)
  (set-face-attribute 'org-upcoming-deadline   nil :inherit 'error                   :foreground nil :weight 'normal)
  (set-face-attribute 'org-scheduled-today     nil :inherit 'success                 :foreground nil :weight 'normal))

;;; Custom faces

(defface org-real-agenda-time-face
  '((t :inherit font-lock-type-face :weight bold))
  "Face for timed agenda entries.")

(defface org-real-agenda-allday-face
  '((t :inherit font-lock-string-face :slant italic))
  "Face for all-day agenda entries.")

(defface org-real-agenda-deadline-date-face
  '((t :inherit error :weight bold))
  "Face for deadline dates in custom agenda sections.")

(defface org-real-agenda-scheduled-date-face
  '((t :inherit font-lock-type-face :weight bold))
  "Face for scheduled dates in custom agenda sections.")

;;; Highlighting

(defun org-real-agenda-highlight-times ()
  "Highlight time ranges at the start of agenda lines."
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward
            "^  \\([0-9]\\{2\\}:[0-9]\\{2\\}\\(?:-[0-9]\\{2\\}:[0-9]\\{2\\}\\)?\\)"
            nil t)
      (put-text-property (match-beginning 1) (match-end 1)
                         'face 'org-real-agenda-time-face))))

(defun org-real-agenda-highlight-allday ()
  "Highlight all-day agenda entries.
Uses the `time-of-day' text property rather than layout heuristics."
  (save-excursion
    (goto-char (point-min))
    (while (not (eobp))
      (let ((bol (line-beginning-position)))
        (when (and (eq (get-text-property bol 'org-agenda-type) 'agenda)
                   (null (get-text-property bol 'time-of-day)))
          (put-text-property bol (line-end-position)
                             'face 'org-real-agenda-allday-face)))
      (forward-line 1))))

(defun org-real-agenda-highlight-date-info ()
  "Highlight date parts in 'Deadline:' and 'Scheduled:' agenda prefixes."
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "\\(Deadline:\\) \\([0-9]+ [[:alpha:]]+\\)" nil t)
      (put-text-property (match-beginning 1) (match-end 1) 'face 'default)
      (put-text-property (match-beginning 2) (match-end 2)
                         'face 'org-real-agenda-deadline-date-face)))
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "\\(Scheduled:\\) \\([0-9]+ [[:alpha:]]+\\)" nil t)
      (put-text-property (match-beginning 1) (match-end 1) 'face 'default)
      (put-text-property (match-beginning 2) (match-end 2)
                         'face 'org-real-agenda-scheduled-date-face))))

;;; Finalize hook

(defvar org-real-agenda--active nil
  "Non-nil during `org-real-agenda' view generation.
Guards the finalize hook so styling only applies to this view.")

(defun org-real-agenda-finalize ()
  "Apply custom styling after agenda generation."
  (when org-real-agenda--active
    (when (fboundp 'org-modern-agenda)
      (org-modern-agenda))
    (org-real-agenda-highlight-times)
    (org-real-agenda-highlight-allday)
    (org-real-agenda-highlight-date-info)))

(add-hook 'org-agenda-finalize-hook #'org-real-agenda-finalize)

;;; Custom commands

;; "Must do": tasks with a DEADLINE or SCHEDULED date (either is sufficient).
;; "When I have time": tasks with neither date set.
;; Note: an entry where one property exists and the other is an empty string
;; (degenerate) would fall through both filters; this is not a realistic case.
(add-to-list 'org-agenda-custom-commands
             '("g" "Tasks"
               ((agenda ""
                        ((org-agenda-span 7)
                         (org-agenda-start-day "+0d")
                         (org-agenda-start-on-weekday nil)
                         (org-agenda-overriding-header "")
                         (org-agenda-cmp-user-defined #'org-real-agenda-cmp-allday-first)
                         (org-agenda-sorting-strategy '(user-defined-up time-up))))
                (tags-todo "+DEADLINE<>\"\"|+SCHEDULED<>\"\""
                           ((org-agenda-overriding-header "Must do")
                            (org-agenda-cmp-user-defined #'org-real-agenda-cmp-earliest-date)
                            (org-agenda-sorting-strategy
                             '(user-defined-up priority-down category-keep))))
                (tags-todo "-DEADLINE<>\"\"-SCHEDULED<>\"\""
                           ((org-agenda-overriding-header "When I have time"))))))

;;; Entry point

(defun org-real-agenda ()
  "Open the custom agenda view."
  (interactive)
  (let ((org-real-agenda--active t))
    (org-agenda nil "g")))

(provide 'org-real-agenda)
;;; org-real-agenda.el ends here
