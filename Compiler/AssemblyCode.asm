main:
    addiu $sp,$sp,-28
    sw $fp,24($sp)
    move $fp,$sp
    li  $2, 1000
    sw  $2, 20($fp)
    move $2,$0
    move $sp,$fp
    lw $fp,24($sp)
    addiu $sp,$sp,28
    j $31
nop
