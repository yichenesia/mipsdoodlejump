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
	lw $t5, colorone # $t1 stores the red colour code
	lw $t6, colortwo

DrawBranch: 	
	add $t1, $zero, $zero # Loop increment variable, i
      	addi $t2, $zero, 5 # Length of a platform
      	addi $t0, $t0, 144
LOOP: 	beq $t1, $t2, DrawBranchTwo
	addi $t0, $t0, 4
	sw $t5, 0($t0)
	addi $t1, $t1, 1
	j LOOP

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
