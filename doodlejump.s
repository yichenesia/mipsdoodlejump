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
	
	platformone: .word 160
	platformtwo: .word 1168
	platformthree: .word 3136
	
	doodler: .word 2752
.text
	lw $t0, displayAddress # $t0 stores the base address for display
	lw $s0, colorone # $s0 stores the orange colour code
	lw $s1, colortwo # $s1 stores the blue colour code
	lw $s2, colorthree # $s2 stores the green colour code
	add $s3, $zero, $zero
	addi $s4, $zero, 1
	addi $s5, $zero, 7

main: 	# Check for Keyboard Input
	lw $t8, 0xffff0000
	beq $t8, 1, KeyboardInput # Update location of doodler (And potentially platforms?)
UpDown: beq $s3, $s5, CheckUpDown # Checks if s3, the total amount of upward/downward movements have hit 5
	j CheckMove
CheckMove: 
	addi $t1, $zero, 0xFFFFFFFE # Stores 1 into t1 so that we can check equality
	beq $s4, $t1, MoveDown # Checks if s4 is 0, which means it is currently in the  "movedown" phase
	addi $t1, $zero, 1
	beq $s4, $t1, MoveUp

CheckUpDown: 
	not $s4, $s4 # "Reverses" the bits in s4
	add $s3, $zero, $zero # Resets the counter
	j CheckMove
	
MoveUp:
	lw $t1, doodler 
	subiu $t2, $t1, 128
	sw $t2, doodler
	addi $s3, $s3, 1
	j DrawBG
MoveDown:
	lw $t1, doodler
	addiu $t2, $t1, 128
	sw $t2, doodler
	addi $s3, $s3, 1
	j DrawBG
	
DrawBG:	add $a0, $t0, $zero # Store the display address into an argument function
	addi $a1, $zero, 4092 # The max size 
	jal DrawBackground
	j DrawPF

DrawPF:
	lw $t1, platformone # Load the offset location of the branch into a register
	add $a0, $t0, $t1 # Add the offset to the displayAddress, and store it as an argument
	jal DrawPlatform # Draw the branch
	lw $t1, platformtwo
	add $a0, $t0, $t1
	jal DrawPlatform
	lw $t1, platformthree
	add $a0, $t0, $t1
	jal DrawPlatform
	
	j DrawDD

DrawDD:
	lw $t1, doodler 
	add $a0, $t0, $t1
	jal DrawDoodler
	
	j Continue

Continue:
	# Sleep
	li $v0, 32
	li $a0, 1000
	syscall
	
	# Continue looping
	j  main
KeyboardInput: 
	lw $t2, 0xffff0004 # Load the keyboard input ASCII code
	beq $t2, 0x6A, MoveLeft # If the ASCII code corresponds to j
	beq $t2, 0x6B, MoveRight # If the ASCII Code corresponds to k
	bne $t2, 0x6A, Exit # Exit game when j or k is not pressed
	bne $t2, 0x6B, Exit
MoveLeft:
	lw $t1, doodler # Load the initial location of the doodler
	subiu $t2, $t1, 4 # Subtract 4 to move one pixel left
	sw $t2, doodler
	j UpDown
MoveRight:
	lw $t1, doodler
	addi $t2, $t1, 4 # Add 4 to move one pixel right
	sw $t2, doodler
	j UpDown
	
DrawBackground:
	add $t1, $zero, $zero # Initialize increment variable i
L1:	beq $t1, $a1, FinishBG
	lw $t2, platformone
	lw $t3, platformtwo
	lw $t4, platformthree
	
	sw $s2, 0($a0) # Store color into memory at a0
	addi $a0, $a0, 4 # Increment address by 4
	addi $t1, $t1, 1 # Increment loop variable by 1
	j L1

FinishBG:	
	jr $ra

DrawPlatform: 	
	add $t1, $zero, $zero # Loop increment variable, i
      	addi $t2, $zero, 5 # Length of a platform
L2: 	beq $t1, $t2, FinishPlatform # If i == 5, exit the loop
	beqz $t1 IF # If i == 0, do not increment by 4
	addi $a0, $a0, 4 # Increment the "location pointer" by 4 to create another pixel
	sw $s0, 0($a0) # Load it into memory
	addi $t1, $t1, 1 # Increment i
	j L2 # Continue looping
IF:	sw $s0, 0($a0)
	addi $t1, $t1, 1
	j L2
FinishPlatform:	
	jr $ra # Jump back to Draw

DrawDoodler: 
	# Draws the doodler relative to the top LEFT corner of a box that is 3x3
	sw $s1, 4($a0) 
	sw $s1, 128($a0)
	sw $s1, 136($a0)
	sw $s1, 256($a0)
	sw $s1, 264($a0)
	jr $ra
	
Exit:
	li $v0, 10 # terminate the program gracefully
	syscall
