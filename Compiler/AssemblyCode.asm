main:
    addiu $sp,$sp,-16
    sw $fp,12($sp)
    move $fp,$sp
    li  $2, 0
    sw  $2, 8($fp)
	lw $2 8($fp)
	li $3 5
	slt $2 $2 $3
	bne $2 $0 endelse1
    li  $2, 6
    sw  $2, 12($fp)
	endif1:
	endelse1:
    move $2,$0
    move $sp,$fp
    lw $fp,12($sp)
    addiu $sp,$sp,16
    j $31
nop
