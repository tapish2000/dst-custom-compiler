.data
newline:  .asciiz "\n"
.text
main:
    addiu $sp,$sp,-28
    sw $fp,24($sp)
    move $fp,$sp
li $2, 1, 
sw $2, 8($fp), 
li $2, 2, 
sw $2, 12($fp), 
li $2, 3, 
sw $2, 16($fp), 
    sw $0, 20($fp)
    move $2,$0
    move $sp,$fp
    lw $fp,24($sp)
    addiu $sp,$sp,28
    j $31
nop
