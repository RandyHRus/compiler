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
    (assign-homes '(module () (begin (set! x.1 3) (halt 1))))
    '(begin (set! fv0 3) (halt 1)))

(check-equal?
    (assign-homes '(module () (begin (set! x.1 3) (set! y.2 x.1) (halt y.2))))
    '(begin (set! fv1 3) (set! fv0 fv1) (halt fv0)))

(check-equal?
    (assign-homes '(module () (begin (set! x.1 3) (begin (set! y.2 x.1)) (halt y.2))))
    '(begin (set! fv1 3) (begin (set! fv0 fv1)) (halt fv0)))