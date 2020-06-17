#lang racket/base

(provide parse-mind-map)

(require "lexer.rkt")

(define (plant-idea tree level line)
  (if (= level 0)
      (cons (list line) tree)
      (cons (plant-idea (car tree) (sub1 level) line) (cdr tree))))

(define (parse-mind-map in)
  (port-count-lines! in)
  (define get-next (make-lexer))
  (define reversed-parse-tree
    (let loop ([tree null])
      (define-values (lineno colno pos) (port-next-location in))
      (define line (read-line in))
      (cond
        [(eof-object? line) tree]
        [(or (equal? "" line)
             (regexp-match? #px"^\\s*$" line))
         (loop tree)]
        [else
          (let-values ([(level trimmed-line) (get-next line lineno)])
            (loop (plant-idea tree level trimmed-line)))])))
  (reverse/recursive reversed-parse-tree))

(define (reverse/recursive lst)
  (for/list ([el (in-list (reverse lst))])
    (if (list? el)
        (reverse/recursive el)
        el)))

(module+ test
  (require rackunit)
  (test-equal? "A top-level idea can be added trivially"
               (plant-idea null 0 "!")
               '(("!")))

  (test-equal? "A sub-level idea is accumulated within the last-added idea at a higher level"
               (plant-idea '((("i") "H")) 1 "!")
               '((("!") ("i") "H")))

  (test-equal? "Can reverse a list recursively"
               (reverse/recursive '((("!") ("i") "H")))
               '(("H" ("i") ("!")))))
