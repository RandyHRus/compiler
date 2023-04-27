# Values-lang v3 to x64 compiler

Compiles Values-lang v3 to x64 using a series of passes

-   Uniquify
-   Sequentialize-let
-   normalize-bind
-   select-instructions
-   uncover-locals
-   assign-fvars
-   assign-homes
-   replace-locations
-   flatten-begins
-   patch-instructions
-   generate-x64

Values-lang v3 language definition:  
p ::= (module tail)
tail ::= value | (let ([x value] ...) tail)  
value ::= triv | (binop triv triv) | (let ([x value] ...) value)  
triv ::= int64 | x  
x ::= name?  
binop ::= \* | +  
int64 ::= int64?

## Examples

```
//Values-lang v3
'(module (let ([x 6]) x))

//x64 result
mov QWORD [rbp - 0], 6
mov rax, QWORD [rbp - 0]
```

```
//Values-lang v3
'(module (let ([x 6]) x))

//x64 result
mov QWORD [rbp - 0], 2
mov r10, QWORD [rbp - 0]
add r10, 2\nmov QWORD [rbp - 0], r10
mov rax, QWORD [rbp - 0]
```

```
//Values-lang v3
'(module (let ([x (+ 2 2)]) x))

//x64 result
mov QWORD [rbp - 0], 2
mov r10, QWORD [rbp - 0]
add r10, 2\nmov QWORD [rbp - 0], r10
mov rax, QWORD [rbp - 0]
```

```
//Values-lang v3
'(module
    (let ([x 3]
          [ y (let
            ([x 1]) x)]
          [z (let ([x 1]) x)])
    (let ([x 1]) (+ x y))))

//x64 result
mov QWORD [rbp - 48], 3
mov QWORD [rbp - 40], 1
mov r10, QWORD [rbp - 40]
mov QWORD [rbp - 32], r10
mov QWORD [rbp - 24], 1
mov r10, QWORD [rbp - 24]
mov QWORD [rbp - 16], r10
mov QWORD [rbp - 8], 1
mov r10, QWORD [rbp - 8]
mov QWORD [rbp - 0], r10
mov r10, QWORD [rbp - 0]
add r10, QWORD [rbp - 32]
mov QWORD [rbp - 0], r10
mov rax, QWORD [rbp - 0]
```

## Notes

This project was built for CPSC411 course at the University of British Columbia
