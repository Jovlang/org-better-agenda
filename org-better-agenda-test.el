;;; org-better-agenda-test.el --- ERT tests for org-better-agenda -*- lexical-binding: t; -*-

;;; Commentary:
;; Run with: emacs -batch -L . -l org-better-agenda-test.el -f ert-run-tests-batch-and-exit

;;; Code:

(require 'cl-lib)
(require 'ert)
(require 'org)
(require 'org-better-agenda)

;;; Helpers

(defun ora-test--make-agenda-entry (&optional time-of-day)
  "Make a minimal agenda entry string, optionally with TIME-OF-DAY property."
  (let ((s (copy-sequence "Task title")))
    (when time-of-day
      (put-text-property 0 1 'time-of-day time-of-day s))
    s))

(defun ora-test--make-dated-entry (marker)
  "Make an agenda entry string carrying MARKER as `org-marker'."
  (let ((s (copy-sequence "Task title")))
    (put-text-property 0 1 'org-marker marker s)
    s))

(defmacro ora-test--with-org-entry (content &rest body)
  "Run BODY in a temp org buffer with CONTENT, point at the first heading.
The buffer is killed on exit; do not capture markers from this macro."
  (declare (indent 1))
  `(with-temp-buffer
     (org-mode)
     (insert ,content)
     (goto-char (point-min))
     ,@body))

(defmacro ora-test--with-live-org-buffers (bindings &rest body)
  "Bind (VAR CONTENT) pairs to live markers, run BODY, then kill the buffers.
Each VAR receives a marker at the first position of a persistent org buffer so
the buffer is not killed out from under the marker during BODY."
  (declare (indent 1))
  (let ((buf-syms (mapcar (lambda (_) (gensym "ora-buf-")) bindings)))
    `(let (,@(mapcar (lambda (bs) `(,bs nil)) buf-syms)
           ,@(mapcar (lambda (b)  `(,(car b) nil)) bindings))
       (unwind-protect
           (progn
             ,@(cl-mapcar
                (lambda (bs b)
                  `(progn
                     (setq ,bs (generate-new-buffer " *ora-test*"))
                     (with-current-buffer ,bs
                       (org-mode)
                       (insert ,(cadr b))
                       (goto-char (point-min))
                       (setq ,(car b) (point-marker)))))
                buf-syms bindings)
             ,@body)
         ,@(mapcar (lambda (bs)
                     `(when (buffer-live-p ,bs) (kill-buffer ,bs)))
                   buf-syms)))))

;;; org-better-agenda-format-date

(ert-deftest ora/format-date/normal ()
  (should (equal (org-better-agenda-format-date "<2026-04-04 Sat>") "4 April")))

(ert-deftest ora/format-date/nil-input ()
  (should (null (org-better-agenda-format-date nil))))

(ert-deftest ora/format-date/january ()
  (should (equal (org-better-agenda-format-date "<2026-01-01 Thu>") "1 January")))

(ert-deftest ora/format-date/december ()
  (should (equal (org-better-agenda-format-date "<2026-12-31 Thu>") "31 December")))

(ert-deftest ora/format-date/malformed-returns-nil ()
  "A bad timestamp must not error — condition-case returns nil."
  (should (null (org-better-agenda-format-date "not-a-date"))))

(ert-deftest ora/format-date/with-time-component ()
  "Timestamps that include a time should still return just the date."
  (should (equal (org-better-agenda-format-date "<2026-06-15 Mon 14:30>") "15 June")))

(ert-deftest ora/format-date/with-repeater ()
  "Repeating timestamps should parse without error."
  (should (equal (org-better-agenda-format-date "<2026-04-04 Sat +1w>") "4 April")))

;;; org-better-agenda-cmp-allday-first

(ert-deftest ora/cmp-allday/both-allday ()
  (should (null (org-better-agenda-cmp-allday-first
                 (ora-test--make-agenda-entry)
                 (ora-test--make-agenda-entry)))))

(ert-deftest ora/cmp-allday/allday-sorts-before-timed ()
  (should (= -1 (org-better-agenda-cmp-allday-first
                 (ora-test--make-agenda-entry nil)
                 (ora-test--make-agenda-entry 1430)))))

(ert-deftest ora/cmp-allday/timed-sorts-after-allday ()
  (should (= 1 (org-better-agenda-cmp-allday-first
                (ora-test--make-agenda-entry 900)
                (ora-test--make-agenda-entry nil)))))

(ert-deftest ora/cmp-allday/both-timed-returns-nil ()
  "Two timed entries: allday comparator defers to other criteria."
  (should (null (org-better-agenda-cmp-allday-first
                 (ora-test--make-agenda-entry 900)
                 (ora-test--make-agenda-entry 1430)))))

;;; org-better-agenda-cmp-earliest-date
;;
;; These tests use `ora-test--with-live-org-buffers' because the comparator
;; dereferences markers into their source buffers.  `with-temp-buffer' kills
;; the buffer on exit, leaving dead markers before the assertion runs.

(ert-deftest ora/cmp-date/earlier-deadline-sorts-first ()
  (ora-test--with-live-org-buffers
      ((ma "* Task A\nDEADLINE: <2026-01-01 Thu>\n")
       (mb "* Task B\nDEADLINE: <2026-06-01 Mon>\n"))
    (let ((a (ora-test--make-dated-entry ma))
          (b (ora-test--make-dated-entry mb)))
      (should (= -1 (org-better-agenda-cmp-earliest-date a b)))
      (should (=  1 (org-better-agenda-cmp-earliest-date b a))))))

(ert-deftest ora/cmp-date/same-date-returns-nil ()
  (ora-test--with-live-org-buffers
      ((ma "* Task A\nDEADLINE: <2026-04-04 Sat>\n")
       (mb "* Task B\nDEADLINE: <2026-04-04 Sat>\n"))
    (should (null (org-better-agenda-cmp-earliest-date
                   (ora-test--make-dated-entry ma)
                   (ora-test--make-dated-entry mb))))))

(ert-deftest ora/cmp-date/dated-sorts-before-undated ()
  (ora-test--with-live-org-buffers
      ((ma "* Task A\nDEADLINE: <2026-04-04 Sat>\n")
       (mb "* Task B\n"))
    (let ((a (ora-test--make-dated-entry ma))
          (b (ora-test--make-dated-entry mb)))
      (should (= -1 (org-better-agenda-cmp-earliest-date a b)))
      (should (=  1 (org-better-agenda-cmp-earliest-date b a))))))

(ert-deftest ora/cmp-date/both-undated-returns-nil ()
  (ora-test--with-live-org-buffers
      ((ma "* Task A\n")
       (mb "* Task B\n"))
    (should (null (org-better-agenda-cmp-earliest-date
                   (ora-test--make-dated-entry ma)
                   (ora-test--make-dated-entry mb))))))

(ert-deftest ora/cmp-date/scheduled-used-when-no-deadline ()
  (ora-test--with-live-org-buffers
      ((ma "* Task A\nSCHEDULED: <2026-03-01 Sun>\n")
       (mb "* Task B\nDEADLINE: <2026-05-01 Fri>\n"))
    (should (= -1 (org-better-agenda-cmp-earliest-date
                   (ora-test--make-dated-entry ma)
                   (ora-test--make-dated-entry mb))))))

(ert-deftest ora/cmp-date/uses-earliest-of-deadline-and-scheduled ()
  "When both DEADLINE and SCHEDULED are set, the earlier one wins."
  (ora-test--with-live-org-buffers
      ;; A: scheduled Feb 1, deadline Apr 1 → effective date Feb 1
      ((ma "* Task A\nSCHEDULED: <2026-02-01 Sun>\nDEADLINE: <2026-04-01 Wed>\n")
       ;; B: deadline Mar 1
       (mb "* Task B\nDEADLINE: <2026-03-01 Sun>\n"))
    ;; Feb 1 < Mar 1, so A sorts before B
    (should (= -1 (org-better-agenda-cmp-earliest-date
                   (ora-test--make-dated-entry ma)
                   (ora-test--make-dated-entry mb))))))

(ert-deftest ora/cmp-date/dead-marker-does-not-crash ()
  "A marker whose buffer has been killed must not signal an error."
  (ora-test--with-live-org-buffers
      ((ma "* Task A\nDEADLINE: <2026-04-04 Sat>\n")
       (mb "* Task B\nDEADLINE: <2026-06-01 Mon>\n"))
    ;; Kill A's buffer — ma is now a dead marker
    (kill-buffer (marker-buffer ma))
    ;; A has no resolvable date → treated as undated → B (dated) sorts first
    (should (= 1 (org-better-agenda-cmp-earliest-date
                  (ora-test--make-dated-entry ma)
                  (ora-test--make-dated-entry mb))))))

;;; org-better-agenda-entry-date-info

(ert-deftest ora/entry-date-info/deadline-only ()
  (ora-test--with-org-entry "* Task\nDEADLINE: <2026-04-04 Sat>\n"
    (should (equal (org-better-agenda-entry-date-info) "Deadline: 4 April"))))

(ert-deftest ora/entry-date-info/scheduled-only ()
  (ora-test--with-org-entry "* Task\nSCHEDULED: <2026-06-15 Mon>\n"
    (should (equal (org-better-agenda-entry-date-info) "Scheduled: 15 June"))))

(ert-deftest ora/entry-date-info/both ()
  (ora-test--with-org-entry
      "* Task\nDEADLINE: <2026-04-04 Sat> SCHEDULED: <2026-03-01 Sun>\n"
    (should (equal (org-better-agenda-entry-date-info)
                   "Deadline: 4 April · Scheduled: 1 March"))))

(ert-deftest ora/entry-date-info/neither ()
  (ora-test--with-org-entry "* Task\n"
    (should (equal (org-better-agenda-entry-date-info) ""))))

(provide 'org-better-agenda-test)
;;; org-better-agenda-test.el ends here
