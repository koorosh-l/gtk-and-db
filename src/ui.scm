(define-module (ui)
  #:use-module (sxml simple)
  #:export (input-desc ui ui-xml-str))
(define input-desc
  `(("books"
     .("ISBN" "ISBNHash" "title" "writer" "publisher" "price"))
    ("customers"
     .("cs_id" "name" "surname" "phone_number" "dob" "join_date"))
    ("sales"
     .("cs_id" "sale_id" "total_price" "date"))
    ("history"
     .("all?" "month" "year" "max-records"))))
(define (gen-entry name-space name)
  `(object (@ (class "GtkEntry") (id ,(string-append name-space "-" name "-entry")))
	   (property (@ (name "placeholder-text")) ,name)))
(define (gen-control-box prefix)
  `(object (@ (class "GtkFrame"))
	   (child
	    (object (@ (class "GtkGrid"))
		    (property (@ (name "row-spacing")) 4)
		    (property (@ (name "column-spacing")) 4)
		    (child (object (@ (class "GtkButton") (id ,(string-append prefix "-" "add")))
				   (property (@ (name "label")) "Add")
				   (layout
				    (property (@ (name "column")) 0)
				    (property (@ (name "row"))    0))))
		    (child (object (@ (class "GtkButton") (id ,(string-append prefix "-" "remove")))
				   (property (@ (name "label")) "Remove")
				   (layout
				    (property (@ (name "column")) 1)
				    (property (@ (name "row"))    0))))
		    (child (object (@ (class "GtkButton") (id ,(string-append prefix "-" "edit")))
				   (property (@ (name "label")) "Edit")
				   (layout
				    (property (@ (name "column")) 0)
				    (property (@ (name "row"))    1))))
		    (child (object (@ (class "GtkButton") (id ,(string-append prefix "-" "complete")))
				   (property (@ (name "label")) "Complete")
				   (layout
				    (property (@ (name "column")) 1)
				    (property (@ (name "row"))    1)))))))) ;; checking
(define (gen-input-frame prefix entries)
  `(object (@ (class "GtkFrame"))
	   (child
	    (object (@ (class "GtkBox"))
		    (property (@ (name "orientation")) "GTK_ORIENTATION_HORIZONTAL")
		    (child ))
	    ,(append `(object (@ (class "GtkBox"))
			      (property (@ (name "orientation")) "GTK_ORIENTATION_VERTICAL"))
		     (map (lambda (label)
			    `(child ,(gen-entry prefix label)))
			  entries)))))
(define (gen-left prefix entries)
  `(object (@ (class "GtkBox"))
	   (property (@ (name "orientation")) "GTK_ORIENTATION_VERTICAL")
	   (child ,(gen-input-frame  prefix entries))
	   (child ,(gen-control-box  prefix))))
(define (gen-right prefix)
  `(object (@ (class "GtkFrame"))
	   (child (@ (type "end"))
		  (object (@ (class "GtkGridView") (id ,(string-append prefix "-" "grid-view")))))
	   (property (@ (name "hexpand")) "TRUE")
	   (property (@ (name "vexpand")) "TRUE")
	   (property (@ (name "valign"))  "0")
	   (property (@ (name "halign"))  "0")))
(define (make-page prefix)
  `(object (@ (class "GtkCenterBox"))
	   (property (@ (name "orientation")) "GTK_ORIENTATION_HORIZONTAL")
	   (child (@ (type "start"))
		  ,(gen-left prefix (assoc-ref input-desc prefix)))
	   (child (@ (type "end"))
		  ,(gen-right prefix))))
(define (make-tab  title id child)
  `(object (@ (class "GtkStackPage") (id ,id))
	   (property (@ (name "name"))  ,title)
	   (property (@ (name "title")) ,title)
	   (property (@ (name "child")) ,child)))

(define (exclude sym l) (filter (lambda (a) (equal? a sym)) l))

(define ui
  `(interface
    (@ (domain "xyz.quasikote"))
    (object
     (@ (class "GtkApplicationWindow") (id "main-window"))
     (property (@ (name "title")) "BS manager")
     (property (@ (name "default-height")) "300")
     (property (@ (name "default-width")) "600")
     (child
      (object (@ (class "GtkBox") (id "main-view-stack"))
	      (property (@ (name "orientation")) "GTK_ORIENTATION_VERTICAL")
	      (child (object (@ (class "GtkStackSwitcher") (id "switchero"))))
	      (child ,(append
		       `(object (@ (class "GtkStack") (id "stacked")))
		       (map (lambda (i) `(child ,(make-tab (string-capitalize (car i)) (car i) (make-page (car i)))))
			    input-desc))))))))

(define ui-xml-str
  (call-with-output-string
    (lambda (p)
      (sxml->xml ui p))))
