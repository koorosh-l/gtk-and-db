#! /bin/sh
# -*- mode: scheme; coding: utf-8 -*-
exec guile -e main -s "$0" "$@" 
!#

(add-to-load-path (getenv "PWD"))

(use-modules (ui) (db-ops)
	     (gi) (gi repository) (sqlite3)
	     (sxml simple) (ice-9 pretty-print))

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
	 [inputs  (map (lambda (i)
			 (map (lambda (j)
				(define id (string-append (car i) "-" j "-" "entry"))
				(cons id (builder:get-object builded id)))
			      (assoc-ref input-desc (car i))))
		       input-desc)]
	 [controls 1]
	 [grid-views (map (lambda (elm) (builder:get-object builded (string-append (car elm) "-" "grid-view")))
			  input-desc)])
    (pretty-print inputs)
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
