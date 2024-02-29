(define-module (utils)
  #:export (lognret do-times let*-log))

(define-syntax-rule (do-times count body ...)
  (let loop ([i count] [res (begin body ...)])
    (cond
     [(= i 1) res]
     [else (loop (1- i) (begin body ...))])))
(define-syntax lognret
  (syntax-rules ()
    [(_ val) (let () (write val (current-error-port)) (newline (current-error-port)) val)]
    [(_ fmt val) (let ()
		   (write fmt (current-error-port)) (write val (current-error-port))
		      (newline (current-error-port)) val)]))
(define-syntax let*-log
  (syntax-rules ()
    [(_ ([n* v*] ...)
	body ...)
     (let* ([n* (lognret v*)] ...)
       body ...)]))
