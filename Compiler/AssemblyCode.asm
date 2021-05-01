.data
newline:  .asciiz "\n"
.text
main:
    addiu $sp,$sp,-40
    sw $fp,36($sp)
    move $fp,$sp
    li $2, 5, 
    sw $2, 8($fp), 
    li $2, 2, 
    sw $2, 12($fp), 
    li $2, 3, 
    sw $2, 16($fp), 
    li $2, 1, 
    sw $2, 20($fp), 
    li $2, 4, 
    sw $2, 24($fp), 
    li  $2, 0
    sw $2, 28($fp)
loopif1:
    lw  $2, 28($fp)
    li  $3, 5
	slt $2 $2 $3
    beq $2, $0, endloopif1
    nop
    li  $4, 0
    sw $4, 32($fp)
loopif2:
    lw  $4, 32($fp)
    li  $5, 5
    lw $6, 28($fp)
  sub $5, $5, $6
    subu $5, $5, 1
	slt $4 $4 $0
    beq $4, $0, endloopif2
    nop
    lw  $6, 32($fp)
    sll  $6, $6, 2
    add  $6, $6, $fp
    lw  $6, 8($6)
    lw  $7, 32($fp)
    addu $7, $7, 1
    sll  $0, $0, 2
    add  $0, $0, $fp
    lw  $0, 8($0)
	slt $6 $0 $6
	beq $6 $0 endif1
    lw  $8, 32($fp)
    addu $8, $8, 1
    sll  $0, $0, 2
    add  $0, $0, $fp
    lw  $0, 8($0)
    sw $0, 36($fp)
    lw  $9, 32($fp)
    addu $9, $9, 1
    lw  $10, 32($fp)
    sll  $10, $10, 2
    add  $10, $10, $fp
    lw  $10, 8($10)
    sll  $0, $0, 2
    add  $0, $0, $fp
    sw $10, 8($0)
    lw  $10, 32($fp)
    lw  $11, 36($fp)
    sll  $10, $10, 2
    add  $10, $10, $fp
    sw $11, 8($10)
	b endelse1
endif1:
endelse1:
    lw  $10, 32($fp)
    addu $10, $10, 1
    sw  $0, 32($fp)
endloop2:
    lw  $11, 28($fp)
    addu $11, $11, 1
    sw  $0, 28($fp)
endloop1:
    move $2,$0
    move $sp,$fp
    lw $fp,36($sp)
    addiu $sp,$sp,40
    j $31
nop
