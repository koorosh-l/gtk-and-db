(define-module (db-ops)
  #:use-module (utils)
  #:use-module (ui)
  #:use-module (srfi srfi-1)
  #:use-module ((sqlite3) #:prefix db:)
  #:use-module (ice-9 textual-ports)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 control))

(define-public db-name "../db/bs.db3")
(define-public create-sql "../db/creat_table.sql")
(define-public flags   (logior db:SQLITE_OPEN_CREATE))
(define-public (gen/open-db)
  (if (file-exists? db-name) (db:sqlite-open db-name)
      (let ([db (db:sqlite-open db-name)])
	(db:sqlite-exec db (call-with-input-file create-sql get-string-all)))))
(define db (gen/open-db))
(define (close-db) (db:sqlite-close db))
(define (make-params n)
  (cond
   [(zero? n) "*"]
   [(zero? (1- n)) "?"]
   [else (string-append (string #\? #\, #\space)
			(make-params (1- n)))]))
(define (insert input-desc 1t-name . args)
  (let*-log ([fields       (assoc-ref input-desc t-name)]
	     [fileds-str   (string-append (fold (lambda (a b) (format #f "~a, ~a" a b))
						""  (reverse (take fields (1- (length fields)))))
					  (car (drop fields (1- (length fields)))))]
	     [param        (make-params (length fields))]
	     [ins-template (apply format `(#f "INSERT INTO ~a(~a) VALUES (~a);" ,t-name ,fileds-str ,param))]
	     [stmt (db:sqlite-prepare db ins-template)])
	    (for-each (lambda (key value) (db:sqlite-bind stmt key value)) (iota (length args) 1) args)
	    (db:sqlite-step stmt)
	    (db:sqlite-finalize stmt)))
(define-public (select t-name count . args)
  (let*-log ([fields          (assoc-ref input-desc t-name)]
	     [param           (make-params (length args))]
	     [select-template (apply format `(#f "SELECT ~a FROM ~a;" ,param ,t-name ))]
	     [stmt            (db:sqlite-prepare db select-template #:cache? #t)])
	    (for-each (lambda (key value) (db:sqlite-bind stmt key value)) (iota (length args)) args)
	    (values (db:sqlite-fold (lambda (a b)
				      (cons a b))
				    '() stmt)
		    (db:sqlite-finalize stmt))))
(define-public (isbn-hash str) (hash str (inexact->exact 1e9)))
(define-public (insert-book isbn title writer publisher price)
  (insert input-desc "books" isbn (isbn-hash isbn) title writer publisher price))
(define-public (insert-customer cs-id name surname phone-number dob join-date)
  (insert input-desc "customers" cs-id name surname phone-number dob join-date))
(define-public (insert-sales cs-id sale-id total-price)
  (insert input-desc "sales" cs-id sale-id total-price))
(define-public (insert-sale-dtls id sale-id isbn-hash price)
  (insert `(("sale_details" .("id" "sale_id" "ISBNhash" "price")))
	  "sales_details" id sale-id isbn-hash price))
(define-public (get-next-id t-name)
  1)
