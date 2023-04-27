#lang racket

(require
 cpsc411/compiler-lib
 cpsc411/2c-run-time)

(provide
 check-values-lang
 uniquify
 sequentialize-let
 normalize-bind
 select-instructions
 uncover-locals
 assign-fvars
 replace-locations
 assign-homes
 flatten-begins
 patch-instructions
 implement-fvars
 check-paren-x64
 generate-x64

 interp-values-lang

 interp-paren-x64)

;; STUBS; delete when you've begun to implement the passes or replaced them with
;; your own stubs.
(define-values (check-values-lang
                interp-values-lang )
  (values
   values
   values))


;;------------------------------------------------------------------------
;;---------------------------Milestone 1----------------------------------
;;------------------------------------------------------------------------

;; Optional;
;; Takes valid Paren-x64 v1 syntax, and returns a valid Paren-x64 v1 program or raises an error with a descriptive error message.
;; Here, we check register initialization. Note that this procedure can assume its input is well-formed Paren-x64 v1 syntax, and only concern itself with register initialization.
;; second part of check-paren-x64
(define (check-paren-x64-init p)
  p)

;; Optional;
;; Takes an arbitrary value and either returns it, if it is valid Paren-x64 v1 syntax, 
;; or raises an error with a descriptive error message.
;; First part of check-paren-x64
(define (check-paren-x64-syntax p)
  p)

;; Takes an arbitrary value and either returns it, if it is valid Paren-x64 v1 program,
;; or raises an error with a descriptive error message.
(define (check-paren-x64 p)
  (check-paren-x64-init (check-paren-x64-syntax p)))

;; optional
(define (interp-paren-x64 p)
  p)

;; paren-x64-v2? -> (and/c string? x64-instructions?)
;; Compiles a Paren-x64 v1 program into a x64 instruction sequence represented as a string.
;; Assume that p is a valid paren-x64.
(define (generate-x64 p)

  ; Paren-x64-v2 -> x64-instruction-sequence
  (define (program->x64 p)
    (define string-list 
      (match p
        [`(begin ,s ...)
          (map (lambda (i) (statement->x64 i)) s)]))
    (apply string-append string-list))

  (define (statement->x64 s)
    (match s
      [`(set! ,addr ,int32) #:when (and (addr? addr) (int32? int32))
        (string-append "mov " (addr->x64 addr) ", " (number->string int32) "\n")]
      [`(set! ,addr ,reg) #:when (and (addr? addr) (register? reg))
        (string-append "mov " (addr->x64 addr) ", " (symbol->string reg) "\n")]
      [`(set! ,reg ,loc) #:when (and (register? reg) (loc? loc))
        (string-append "mov " (symbol->string reg) ", " (loc->x64 loc) "\n")]
      [`(set! ,reg ,triv) #:when (and (register? reg) (triv? triv))
        (string-append "mov " (symbol->string reg) ", " (triv->x64 triv) "\n")]
      [`(set! ,reg_1 (,binop ,reg_1 ,int32)) #:when (and (register? reg_1) (int32? int32))
        (string-append (get-operation binop) (symbol->string reg_1) ", " (number->string int32) "\n")]
      [`(set! ,reg_1 (,binop ,reg_1 ,loc)) #:when (and (register? reg_1) (loc? loc))
        (string-append (get-operation binop) (symbol->string reg_1) ", " (loc->x64 loc) "\n")]))

  ; (Paren-x64-v2 loc) -> x64-instruction-sequence
  (define (loc->x64 l)
    (match l
      [reg #:when (register? reg)
        (symbol->string reg)]
      [addr #:when (addr? addr)
        (addr->x64 l)]))

  ; (Paren-x64-v2 addr) -> x64-instruction-sequence
  (define (addr->x64 a)
    (match a
      [`(,fbp - ,dispoffset)
        (string-append "QWORD [" (symbol->string fbp) " - " (number->string dispoffset) "]")]))

  ; (Paren-x64-v2 triv) -> x64-instruction-sequence
  (define (triv->x64 t)
    (match t
      [reg #:when (register? t)
        (symbol->string reg)]
      [int64 #:when (int64? t)
        (number->string int64)]))

  (define (triv? t)
    (or (register? t) (int64? t)))

  (define (loc? l)
    (or (register? l) (addr? l)))

  (define (addr? a)
    (match a
      [`(,fbp - ,dispoffset)
        (and (equal? fbp (current-frame-base-pointer-register)) (dispoffset? dispoffset))]
      [_ #f]))

  (define (get-operation o)
    (match o
      ['+ "add "]
      ['* "imul "]))

  (program->x64 p))

;;------------------------------------------------------------------------
;;---------------------------Milestone 2----------------------------------
;;------------------------------------------------------------------------

;; values-lang-v3? -> values-unique-lang-v3?
;; Compiles Values-lang v3 to Values-unique-lang v3 by 
;; resolving all lexical identifiers to abstract locations.
(define (uniquify p)

  ;; (values-lang-v3? tail) env -> (values-unique-lang-v3? tail)
  (define (uniquify-tail tail env)
    (match tail
      [`(let ([,xs ,vals] ...) ,tail2)
        (define-values (unique-xs-values new-env) 
          (uniquify-xs-values xs vals env))
        `(let ,unique-xs-values ,(uniquify-tail tail2 new-env))]
      [value
        (uniquify-value value env)]))

  ;; (values-lang-v3? value) -> (values-unique-lang-v3? value)
  (define (uniquify-value value env)
    (match value
      [`(let ([,xs ,vals] ...) ,value2)
        (define-values (unique-xs-values new-env) 
          (uniquify-xs-values xs vals env))
        `(let ,unique-xs-values ,(uniquify-value value2 new-env))]
      [`(,binop ,triv ,triv2) 
        `(,binop ,(uniquify-triv triv env) ,(uniquify-triv triv2 env))]
      [triv (uniquify-triv triv env)]))

  ;; (values-lang-v3? xs) (values-lang-v3? values) env -> (values-unique-lang-v3? ((x value) ...)) new-env
  (define (uniquify-xs-values xs vals env)
    (for/foldr ([result '()]
              [new-env env]) ;acc
              ([x xs]
              [val vals])
        (define new-x (fresh x))
        (values
          (append `((,new-x ,(uniquify-value val env))) result)
          (dict-set new-env x new-x))))

  ;; (values-lang-v3? triv) env -> (values-unique-lang-v3? triv)
  (define (uniquify-triv triv env)
    (match triv 
      [int64
        #:when (int64? int64)
        int64]
      [x (uniquify-x x env)]))

  ;; (values-lang-v3? x) env -> (values-unique-lang-v3? x) new-env
  (define (uniquify-x x env)
    (dict-ref env x))

  (match p 
    [`(module ,tail)
      ;; env stores assignments of lexical identifiers to abstract locations
      `(module ,(uniquify-tail tail '()))]))

;; values-unique-lang-v3? -> imp-mf-lang-v3?
;; Compiles Values-unique-lang v3 to Imp-mf-lang v3 by 
;; picking a particular order to implement let expressions using set!.
(define (sequentialize-let p)

  ;; (values-unique-lang-v3? value) -> (imp-mf-lang-v3? value)
  (define (sequentialize-let-value v)
    (match v
      [`(let ([,alocs ,vals] ...) ,value)
        `(begin ,@(create-effect alocs vals) ,(sequentialize-let-value value))]
      [`(,binop ,triv1 ,triv2)
        v]
      [triv 
        triv]))

  ;; (values-unique-lang-v3? tail) -> (imp-mf-lang-v3? tail)
  (define (sequentialize-let-tail t) 
    (match t
      [`(let ([,alocs ,vals] ...) ,tail)
        `(begin ,@(create-effect alocs vals) ,(sequentialize-let-tail tail))]
      [value 
        (sequentialize-let-value value)]))

  ;; (values-unique-lang-v3? alocs) (values-unique-lang-v3? vals) -> (imp-mf-lang-v3? tail)
  (define (create-effect alocs vals) 
    (for/fold ([result '()])
              ([aloc alocs]
               [value vals])
      (append result `((set! ,aloc ,(sequentialize-let-value value))))))

  (match p
    [`(module ,tail)
      `(module ,(sequentialize-let-tail tail))]))

;; Imp-mf-lang-v3 -> Imp-cmf-lang-v3
;; Compiles Imp-mf-lang v3 to Imp-cmf-lang v3, pushing set! under begin so that 
;; the right-hand-side of each set! is simple value-producing operation. 
;; This normalizes Imp-mf-lang v3 with respect to the equations
(define (normalize-bind p) 

  ;; (Imp-mf-lang-v3 tail) -> (Imp-cmf-lang-v3 tail)
  (define (normalize-bind-tail t) 
    (match t
      [`(begin ,effects ... ,t)
        `(begin 
          ,@(normalize-bind-effects effects)
          ,(normalize-bind-tail t))]
      [value (normalize-bind-value value)]))

  ;; (Imp-mf-lang-v3 value) (Imp-mf-lang-v3 aloc) -> (Imp-cmf-lang-v3 effect)
  (define (normalize-bind-value-append-aloc v aloc) 
    (match v
      [`(begin ,effects ... ,value)
        `(begin 
          ,@(normalize-bind-effects effects)
          (set! ,aloc ,(normalize-bind-value value)))]
      [`(,binop ,triv1 ,triv2)
        `(set! ,aloc ,v)]
      [triv 
        `(set! ,aloc ,v)]))

  ;; (Imp-mf-lang-v3 value) -> (Imp-cmf-lang-v3 value)
  (define (normalize-bind-value v) 
    (match v
      [`(begin ,effects ... ,value)
        `(begin 
          ,@(normalize-bind-effects effects)
          ,(normalize-bind-value value))]
      [`(,binop ,triv1 ,triv2)
        v]
      [triv 
        triv]))

  ;; (Imp-mf-lang-v3 effects) -> (Imp-cmf-lang-v3 effects)
  (define (normalize-bind-effects effects) 
    (for/fold ([result '()])
              ([effect effects])
      (append result `(,(normalize-bind-effect effect))))) 

  ;; (Imp-mf-lang-v3 effect) -> (Imp-cmf-lang-v3 effect)
  (define (normalize-bind-effect effect) 
    (match effect
      [`(set! ,aloc ,value)
        (normalize-bind-value-append-aloc value aloc)]
      [`(begin ,effects ...)
        `(begin ,@(normalize-bind-effects effects))]))

  (match p
    [`(module ,tail)
      `(module ,(normalize-bind-tail tail))]))

;; Compiles Imp-cmf-lang v3 to Asm-lang v2, 
;; selecting appropriate sequences of abstract assembly 
;; instructions to implement the operations of the source language.
(define (select-instructions p)

  ; (Imp-cmf-lang-v3 value) -> (List-of (Asm-lang-v2 effect)) and (Asm-lang-v2 aloc)
  ; Assigns the value v to a fresh temporary, returning two values: the list of
  ; statements the implement the assignment in Loc-lang, and the aloc that the
  ; value is stored in.
  (define (assign-tmp v)
    (define tmp (fresh 'tmp))
    (match v
      [`(,binop ,triv1 ,triv2)
        (values `((set! ,tmp ,triv1) (set! ,tmp (,binop ,tmp ,triv2))) tmp)]))

  ;; (Imp-cmf-lang-v3 value) (Imp-cmf-lang-v3 aloc) -> (List-of (Asm-lang-v2 effect))
  (define (select-value-append-aloc v aloc) 
    (match v
      [`(,binop ,triv1 ,triv2)
        `((set! ,aloc ,triv1) (set! ,aloc (,binop ,aloc ,triv2)))]
      [triv 
        `((set! ,aloc ,triv))]))

  ;; (Imp-cmf-lang-v3 value) -> (Asm-lang-v2 value)
  (define (select-value v)
    (match v
      [`(,binop ,triv1 ,triv2)
        (define-values (statements aloc) 
          (assign-tmp v))
        `(begin ,@statements (halt ,aloc))]
      [triv 
        `(halt ,triv)]))

  ;; (Imp-cmf-lang-v3 tail) -> (Asm-lang-v2 tail)
  (define (select-tail e)
    (match e 
      [`(begin ,effects ... ,tail)
        (make-begin-effect `(,@(select-effects effects) ,(select-tail tail)))]
      [value (select-value value)]))

  ;; (List-of (Imp-cmf-lang-v3 effect)) -> (List-of (Asm-lang-v2 effect))
  (define (select-effects effects)
    (for/fold ([result '()])
              ([effect effects])
      (append result (select-effect effect))))

  ;; (Imp-cmf-lang-v3 effect) -> (List-of (Asm-lang-v2 effect))
  (define (select-effect e)
    (match e 
      [`(set! ,aloc ,value)
        (select-value-append-aloc value aloc)]
      [`(begin ,effects ... ,effect)
        `(,@(select-effects effects) ,@(select-effect effect))]))

  (match p
    [`(module ,tail)
     `(module () ,(select-tail tail))]))

;; Asm-lang-v2 -> nested-asm-lang-v2
(define (assign-homes p)
  (replace-locations (assign-fvars (uncover-locals p))))

;; Asm-lang-v2 -> Asm-lang-v2/locals?
(define (uncover-locals p)
  (define (uncover-tail tail locals)
    (match tail
      [`(halt ,triv)
        (set-union locals (uncover-triv triv locals))]
      [`(begin ,effects ... ,tail2)
        (set-union locals (uncover-effects effects locals) (uncover-tail tail2 locals))]))
  
  ;; (Asm-lang-v2 (list effect)) locals -> (set locals)
  (define (uncover-effects effects locals)
    (for/fold ([acc locals])
              ([effect effects])
      (uncover-effect effect acc)))

  ;; (Asm-lang-v2 effect) locals -> (set locals)
  (define (uncover-effect effect locals)
    (match effect
      [`(set! ,aloc_1 (,binop ,aloc_1 ,triv))
        (set-union locals (uncover-aloc aloc_1 locals) (uncover-triv triv locals))]
      [`(set! ,aloc ,triv)
        (set-union locals (uncover-aloc aloc locals) (uncover-triv triv locals))]
      [`(begin ,effects ...)
        (set-union locals (uncover-effects effects locals))]))

  ;; (Asm-lang-v2 triv) locals -> (set locals)
  (define (uncover-triv triv locals)
    (match triv
      [(? integer?)
        locals]
      [`,aloc
       (uncover-aloc aloc locals)]))

   ;; (Asm-lang-v2 triv) locals -> (set locals)
  (define (uncover-aloc aloc locals)
    (set-add locals aloc))
    
  (match p
    [`(module ,info ,tail)
      `(module ((locals ,(uncover-tail tail '()))) ,tail)]))

;; asm-lang-v2/locals? -> asm-lang-v2/assignments?
(define (assign-fvars p)
  (define (create-assignment alocs)
    (begin 
      (define-values (assignments _)
        (for/foldr ([acc '()]
                    [index 0])
                  ([l alocs])
          (define-values (new-acc new-index)
            (values (set-add acc `(,l ,(make-fvar index))) (+ index 1)))
          (values new-acc new-index)))
      assignments))

  ;; (asm-lang-v2/locals info) -> (asm-lang-v2/assignments info)
  (define (assign-info info)
    (match info
      [`((locals (,alocs ...)))
        `((locals ,alocs) (assignment ,(create-assignment alocs)))]))

  (match p 
    [`(module ,info ,tail)
      `(module ,(assign-info info) ,tail)]))

;; asm-lang-v2/assignments? -> nested-asm-lang-v2?
(define (replace-locations p)
  (define (replace-tail tail assignments)
    (match tail
      [`(halt ,triv)
        `(halt ,(replace-triv triv assignments))]
      [`(begin ,effects ... ,tail2)
        `(begin ,@(replace-effects effects assignments) ,(replace-tail tail2 assignments))]))
  
  ;; (asm-lang-v2/assignments (list effect)) assignments -> (nested-asm-lang-v2 (list effect))
  (define (replace-effects effects assignments)
    (for/list ([effect effects])
      (replace-effect effect assignments)))

  ;; (asm-lang-v2/assignments effect) assignments -> (nested-asm-lang-v2 effect)
  (define (replace-effect effect assignments)
    (match effect
      [`(set! ,aloc_1 (,binop ,aloc_1 ,triv))
        (define aloc_1_home (replace-aloc aloc_1 assignments))
        `(set! ,aloc_1_home (,binop ,aloc_1_home ,(replace-triv triv assignments)))]
      [`(set! ,aloc ,triv)
        `(set! ,(replace-aloc aloc assignments) ,(replace-triv triv assignments))]
      [`(begin ,effects ...)
        `(begin ,@(replace-effects effects assignments))]))

  ;; (asm-lang-v2/assignments triv) assignments -> (nested-asm-lang-v2 triv)
  (define (replace-triv triv assignments)
    (match triv
      [(? integer?)
        triv]
      [`,aloc
        (replace-aloc aloc assignments)]))

  ;; (asm-lang-v2/assignments aloc) assignments -> (nested-asm-lang-v2 loc)
  (define (replace-aloc aloc assignments)
    (first (dict-ref assignments aloc)))

  ;; (asm-lang-v2/assignments info) -> assignments
  (define (get-assignments info)
    (match info
      [`((locals (,aloc ...)) (assignment ,assignments))
        assignments]))
    
  (match p
    [`(module ,info ,tail)
      (replace-tail tail (get-assignments info))]))

;; nested-asm-lang-v2 -> para-asm-lang-v2
;; Flatten all nested begin expressions.
(define (flatten-begins p) 
  
  ;; (nested-asm-lang-v2 tail) -> (para-asm-lang-v2 tail)
  (define (flatten-tail t)
    (match t
      [`(halt ,triv)
        t]
      [`(begin ,effects ... ,tail)
        (define effects-result
          (for/list ([e effects])
            (flatten-effect e)))
        (make-begin effects-result (flatten-tail tail))]))
    
  ;; (nested-asm-lang-v2 effect) -> (para-asm-lang-v2 effect)
  (define (flatten-effect e)
    (match e
      [`(set! ,loc ,triv)
        e]
      [`(set! ,loc_1 (,binop ,loc_1 ,triv))
        e]
      [`(begin ,effects ... ,effect)
        (define effects-result
          (for/list ([e effects])
            (flatten-effect e)))
        (make-begin effects-result (flatten-effect effect))]))
    
  (match p
    [`,tail
      (make-begin-effect `(,(flatten-tail tail)))]))

;; para-asm-lang-v2? -> paren-x64-fvars-v2?
;; Compiles Para-asm-lang v2 to Paren-x64-fvars v2 by patching instructions
;; that have no x64 analogue into a sequence of instructions. 
;; The implementation should use auxiliary registers from 
;; current-patch-instructions-registers when generating instruction sequences,
;; and current-return-value-register for compiling halt.
(define (patch-instructions p)

  ;; (para-asm-lang-v2 effect) -> (paren-x64-fvars-v2 (list effect))
  (define (patch-effect e)
    (define r1 (first (current-patch-instructions-registers)))
    (define r2 (second (current-patch-instructions-registers)))
    (match e
      [`(set! ,loc_1 (,binop ,loc_1 ,triv)) #:when (and (int64? triv) (not (int32? triv)))
        (if (fvar? loc_1)
          `((set! ,r1 ,loc_1)
            (set! ,r2 ,triv)
            (set! ,r1 (,binop ,r1 ,r2))
            (set! ,loc_1 ,r1))
          `((set! ,r2 ,triv)
            (set! ,loc_1 (,binop ,loc_1 ,r2))))]
      [`(set! ,loc_1 (,binop ,loc_1 ,triv))
        (if (fvar? loc_1)
          `((set! ,r1 ,loc_1)
            (set! ,r1 (,binop ,r1 ,triv))
            (set! ,loc_1 ,r1))
          (list e))]
      [`(set! ,loc ,triv) #:when (and (int64? triv) (not (int32? triv)))
        (if (and (fvar? loc))
          `((set! ,r1 ,triv) 
            (set! ,loc ,r1))
          (list e))]
      [`(set! ,loc ,triv) 
        (if (and (fvar? loc) (fvar? triv))
          `((set! ,r1 ,triv) 
            (set! ,loc ,r1))
          (list e))]))
  
  (match p
    [`(begin ,effects ... (halt ,triv))
      (define effects-result
        (for/foldr ([acc '()])
                   ([e effects])
          (append (patch-effect e) acc)))
      `(begin ,@effects-result (set! ,(current-return-value-register) ,triv))]))

; paren-x64-fvars-v2? -> paren-x64-v2?
; Compiles the Paren-x64-fvars v2 to Paren-x64 v2 by 
; reifying fvars into displacement mode operands. 
; The pass should use current-frame-base-pointer-register.
(define (implement-fvars p)
  
  ; (paren-x64-fvars-v2 s) -> (paren-x64-v2 s)
  (define (implement-s s)
    (define cfbp (current-frame-base-pointer-register))
    (match s
      [`(set! ,fvar ,int32) #:when (and (fvar? fvar) (int32? int32))
        `(set! (,cfbp - ,(get-offset fvar)) ,int32)]
      [`(set! ,fvar ,reg) #:when (and (fvar? fvar) (register? reg))
        `(set! (,cfbp - ,(get-offset fvar)) ,reg)]
      [`(set! ,reg ,loc) #:when (and (register? reg) (loc? loc))
        `(set! ,reg ,(implement-loc loc))]
      [`(set! ,reg ,triv) #:when (and (register? reg) (triv? triv))
        s]
      [`(set! ,reg_1 (,binop ,reg_1 ,int32)) #:when (and (register? reg_1) (int32? int32))
        s]
      [`(set! ,reg_1 (,binop ,reg_1 ,loc)) #:when (and (register? reg_1) (loc? loc))
        `(set! ,reg_1 (,binop ,reg_1 ,(implement-loc loc)))]))

  ; (paren-x64-fvars-v2 loc) -> (paren-x64-v2 loc)
  (define (implement-loc l)
    (match l
      [reg #:when (register? reg)
        reg]
      [fvar #:when (fvar? fvar)
        `(,(current-frame-base-pointer-register) - ,(get-offset fvar))]))
    
  (define (loc? l)
    (or (register? l) (fvar? l)))

  (define (triv? t)
    (or (register? t) (int64? t)))

  ; (paren-x64-fvars-v2 fvar) -> (paren-x64-v2 addr)
  (define (get-offset fvar)
    (* 8 (fvar->index fvar)))

  (match p
    [`(begin ,ss ...)
      `(begin
        ,@(for/list ([s ss])
          (implement-s s)))]))

(current-pass-list
 (list
  check-values-lang
  uniquify
  sequentialize-let
  normalize-bind
  select-instructions
  assign-homes
  flatten-begins
  patch-instructions
  implement-fvars
  generate-x64
  wrap-x64-run-time
  wrap-x64-boilerplate))

(module+ test
  (require
   rackunit
   rackunit/text-ui
   cpsc411/test-suite/public/v3
   ;; NB: Workaround typo in shipped version of cpsc411-lib
   (except-in cpsc411/langs/v3 values-lang-v3)
   cpsc411/langs/v2)

  (run-tests
    (v3-public-test-sutie
      (current-pass-list)
      (list
      interp-values-lang-v3
      interp-values-lang-v3
      interp-values-unique-lang-v3
      interp-imp-mf-lang-v3
      interp-imp-cmf-lang-v3
      interp-asm-lang-v2
      interp-nested-asm-lang-v2
      interp-para-asm-lang-v2
      interp-paren-x64-fvars-v2
      interp-paren-x64-v2
      #f #f))))
