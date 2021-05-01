.data
newline:  .asciiz "\n"
.text
main:
    addiu $sp,$sp,-20
    sw $fp,16($sp)
    move $fp,$sp
    li  $2, 6
    sw $2, 8($fp)
    li  $2, 4
    sw $2, 12($fp)
    li  $2, 5
    sw $2, 16($fp)
    lw  $2, 8($fp)
    lw  $3, 12($fp)
	slt $2 $3 $2
	beq $2 $0 endif1
    lw  $4, 8($fp)
    lw  $5, 16($fp)
	slt $4 $5 $4
	beq $4 $0 endif2
    lw  $6, 8($fp)
    addi $a0, $6, 0
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, newline
    syscall
	b endelse2
endif2:
    lw  $7, 16($fp)
    addi $a0, $7, 0
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, newline
    syscall
endelse2:
	b endelse1
endif1:
    lw  $8, 12($fp)
    lw  $9, 16($fp)
	slt $8 $9 $8
	beq $8 $0 endif3
    lw  $10, 12($fp)
    addi $a0, $10, 0
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, newline
    syscall
	b endelse3
endif3:
    lw  $11, 16($fp)
    addi $a0, $11, 0
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, newline
    syscall
endelse3:
endelse1:
    move $2,$0
    move $sp,$fp
    lw $fp,16($sp)
    addiu $sp,$sp,20
    j $31
nop
