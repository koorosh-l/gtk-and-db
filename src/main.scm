#! /bin/sh
# -*- mode: scheme; coding: utf-8 -*-
exec guile -e main -s "$0" "$@" 
!#

(add-to-load-path (getenv "PWD"))
(use-modules (ui) (db-ops)
	     (gi) (gi repository) (sqlite3)
	     (sxml simple) (ice-9 pretty-print)
	     (ice-9 match))
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
(load-by-name "Gtk" "Entry")
(load-by-name "Gtk" "StackSwitcher")
(load-by-name "Gtk" "EntryBuffer")

(define (get-control builded name-space op)
  (builder:get-object builded (format #f "~a-~a" name-space op)))
(define (button-callback name-space name btn)
  ;; (match name
  ;;   ["add" (lambda (a)
  ;; 	     (insert ))]
  ;;   ["remove"]
  ;;   ["edit"]
  ;;   ["complete" ])
  (lambda a (display (list name-space name btn)) (newline)))
(define (get-entries name-space) name-space)
(define (controls-forech proc builded)
  (for-each (lambda (name-space)
	      (for-each (lambda (name)
			  (proc (list (car name-space) name (get-object builded (format #f "~a-~a" (car name-space) name)))))
			'("add" "remove" "edit" "complete")))
	    input-desc))

(define (gtk-main app)
  (let* ([builded     (builder:new-from-string ui-xml-str (string-length ui-xml-str))]
	 [main-window (builder:get-object builded "main-window")]
	 [bs-stack    (builder:get-object builded "stacked")]
	 [bs-switcher (builder:get-object builded "switchero")]
	 [inputs  (map (lambda (i)
			 (map (lambda (j)
				(define id (string-append (car i) "-" j "-" "entry"))
				(cons id (builder:get-object builded id)))
			      (assoc-ref input-desc (car i))))
		       input-desc)]
	 [grid-views (map (lambda (elm) (builder:get-object builded (string-append (car elm) "-" "grid-view")))
			  input-desc)])
    (controls-forech (lambda (btn) (display btn) (newline)
			(match btn
			  [(name-space name button)
			   1]))
		     builded)
    (stack-switcher:set-stack bs-switcher bs-stack)
    (window:set-application main-window app)
    (show main-window)
    (connect  (get-control builded "books" "add") clicked  (lambda a (display a) (newline) (destroy main-window)))))
(define (activate-call-back app)
  (gtk-main app)) 
(define (main cmd)
  (let ([app (make <GtkApplication> #:application-id "xyz.quasikote.www")])
    (connect app activate activate-call-back)
    (run app )))
(exit (main (command-line)))
