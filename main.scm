#! /bin/sh
# -*- mode: scheme; coding: utf-8 -*-
exec guile -e main -s "$0" "$@"
!#

(use-modules (gi)
	     (gi repository)
	     (sxml simple)
;;	     (sqlite3)
	     )
(define control-box
  `(object (@ (class "GtkGrid"))
	   (child (object (@ (class "GtkButton"))
			  (property (@ (name "label"))
				    "Add")))
	   (child (object (@ (class "GtkButton"))
			  (poreperty (@ (name "label"))
				     "Remove")))
	   (child (object (@ (class "GtkButton"))
			  (poreperty (@ (name "label" ))
				     "Edit")))
	   (child (object (@ (class "GtkButton"))
			  (poreperty (@ (name "label"))
				     "Complete")))))
(define ui
  `(interface
    (@ (domain "xyz.quasikote"))
    (object
     (@ (class "GtkApplicationWindow") (id "main-window"))
     (property (@ (name "title")) "BS manager")
     (property (@ (name "default-height")) "700")
     (property (@ (name "default-width")) "1000")
     (child
      (object (@ (class "GtkBox") (id "main-view-stack"))
	      (property (@ (name "orientation")) "GTK_ORIENTATION_VERTICAL")
	      (child (object (@ (class "GtkStackSwitcher") (id "switchero"))))
	      (child
	       (object (@ (class "GtkStack"))
		       (child (object (@ (class "GtkStackPage") (id "books"))
				(property (@ (name "name")) "books")
				(property (@ (name "title")) "Books")
				(property (@ (name "child"))
					  (object (@ (class "GtkLabel"))
						  (property (@ (name "label")) "books perhaps")))))
		       (child (object (@ (class "GtkStackPage") (id "customers"))
				(property (@ (name "name")) "customers")
				(property (@ (name "title")) "Customers")
				(property (@ (name "child"))
					  (object (@ (class "GtkLabel"))
						  (property (@ (name "label")) "some customers plz")))))
		       (child (object (@ (class "GtkStackPage") (id "sales"))
				(property (@ (name "name")) "sales")
				(property (@ (name "title")) "Sell")
				(property (@ (name "child"))
					  (object (@ (class "GtkLabel"))
						  (property (@ (name "label")) "buy high sell low")))))
		       (child (object (@ (class "GtkStackPage") (id "history"))
				(property (@ (name "name")) "history")
				(property (@ (name "title")) "History")
				(property (@ (name "child"))
					  (object (@ (class "GtkLabel"))
						  (property (@ (name "label")) "what happend duno"))))))))))))

(define (gen-ui-file file-name sxml)
  (call-with-output-file file-name
    (lambda (p)
      (display "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>" p)
      (sxml->xml sxml p)
      (newline p))))
(gen-ui-file "./bs-ui.xml" ui)
(define cmd (command-line))
(require "Gio" "2.0")
(require "Gtk" "4.0")
(load-by-name "Gio" "Application")
(load-by-name "Gtk" "Application")
(load-by-name "Gtk" "ApplicationWindow")
(load-by-name "Gtk" "ResponseType")
(load-by-name "Gtk" "Builder")

(load-by-name "Gtk" "Window")
(load-by-name "Gtk" "Widget")
(load-by-name "Gtk" "CenterBox")
(load-by-name "Gtk" "Grid")
(load-by-name "Gtk" "Fixed")
(load-by-name "Gtk" "FileDialog")
(load-by-name "Gtk" "FileChooserDialog")

(load-by-name "Gtk" "Button")
(load-by-name "Gtk" "DropDown")
(load-by-name "Gtk" "DropDown")
(load-by-name "Gtk" "Align")
(load-by-name "Gtk" "Orientable")
(load-by-name "Gtk" "Orientation")

(define (show-welcome app)
  (let* ([welcome-window (make <GtkWindow> #:application app #:title "DB Browser" #:default-height 50 #:default-width 50 #:decorated #f)]
	 [box (make <GtkCenterBox>)]
	 [open-button (make <GtkButton> #:label "Open DB File")]
	 [select-button (make <GtkButton> #:label "select")]
	 [file-ch   (make <GtkFileChooserDialog> #:parent welcome-window #:title "select db file")])
    (connect open-button clicked (lambda _
				   (show file-ch)))
    (center-box:set-center-widget box open-button)
    (window:set-child welcome-window box)
    (show welcome-window)))


(define (activate-call-back app)
  (show-welcome app)) 

(define (main cmd)
  (let ([app (make <GtkApplication> #:application-id "xyz.quasikote.www")])
    (connect app activate activate-call-back)
    (run app cmd)))
(exit (main cmd))

