#lang racket
(require
rackunit
rackunit/text-ui
cpsc411/test-suite/public/v3
"../compiler.rkt"
;; NB: Workaround typo in shipped version of cpsc411-lib
(except-in cpsc411/langs/v3 values-lang-v3)
cpsc411/langs/v2)

(check-equal? (normalize-bind '(module (+ 2 2)))
    '(module (+ 2 2)))

(check-equal? (normalize-bind '(module (begin (set! x.1 5) x.1)))
    '(module (begin (set! x.1 5) x.1)))

(check-equal? (normalize-bind '(module (begin (set! z.1 (begin (set! x.2 1) x.2)) z.1)))
    '(module (begin (begin (set! x.2 1) (set! z.1 x.2)) z.1)))

(check-equal? (normalize-bind 
'(module
    (begin
        (set! x.3 3)
        (set! y.2 (begin (set! x.4 1) x.4))
        (set! z.1 (begin (set! x.5 1) x.5))
        (begin (set! x.6 1) (+ x.6 y.2)))))
'(module
    (begin
    (set! x.3 3)
    (begin (set! x.4 1) (set! y.2 x.4))
    (begin (set! x.5 1) (set! z.1 x.5))
    (begin (set! x.6 1) (+ x.6 y.2)))))

(check-equal? (normalize-bind 
    '(module (begin 
        (set! y.5 
        (begin (set! z.6 1) 
                (set! r.7 1) r.7))
        (set! e.8 1) e.8)))
    '(module (begin (begin (set! z.6 1) (set! r.7 1) (set! y.5 r.7)) (set! e.8 1) e.8)))

(check-equal? (normalize-bind 
    '(module (begin 
        (set! x.3 
        (begin 
            (set! x.4 (begin 
            (set! y.5 
                (begin (set! z.6 1) 
                        (set! r.7 1) r.7))
            (set! e.8 1) e.8))
            (set! i.10 1) i.10))
        (set! k.9 1) k.9)))
    '(module
        (begin
        (begin
            (begin
            (begin (set! z.6 1) (set! r.7 1) (set! y.5 r.7))
            (set! e.8 1)
            (set! x.4 e.8))
            (set! i.10 1)
            (set! x.3 i.10))
        (set! k.9 1)
        k.9)))