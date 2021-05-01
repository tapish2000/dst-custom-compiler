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
	slt $4 $4 $5
    beq $4, $0, endloopif2
    nop
    lw  $6, 32($fp)
    sll  $6, $6, 2
    add  $6, $6, $fp
    lw  $6, 8($6)
    lw  $7, 32($fp)
    addu $7, $7, 1
    sll  $7, $7, 2
    add  $7, $7, $fp
    lw  $7, 8($7)
	slt $6 $7 $6
	beq $6 $0 endif1
    lw  $8, 32($fp)
    addu $8, $8, 1
    sll  $8, $8, 2
    add  $8, $8, $fp
    lw  $8, 8($8)
    sw $8, 36($fp)
    lw  $8, 32($fp)
    addu $8, $8, 1
    lw  $9, 32($fp)
    sll  $9, $9, 2
    add  $9, $9, $fp
    lw  $9, 8($9)
    sll  $8, $8, 2
    add  $8, $8, $fp
    sw $9, 8($8)
    lw  $8, 32($fp)
    lw  $9, 36($fp)
    sll  $8, $8, 2
    add  $8, $8, $fp
    sw $9, 8($8)
	b endelse1
endif1:
endelse1:
    lw  $8, 32($fp)
    addu $8, $8, 1
    sw  $8, 32($fp)
endloopif2:
    lw  $8, 28($fp)
    addu $8, $8, 1
    sw  $8, 28($fp)
endloopif1:
    move $2,$0
    move $sp,$fp
    lw $fp,36($sp)
    addiu $sp,$sp,40
    j $31
nop
