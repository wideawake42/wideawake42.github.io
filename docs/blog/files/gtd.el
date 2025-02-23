;;; ORG-AGENDA
;; this is all written with gtd flavor

;; tell it what files to look at, in this case, our gtd-related org files
(setq org-agenda-files
      (mapcar 'file-truename
	      (file-expand-wildcards "~/org/gtd/*.org")))

;; make sure to autosave all our gtd-related org buffers after refiling, otherwise we'll have to do it manually
;; Save the corresponding buffers
(defun gtd-save-org-buffers ()
  "Save `org-agenda-files' buffers without user confirmation.
See also `org-save-all-org-buffers'"
  (interactive)
  (message "Saving org-agenda-files buffers...")
  (save-some-buffers t (lambda ()
			 (when (member (buffer-file-name) org-agenda-files)
			   t)))
  (message "Saving org-agenda-files buffers... done"))
;; Add the save function after refile
(advice-add 'org-refile :after
	    (lambda (&rest _)
	      (gtd-save-org-buffers)))

;; adds TODO keywords to indicate different states of doneness/action on an item
;; the separator bar separates states that need action from states that are DONE (need
;; no further action)
(setq org-todo-keywords
      '((sequence "TODO(t)" "NEXT(n)" "STARTED(s)" "WAIT(w)" "SUBMITTED(b)" "|" "DONE(d)" "CANCELLED(c)" "ACCEPTED(a)" "REJECTED(r)")))


;; tells org to log a timestamp when a TODO is put into a DONE state
;; (using a #+startup thing to make it also leave a note with the timestamp for my submissions.org file
(setq org-log-done 'time)


;; don't let Agenda treat scheduled items like TODOs (scheduled means when you want to start working on something)
(setq org-agenda-todo-ignore-scheduled t)
;; the following has been commented out because what if you need a month to do something?
;; (setq org-agenda-todo-ignore-deadlines t)
;; ignore anything with a plain date because those are how you REALLY schedule meetings
(setq org-agenda-todo-ignore-timestamp t)

;; set global Effort options
(customize-set-variable 'org-global-properties
                        '(("Effort_ALL" . "0:05 0:10 0:15 0:20 0:30 0:45 1:00 1:30 2:00 3:00 4:00 5:00 6:00")))

;; set priority options - not about urgency exactly because that's what deadlines are for, but
;; priority A means this is required / no workaround exists / MUST
;; priority B means this is significant impact / workaround would require excessive resources / NEED
;; priority C is default / normal priority - moderate impact / workaround requires some resources / SHOULD
;; priority D means do this before any somedays - minor impact / minimal workaround / COULD
(setq org-highest-priority ?A
      org-default-priority ?C
      org-lowest-priority ?D)


;; set agenda deadline warning days
;; can customize this for a specific thing by putting, e.g., -3d to the deadline timestamp
(setq org-deadline-warning-days 7)


;; I've just changed the prefix length here from the default 12
;; to make enough room for the category 'nextactions' without it cutting into the todo state
(setq org-agenda-prefix-format
      '((agenda . " %i %-14:c %?-5t %12s")
	(todo . " %i %-14:c %-20(truncate-string-to-width (org-format-outline-path (org-get-outline-path)) 20 nil nil t) ")
	(tags . " %i %-14:c")
	(search . " %i %-14:c")))


;; set the sorting of agenda stuff
(setq org-agenda-sorting-strategy
      '((agenda time-up ts-up urgency-down category-up habit-down)
	(todo urgency-down todo-state-up category-up)
	(tags urgency-down category-up)
	(search category-up)))


;; hide specific filetags
;; (setq org-agenda-hide-tags-regexp (regexp-opt '("nextactions" "projects" "tickler")))

;; hide ALL filetags
(setq org-agenda-remove-tags t)


;; Key bindings
(define-key global-map  (kbd "C-c a") 'org-agenda)

;; use edna in order to create triggers/blockers for TODOs
(use-package org-edna
  :config
  (org-edna-mode)
  ;; set Edna to run if the old TODO state is in org-not-done-keywords
  (setq org-edna-from-todo-states 'todo))


;;;; GTD process
;;;;; CAPTURE
;; Capture templates
;; the submissions template is plain type because otherwise it will not accept the second-level heading
(setq org-capture-templates
      `(("i" "Inbox" entry  (file "~/org/gtd/inbox.org")
        ,(concat "\n* %?\n"
                 "/Entered on/ %U\n"""))
	("s" "Submissions" plain (file "~/org/gtd/submissions.org")
	 ,(concat "\n** SUBMITTED what where%?\n"
		  "/Submitted on/ %U\n"""))))

(defun org-capture-inbox ()
     (interactive)
     (call-interactively 'org-store-link)
     (org-capture nil "i"))

(defun org-capture-submissions ()
  (interactive)
  (call-interactively 'org-store-link)
  (org-capture nil "s"))

;; the inbox.org file contains a FILETAGS line which defines a common tag inherited by all entries ("inbox")

;; Use full window for org-capture
(add-hook 'org-capture-mode-hook 'delete-other-windows)


;;keybindings
(define-key global-map            (kbd "C-c c") 'org-capture)
(define-key global-map            (kbd "C-c i") 'org-capture-inbox)
(define-key global-map            (kbd "C-c s") 'org-capture-submissions)

;;;;; CLARIFY / ORGANIZE
;; figure out if it's trash > delete, or >2 min > do it
;; otherwise send to projects, next actions, someday, tickler (schedule first)
;; no waiting for list because WAIT as a status makes more sense in org
;; if it needs to go on a calendar, put it on your proton calendar


;; tell org-mode we want to specify a refile target using the file path and not do it in chunks
(setq org-refile-use-outline-path 'file)
(setq org-outline-path-complete-in-steps 'nil)
;; specify refile target
;; and the level indicates which heading level it can look at; can use maxlevel to specify that it can go up through a certain level
(setq org-refile-targets '(("projects.org" :level 1)
			   ("someday.org" :level 1)
			   ("tickler.org" :level 1)
			   ("nextactions.org" :level 1)
			   ("to-watch.org" :level 1)
			   ("to-read.org" :level 1)
			   ("submissions.org" :level 1)))

(transient-define-prefix ej-org-gtd-refile ()
  "Choose where to refile for inbox processing."
  [("p" "Project" ej-org-gtd-refile-to-projects)
   ("n" "Next Actions" ej-org-gtd-refile-to-nextactions)
   ("t" "Tickler" ej-org-gtd-refile-to-tickler)
   ("s" "Someday" ej-org-gtd-refile-to-someday)
   ("w" "To Watch" ej-org-gtd-refile-to-watch)
   ("r" "To Read" ej-org-gtd-refile-to-read)])

;;keybindings for custom refile
(define-key org-mode-map (kbd "C-c r") 'ej-org-gtd-refile)

(defun ej-org-gtd-refile-to-nextactions ()
  "Refile to nextactions.org and add the NEXT todo state."
  (interactive)
  (call-interactively 'org-set-property "CATEGORY")
  (org-todo "NEXT") ;; change to "NEXT"
  ;; move to correct location
  (org-refile nil nil (list "NewHeadline" "~/org/gtd/nextactions.org")))

(defun ej-org-gtd-refile-to-someday ()
  "Refile to someday.org."
  (interactive)
  (call-interactively 'org-set-property "CATEGORY")
  (org-refile nil nil (list "NewHeadline" "~/org/gtd/someday.org")))

(defun ej-org-gtd-refile-to-tickler ()
  "Check to see if the item is SCHEDULED, and prompt for date if not. Then refile to tickler.org."
  (interactive)
  (call-interactively 'org-set-property "CATEGORY")
  (org-todo "TODO") ;; add TODO
  (let ((scheduled (org-entry-get nil "SCHEDULED"))) ; Get the value of the SCHEDULED property
    (if scheduled
        (org-refile nil nil (list "NewHeadline" "~/org/gtd/tickler.org"))
      (progn
	(org-schedule nil)
	(org-refile nil nil (list "NewHeadline" "~/org/gtd/tickler.org"))))))

(defun ej-org-gtd-refile-to-projects ()
  "Refile to projects.org."
  (interactive)
  (call-interactively 'org-set-property "CATEGORY")
  (org-goto-first-child)
  (org-todo "NEXT") ;; change first child's state to NEXT
  ;; this loop moves you up to the top-level heading before refiling
  (while
      (org-up-heading-safe))
  (org-refile nil nil (list "NewHeadline" "~/org/gtd/projects.org")))

(defun ej-org-gtd-refile-to-watch ()
  "Refile to someday.org."
  (interactive)
  (call-interactively 'org-set-property "CATEGORY")
  (org-todo "TODO")
  (org-refile nil nil (list "NewHeadline" "~/org/gtd/to-watch.org")))

(defun ej-org-gtd-refile-to-read ()
  "Refile to someday.org."
  (interactive)
  (call-interactively 'org-set-property "CATEGORY")
  (org-todo "TODO")
  (org-refile nil nil (list "NewHeadline" "~/org/gtd/to-read.org")))


;;;;;; makes any second-level heading be marked NEXT when the previous one is marked done
(defun insert-trigger-property-into-projects-org ()
  "Insert ':TRIGGER: next-sibling todo!(NEXT)' into the properties drawer of any second-level heading in projects.org."
  (interactive)
  (when (string= (buffer-name) "projects.org")
    (goto-char (point-min))  ;; Go to the beginning of the buffer
    (while (re-search-forward "^\\*\\*" nil t)  ;; Match second-level headings
      (let ((heading-start (match-beginning 0))
	    (heading-end (or
			  ;; Find the next heading's start
			  (save-excursion (re-search-forward "^\\*" nil t))
			  ;; OR return the end of buffer
			  (point-max)
			  )))
        (save-excursion
          ;; Move to the beginning of the heading's properties drawer, if it exists
          (if (re-search-forward "^:PROPERTIES:" heading-end t)
              (progn
                ;; Check if :TRIGGER: already exists in the properties drawer
                (goto-char (match-end 0))
                (unless (re-search-forward "^:TRIGGER:" (save-excursion (re-search-forward "^:END:" heading-end t) (point)) t)
                  ;; If :TRIGGER: doesn't exist, insert it just before :END
                  (insert "\n:TRIGGER: next-sibling todo!(NEXT)")))
            ;; If no properties drawer exists, create one
            (progn
              (goto-char heading-start)
              (end-of-line)
              (insert "\n:PROPERTIES:\n:TRIGGER: next-sibling todo!(NEXT)\n:END:"))))))))


(add-hook 'before-save-hook
          (lambda ()
            (when (string= (buffer-name) "projects.org")
              (insert-trigger-property-into-projects-org))))



;;;;;; auto-archives all the DONE entries after save
(defun ej-auto-archive-done-entries ()
  "Archive DONE items."
  (interactive)
  ;; trying to fix an issue where org-archive-all-done was not being recognized until I searched for it in the help files every time I restarted emacs
  (require 'org-archive)
  (when (or (string= (buffer-name) "projects.org")
	    (string= (buffer-name) "nextactions.org")
	    (string= (buffer-name) "tickler.org")
	    (string= (buffer-name) "to-watch.org")
	    (string= (buffer-name) "to-read.org"))
    ;; remember where I was
    (save-excursion
      (goto-char (point-min))  ;; Go to the beginning of the buffer
      ;; leave the following commented out. it matches first level headings, but means that things without children don't get archived. the tradeoff is that it won't archive any done child in a project unless all its siblings are done
      ;; (while (re-search-forward "^\\* " nil t)
      (org-archive-all-done)))) ;;org-archive-all-done searches within current tree


(add-hook 'before-save-hook
	  (lambda ()
	    (when (or (string= (buffer-name) "projects.org")
		      (string= (buffer-name) "nextactions.org")
		      (string= (buffer-name) "tickler.org")
		      (string= (buffer-name) "to-watch.org")
		      (string= (buffer-name) "to-read.org"))
	      (ej-auto-archive-done-entries))))



;;;;; REFLECT
;; use your dailies and weeklies in org-roam to do your reflect/review

;;;;; ENGAGE
;; call various agenda views to engage with tasks


;;;; SUPER-AGENDA
(use-package org-super-agenda
  :config
  (org-super-agenda-mode)
  ;; resorts items after grouping to preserve their order
  ;;(setq org-super-agenda-keep-order 1)
  ;; straight line separator between agenda blocks
  ;;(setq org-agenda-block-separator 9472)

 ;; (setq org-super-agenda-groups
  ;;	'((:auto-category t))))

  ;; make groups for to-dos
  (setq org-super-agenda-groups
	'(
	  (:name "@home"
		 :and (:tag ("@home") :todo ("NEXT" "STARTED"))
		 :order 9)
          (:name "@study"
		 :and (:tag ("@study") :todo ("NEXT" "STARTED"))
		 :order 6)
	  (:name "@errand"
		 :and (:tag ("@errand") :todo ("NEXT" "STARTED"))
		 :order 10)
	  (:name "@email"
		 :and (:tag ("@email") :todo ("NEXT" "STARTED"))
		 :order 1)
	  (:name "@web"
		 :and (:tag ("@web") :todo ("NEXT" "STARTED"))
		 :order 3)
	  (:name "@call"
		 :and (:tag ("@call") :todo ("NEXT" "STARTED"))
		 :order 2)
	  (:name "@talk"
		 :and (:tag ("@talk") :todo ("NEXT" "STARTED"))
		 :order 4)
	  (:name "@buy"
		 :and (:tag ("@buy") :todo ("NEXT" "STARTED"))
		 :order 5)
	  (:name "@phone"
		 :and (:tag ("@phone") :todo ("NEXT" "STARTED"))
		 :order 7)
	  (:name "@computer"
		 :and (:tag ("@computer") :todo ("NEXT" "STARTED"))
		 :order 8)
	  (:name "Waiting For"
		 :todo ("WAIT")
		 :order 11)
	  (:name "Tickler"
		 :and (:tag ("tickler") :todo ("TODO"))
		 :order 12)
	  (:name "To Watch"
		 :and (:tag ("watch") :todo ("TODO"))
		 :order 13)
	  (:name "To Read"
		 :and (:tag ("read") :todo ("TODO"))
		 :order 14)
	  (:name "Conference submissions"
		 :and (:tag ("conference") :todo ("SUBMITTED"))
		 :order 15)
	  (:name "Journal submissions"
		 :and (:tag ("journal") :todo ("SUBMITTED"))
		 :order 15)
	  (:name "Other submissions"
		 :and (:tag ("submissions") :todo("SUBMITTED"))
		 :order 16)
	  (:discard (:anything))
          )))
