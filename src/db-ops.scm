(define-module (db-ops)
  #:use-module (utils)
  #:use-module (ui)
  #:use-module (srfi srfi-1)
  #:use-module ((sqlite3) #:prefix db:)
  #:use-module (ice-9 textual-ports)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 control))
;;str -> check -> map -> insert
;;                    -> alert pop up
;; all the errors are emited in the checking step
(define popup (lambda a (display a) (newline))
					;(make-parameter (lambda a (apply format (append (current-output-port) a))))
  )
(define-syntax-rule (&cmp func func* ...)
  (lambda (arg) (and (func arg) (func* arg) ...)))
(define (nem? str) (> (string-length str) 0))
(define (unq? str) #t)
(define (rl? n) (and (real? n) (positive? n)))
(define (in? n) (exact? n) (positive? n))
(define prk? (&cmp in? unq?))
(define (string->unix-time) 0)
(define-public type-checking `(("books"	    .(later ,(&cmp nem? unq?) ,unq? ,unq?
						    ,(&cmp nem? unq?) ,(&cmp nem? unq?)
						    ,nem?))
			       ("customers" .(later ,in?  ,nem?  ,nem? ,nem? ,in? ,in?))
			       ("sales"     .(later ,nem? ,nem? ,rl? ,nem?))
			       ("history"   .(later ,nem? ,nem? ,nem? ,in?))))
(define-public type-mapping `(("books"	   .(,identity ,identity ,identity ,identity ,identity ,identity))
			      ("customers" .(,identity ,identity ,identity ,identity ,identity ,identity))
			      ("sales"	   .(,identity ,identity ,identity ,string->number ,identity))
			      ("history"   .())))
(define-public (type-check name-space args)
  (call/ec (lambda (esc)
	     (for-each (lambda (pred input) (when (not (pred input)) input) #t)
		       (cdr (assoc-ref  type-checking name-space))
		       args))))
(define-public (type-map name-space args)
  (map (lambda (-> arg) (-> arg))
       (assoc-ref type-mapping name-space)
       args))

(define-public db-name "../db/bs.db3")
(define-public create-sql "../db/creat_table.sql")
(define-public flags   (logior db:SQLITE_OPEN_CREATE))
(define-public (gen/open-db)
  (cond
   [(file-exists? db-name) (db:sqlite-open db-name)]
   [else (let ([db (db:sqlite-open db-name)]) (db:sqlite-exec db (call-with-input-file create-sql get-string-all)))]))
(define db (gen/open-db))
(define (close-db) (db:sqlite-close db))
(define (make-params n)
  (cond
   [(zero? (1- n)) "?"]
   [else (string-append (string #\? #\, #\space)
			(make-params (1- n)))]))
(define (insert t-name . args)
  (call/ec (lambda (return)
	     (when (not (type-check t-name args)) ((popup) "wrong args ~a" args) (return #f))
	     (let*-log ([args (type-map t-name args)]
			[fields       (assoc-ref input-desc t-name)]
			[fileds-str   (string-append (fold (lambda (a b) (format #f "~a, ~a" a b))
							   ""  (reverse (take fields (1- (length fields)))))
						     (car (drop fields (1- (length fields)))))]
			[param        (make-params (length fields))]
			[ins-template (apply format `(#f "INSERT INTO ~a(~a) VALUES (~a);" ,t-name ,fileds-str ,param))]
			[stmt (db:sqlite-prepare db ins-template)])
		       (for-each (lambda (key value) (db:sqlite-bind stmt key value)) (iota (length args) 1) args)
		       (db:sqlite-step stmt)
		       (db:sqlite-finalize stmt)))))
(define (select t-name count . args)
  (let* ([fields          (assoc-ref input-desc t-name)]
	 [param           (string-append (string-append (fold (lambda (a b) (format #f "?, ~a" b)) "" (cdr fields))) "?")]
	 [select-template (apply format `(#f "SELECT ~a FROM ~a;" ,param ,t-name ))]
	 [stmt            (db:sqlite-prepare db select-template #:cache? #t)])
    (for-each (lambda (key value)(db:sqlite-bind stmt key value)) (iota (length args)) args)
    (values (db:sqlite-fold (lambda (a b)
			      (cons a b))
			    '() stmt)
	    (db:sqlite-finalize stmt))))
(define (insert-book isbn title writer publisher price)
  (define (isbn-hash str) (hash str (inexact->exact 1e9)))
  (insert "books" isbn (isbn-hash isbn) title writer publisher price))
(define (insert-customer cs-id name surname phone-number dob join-date)
  (insert "customers" cs-id name surname phone-number dob join-date))
(define (insert-sales cs-id sale-id total-price)
  (insert "sales" cs-id sale-id total-price))
(define (insert-sale-dtls id sale-di isbn-h ) 1)
(define-public (add name-space . args)
  (match name-space
    ["books"     (apply insert-book args)]
    ["customers" (apply insert-customer args)]
    ["sales"     (apply insert-sales args)]))
