#lang racket
(require
rackunit
rackunit/text-ui
cpsc411/test-suite/public/v3
"compiler.rkt"
;; NB: Workaround typo in shipped version of cpsc411-lib
(except-in cpsc411/langs/v3 values-lang-v3))

(define compile
  (apply
   compose   (reverse
    (list
     uniquify
     sequentialize-let
     normalize-bind
     select-instructions
     assign-homes
     flatten-begins
     patch-instructions
     implement-fvars
     generate-x64))))


(compile '(module (let ([x 3][y (let ([x 1]) x)][z (let ([x 1]) x)]) (let ([x 1]) (+ x y)))))