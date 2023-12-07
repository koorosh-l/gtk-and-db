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

(define input-desc `(("dev"       . ("name" "last-name" "dob" "id"));
		     (books     . (ISBN        titl        writer      publisher    price))
		     (customers . (customer-id name        surname     phone-number dob))
		     (sales     . (recipt-id   customer-id books       total-price  date))
		     (history   . (month       year        max-records all?))))

(define dummy `(object (@ (class "GtkLabel"))
		       (property (@ (name "label")) "dummy widget")))
(define (gen-entry label id pos)
  `(object (@ (class "GtkEntry") (id ,id))))

(define (gen-control-box prefix)
  `(object (@ (class "GtkFrame"))
	   (child
	    (object (@ (class "GtkGrid"))
		    (property (@ (name "row-spacing")) 4)
		    (property (@ (name "column-spacing")) 4)
		    (child (object (@ (class "GtkButton") (id ,(string-append prefix "add")))
				   (property (@ (name "label")) "Add")
				   (layout
				    (property (@ (name "column")) 0)
				    (property (@ (name "row"))    0))))
		    (child (object (@ (class "GtkButton") (id ,(string-append prefix "remove")))
				   (property (@ (name "label")) "Remove")
				   (layout
				    (property (@ (name "column")) 1)
				    (property (@ (name "row"))    0))))
		    (child (object (@ (class "GtkButton") (id ,(string-append prefix "edit")))
				   (property (@ (name "label")) "Edit")
				   (layout
				    (property (@ (name "column")) 0)
				    (property (@ (name "row"))    1))))
		    (child (object (@ (class "GtkButton") (id ,(string-append prefix "complete")))
				   (property (@ (name "label")) "Complete")
				   (layout
				    (property (@ (name "column")) 1)
				    (property (@ (name "row"))    1))))))))
(define (gen-input-frame prefix entries)
  `(object (@ (class "GtkFrame"))
	   (child
	    (object (@ (class "GtkBox"))
		    (property (@ (name "orientation")) "GTK_ORIENTATION_HORIZANTAL")
		    (child ))
	    ,(append `(object (@ (class "GtkBox"))
			      (property (@ (name "orientation")) "GTK_ORIENTATION_VERTICAL"))
		     (map (lambda (label)
			    `(child ,(gen-entry label (string-append prefix label) 0)))
			  entries)))))
(define (gen-grid-view   id)
  `(object (@ (class "GtkListView") (id ,id))
	   (property (@ (name "hexpand")) "TRUE")
	   (property (@ (name "vexpand")) "TRUE")))
(define (gen-left prefix entries)
  `(object (@ (class "GtkBox"))
	   (property (@ (name "orientation")) "GTK_ORIENTATION_VERTICAL")
	   (child ,(gen-input-frame  prefix entries))
	   (child ,(gen-control-box  prefix))))
(define (gen-right prefix)
  `(object (@ (class "GtkFrame"))
	   (child (@ (type "end"))
		  (object (@ (class "GtkGridView") (id (string-append prefix "grid-view")))))
	   (property (@ (name "hexpand")) "TRUE")
	   (property (@ (name "vexpand")) "TRUE")
	   (property (@ (name "valign"))  "0")
	   (property (@ (name "halign"))  "0")))
(define (make-page prefix)
  `(object (@ (class "GtkCenterBox"))
	   (property (@ (name "orientation")) "GTK_ORIENTATION_HORIZANTAL")
	   (child (@ (type "start"))
		  ,(gen-left prefix (assoc-ref input-desc prefix)))
	   
	   (child (@ (type "end"))
		  ,(gen-right prefix))))
(define (make-tab title id child)
  `(object (@ (class "GtkStackPage") (id ,id))
	   (property (@ (name "name"))  ,title)
	   (property (@ (name "title")) ,title)
	   (property (@ (name "child")) ,child)))

(define ui
  `(interface
    (@ (domain "xyz.quasikote"))
    (object
     (@ (class "GtkApplicationWindow") (id "main-window"))
     (property (@ (name "title")) "BS manager")
     (property (@ (name "default-height")) "400")
     (property (@ (name "default-width")) "900")
     (child
      (object (@ (class "GtkBox") (id "main-view-stack"))
	      (property (@ (name "orientation")) "GTK_ORIENTATION_VERTICAL")
	      (child (object (@ (class "GtkStackSwitcher") (id "switchero"))))
	      (child
	       (object (@ (class "GtkStack") (id "stacked"))
		       (child ,(make-tab "DEV"       "dev"       (make-page "dev")))
		       (child ,(make-tab "Books"     "books"     (gen-control-box "asdf")))
		       (child ,(make-tab "Customers" "customers" (gen-control-box "customers-")))
		       (child ,(make-tab "Sell"      "sell"      (gen-control-box "sell-")))
		       (child ,(make-tab "history"   "history"   (gen-control-box "history-"))))))))))

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

