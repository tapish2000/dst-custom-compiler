
section .text

extern _printf
extern _scanf
global _main
_main:
    fldcw [cw]
    call _source_start
    ret

; ----------------------- ;

_source_start:
    addiu $sp,$sp,-36
    sw $fp,32($sp)
    move $fp,$sp
    li  $2, 1
    sw  $2, 28($fp)
    li  $2, 2
    sw  $2, 32($fp)
    lw $2, 28($fp)
    lw $3, 32($fp)
    addu $2, $3, $2
    sw  $2, 8($fp)
    move $2,$0
    move $sp,$fp
    lw $fp,32($sp)
    addiu $sp,$sp,36
    j $31
nop
