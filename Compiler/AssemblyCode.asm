.data
newline:  .asciiz "\n"
.text
main:
    addiu $sp,$sp,-36
    sw $fp,32($sp)
    move $fp,$sp
    li $2, 1, 
    sw $2, 8($fp), 
    li $2, 2, 
    sw $2, 12($fp), 
    li $2, 3, 
    sw $2, 16($fp), 
    li $2, 4, 
    sw $2, 20($fp), 
    li $2, 5, 
    sw $2, 24($fp), 
    li  $3, 6
    sw  $3, 28($fp)
	lw $3 16($fp)
    lw $4, 28($fp)
   add $3, $4, $3
    sw  $3, 28($fp)
    lw $4, 28($fp)
	lw $5 20($fp)
   add $4, $5, $4
    sw  $4, 28($fp)
    move $2,$0
    move $sp,$fp
    lw $fp,32($sp)
    addiu $sp,$sp,36
    j $31
nop
