#lang racket
(require
rackunit
rackunit/text-ui
cpsc411/test-suite/public/v3
"../compiler.rkt"
;; NB: Workaround typo in shipped version of cpsc411-lib
(except-in cpsc411/langs/v3 values-lang-v3)
cpsc411/langs/v2)

(check-equal? (select-instructions '(module (+ 2 2)))
    '(module () (begin (set! tmp.1 2) (set! tmp.1 (+ tmp.1 2)) (halt tmp.1))))

(check-equal? (select-instructions '(module (begin (set! x.1 5) x.1)))
    '(module () (begin 
        (set! x.1 5) 
        (halt x.1))))

(check-equal? (select-instructions '(module (begin (set! x.1 (+ 2 2)) x.1)))
    '(module () (begin 
        (set! x.1 2) 
        (set! x.1 (+ x.1 2)) 
        (halt x.1))))

(check-equal? (select-instructions
    '(module
        (begin
            (set! x.1 2)
            (set! x.2 2)
            (+ x.1 x.2))))
    '(module
    ()
    (begin
        (set! x.1 2)
        (set! x.2 2)
        (set! tmp.2 x.1)
        (set! tmp.2 (+ tmp.2 x.2))
        (halt tmp.2))))

(check-equal? (select-instructions
    '(module
        (begin
            (set! x.1 (* 2 5))
            (set! x.2 2)
            (+ x.1 x.2))))
    '(module
        ()
        (begin
            (set! x.1 2)
            (set! x.1 (* x.1 5))
            (set! x.2 2)
            (set! tmp.3 x.1)
            (set! tmp.3 (+ tmp.3 x.2))
            (halt tmp.3))))

(check-equal? (select-instructions
    '(module
        (begin
            (set! x.1 (* 2 5))
            3)))
    '(module () (begin (set! x.1 2) (set! x.1 (* x.1 5)) (halt 3))))

(check-equal? (select-instructions
    '(module (begin (begin (set! bar.25 1) (set! foo.24 bar.25)) (set! bar.23 2) (+ foo.24 bar.23))))
    '(module
        ()
        (begin
            (set! bar.25 1)
            (set! foo.24 bar.25)
            (set! bar.23 2)
            (set! tmp.4 foo.24)
            (set! tmp.4 (+ tmp.4 bar.23))
            (halt tmp.4))))
