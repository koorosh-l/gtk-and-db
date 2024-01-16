#! /bin/sh
# -*- mode: scheme; coding: utf-8 -*-
exec guile -e main -s "$0" "$@"
!#

(add-to-load-path (getenv "PWD"))
(use-modules (ui) (db-ops)
	     (gi) (gi repository)
	     (sqlite3)
	     (sxml simple)
	     (ice-9 pretty-print) (ice-9 match))
(define (memoize f)
  (let ([prv (list)]
	[res (list)])
    (lambda x
      (define q (assoc x prv))
      (cond
       [q (display "HIT\n") (cdr q)]
       [else (set! res (apply f x))
	     (set! prv (cons (cons x res) prv))
	     res]))))
(define-syntax-rule (def-mem (name args ...) body ...) (define name (memoize (lambda (args ...) body ...))))
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
(load-by-name "Gtk" "Buildable")

(define ui-obj (make-parameter 'hello))
(def-mem (get-control name-space op)
  (builder:get-object (ui-obj) (format #f "~a-~a" name-space op)))
(define (controls-forech proc)
  (for-each (lambda (name-space)
	      (for-each (lambda (name)
			  (proc `(,(car name-space) ,name
				  ,(get-control (car name-space) name))))
			'("add" "remove" "edit" "complete")))
	    input-desc))
(def-mem (get-entry name-space name)
  (builder:get-object (ui-obj) (format #f "~a-~a-entry" name-space name)))
(define (entries-foreach proc)
  (for-each (lambda (name-space)
	      (for-each (lambda (name)
			  (proc `(,(car name-space) ,name ,(get-entry (car name-space) name))))
			(cdr name-space)))
	    input-desc))
(def-mem (get-text-from-entry entry)
  (let* ([bfr (get-buffer entry)] [str (get-text bfr)])
    (delete-text bfr 0 (string-length str))
    str))
(define (install-add name-space)
  1)

(define (gtk-main app)
  (let* ([builded     (builder:new-from-string (@ (ui) ui-xml-str) (string-length ui-xml-str))]
	 [main-window (builder:get-object builded "main-window")]
	 [bs-stack    (builder:get-object builded "stacked")]
	 [bs-switcher (builder:get-object builded "switchero")])
    (parameterize ([ui-obj builded])
      (install-add "books"))
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
