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
	colorone: .word 0xFFCA8A
	colortwo: .word 0x8AB8FF
	colorthree: .word 0xD8FFEC
	
	
.text
	lw $t0, displayAddress # $t0 stores the base address for display
	lw $s0, colorone # $s0 stores the orange colour code
	lw $s1, colortwo # $s1 stores the blue colour code
	lw $s2, colorthree # $s2 stores the green colour code

Draw: 	
	add $a0, $t0, $zero
	addi $a1, $zero, 4092
	jal DrawBackground
	
	addi $a0, $t0, 160 # Initialize the input argument to the function, the leftmost element of the branch
	jal DrawBranch	# Draw the branch
	addi $a0, $t0, 1168 
	jal DrawBranch
	addi $a0, $t0, 3136 
	jal DrawBranch
	addi $a0, $t0, 2752
	jal DrawDoodler
	
	j Exit


DrawBackground:
	add $t1, $zero, $zero # Initialize increment variable i
L1:	beq $t1, $a1, FinishBG
	sw $s2, 0($a0)
	addi $a0, $a0, 4
	addi $t1, $t1, 1
	j L1
FinishBG:	
	jr $ra

	
DrawBranch: 	
	add $t1, $zero, $zero # Loop increment variable, i
      	addi $t2, $zero, 5 # Length of a platform
L2: 	beq $t1, $t2, FinishBranch # If i == 5, exit the loop
	beqz $t1 IF # If i == 0, do not increment by 4
	addi $a0, $a0, 4 # Increment the "location pointer" by 4 to create another pixel
	sw $s0, 0($a0) # Load it into memory
	addi $t1, $t1, 1 # Increment i
	j L2 # Continue looping
IF:	sw $s0, 0($a0)
	addi $t1, $t1, 1
	j L2
FinishBranch:	
	jr $ra # Jump back to Draw


DrawDoodler: 
	sw $s1, 4($a0)
	sw $s1, 128($a0)
	sw $s1, 136($a0)
	sw $s1, 256($a0)
	sw $s1, 264($a0)
	jr $ra
	
Exit:
	li $v0, 10 # terminate the program gracefully
	syscall
