#lang racket
(require
rackunit
rackunit/text-ui
cpsc411/test-suite/public/v3
"../compiler.rkt"
;; NB: Workaround typo in shipped version of cpsc411-lib
(except-in cpsc411/langs/v3 values-lang-v3)
cpsc411/langs/v2)

(check-equal? (uniquify '(module (+ 2 2)))
    '(module (+ 2 2)))


(check-equal? (uniquify'(module (let ([x 5]) x)))
    '(module (let ((x.1 5)) x.1)))

(check-equal? (uniquify'(module (let ([x (+ 2 2)]) x)))
    '(module (let ((x.2 (+ 2 2))) x.2)))

(check-equal? (uniquify '(module (let ([x 2]) (let ([y 2]) (+ x y)))))
    '(module (let ((x.3 2)) (let ((y.4 2)) (+ x.3 y.4)))))

(check-equal? (uniquify '(module (let ([x 2]) (let ([x 2]) (+ x x)))))
    '(module (let ((x.5 2)) (let ((x.6 2)) (+ x.6 x.6)))))

(check-equal? (uniquify '(module (let ([x 3][y 2][z 1]) x)))
    '(module (let ((x.9 3) (y.8 2) (z.7 1)) x.9)))

(check-equal? 
    (uniquify '(module (let ([x 3][y (let ([x 1]) x)][z (let ([x 1]) x)]) (let ([x 1]) (+ x y)))))
    '(module
        (let ((x.14 3) (y.12 (let ((x.13 1)) x.13)) (z.10 (let ((x.11 1)) x.11)))
            (let ((x.15 1)) (+ x.15 y.12)))))