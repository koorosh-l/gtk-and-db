(define-module (db-ops)
  #:use-module ((sqlite3) #:prefix db:))
(define gen-db-stmt
  "")
(define (gen-add table)
  (lambda (db . l)
    (string-append "INSERT INTO " table " (ISBN,title,writer,publisher,price) VALUES ("
		   (apply string-append (cons (car l) (map (lambda (str) (string-append "," str)) (cdr l))))
		   ");")))

(define (add-book db isbn title writer publisher price)
  (sqlite-exec db (string-append "INSERT INTO books (ISBN,title,writer,publisher,price) VALUES (" isbn title writer publisher price ");")))
(define (add-customer db isbn title writer publisher price)
  (sqlite-exec db (string-append "INSERT INTO books (ISBN,title,writer,publisher,price) VALUES (" isbn title writer publisher price ");")))
(define (add-sales db customer-d books total-price date)
  (sqlite-exec db (string-append "INSERT INTO books (ISBN,title,writer,publisher,price) VALUES (" isbn title writer publisher price ");")))
(define remove)
(define edit)
(define compelet)
