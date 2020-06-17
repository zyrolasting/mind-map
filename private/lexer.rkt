#lang racket/base

#|
Monitor indentation levels of lines on the fly using Python 3 rules
as summarized here: https://stackoverflow.com/a/25471702/394397

<Quote Antti Haapala>
-- If both number of tabs and number of spaces matches the previous
   line (no matter the order), then this line belongs to the same
   block with the previous line
-- if the number of one of (tabs, spaces) is greater than on the
   previous line and number of the other is at least equal to those
   on the previous line, this is an indented block
-- the tuple (tabs, spaces) matches an indent from a previous block
   - this dedents to that block
-- otherwise an IndentationError or a TabError is raised.
</Quote Antti Haapala>
|#

(provide make-lexer
         (struct-out exn:fail:mind-map:indent))

(require racket/list
         racket/string)

(define (make-lexer)
  (define stack (list (ws-stats 0 0)))
  (define level 0)
  (define lineno 1)
  (λ (line)
    (define-values (next-stack next-level) (find-indentation-level stack level line lineno))
    (set! stack next-stack)
    (set! level next-level)
    (set! lineno (add1 lineno))
    (values next-level (string-trim line))))

(define (find-indentation-level stack level line lineno)
  (define prev (car stack))
  (define leader (regexp-match LEADING-WHITESPACE line))

  (if leader
      (let ([next (make-ws-stats (cadr leader))])
        (cond
          ; Trivial: Indentation did not change.
          [(indentation=? next prev)
           (values stack level)]

          [(indentation>? next prev) ; Indentation increased.
           (values (cons next stack)
                   (add1 level))]

          [else ; Indentation decreased.
           (let ([index
                  (for/or ([i (in-range (length stack))])
                    (and (indentation=? next (list-ref stack i))
                         i))])
             (if index
                 (let ([new-stack (drop stack index)])
                   (values new-stack
                           (sub1 (length new-stack))))
                 (raise-indentation-error lineno)))]))
      (values (list (ws-stats 0 0))
              0)))

(define LEADING-WHITESPACE #px"^(\\s+)");
(define TABS #px"\t");
(define SPACES #px" ");

(struct ws-stats (num-tabs num-spaces) #:transparent)
(struct exn:fail:mind-map:indent exn:fail (line-number))

(define (raise-indentation-error lineno)
  (raise (exn:fail:mind-map:indent
          (format "Indentation error on line ~a" lineno)
          (current-continuation-marks)
          lineno)))

(define (count-matches str patt)
  (length (regexp-match* patt str)))

(define (make-ws-stats ws)
  (ws-stats (count-matches ws TABS)
            (count-matches ws SPACES)))

(define (indentation=? s1 s2)
  (and (= (ws-stats-num-tabs s1) (ws-stats-num-tabs s2))
       (= (ws-stats-num-spaces s1) (ws-stats-num-spaces s2))))

(define (indentation>? s1 s2)
  (or (and (> (ws-stats-num-tabs s1) (ws-stats-num-tabs s2))
           (>= (ws-stats-num-spaces s1) (ws-stats-num-spaces s2)))
      (and (> (ws-stats-num-spaces s1) (ws-stats-num-spaces s2))
           (>= (ws-stats-num-tabs s1) (ws-stats-num-tabs s2)))))
