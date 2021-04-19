
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
    addiu $sp,$sp,-8
    sw $fp,4($sp)
    move $fp,$sp
    li  $2, 6
    sw  $2, 8($fp)
    lw $2, 8($fp)
    addu $2, $2, 7
    sw $2, 12($fp)
    move $2,$0
    move $sp,$fp
    lw $fp,4($sp)
    addiu $sp,$sp,8
    j $31
nop
