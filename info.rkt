#lang info
(define collection "mind-map")
(define deps '("base" "racket-graphviz"))
(define build-deps '("scribble-lib" "racket-doc" "rackunit-lib"))
(define scribblings '(("scribblings/mind-map.scrbl" ())))
(define pkg-desc "Write and render mind maps in Racket")
(define version "0.0")
(define pkg-authors '(sage))
