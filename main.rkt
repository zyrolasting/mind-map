#lang racket/base

(provide read-thoughts
         thoughts->pict
         in-thoughts
         thoughts->digraph-data
         (struct-out exn:fail:mind-map:indent))

(require racket/format
         racket/list
         racket/generator
         racket/sequence
         net/url
         graphviz
         "private/lexer.rkt"
         "private/parser.rkt")

(define (in-thoughts thoughts)
  (define count!
    (let ([i -1]) (λ () (begin (set! i (add1 i)) i))))

  (define (visit parent-name parent-label child)
    (define child-name (count!))
    (define child-label (car child))
    (yield parent-name parent-label child-name child-label)
    (for ([grandchild (in-list (cdr child))])
      (visit child-name child-label grandchild)))

  (in-generator #:arity 4
   (let loop ([next thoughts])
     (if (null? next)
         (void)
         (begin (visit #f #f (car next))
                (loop (cdr next)))))))

(define (thoughts->vertex-defns thoughts)
  (for/list ([(parent-name parent-label child-name child-label)
              (in-thoughts thoughts)])
    (cons child-name child-label)))

(define (thoughts->edge-defns thoughts)
  (for/fold ([defs null])
            ([(parent-name parent-label child-name child-label)
              (in-thoughts thoughts)])
    (if parent-name
        (cons (cons parent-name child-name)
              defs)
        defs)))

(define (thoughts->digraph-data thoughts)
  (values (thoughts->vertex-defns thoughts)
          (thoughts->edge-defns thoughts)))

(define (thoughts->pict thoughts)
  (define-values (V E) (thoughts->digraph-data thoughts))
  (digraph->pict
   (make-digraph
    (append (map (λ (vpair) `(,(~v (car vpair)) #:label ,(cdr vpair))) V)
            (map (λ (vpair) `(edge (,(~v (car vpair)) ,(~v (cdr vpair))))) E)))))

(define (read-thoughts in)
  (parse-mind-map
   (if (string? in)
       (open-input-string in)
       in)))

(module+ reader
  (provide (rename-out [-read read]
                       [-read-syntax read-syntax]))

  (define (-read in)
    (syntax->datum (-read-syntax #f in)))

  (define (-read-syntax src in)
    (with-syntax ([parse-tree (parse-mind-map in)])
      #'(module mind-map-module racket/base
          (require mind-map)
          (provide thoughts)
          (define thoughts 'parse-tree)))))
