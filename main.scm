#! /bin/sh
# -*- mode: scheme; coding: utf-8 -*-
exec guile -e main -s "$0" "$@"
!#

(use-modules (gi)
	     (gi repository)
;;	     (sqlite3)
	     )

(define cmd (command-line))
(require "Gio" "2.0")
(require "Gtk" "4.0")
(load-by-name "Gio" "Application")
(load-by-name "Gtk" "Application")
(load-by-name "Gtk" "ApplicationWindow")
(load-by-name "Gtk" "ResponseType")

(load-by-name "Gtk" "Window")
(load-by-name "Gtk" "Widget")
(load-by-name "Gtk" "CenterBox")
(load-by-name "Gtk" "Grid")
(load-by-name "Gtk" "Fixed")
(load-by-name "Gtk" "FileDialog")
(load-by-name "Gtk" "FileChooserDialog")

(load-by-name "Gtk" "Button")
(load-by-name "Gtk" "DropDown")(load-by-name "Gtk" "DropDown")
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

