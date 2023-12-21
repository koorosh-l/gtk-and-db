(define-module (db-ops)
  #:use-module (ui)
  #:use-module (srfi srfi-1)
  #:use-module ((sqlite3) #:prefix db:)
  #:use-module (ice-9 textual-ports)
  #:use-module (ice-9 match))

(define-syntax-rule (do-times count body ...)
  (let loop ([i count] [res (begin body ...)])
    (cond
     [(= i 1) res]
     [else (loop (1- i) (begin body ...))])))

(define-public db-name "./db/bs.db3")
(define-public flags   (logior db:SQLITE_OPEN_CREATE))
(define-public (gen/open-db)
  (cond
   [(file-exists? db-name) (db:sqlite-open db-name)]
   [else (let ([db (db:sqlite-open db-name)])
	   (db:sqlite-exec db (call-with-input-file "./db/creat_table.sql" get-string-all)))]))
(define-public db (gen/open-db))
(define-public (insert t-name . args)
  (let* ([fields       (assoc-ref input-desc t-name)]
	 [fileds-str   (string-append (fold (lambda (a b) (format #f "~a, ~a" a b)) "" (cdr fields)) (car (reverse fields)))]
	 [param        (string-append (string-append (fold (lambda (a b) (format #f "?, ~a" b)) "" (cdr fields))) "?")]
	 [ins-template (apply format `(#f "INSERT INTO ~a(~a) VALUE (~a);" ,t-name ,fileds-str ,param))]
	 [stmt         (db:sqlite-prepare db ins-template #:cache? #t)])
    (for-each (lambda (key value) (db:sqlite-bind stmt key value)) (iota (length args)) args)
    (db:sqlite-step stmt)
    (db:sqlite-finalize stmt)))

(define-public (select t-name count . args)
  (let* ([fields          (assoc-ref input-desc t-name)]
	 [param           (string-append (string-append (fold (lambda (a b) (format #f "?, ~a" b)) "" (cdr fields))) "?")]
	 [select-template (apply format `(#f "SELECT ~a FROM ~a;" ,param ,t-name ))]
	 [stmt            (db:sqlite-prepare db select-template #:cache? #t)])
    (for-each (lambda (key value)(db:sqlite-bind stmt key value)) (iota (length args)) args)
    (values (db:sqlite-fold (lambda (a b)
			      (cons a b))
			    '() stmt)
	    (db:sqlite-finalize stmt))))
