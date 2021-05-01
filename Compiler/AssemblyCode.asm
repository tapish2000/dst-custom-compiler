.data
newline:  .asciiz "\n"
.text
main:
    addiu $sp,$sp,-48
    sw $fp,44($sp)
    move $fp,$sp
    li $2, 1, 
    sw $2, 8($fp), 
    li $2, 6, 
    sw $2, 12($fp), 
    li $2, 2, 
    sw $2, 16($fp), 
    li $2, 5, 
    sw $2, 20($fp), 
    li $2, 8, 
    sw $2, 24($fp), 
    li $2, 3, 
    sw $2, 28($fp), 
    li  $2, 0
    sw $2, 32($fp)
    li $2, 0, 
    sw $2, 36($fp), 
    li $2, 0, 
    sw $2, 40($fp), 
    li $2, 0, 
    sw $2, 44($fp), 
loopif1:
    lw  $2, 32($fp)
    li  $3, 3
	slt $2 $2 $3
    beq $2, $0, endloopif1
    nop
    lw  $4, 32($fp)
    lw  $5, 32($fp)
    sll  $5, $5, 2
    add  $5, $5, $fp
    lw  $5, 8($5)
    lw  $6, 32($fp)
	lw $7 20($fp)
    add $5, $5, $7
    sll  $4, $4, 2
    add  $4, $4, $fp
    sw $5, 36($4)
    lw  $4, 32($fp)
    sll  $4, $4, 2
    add  $4, $4, $fp
    lw  $4, 36($4)
    addi $a0, $4, 0
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, newline
    syscall
    lw  $5, 32($fp)
    addu $5, $5, 1
    sw  $5, 32($fp)
    b loopif1
endloopif1:
    move $2,$0
    move $sp,$fp
    lw $fp,44($sp)
    addiu $sp,$sp,48
    j $31
nop
