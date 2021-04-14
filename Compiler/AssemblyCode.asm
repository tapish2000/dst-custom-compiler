
section .text

extern _printf
extern _scanf
global _main
_main:
    fldcw [cw]
    call _source_start
    ret

; ----------------------- ;

    push ebp
    mov  ebp, esp
    mov  esp, ebp
    pop  ebp
    mov  esp, ebp
    pop  ebp

; ----------------------- ;

    push ebp
    mov  ebp, esp

; ----------------------- ;

_source_start:
    push ebp
    mov  ebp, esp

; ----------------------- ;

