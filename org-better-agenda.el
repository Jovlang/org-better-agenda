;;; org-better-agenda.el --- Custom org-agenda view -*- lexical-binding: t; -*-

;;; Commentary:
;; Self-contained custom agenda view with deadline/scheduled sorting,
;; all-day highlighting, and custom faces.
;; Requires org and org-agenda.  Integrates with org-modern if available.

;;; Code:

(require 'org)
(require 'org-agenda)
(require 'org-modern nil t)             ; soft dependency — used if present

;;; Customization group

(defgroup org-better-agenda nil
  "Customization for org-better-agenda."
  :group 'org-agenda
  :prefix "org-better-agenda-")

;;; Localization

(defconst org-better-agenda--strings
  '((en . ((months        . ["" "January" "February" "March" "April" "May" "June"
                              "July" "August" "September" "October" "November" "December"])
           ;; Sunday = index 0 … Saturday = index 6, matching calendar-day-of-week
           (day-names     . ["Sunday" "Monday" "Tuesday" "Wednesday"
                              "Thursday" "Friday" "Saturday"])
           (deadline-label  . "Deadline")
           (scheduled-label . "Scheduled")
           (now-label       . "now")
           (must-do-header  . "Must do")
           (someday-header  . "When I have time")
           (view-title      . "Tasks")))
    (no . ((months        . ["" "januar" "februar" "mars" "april" "mai" "juni"
                              "juli" "august" "september" "oktober" "november" "desember"])
           (day-names     . ["Søndag" "Mandag" "Tirsdag" "Onsdag"
                              "Torsdag" "Fredag" "Lørdag"])
           (deadline-label  . "Frist")
           (scheduled-label . "Planlagt")
           (now-label       . "nå")
           (must-do-header  . "Nødvendige gjøremål")
           (someday-header  . "Når jeg har tid/lyst")
           (view-title      . "Oppgaver"))))
  "Per-language string table for org-better-agenda.")

(defcustom org-better-agenda-language 'en
  "Language for agenda labels and date formatting.
Supported values: `en' (English), `no' (Norwegian Bokmål).
After changing this interactively, call `org-better-agenda-setup' to apply."
  :type '(choice (const :tag "English" en)
                 (const :tag "Norwegian Bokmål" no))
  :group 'org-better-agenda
  :set (lambda (sym val)
         (set-default sym val)
         (when (featurep 'org-better-agenda)
           (org-better-agenda-setup))))

(defun org-better-agenda--str (key)
  "Return the localized string for KEY in `org-better-agenda-language'."
  (let ((table (alist-get org-better-agenda-language org-better-agenda--strings)))
    (alist-get key table)))

;;; Date formatting

(defun org-better-agenda-format-date (datestr)
  "Format Org DATESTR like <2026-04-04 Sat> as '4 April'.
Returns nil on any parse error so a bad timestamp never breaks the agenda."
  (when datestr
    (condition-case nil
        (let* ((ts (org-time-string-to-time datestr))
               (day (string-to-number (format-time-string "%d" ts)))
               (month (string-to-number (format-time-string "%m" ts))))
          (let ((month-name (aref (org-better-agenda--str 'months) month))
                (sep (if (eq org-better-agenda-language 'en) " " ". ")))
            (format "%d%s%s" day sep month-name)))
      (error nil))))

(defun org-better-agenda-entry-date-info ()
  "Return readable DEADLINE/SCHEDULED info for current entry."
  (let* ((deadline (org-entry-get nil "DEADLINE"))
         (scheduled (org-entry-get nil "SCHEDULED"))
         (dl-label (org-better-agenda--str 'deadline-label))
         (sc-label (org-better-agenda--str 'scheduled-label))
         (parts
          (delq nil
                (list
                 (when deadline
                   (format "%s: %s" dl-label (org-better-agenda-format-date deadline)))
                 (when scheduled
                   (format "%s: %s" sc-label (org-better-agenda-format-date scheduled)))))))
    (string-join parts " · ")))

;;; Agenda date header

(defun org-better-agenda-format-date-header (date)
  "Format DATE for the org-agenda date header using the current language.
DATE is a calendar list (MONTH DAY YEAR).  Mirrors the layout of
`org-agenda-format-date-aligned' but uses localized day and month names."
  (require 'cal-iso)
  (let* ((day         (cadr date))
         (day-of-week (calendar-day-of-week date))
         (month       (car date))
         (year        (nth 2 date))
         (iso-week    (org-days-to-iso-week
                       (calendar-absolute-from-gregorian date)))
         (day-name    (aref (org-better-agenda--str 'day-names) day-of-week))
         (month-name  (aref (org-better-agenda--str 'months) month))
         (weekstring  (if (= day-of-week 1)
                          (format " W%02d" iso-week)
                        ""))
         (day-str     (if (eq org-better-agenda-language 'en)
                          (format "%2d" day)
                        (format "%d." day))))
    (format "%-10s %s %s %4d%s"
            day-name day-str month-name year weekstring)))

;;; Sorting

(defun org-better-agenda-entry-earliest-date ()
  "Return earliest of DEADLINE and SCHEDULED for current entry, or nil."
  (let* ((deadline (org-entry-get nil "DEADLINE"))
         (scheduled (org-entry-get nil "SCHEDULED"))
         (times (mapcar #'org-time-string-to-time
                        (delq nil (list deadline scheduled)))))
    (when times
      (car (sort times #'time-less-p)))))

(defun org-better-agenda--marker-from-entry (entry)
  "Return Org marker from agenda ENTRY string."
  (or (get-text-property 0 'org-marker entry)
      (get-text-property 0 'org-hd-marker entry)))

(defun org-better-agenda-cmp-earliest-date (a b)
  "Compare agenda entries A and B by earliest relevant date."
  (let ((ma (org-better-agenda--marker-from-entry a))
        (mb (org-better-agenda--marker-from-entry b))
        ta tb)
    (setq ta
          (when (and ma (marker-buffer ma))
            (with-current-buffer (marker-buffer ma)
              (goto-char ma)
              (org-better-agenda-entry-earliest-date))))
    (setq tb
          (when (and mb (marker-buffer mb))
            (with-current-buffer (marker-buffer mb)
              (goto-char mb)
              (org-better-agenda-entry-earliest-date))))
    (cond
     ((and ta tb)
      (cond
       ((time-less-p ta tb) -1)
       ((time-less-p tb ta) 1)
       (t nil)))
     (ta -1)
     (tb 1)
     (t nil))))

(defun org-better-agenda-cmp-allday-first (a b)
  "Sort all-day agenda entries before timed entries."
  (let ((ta (get-text-property 0 'time-of-day a))
        (tb (get-text-property 0 'time-of-day b)))
    (cond
     ((and (null ta) (null tb)) nil)
     ((null ta) -1)
     ((null tb) 1)
     (t nil))))

;;; Custom faces

(defface org-better-agenda-time-face
  '((t :inherit font-lock-type-face :weight bold))
  "Face for timed agenda entries.")

(defface org-better-agenda-allday-face
  '((t :inherit font-lock-string-face :slant italic))
  "Face for all-day agenda entries.")

(defface org-better-agenda-deadline-date-face
  '((t :inherit error :weight bold))
  "Face for deadline dates in custom agenda sections.")

(defface org-better-agenda-scheduled-date-face
  '((t :inherit font-lock-type-face :weight bold))
  "Face for scheduled dates in custom agenda sections.")

;;; Highlighting

(defun org-better-agenda-highlight-times ()
  "Highlight time ranges at the start of agenda lines."
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward
            "^  \\([0-9]\\{2\\}:[0-9]\\{2\\}\\(?:-[0-9]\\{2\\}:[0-9]\\{2\\}\\)?\\)"
            nil t)
      (put-text-property (match-beginning 1) (match-end 1)
                         'face 'org-better-agenda-time-face))))

(defun org-better-agenda-highlight-allday ()
  "Highlight all-day agenda entries.
Uses the `time-of-day' text property rather than layout heuristics."
  (save-excursion
    (goto-char (point-min))
    (while (not (eobp))
      (let ((bol (line-beginning-position)))
        (when (and (eq (get-text-property bol 'org-agenda-type) 'agenda)
                   (null (get-text-property bol 'time-of-day))
                   (get-text-property bol 'org-marker))
          (put-text-property bol (line-end-position)
                             'face 'org-better-agenda-allday-face)))
      (forward-line 1))))

(defun org-better-agenda-highlight-date-info ()
  "Highlight date parts in deadline/scheduled agenda prefixes."
  (let ((dl-re (regexp-quote (org-better-agenda--str 'deadline-label)))
        (sc-re (regexp-quote (org-better-agenda--str 'scheduled-label))))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward
              (format "\\(%s:\\) \\([0-9]+\\.? [[:alpha:]]+\\)" dl-re)
              nil t)
        (put-text-property (match-beginning 1) (match-end 1) 'face 'default)
        (put-text-property (match-beginning 2) (match-end 2)
                           'face 'org-better-agenda-deadline-date-face)))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward
              (format "\\(%s:\\) \\([0-9]+\\.? [[:alpha:]]+\\)" sc-re)
              nil t)
        (put-text-property (match-beginning 1) (match-end 1) 'face 'default)
        (put-text-property (match-beginning 2) (match-end 2)
                           'face 'org-better-agenda-scheduled-date-face)))))

;;; Finalize hook

(defun org-better-agenda-finalize ()
  "Apply custom styling after agenda generation."
  (org-better-agenda-highlight-allday)
  (when (fboundp 'org-modern-agenda)
    (org-modern-agenda))
  (org-better-agenda-highlight-times)
  (org-better-agenda-highlight-date-info))

(add-hook 'org-agenda-finalize-hook #'org-better-agenda-finalize)

;;; Tags toggle

(defun org-better-agenda-toggle-tags ()
  "Toggle tag display in the agenda and refresh."
  (interactive)
  (setq org-agenda-remove-tags (not org-agenda-remove-tags))
  (org-agenda-redo-all))

;;; Agenda display settings and keybindings

(with-eval-after-load 'org-agenda
  (setq org-agenda-show-all-dates t
        org-agenda-skip-scheduled-if-done t
        org-agenda-skip-deadline-if-done t
        org-agenda-scheduled-leaders '("" "")
        org-agenda-block-separator ?─
        org-agenda-tags-column 45
        org-tags-column 0
        org-agenda-remove-tags t
        org-agenda-format-date #'org-better-agenda-format-date-header
        org-agenda-time-grid
        '((daily today require-timed)
          (800 1200 1600 2000)
          "  ·  "
          "────────────────")
        org-agenda-prefix-format
        '((agenda . "  %-12t% s")
          (todo   . " %i ")
          (tags   . " %i %(org-better-agenda-entry-date-info) ")
          (search . " %i ")))

  (define-key org-agenda-mode-map (kbd "d") #'org-agenda-deadline)
  (define-key org-agenda-mode-map (kbd "s") #'org-agenda-schedule)
  (define-key org-agenda-mode-map (kbd "\\") #'org-agenda-set-tags)
  (define-key org-agenda-mode-map (kbd "T") #'org-better-agenda-toggle-tags)

  (set-face-attribute 'org-agenda-date-today   nil :inherit 'warning                :foreground nil :weight 'bold   :underline nil)
  (set-face-attribute 'org-agenda-date         nil :inherit 'font-lock-keyword-face  :foreground nil :weight 'normal)
  (set-face-attribute 'org-agenda-date-weekend nil :inherit 'font-lock-constant-face :foreground nil :weight 'normal)
  (set-face-attribute 'org-agenda-structure    nil :inherit 'font-lock-builtin-face  :foreground nil :weight 'bold   :height 1.05)
  (set-face-attribute 'org-time-grid           nil :inherit 'shadow                  :foreground nil :weight 'normal)
  (set-face-attribute 'org-agenda-current-time nil :inherit 'warning                :foreground nil :weight 'bold)
  (set-face-attribute 'org-upcoming-deadline   nil :inherit 'error                   :foreground nil :weight 'normal)
  (set-face-attribute 'org-scheduled-today     nil :inherit 'success                 :foreground nil :weight 'normal))

;;; Custom commands

;; "Must do": tasks with a DEADLINE or SCHEDULED date (either is sufficient).
;; "When I have time": tasks with neither date set.
(defun org-better-agenda--build-command ()
  "Return the \"g\" agenda command spec for the current language."
  `("g" ,(org-better-agenda--str 'view-title)
    ((agenda ""
             ((org-agenda-span 7)
              (org-agenda-start-day "+0d")
              (org-agenda-start-on-weekday nil)
              (org-agenda-overriding-header "")
              (org-agenda-cmp-user-defined #'org-better-agenda-cmp-allday-first)
              (org-agenda-sorting-strategy '(user-defined-up time-up))))
     (tags-todo "+DEADLINE<>\"\"|+SCHEDULED<>\"\""
                ((org-agenda-overriding-header
                  ,(org-better-agenda--str 'must-do-header))
                 (org-agenda-cmp-user-defined
                  #'org-better-agenda-cmp-earliest-date)
                 (org-agenda-sorting-strategy
                  '(user-defined-up priority-down category-keep))))
     (tags-todo "-DEADLINE<>\"\"-SCHEDULED<>\"\""
                ((org-agenda-overriding-header
                  ,(org-better-agenda--str 'someday-header)))))))

(defun org-better-agenda-setup ()
  "Register the \"g\" agenda command and apply language-specific settings.
Call this after changing `org-better-agenda-language' if you want the
command available in the standard org-agenda dispatcher (\\[org-agenda])."
  (setq org-agenda-custom-commands
        (assoc-delete-all "g" org-agenda-custom-commands))
  (add-to-list 'org-agenda-custom-commands
               (org-better-agenda--build-command))
  (setq org-agenda-current-time-string
        (format "◀ %s ──────────" (org-better-agenda--str 'now-label))))

;;; Entry point

(defun org-better-agenda ()
  "Open the custom agenda view."
  (interactive)
  ;; Build the command inline so it always reflects the current language,
  ;; regardless of when setup was last called.
  (let ((org-agenda-custom-commands (list (org-better-agenda--build-command)))
        (org-agenda-current-time-string
         (format "◀ %s ──────────" (org-better-agenda--str 'now-label))))
    (org-agenda nil "g")))

;;; Initialize

(org-better-agenda-setup)

(provide 'org-better-agenda)
;;; org-better-agenda.el ends here
