#!/bin/guile -s
!#
;; (define source-path
;;   1)
;; (display source-path)
(use-modules (ice-9 ftw)
	     (ice-9 regex)
	     (ice-9 textual-ports)
	     (ice-9 binary-ports)
	     (srfi srfi-1)
	     ((rnrs base) :version (6)))

(define (debug str) (display (string-append str "\n")))
(define (orlist lst)
  (fold (lambda (b1 b2) (or b1 b2)) #f lst))
(define openjdk-srcdir "openjdk21-src")
(define wrapper-package-path "com.deltazx.wrapper.")
(define (file-get-lines file)
  (call-with-input-file file
    (lambda (port)
      (unfold (lambda (port) (eof-object? (lookahead-char port)))
	      (lambda (port) (get-line port))
	      (lambda (x) x)
	      port))))
(define (file-put-lines file lst)
  (call-with-output-file file
    (lambda (port)
      (for-each
       (lambda (str) (put-string port (string-append str "\n")))
       lst))))
(define packages
  (let ((lst (file-get-lines
	      "api-packages-paths-for-scheme.list")))
    (assert (not (member "" lst)))
    lst))
(define packages-dotted
  (let ((remove-module-in-path
	 (lambda (str)
	   (regexp-substitute #f
			      (assert (string-match "^([^/]*)/" str))
			      'post)))
	(replace-dot-with-slash
	 (lambda (str)
	   (regexp-substitute/global #f "/" str
				     'pre "." 'post))))
      (map
       (lambda (x) (replace-dot-with-slash
		    (remove-module-in-path x)))
       packages)))
(display packages-dotted)
;; (error #f "bp" packages-dotted)
;; (debug (error "breakpoint"))
(define (patterns)
  (map 
   (lambda (package)
     (string-append
      (regexp-quote
      ;; (regexp-substitute #f (string-match "\\." package)
      ;; 			 'pre "/" 'post)
       package)
      "$"))
   packages))
(define (modify-package-decls-of-file file)
  ;; with input file with output file
  ;; in (define packages ..) there is a mapping file to line list part
  ;; when substituting statements with wildcards show some erroutput
  ;; and first put aside possible unqualified names in the class/inteface decl part
  (debug (string-append "MODIFY " file))
  (file-put-lines file
		  (map (lambda (line)
			 ;; TODO add support for import static statements, and the imported line may be not of <path>.<class>
			 ;; It is possibly <path>.<class>.<member>
			 (cond ((string-match "^import ((static )?)(.*);$" line)
				=> (lambda (match-struct)
				     ;; (debug (string-append
				     ;; 	     "import modified "
				     ;; 	     (match:substring match-struct 1)))
				     (string-append
				      "import " (match:substring match-struct 1)
				      ((lambda (match-struct-2)
					 (if match-struct-2
					     (if (not (member (match:substring match-struct-2 1) packages-dotted))
						 (regexp-substitute #f match-struct-2
								    'pre wrapper-package-path 0 'post)
						 (match:substring match-struct-2 0))
					     (error #f "unrecognized import statement" match-struct)))
				       (string-match
					(string-append
					 "^([[:lower:]][[:alnum:]_\\$]*(\\.[[:lower:]][[:alnum:]_\\$]*)*)\\."
					 "([[:upper:]][[:alnum:]_\\$]*\\.)*"
					 "([[:alpha:]][[:alnum:]_\\$]*\\.)*"
					 "([[:alpha:]][[:alnum:]_\\$]*|\\*) ?$")
					(match:substring match-struct 3)))
				      ";")))
			       ((string-match "^package (.*);$" line)
				=> (lambda (match-struct)
				     ;; (debug (string-append
				     ;; 	     "package modified "
				     ;; 	     (match:substring match-struct 1)))
				     (if (not (member
					  ((lambda (x)
					     (regexp-substitute/global #f " " x 'pre 'post))
					   (match:substring match-struct 1))
					  packages-dotted))
					 (regexp-substitute #f match-struct
							    'pre
							    "package "
							    wrapper-package-path
							    1
							    ";"
							    'post)
					 (match:substring match-struct 0))))
			       (#t line)))
		       (file-get-lines file))))
;; (map (lambda (p) (debug p)) (patterns))
;; (define closure-ftw-proc-for-all-subdirs
;;   (lambda (action)
;;     (lambda (filename statinfo flag)
;;       )))
(define (enter?-dummy name stat result)
  (not (memq name '("." ".."))))
(define (enter?-false name stat result)
  (debug (string-append "enter?-false " name))
  #f)
(define (leaf-dummy path stat result) #t)
(define (leaf-modify-package-decls path stat result)
  (debug (string-append "!!!!!" path)))
(define (modify-package-decls path)
  (debug (string-append "!!!!!" path))
  )
(define (down-dummy path stat result) #t)
(define (down-for-certain-packages path stat result)
  ;; (debug (string-append "down " path "\n"))
  (if (not (orlist (map (lambda (pattern)
			  (string-match pattern (canonicalize-path path)))
			(patterns))))
      (begin
	(debug (string-append "DOWN " path))
	;; (file-system-fold
	;;  enter?-false
	;;  leaf-modify-package-decls
	;;  down-dummy
	;;  up-dummy
	;;  skip-dummy
	;;  error-dummy
	;;  init
	;;  path)
	;;  This does not work because the base dir is also applied enter?-false
	(map
	 (lambda (name)
	   (modify-package-decls-of-file (string-append path "/" name)))
	 (scandir path
		  (lambda (name) (string-match "^[^-].*\\.java$" name)))))))
(define (up-dummy path stat result) #t)
(define (skip-dummy path stat result) #t)
(define (error-dummy path stat errno result)
  (error (strerror errno)))
(define init 0)
;; (error #f "bp")
(map (lambda (subdir)
       (let ((dirpath (string-append
		       openjdk-srcdir
		       file-name-separator-string
		       subdir)))
	 (file-system-fold
	  enter?-dummy
	  leaf-dummy
	  down-for-certain-packages
	  up-dummy
	  skip-dummy
	  error-dummy
	  init
	  dirpath)))
     (scandir openjdk-srcdir (lambda (name)
			       ;; (debug name)
			       (not (or (equal? (basename name) ".")
					(equal? (basename name) ".."))))))
;; (ftw openjdk-srcdir
;;      (lambda ()
;;        (scandir openjdk-srcdir)))
