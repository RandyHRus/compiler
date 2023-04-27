#lang racket
(require
rackunit
rackunit/text-ui
cpsc411/test-suite/public/v3
"../compiler.rkt"
;; NB: Workaround typo in shipped version of cpsc411-lib
(except-in cpsc411/langs/v3 values-lang-v3)
cpsc411/langs/v2)

(check-equal?
    (uncover-locals
        '(module ()
            (begin
            (set! x.1 0)
            (halt x.1))))
    '(module ((locals (x.1))) (begin (set! x.1 0) (halt x.1))))

(check-equal?
    (uncover-locals
        '(module ()
            (begin
            (set! x.1 0)
            (set! y.1 x.1)
            (set! y.1 (+ y.1 x.1))
            (halt y.1))))
    '(module
        ((locals (x.1 y.1)))
        (begin (set! x.1 0) (set! y.1 x.1) (set! y.1 (+ y.1 x.1)) (halt y.1))))