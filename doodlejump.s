# Demo for painting
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
.data
	displayAddress: .word 0x10008000
	colorone: .word 0xff0000
	colortwo: .word 0x00ff00
	colorthree: .word 0x0000ff
	
.text
	lw $t0, displayAddress # $t0 stores the base address for display
	lw $s0, colorone # $t1 stores the red colour code
	lw $s1, colortwo

Draw: 	
	addi $a0, $t0, 160 # Initialize the input argument to the function, the leftmost element of the branch
	jal DrawBranch	# Draw the branch
	addi $a0, $t0, 1168 # Initialize the input argument to the function, the leftmost element of the branch
	jal DrawBranch
	addi $a0, $t0, 3136 # Initialize the input argument to the function, the leftmost element of the branch
	jal DrawBranch
	j Exit


DrawBranch: 	
	add $t1, $zero, $zero # Loop increment variable, i
      	addi $t2, $zero, 5 # Length of a platform
LOOP: 	beq $t1, $t2, End
	beqz $t1 IF
	addi $a0, $a0, 4
	sw $s0, 0($a0)
	addi $t1, $t1, 1
	j LOOP
IF:	sw $s0, 0($a0)
	addi $t1, $t1, 1
	j LOOP
End:	jr $ra


DrawBranchTwo: 	
	add $t1, $zero, $zero # Loop increment variable, i
      	addi $t2, $zero, 5 # Length of a platform
 	addi $t0, $t0, 1024
LOOPTwo:
	beq $t1, $t2, DrawBranchThree
	addi $t0, $t0, 4
	sw $t5, 0($t0)
	addi $t1, $t1, 1
	j LOOPTwo

DrawBranchThree: 	
	add $t1, $zero, $zero # Loop increment variable, i
      	addi $t2, $zero, 5 # Length of a platform
 	addi $t0, $t0, 2048
LOOPThree:
	beq $t1, $t2, DrawDoodler
	addi $t0, $t0, 4
	sw $t5, 0($t0)
	addi $t1, $t1, 1
	j LOOPThree

DrawDoodler: 
	lw $t0, displayAddress
	sw $t6, 4($t0)
	sw $t6, 128($t0)
	sw $t6, 136($t0)
	sw $t6, 256($t0)
	sw $t6, 264($t0)
	
Exit:
	li $v0, 10 # terminate the program gracefully
	syscall
