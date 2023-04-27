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
    (implement-fvars
        '(begin 
            (set! r9 1) 
            (set! r10 -9223372036854775808)
            (set! r11 r11) 
            (set! r12 9223372036854775807)))
    '(begin
        (set! r9 1)
        (set! r10 -9223372036854775808)
        (set! r11 r11)
        (set! r12 9223372036854775807)))

(check-equal?
    (implement-fvars
        '(begin 
            (set! fv2 0) 
            (set! fv1 0)
            (set! r10 fv2) 
            (set! fv0 r10) 
            (set! r10 fv1) 
            (set! r10 (+ r10 fv2)) 
            (set! fv1 r10) 
            (set! r10 fv1) 
            (set! r10 (+ r10 fv0)) 
            (set! fv1 r10) 
            (set! rax fv1)))
    '(begin
        (set! (rbp - 16) 0)
        (set! (rbp - 8) 0)
        (set! r10 (rbp - 16))
        (set! (rbp - 0) r10)
        (set! r10 (rbp - 8))
        (set! r10 (+ r10 (rbp - 16)))
        (set! (rbp - 8) r10)
        (set! r10 (rbp - 8))
        (set! r10 (+ r10 (rbp - 0)))
        (set! (rbp - 8) r10)
        (set! rax (rbp - 8))))