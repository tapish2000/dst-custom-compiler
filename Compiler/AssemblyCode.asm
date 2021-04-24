main:
    addiu $sp,$sp,-36
    sw $fp,32($sp)
    move $fp,$sp
    lw $2, 28($fp)
  addu $2, $2, 1
    lw $3, 28($fp)
  addu $3, $3, 1
    lw  $4, $28($fp)
    sll  $4, $4, 2
 	  add $3, $3, $fp
    sw $4, 8($3)
    move $2,$0
    move $sp,$fp
    lw $fp,32($sp)
    addiu $sp,$sp,36
    j $31
nop
