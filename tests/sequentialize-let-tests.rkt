#lang racket
(require
rackunit
rackunit/text-ui
cpsc411/test-suite/public/v3
"../compiler.rkt"
;; NB: Workaround typo in shipped version of cpsc411-lib
(except-in cpsc411/langs/v3 values-lang-v3)
cpsc411/langs/v2)

(check-equal? (sequentialize-let '(module (+ 2 2)))
    '(module (+ 2 2)))

(check-equal? (sequentialize-let '(module (let ((x.1 5)) x.1)))
    '(module (begin (set! x.1 5) x.1)))

(check-equal? (sequentialize-let '(module (let ((x.1 2)) (let ((y.2 2)) (+ x.1 y.2)))))
    '(module (begin (set! x.1 2) (begin (set! y.2 2) (+ x.1 y.2)))))

(check-equal? (sequentialize-let '(module (let ((x.3 3) (y.2 2) (z.1 1)) x.3)))
    '(module (begin (set! x.3 3) (set! y.2 2) (set! z.1 1) x.3)))

(check-equal? 
    (sequentialize-let '(module
        (let ((x.3 3) (y.2 (let ((x.4 1)) x.4)) (z.1 (let ((x.5 1)) x.5)))
        (let ((x.6 1)) (+ x.6 y.2)))))  
    '(module
        (begin
        (set! x.3 3)
        (set! y.2 (begin (set! x.4 1) x.4))
        (set! z.1 (begin (set! x.5 1) x.5))
        (begin (set! x.6 1) (+ x.6 y.2)))))