main:
    addiu $sp,$sp,-20
    sw $fp,16($sp)
    move $fp,$sp
    li  $2, 10
    sw  $2, 8($fp)
	lw $2 8($fp)
	li $3 7
	slt $2 $2 $3
	beq $2 $0 endif1
    lw $3, 8($fp)
    addu $3, $3, 2
    sw $3, 12($fp)
	b endelse1
	endif1:
    lw $3, 8($fp)
    addu $3, $3, 2
    sw $3, 16($fp)
	endelse1:
    move $2,$0
    move $sp,$fp
    lw $fp,16($sp)
    addiu $sp,$sp,20
    j $31
nop
