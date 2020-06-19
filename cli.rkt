#lang racket/base

(provide DEFAULT-OUTPUT-DIRNAME)

(require racket/cmdline
         racket/file
         racket/path
         racket/string
         file/convertible
         "main.rkt")

; The manual also uses this constant.
(define DEFAULT-OUTPUT-DIRNAME "mind-maps-out")

(module+ main
  (define force? #f)
  (define << printf)
  (define dest-dir (build-path (current-directory) DEFAULT-OUTPUT-DIRNAME))

  (command-line
   #:program "mind-map"
   #:once-each
   [("--dest")
    user-dest-dir
    "Set the output directory"
    (set! dest-dir (read-user-path user-dest-dir))]
   [("-f" "--force")
    "Overwrite output files, if they exist."
    (set! force? #t)]
   [("-q" "--quiet")
    "Suppress messages on STDOUT"
    (set! << void)]
   #:args mind-map-paths

   ; Validate user arguments.
   (when (null? mind-map-paths)
     (eprintf "No mind-maps specified.~n")
     (exit 1))

   (define unreadable
     (for/fold ([dne null])
               ([mm (in-list mind-map-paths)])
       (if (and (file-exists? mm)
                (member 'read (file-or-directory-permissions mm)))
           dne
           (cons mm dne))))

   (unless (null? unreadable)
     (eprintf "These files are not readable:~n~a~n"
              (string-join (reverse (map (λ (p) (format "  ~a" p)) unreadable)) "\n"))
     (exit 1))

   ; Read input files
   (define parse-trees
     (for/list ([mm (in-list mind-map-paths)])
       (cond [(has-lang? mm)
              (<< "Loading Racket module ~a~n" mm)
              (dynamic-require mm 'thoughts)]
             [else
              (<< "Loading text file ~a~n" mm)
              (call-with-input-file mm
                (λ (in) (read-thoughts in)))])))

   ; Write output files
   (make-directory* dest-dir)
   (for ([thoughts (in-list parse-trees)]
         [mm (in-list mind-map-paths)])
     (define output-path (build-path dest-dir (path-replace-extension (file-name-from-path mm) #".svg")))
     (if (or force? (not (file-exists? output-path)))
         (call-with-output-file output-path #:exists 'truncate/replace
           (λ (o) (write-bytes (convert (thoughts->pict thoughts) 'svg-bytes) o)
              (<< "Wrote ~a~n" output-path)))
         (<< "Skipped ~a~n" output-path)))))

(define (has-lang? path)
  (call-with-input-file path
    (λ (in) (regexp-match? #px"^\\s*#lang\\s+mind-map\\s+" in))))

(define (read-user-path user-path)
  (define p (string->path user-path))
  (cond [(file-exists? p)
         (eprintf "Expected ~a to be a directory, but it's a file.~n" p)
         (exit 1)]
        [else p]))
