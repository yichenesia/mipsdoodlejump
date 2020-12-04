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
	
	platformone: .space 4 #688
	platformtwo: .space 4 #2336
	platformthree: .space 4 #3136
	
	doodler: .word 2576
.text
	lw $t0, displayAddress # $t0 stores the base address for display
	add $s3, $zero, $zero # s3 stores the number of times the doodler has shifted up/down
	addi $s4, $zero, 1 # s4 stores the status of the doodler; if it's going up or down
	addi $s5, $zero, 9 #s5 stores the MAX number of times a doodler can move up or down

start: 	
	# Renders the first frame
	jal InitialPlatforms
	j DrawBG

main: 	# Check for Keyboard Input
	lw $t8, 0xffff0000
	beq $t8, 1, KeyboardInput # Update location of doodler (And potentially platforms?)
UpDown: beq $s3, $s5, SwitchUpDown # Checks if s3, the total amount of upward/downward movements have hit 7
	j MoveDoodler
	
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

SwitchUpDown: 
	add $s4, $zero, $zero # "Reverses" the bits in s4
	add $s3, $zero, $zero # Resets the counter
MoveDoodler: 
	addi $t1, $zero, 0 # Stores 0 into t1 so that we can check equality
	beq $s4, $t1, MoveDown # Checks if s4 is 0, which means it is currently in the  "movedown" phase
	addi $t1, $zero, 1 # Stores 1 into t1 so we can check equality
	beq $s4, $t1, MoveUp # If s4 is 1, go into "moveup" phase
MoveUp:
	lw $t1, doodler # Load doodler address
	subiu $t2, $t1, 128 # subtract 128 from the doodler address, moving the doodler up one pixel
	sw $t2, doodler # store it back into memory
	addi $s3, $s3, 1 # add 1 to the "going up" counter 
	
	j CheckCollision
MoveDown:
	lw $t1, doodler
	addiu $t2, $t1, 128
	sw $t2, doodler
CheckCollision:
	add $a0, $t2, $zero
	lw $a1, platformthree
	jal Collision
	
	lw $a1, platformtwo
	jal Collision

	lw $a1, platformone
	jal Collision
	
	j DrawBG
	

Collision: # Function
	subiu $t3, $a1, 392 # Left of the platform by 2 pixels
	subiu $t4, $a1, 368 # immediate right of the platform
	blt $a0, $t3, FinishCollision
	bgt $a0, $t4, FinishCollision
HandleCollision:
	add $s3, $zero, $zero # Set the counter of how many pixels the doodler has travelled to 0
	addi $s4, $zero, 1 # Set the direction to up
FinishCollision:
	jr $ra
	
DrawBG:	add $a0, $t0, $zero # Store the display address into an argument function
	addi $a1, $zero, 4092 # The max size 
	jal DrawBackground
DrawPF:
	lw $t1, platformone # Load the offset location of the branch into a register
	add $a0, $t0, $t1 # Add the offset to the displayAddress, and store it as an argument
	jal DrawPlatform # Draw the platform
	lw $t1, platformtwo
	add $a0, $t0, $t1
	jal DrawPlatform
	lw $t1, platformthree
	add $a0, $t0, $t1
	jal DrawPlatform
DrawDD:
	lw $t1, doodler 
	add $a0, $t0, $t1
	jal DrawDoodler
Continue:
	# Sleep
	li $v0, 32
	li $a0, 100
	syscall
	
	# Continue looping
	j  main

# Functions

InitialPlatforms:
	li $v0, 42 # Random number generator
	li $a0, 0 
	li $a1, 19 # Max number 19 (4 * 19 = 76, the max amount we want)
	syscall
	
	addi $t1, $zero, 4 # Store 4 into t1
	mul $t2, $a0, $t1 # Multiply 4 to get the actual pixel offset
	addi $t2, $t2, 16 # Add 16 to change it into the range we want
	addi $t2, $t2, 2944 # Add 2944 - the Y value
	sw $t2, platformthree # Store it into the platform memory
	
	li $v0, 42
	li $a0, 0
	li $a1, 19
	syscall
	
	addi $t1, $zero, 4
	mul $t2, $a0, $t1
	addi $t2, $t2, 16
	addi $t2, $t2, 1920
	sw $t2, platformtwo
	
	li $v0, 42
	li $a0, 0
	li $a1, 19
	syscall
	
	addi $t1, $zero, 4
	mul $t2, $a0, $t1
	addi $t2, $t2, 16
	addi $t2, $t2, 896
	sw $t2, platformone
	
	lw $t1, platformthree
	subi $t2, $t1, 384
	sw $t2, doodler
	
	jr $ra

DrawBackground:
	add $t1, $zero, $zero # Initialize increment variable i
L1:	beq $t1, $a1, FinishBG
	lw $t2, platformone
	lw $t3, platformtwo
	lw $t4, platformthree
	
	lw $t5, colorthree # Load the color code
	sw $t5, 0($a0) # Store color into memory at a0
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
	
	lw $t3, colorone
	
	sw $t3, 0($a0) # Load it into memory
	addi $t1, $t1, 1 # Increment i
	j L2 # Continue looping
IF:	lw $t3, colorone
	sw $t3, 0($a0)
	addi $t1, $t1, 1
	j L2
FinishPlatform:	
	jr $ra # Jump back to Draw

DrawDoodler: 
	# Draws the doodler relative to the top LEFT corner of a box that is 3x3
	lw $t1, colortwo
	sw $t1, 4($a0) 
	sw $t1, 128($a0)
	sw $t1, 136($a0)
	sw $t1, 256($a0)
	sw $t1, 264($a0)
	jr $ra
	
Exit:
	li $v0, 10 # terminate the program gracefully
	syscall
