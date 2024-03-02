(define-module (book-store)
  #:use-module (ui)
  #:use-module (db-ops)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-19)
  #:use-module (ice-9 match)
  #:use-module (ice-9 control)
  #:use-module (ice-9 pretty-print))
;; the *ids are recvied as strings
;; checks are done here db-ops doesn't implement any polcies
;; argumetns passed to the public api conforms with the data types retrived from ui
;; type-check'n popup
;; constraint-check'n popup
;; type-map should always succeed
(define (r n) (and (real? n) (positive? n)))
(define (i n) (exact? n) (positive? n))
(define s string?)

(define type-checking `(("books"        . (,s ,s ,s ,s ,s))
			("customers"    . (,s ,s ,s ,i ,i))
			("sales"        . (,s ,s ,s ,s ,s))
			("sale_details" . (later ,s ,s ,s ,s))))
(define type-mapping `(("books"
			.(,identity ,identity ,identity ,identity ,string->number))
		       ("customers"
			.(,identity ,identity ,identity ,identity ,identity ,identity))
		       ("sales"
			.(,identity ,identity ,identity))
		       ("sale_details"
			.(,identity ,identity ,identity ,identity))))
(define (type-check popup name-space args)
  (call/ec (lambda (brk)
	     (map (lambda (i f)
		    (let ([res (f i)])
		      (when (not res)
			(popup "~a is not ~a" i f)
			(brk #f))
		      i))
		  args
		  (assoc-ref type-checking name-space)))))
(define (type-map name-space args)
  (map (lambda (-> arg) (-> arg))
       (assoc-ref type-mapping name-space)
       args))
(define parse identity)
(define (make-sale customer-id book-count) 1)

(define-public (add popup name-space . args)
  (type-check (lambda (a) (display a) (newline)) name-space args)
  (let ([res (type-map name-space args)])
    (match name-space
      ["books"         (apply insert-book args)]
      ["customers"     (apply insert-customer args)]
      ["sales"         (apply insert-sales args)]
      ["sales_details" (apply insert-sale-dtls args)])))
