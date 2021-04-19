_source_start:
    addiu $sp,$sp,-20
    sw $fp,16($sp)
    move $fp,$sp
    li  $2, 6
    sw  $2, 8($fp)
    li  $2, 4
    sw  $2, 12($fp)
    lw $2, 12($fp)
    lw $3, 8($fp)
    mult $2, $3
    mflo $3
    sw $3, 16($fp)
    move $2,$0
    move $sp,$fp
    lw $fp,16($sp)
    addiu $sp,$sp,20
    j $31
nop
