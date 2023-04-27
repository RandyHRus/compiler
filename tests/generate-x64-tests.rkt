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
    (generate-x64 '(begin (set! rax 42)))
    "mov rax, 42\n")

(check-equal?
    (generate-x64 '(begin (set! rax 42) (set! rax (+ rax 0))))
    "mov rax, 42\nadd rax, 0\n")

(check-equal?
    (generate-x64 '(begin
      (set! (rbp - 0) 0)
      (set! (rbp - 8) 42)
      (set! rax (rbp - 0))
      (set! rax (+ rax (rbp - 8)))))
    "mov QWORD [rbp - 0], 0\nmov QWORD [rbp - 8], 42\nmov rax, QWORD [rbp - 0]\nadd rax, QWORD [rbp - 8]\n")

(check-equal?
    (generate-x64 '(begin
      (set! rax 0)
      (set! rbx 0)
      (set! r9 42)
      (set! rax (+ rax r9))))
    "mov rax, 0\nmov rbx, 0\nmov r9, 42\nadd rax, r9\n")