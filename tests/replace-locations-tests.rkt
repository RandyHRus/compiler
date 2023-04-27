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
    (replace-locations
        '(module ((locals (x.1)) (assignment ((x.1 rax))))
        (begin
            (set! x.1 0)
            (halt x.1))))
        '(begin (set! rax 0) (halt rax)))

(check-equal?
    (replace-locations
        '(module ((locals (x.1 y.1 w.1))
                (assignment ((x.1 rax) (y.1 rbx) (w.1 r9))))
        (begin
            (set! x.1 0)
            (set! y.1 x.1)
            (set! w.1 1)
            (set! w.1 (+ w.1 y.1))
            (halt w.1))))
    '(begin (set! rax 0) (set! rbx rax) (set! r9 1) (set! r9 (+ r9 rbx)) (halt r9)))