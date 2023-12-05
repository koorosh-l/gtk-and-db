#! /bin/sh
# -*- mode: scheme; coding: utf-8 -*-
exec guile -e main -s "$0" "$@"
!#

(use-modules (system repl server)
	     (gi) (gi repository)
	     (sxml simple) (sqlite3)
	     (ice-9 pretty-print))
(when (file-exists? "./guile.sock")
  (delete-file "./guile.sock"))
(run-server (make-unix-domain-server-socket #:path "./guile.sock"))
