#! /bin/sh
# -*- mode: scheme; coding: utf-8 -*-
exec guile -e main -s "$0" "$@"
!#

(use-modules (system repl server))
(when (file-exists? "./guile.sock")
  (delete-file "./guile.sock"))
(run-server (make-unix-domain-server-socket #:path "./guile.sock"))
