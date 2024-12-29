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
	     (srfi srfi-9)
	     ((rnrs base) :version (6)))

(define (debug str) (display (string-append str "\n")))
(define (linebreaker) (error #f "linebreak"))
(define-syntax var-dump
  (syntax-rules ()
    ((var-dump x) (begin (display (quote x))
			 (display ": ")
			 (display x)))))
;; (linebreaker)
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
(define (port-get-lines port)
  (unfold (lambda (port) (eof-object? (lookahead-char port)))
	  (lambda (port) (get-line port))
	  (lambda (x) x)
	  port))
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
(define all-packages
  (let ((lst (file-get-lines
	      "all-packages.list")))
    (assert (not (member "" lst)))
    lst))
;; (var-dump all-packages)
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
;; (var-dump packages-dotted)
(define all-non-api-packages
  (filter (lambda (x) (not (member x packages-dotted))) all-packages))
;; (var-dump all-non-api-packages)
;; (linebreaker)
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
			       ;; ((string-match
			       ;; 	 (string-append "([[:lower:]][[:alnum:]_\\$]*(\\.[[:lower:]][[:alnum:]_\\$]*)*)\\."
			       ;; 			"([[:upper:]][[:alnum:]_\\$]*\\.)*"
			       ;; 			"([[:alpha:]][[:alnum:]_\\$]*\\.)*"
			       ;; 			"([[:alpha:]][[:alnum:]_\\$]*|\\*) ?$") line)
			       ;; 	=> (lambda (match-struct)
			       ;; 	     (debug "Probable BUG!")
			       ;; 	     (debug (string-append file " line: " line))
			       ;; 	     (if (and (not (member
			       ;; 			    ((lambda (x)
			       ;; 			       (regexp-substitute/global #f " " x 'pre 'post))
			       ;; 			     (match:substring match-struct 1))
			       ;; 			    packages-dotted))
			       ;; 		      (not (string-match "^com.deltazx.wrapper"
			       ;; 					 (match:substring match-struct 1))))
			       ;; 		 (regexp-substitute #f match-struct
			       ;; 				    'pre
			       ;; 				    "package "
			       ;; 				    wrapper-package-path
			       ;; 				    1
			       ;; 				    ";"
			       ;; 				    'post)
			       ;; 		 (match:substring match-struct 0))))
			       (#t line)))
		       (file-get-lines file))))
;; (define (file-translate-lines file proc-string-to-string)
;;   )

;; (define-record-type <token>
;;   (make-token kind value)
;;   token?
;;   (kind token-kind)
;;   (value token-value))

;; Reasons not to use regex:
;; - Lack of regex builder (only with string concatenation)
;; - It is not seen as a tree: there are only submatch numbers
;;   You can still write a wrapper I guess.
;;   e.g. Every nonterminal symbol uses its childern's number of submatches to
;;   calculate their offsets
;; - It's not easy to express some cases: e.g. Java Identifier which has to be not a ReservedKeyword
;;   however it's easy for a general purpose language
;; (define white-space* (make-regexp " +"))
;; (define token* ())
;; (define identifier* )
;; (define java-letter (make-regexp "[A-Za-z$_]"))
;; (define java-letter-or-digit (make-regexp "[A-Za-z$_0-9]"))
;; (define identifier-chars ())
;; TODO let's try the parser method. (although this can actually be done in regexp, but for clean code)


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
(define (down-for-certain-packages scanproc)
  (lambda (path stat result)
    ;; (debug (string-append "down " path "\n"))
    (if (not (orlist (map (lambda (pattern)
			    (string-match pattern (canonicalize-path path)))
			  (patterns))))
	(begin
	  (display (string-append "down " path "\n") (current-error-port))
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
	     (scanproc (string-append path "/" name)))
	   (scandir path
		    (lambda (name) (string-match "^[^-].*\\.java$" name))))))))
(define (up-dummy path stat result) #t)
(define (skip-dummy path stat result) #t)
(define (error-dummy path stat errno result)
  (error (strerror errno)))
(define init 0)
;; (error #f "bp")

;; (map (lambda (subdir)
;;        (let ((dirpath (string-append
;; 		       openjdk-srcdir
;; 		       file-name-separator-string
;; 		       subdir)))
;; 	 (file-system-fold
;; 	  enter?-dummy
;; 	  leaf-dummy
;; 	  (down-for-certain-packages modify-package-decls-of-file)
;; 	  up-dummy
;; 	  skip-dummy
;; 	  error-dummy
;; 	  init
;; 	  dirpath)))
;;      (scandir openjdk-srcdir (lambda (name)
;; 			       ;; (debug name)
;; 			       (not (or (equal? (basename name) ".")
;; 					(equal? (basename name) ".."))))))
;; (linebreaker)

(define (remove-spaces string)
  (regexp-substitute/global #f " " string 'pre 'post))

(define all-non-api-packages-regex
  (let ((ret (let ((replace-dot-with-slashdot
		    (lambda (str)
		      (string-append 
				     (regexp-substitute/global #f "\\." str 'pre "\\." 'post)))))
	       (map
		(lambda (x) (replace-dot-with-slashdot x))
		all-non-api-packages))))
    ret))

;; (var-dump all-non-api-packages-regex)
(define all-non-api-packages-regex
  (fold (lambda (str compiled)
		       (string-append compiled "|" str))
		     (car all-non-api-packages-regex)
		     (cdr all-non-api-packages-regex)))
;; (var-dump all-non-api-packages-regex)
(define all-non-api-packages-started-regex
  (string-append "( |<|\\()(" all-non-api-packages-regex ")"
		 "(\\.[[:upper:]][[:alnum:]_\\$]*)+"
		 "(\\.[[:alpha:]][[:alnum:]_\\$]*\\.)*"))
;; (var-dump all-non-api-packages-started-regex)
(define all-non-api-packages-started-regex-compiled
  (make-regexp all-non-api-packages-started-regex))
(assert (regexp-exec all-non-api-packages-started-regex-compiled " sun.util.spi.Shit"))
;; (linebreaker)

(define (replace-unqualified-names file)
  (let* ((need-change #f)
	(lst
	 (call-with-input-file file
	   (lambda (port)
	     (map-lines-excluding-comments
	      port
	      (lambda (line)
		(let ((match-struct
		       (regexp-exec
			all-non-api-packages-started-regex-compiled
			line)))
		  (if match-struct
		      (let ((match-string-space-removed
			     (remove-spaces
			      ;; (debug match-struct)
			      (match:substring match-struct 0))))
			(set! need-change #t)
			(if (and (not (string-match "^ com\\.deltazx\\.wrapper"
						    match-string-space-removed)))
			    ;; (debug (string-append file " line: " line match-string-space-removed))
			    (let ((replacement 
				   (string-append (match:prefix match-struct)
						  (substring (match:substring match-struct 0) 0 1)
						  "com.deltazx.wrapper."
						  (substring (match:substring match-struct 0) 1)
						  (match:suffix match-struct))))
			      (begin (debug (string-append file " replacement: " replacement))
				     replacement))
			    line))
		      line))))))))
    (if need-change (file-put-lines file lst))))

;; possible methods:
;; let variable bindings key
;;
;; to tackle with this kind of complicated problem
;; procedural style has to be used?
;;
;; Idk whether ~define~ in ~let loop~ is good or not
(define (map-lines-excluding-comments port proc)
  (let ((in-comment #f))
    (fold (lambda (line lines)
	    (let loop ((result lines) (start 0) (match #f) (append-once #f))
	      (define (do-if-in-comment)
		(set! match
		      (string-match "\\*/" line start))
		(if match
		    (begin
		      (set! in-comment #f)
		      (set! start (match:end match 0))
		      (loop result start match append-once))
		    (begin
		      (if (not append-once)
			  (set! result (append lines (list line))))
		      result)))
	      (if in-comment
		  (do-if-in-comment)
		  (begin
		    (if (not append-once)
			(begin
			  (set! append-once #t)
			  (set! result (append lines (list (proc line))))))
		    (set! match
			  (string-match "^([^\"]*(\"\"|\"[^\"]*[^\\\"]\"))*(/\\*|[^\"]*[^/]/\\*)" line start))
		    (if match
			(begin 
			  (set! in-comment #t)
			  (set! start (match:end match 0))
			  (do-if-in-comment))
			result)))))
	  '()
	  (port-get-lines port))))

(define (default-task proc)
  (map (lambda (subdir)
	 (let ((dirpath (string-append
			 openjdk-srcdir
			 file-name-separator-string
			 subdir)))
	   (file-system-fold
	    enter?-dummy
	    leaf-dummy
	    (down-for-certain-packages proc)
	    up-dummy
	    skip-dummy
	    error-dummy
	    init
	    dirpath)))
       (scandir openjdk-srcdir (lambda (name)
				 ;; (debug name)
				 (not (or (equal? (basename name) ".")
					  (equal? (basename name) "..")))))))

(define (find-sealed-class file)
  (call-with-input-file file
    (lambda (port)
      (call/cc
       (lambda (return)
	 (map-lines-excluding-comments
	  port
	  (lambda (line)
	    (let ((match
		      (string-match "public.*sealed.*(class|interface)" line)))
	      (if match
	       (begin
		 (var-dump file)
		 (display " . ")
		 (var-dump line)
		 (newline)
		 (return 0)))))))))))

;; TODO add ~non-sealed~, ~sealed~ w/o ~permits~ elimination
(define (revise-sealed-class file)
  (let ((match
	    (call-with-input-file file
	      (lambda (port)
		(string-match "(public[^\n]*[^-])sealed ([^\n]*(class|interface)[^{]*)permits [^{]*\\{"
			      (get-string-all port))))))
    (if (not match)
	(display (string-append "unsealing failed for file: "
				file
				"\n"))
	(call-with-output-file file
	  (lambda (port)
	    (put-string port
			(regexp-substitute #f
					   match
					   'pre 1 2 "{" 'post))
	    (display (string-append "successfully unsealed file: "
				    file
				    "\n")))))))

(define argv (command-line))
(assert (not (null? (cdr argv))))
(let ((command (cadr argv)))
  (define (first-arg)
    (assert (not (null? (cddr argv))))
    (caddr argv))
  (define (arg-list)
    (cddr argv))
  (cond ((equal? command "replace")
	 (display "replace-unqualified-names\n")
	 (assert (not (null? (cddr argv))))
	 (let ((file (caddr argv)))
	   (assert (access? file (logior R_OK W_OK)))
	   (replace-unqualified-names file)))
	((equal? command "replace-decls")
	 (display "replace-decls-of-file\n")
	 (assert (not (null? (cddr argv))))
	 (let ((file (caddr argv)))
	   (assert (access? file (logior R_OK W_OK)))
	   (modify-package-decls-of-file file)))
	((equal? command "find-sealed") (default-task find-sealed-class))
	((equal? command "unseal")
	 (let ((files (arg-list)))
	   (map (lambda (file)
		  (assert (access? file (logior R_OK W_OK)))
		  (revise-sealed-class file))
		files)))
	((equal? command "default") (default-task replace-unqualified-names))
	((equal? command "packages")
	 (var-dump packages)
	 (newline)
	 (var-dump all-non-api-packages)
	 (newline)
	 (var-dump packages-dotted)
	 (newline))
	(else (error #f command))))

;; (ftw openjdk-srcdir
;;      (lambda ()
;;        (scandir openjdk-srcdir)))
