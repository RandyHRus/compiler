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
    (patch-instructions '(begin (set! rbx 42) (halt rbx)))
    '(begin (set! rbx 42) (set! rax rbx)))

(check-equal?
    (patch-instructions
    '(begin
        (set! fv0 0)
        (set! fv1 42)
        (set! fv0 fv1)
        (halt fv0)))
    '(begin
        (set! fv0 0)
        (set! fv1 42)
        (set! r10 fv1)
        (set! fv0 r10)
        (set! rax fv0)))

(check-equal?
    (patch-instructions '(begin (set! rbx 42) (halt rbx)))
    '(begin (set! rbx 42) (set! rax rbx)))

(check-equal?
(patch-instructions
   '(begin
      (set! fv0 0)
      (set! fv1 42)
      (set! fv0 fv1)
      (halt fv0)))
'(begin
   (set! fv0 0)
   (set! fv1 42)
   (set! r10 fv1)
   (set! fv0 r10)
   (set! rax fv0)))

(check-equal?
(patch-instructions
   '(begin
      (set! fv0 0)
      (set! fv1 42)
      (set! fv0 fv1)
      (set! fv2 fv1)
      (set! r15 fv0)
      (halt fv0)))
'(begin
    (set! fv0 0)
    (set! fv1 42)
    (set! r10 fv1)
    (set! fv0 r10)
    (set! r10 fv1)
    (set! fv2 r10)
    (set! r15 fv0)
    (set! rax fv0)))

(check-equal?
(patch-instructions
   '(begin
      (set! rbx 0)
      (set! rcx 0)
      (set! r9 42)
      (set! rbx rcx)
      (set! rbx (+ rbx r9))
      (halt rbx)))
    '(begin
    (set! rbx 0)
    (set! rcx 0)
    (set! r9 42)
    (set! rbx rcx)
    (set! rbx (+ rbx r9))
    (set! rax rbx)))

(check-equal?
(patch-instructions
   '(begin
      (set! fv0 1)
      (set! fv1 2)
      (set! fv2 3)
      (set! fv0 (+ fv0 fv2))
      (set! fv1 (+ fv1 fv2))
      (halt rbx)))
    '(begin
        (set! fv0 1)
        (set! fv1 2)
        (set! fv2 3)
        (set! r10 fv0)
        (set! r10 (+ r10 fv2))
        (set! fv0 r10)
        (set! r10 fv1)
        (set! r10 (+ r10 fv2))
        (set! fv1 r10)
        (set! rax rbx)))

(check-equal?
    (patch-instructions
       `(begin
          (set! fv0 (+ fv0 -9223372036854775808))
          (halt fv0)))
    '(begin
        (set! r10 fv0)
        (set! r11 -9223372036854775808)
        (set! r10 (+ r10 r11))
        (set! fv0 r10)
        (set! rax fv0)))


(check-equal?
    (patch-instructions
       `(begin
          (set! r15 (+ r15 -9223372036854775808))
          (halt fv0)))
    `(begin (set! r11 -9223372036854775808) (set! r15 (+ r15 r11)) (set! rax fv0)))


(check-equal?
    (patch-instructions
       '(begin (set! fv0 2147483648) (halt 12)))
    `(begin (set! r10 2147483648) (set! fv0 r10) (set! rax 12)))

(check-equal?
    (patch-instructions
       '(begin (set! fv0 1) (halt 12)))
    `(begin (set! fv0 1) (set! rax 12)))

(check-equal?
    (patch-instructions
       '(begin (set! r15 2147483648) (halt 12)))
    `(begin (set! r15 2147483648) (set! rax 12)))


(check-equal?
    (patch-instructions
       '(begin (set! r15 (+ r15 r14)) (halt 12)))
    `(begin (set! r15 (+ r15 r14)) (set! rax 12)))

(check-equal?
    (patch-instructions
       '(begin (set! r15 (+ r15 1)) (halt 12)))
    `(begin (set! r15 (+ r15 1)) (set! rax 12)))

(check-equal?
    (patch-instructions
       '(begin (set! fv0 (+ fv0 1)) (halt 12)))
    `(begin (set! r10 fv0) (set! r10 (+ r10 1)) (set! fv0 r10) (set! rax 12)))

(check-equal?
    (patch-instructions
       '(begin (set! fv0 (+ fv0 2147483648)) (halt 12)))
    `(begin
        (set! r10 fv0)
        (set! r11 2147483648)
        (set! r10 (+ r10 r11))
        (set! fv0 r10)
        (set! rax 12)))

(check-equal?
    (patch-instructions
       '(begin (set! fv0 fv1) (halt 12)))
    `(begin (set! r10 fv1) (set! fv0 r10) (set! rax 12)))

(check-equal?
    (patch-instructions
       '(begin (set! fv0 (+ fv0 fv1)) (halt 12)))
    `(begin (set! r10 fv0) (set! r10 (+ r10 fv1)) (set! fv0 r10) (set! rax 12)))