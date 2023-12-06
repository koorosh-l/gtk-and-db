#! /bin/sh
# -*- mode: scheme; coding: utf-8 -*-
exec guile -e main -s "$0" "$@"
!#

(use-modules (gi) (gi repository)
	     (sxml simple) (sqlite3)
	     (ice-9 pretty-print))

(require "Gio" "2.0")
(require "Gtk" "4.0")
(load-by-name "Gio" "Application")
(load-by-name "Gtk" "Application")
(load-by-name "Gtk" "ApplicationWindow")
(load-by-name "Gtk" "Builder")
(load-by-name "Gtk" "Window")
(load-by-name "Gtk" "Widget")
(load-by-name "Gtk" "Button")
(load-by-name "Gtk" "Stack")
(load-by-name "Gtk" "StackSwitcher")

(define control-box
  `(object (@ (class "GtkGrid"))
	   (child (object (@ (class "GtkButton")  (id "add"))
			  (property (@ (name "label")) "Add")
			  (layout
			   (property (@ (name "columns")) 0)
			   (property (@ (name "row"))     0))))
	   
	   (child (object (@ (class "GtkButton")  (id "edit"))
			  (property (@ (name "label")) "Edit")
			  (layout
			   (property (@ (name "columns")) 1)
			   (property (@ (name "row"))     0))))
	   
	   (child (object (@ (class "GtkButton")  (id "remove"))
			  (property (@ (name "label")) "Remove")
			  (layout
			   (property (@ (name "columns")) 2)
			   (property (@ (name "row"))     0))))
	   
	   (child (object (@ (class "GtkButton")  (id "complete"))
			  (property (@ (name "label")) "Complete")
			  (layout
			   (property (@ (name "columns")) 3)
			   (property (@ (name "row"))     0))))))
(define (gen-control-box prefix)
  `(object (@ (class "GtkFrame"))
	   (child
	    (object (@ (class "GtkGrid"))
		    (property (@ (name "row-spacing")) 4)
		    (property (@ (name "column-spacing")) 4)
		    (child (object (@ (class "GtkButton")  (id ,(string-append prefix "add")))
				   (property (@ (name "label")) "Add")
				   (layout
				    (property (@ (name "column")) 0)
				    (property (@ (name "row"))    0))))
		    
		    (child (object (@ (class "GtkButton")  (id ,(string-append prefix "remove")))
				   (property (@ (name "label")) "Remove")
				   (layout
				    (property (@ (name "column")) 1)
				    (property (@ (name "row"))    0))))

		    (child (object (@ (class "GtkButton")  (id ,(string-append prefix "edit")))
				   (property (@ (name "label")) "Edit")
				   (layout
				    (property (@ (name "column")) 0)
				    (property (@ (name "row"))    1))))
		    
		    (child (object (@ (class "GtkButton")  (id ,(string-append prefix "complete")))
				   (property (@ (name "label")) "Complete")
				   (layout
				    (property (@ (name "column")) 1)
				    (property (@ (name "row"))    1))))))))

(define (make-page)
  `(object (@ (class "GtkBox"))
	   (property (@ (name "orientation")) "GTK_ORIENTATION_HORIZANTAL")
	   (child ,(gen-control-box "test-"))
	   (child (object (@ (class "GtkFrame"))
			  (child (object (@ (class "GtkGridView"))))))))


(define (make-tab name title id child)
  (when (symbol? name)  (set! name  (symbol->string name)))
  (when (symbol? id)    (set! id    (symbol->string id)))
  (when (symbol? title) (set! title (symbol->string title)))
  (when (symbol? child) (set! child (symbol->string child)))
  `(object (@ (class "GtkStackPage") (id ,id))
	   (property (@ (name "name")) ,name)
	   (property (@ (name "title")) ,title)
	   (property (@ (name "child"))
		     ,child)))
(define dummy `(object (@ (class "GtkLabel"))
		       (property (@ (name "label")) "dummy widget")))

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
	       (object (@ (class "GtkStack") (id "stacked"))
		       (child ,(make-tab `books1     `Books1     `books1     (make-page)))
		       (child ,(make-tab `books     `Books     `books     (gen-control-box "books-")))
		       (child ,(make-tab `customers `Customers `customers (gen-control-box "customers-")))
		       (child ,(make-tab `sell      `Sell      `sell      (gen-control-box "sell-")))
		       (child ,(make-tab `history   `History   `history   (gen-control-box "history-"))))))))))

(define (gen-ui-file file-name sxml)
  (call-with-output-file file-name
    (lambda (p)
      (display "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>" p)
      (sxml->xml sxml p)
      (newline p))))
(gen-ui-file "./bs-ui.xml" ui)

(define (gtk-main app)
  (let* ([builded     (builder:new-from-file "./bs-ui.xml")]
	 [main-window (builder:get-object builded "main-window")]
	 [bs-stack    (builder:get-object builded "stacked")]
	 [bs-switcher (builder:get-object builded "switchero")]
	 [bs-books-page    (builder:get-object builded "books")]
	 [bs-customer-page (builder:get-object builded "customers")]
	 [bs-sales-page    (builder:get-object builded "sales")]
	 [bs-history-page  (builder:get-object builded "history")])
    (stack-switcher:set-stack bs-switcher bs-stack)
    (window:set-application main-window app)

    (show main-window)))
(define (activate-call-back app)
  (gtk-main app)) 

(define (main cmd)
  (let ([app (make <GtkApplication> #:application-id "xyz.quasikote.www")])
    (connect app activate activate-call-back)
    (run app )))
(exit (main (command-line)))

