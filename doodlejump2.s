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
	orange: .word 0x8c5426
	pink: .word 0xF87DFF
	magenta: .word 0xEB67C6
	azure: .word 0x538AFF
	lightazure: .word 0x77A2FF
	lightblue: .word 0xA2BFFF
	black: .word 0x000000
	red: .word 0xFF0000
	white: .word 0xFFFFFF
	bird: .word 0xF1DFC8
	sun: .word 0xFFE330
	
	p1x: .space 4 #688
	p1y: .space 4 
	p2x: .space 4 
	p2y: .space 4 
	p3x: .space 4 
	p3y: .space 4 

	doodlerx: .space 4
	doodlery: .space 4
	
	name: .space 4
.text
	lw $t0, displayAddress # $t0 stores the base address for display
	
	add $s0, $zero, $zero # 0 means no shift, 1 means shifting is active 
	addi $s1, $zero, 3 # Lowest platform
	add $s2, $zero, $zero # Score counter, min 0, max 99
	add $s3, $zero, $zero # s3 stores the number of times the doodler has shifted up/down
	addi $s4, $zero, 1 # s4 stores the status of the doodler; if it's going up or down
	
	
start: 	
	# Renders the first frames
	add $a0, $t0, 276
	jal DrawStartScreen
Await: 	lw $t8, 0xffff0000
	beq $t8, 1, CheckStart #If it detects keyboard input, changes to start
	j Await
CheckStart:
	lw $t2, 0xffff0004
	beq $t2, 0x73, PrepareGame # If 's', start the game
	beq $t2, 0x6E, EnterName # If 'n', go to input name
	j CheckStart
EnterName:
	lw $t8, 0xffff0000
	beq $t8, 1, CheckName
	j EnterName
CheckName:
	lw $t2, 0xffff0004
	sw $t2, name
	
	addi $a0, $t0, 1716
	
	jal DrawNameLetter

	j CheckStart
PrepareGame:
	jal InitialPlatforms
	j DrawBG



main: 	# Check for Keyboard Input
	lw $t8, 0xffff0000
	beq $t8, 1, KeyboardInput # Update location of doodler (And potentially platforms?)
	
UpDown: addi $t1, $zero, 12
	beq $s3, $t1, SwitchUpDown # Checks if s3, the total amount of upward/downward movements have hit 7
	j MoveDoodler
	
KeyboardInput: 
	lw $t2, 0xffff0004 # Load the keyboard input ASCII code
	beq $t2, 0x6A, MoveLeft # If the ASCII code corresponds to j
	beq $t2, 0x6B, MoveRight # If the ASCII Code corresponds to k
	j UpDown
MoveLeft:
	lw $t1, doodlerx # Load the initial x location of the doodler
	
	subiu $t2, $t1, 4 # Subtract 4 to move one pixel left
	sw $t2, doodlerx
	j UpDown
MoveRight:
	lw $t1, doodlerx
	
	addi $t2, $t1, 4 # Add 4 to move one pixel right
	sw $t2, doodlerx
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
	lw $t1, doodlery # Load doodler address
	subiu $t2, $t1, 128 # subtract 128 from the doodler address, moving the doodler up one pixel
	sw $t2, doodlery # store it back into memory
	addi $s3, $s3, 1 # add 1 to the "going up" counter 
	
	j CheckCollision
MoveDown:
	lw $t1, doodlery
	addiu $t2, $t1, 128
	sw $t2, doodlery
CheckCollision:
	lw $t1, doodlerx
	add $a0, $t2, $t1 # Store doodler absolute value
	
	lw $t1, p3x # Get x value
	lw $t2, p3y # Get y value
	
	add $a1, $t1, $t2 # Store the absolute value of platform into a1
	jal Collision
	
	lw $t1 p2x
	lw $t2, p2y
	
	add $a1, $t1, $t2
	jal Collision

	lw $t1, p1x
	lw $t2, p1y
	
	add $a1, $t1, $t2
	
	jal Collision
	
	jal ShiftPFDown
	
	# TODO: JUMP TO FUNCTION TO START "SHIFTING" DOWN PLATFORM
	addi $t1, $zero, 640
	lw $t2, doodlery
	blt $t2, $t1, ShiftDown # Anything less than 640 in terms of y value will cause shift-downs
	
	j DrawBG

ShiftPFDown:
	beq $s0, $zero, FinishShifting # If s0, the tracker, is 0, stop shifting
	
	addi $t1, $zero, 640 # Keep doodler at a constant Y value while the screen shifts
	sw $t1, doodlery
	
	lw $t1, p1y # Increase the y value of platform 1
	addi $t1, $t1, 128
	sw $t1, p1y
	
	lw $t1, p2y # Increase the y value of platform 2
	addi $t1, $t1, 128
	sw $t1, p2y
	
	lw $t1, p3y # Increase the y value of platform 3
	addi $t1, $t1, 128
	sw $t1, p3y
	
	addi $t2, $zero, 3968 # Max y value
	beq $t1, $t2, CancelShift # Cancel if platform 3 is at the bottom
	lw $t1, p2y
	beq $t1, $t2, CancelShift # Cancel if platform 3 is at the bottom
	lw $t1, p1y
	beq $t1, $t2, CancelShift # Cancel if platform 3 is at the bottom
	
	j FinishShifting
CancelShift:
	add $s0, $zero, $zero # Set s0 to 0 to disable shifting down
FinishShifting:
	jr $ra


ShiftDown: 
	addi $s0, $zero, 1 # Activate "shift-down" procedure
	
#	addi $t1, $zero, 256
	lw $t1, doodlery

	addi $t1, $zero, 3
	beq $t1, $s1, P3REGEN
	addi $t1, $zero, 2
	beq $t1, $s1, P2REGEN
	addi $t1, $zero, 1
	beq $t1, $s1, P1REGEN
P3REGEN:
	li $v0, 42 # Random number generator
	li $a0, 0 
	li $a1, 19 # Max number 19 (4 * 19 = 76, the max amount we want)
	syscall
	
	addi $t1, $zero, 4 # Store 4 into t1
	mul $t2, $a0, $t1 # Multiply 4 to get the actual pixel offset
	addi $t2, $t2, 16 # Add 16 to change it into the range we want
	# t2 now has our x-offset
	
	sw $t2, p3x # Store x-offset into memory
	
	add $t2, $zero, $zero # Initial location of platform
	sw $t2, p3y # Store it into the platform y offset memory
	
	addi $s1, $zero, 2
	
	j FinishGen
P2REGEN:
	li $v0, 42 # Random number generator
	li $a0, 0 
	li $a1, 19 # Max number 19 (4 * 19 = 76, the max amount we want)
	syscall
	
	addi $t1, $zero, 4 # Store 4 into t1
	mul $t2, $a0, $t1 # Multiply 4 to get the actual pixel offset
	addi $t2, $t2, 16 # Add 16 to change it into the range we want
	# t2 now has our x-offset
	
	sw $t2, p2x # Store x-offset into memory
	
	add $t2, $zero, $zero # Initial location of platform
	sw $t2, p2y # Store it into the platform y offset memory
	
	addi $s1, $zero, 1
	
	j FinishGen
P1REGEN:
	li $v0, 42 # Random number generator
	li $a0, 0 
	li $a1, 19 # Max number 19 (4 * 19 = 76, the max amount we want)
	syscall
	
	addi $t1, $zero, 4 # Store 4 into t1
	mul $t2, $a0, $t1 # Multiply 4 to get the actual pixel offset
	addi $t2, $t2, 16 # Add 16 to change it into the range we want
	# t2 now has our x-offset
	
	sw $t2, p1x # Store x-offset into memory
	
	add $t2, $zero, $zero # Initial location of platform
	sw $t2, p1y # Store it into the platform y offset memory
	
	addi $s1, $zero, 3
FinishGen: 
	j DrawBG

DrawBG:	add $a0, $t0, $zero # Store starting display address
	addi $a1, $zero, 4092 # The max size 
	jal DrawBackground
	
	blt $s2, 10, DrawSingleDigit
	bge $s2, 99, DrawMaxScore
	bge $s2, 10, DrawDoubleDigit
DrawMaxScore:
	addi $a0, $t0, 132 # tens place
	jal Draw9
	
	addi $a0, $t0, 148 # ones place
	jal Draw9
	
	j DrawBGItem
DrawSingleDigit:
	addi $a0, $t0, 132 # tens place
	jal Draw0
	
	addi $a0, $t0, 148 # ones place
	add $t1, $s2, $zero
	j DetermineDigit
	
DrawDoubleDigit:
	addi $t2, $zero, 10
	div $s2, $t2
	
	mflo $t1

	addi $a0, $t0, 132 # tens place
	addi $t2, $zero, 1
	j DetermineDigit
OnesDigit: 
	addi $t2, $zero, 10
	div $s2, $t2
	mfhi $t1
	
	addi $a0, $t0, 148 # ones place
	addi $t2, $zero, 0
	j DetermineDigit
	
DetermineDigit:
	beq $t1, 0, IF0
	beq $t1, 1, IF1
	beq $t1, 2, IF2
	beq $t1, 3, IF3
	beq $t1, 4, IF4
	beq $t1, 5, IF5
	beq $t1, 6, IF6
	beq $t1, 7, IF7
	beq $t1, 8, IF8
	beq $t1, 9, IF9
IF0: 
	jal Draw0
	beq $t2, 1, FinishTens
	j FinishDigit
IF1:
	jal Draw1
	beq $t2, 1, FinishTens
	j FinishDigit
IF2: 
	jal Draw2
	beq $t2, 1, FinishTens
	j FinishDigit
IF3:
	jal Draw3
	beq $t2, 1, FinishTens
	j FinishDigit
IF4: 
	jal Draw4
	beq $t2, 1, FinishTens
	j FinishDigit
IF5:
	jal Draw5
	beq $t2, 1, FinishTens
	j FinishDigit
IF6: 
	jal Draw6
	beq $t2, 1, FinishTens
	j FinishDigit
IF7:
	jal Draw7
	beq $t2, 1, FinishTens
	j FinishDigit
IF8: 
	jal Draw8
	beq $t2, 1, FinishTens
	j FinishDigit
IF9:
	jal Draw9
	beq $t2, 1, FinishTens
	j FinishDigit
FinishTens:
	j OnesDigit
FinishDigit:
	j DrawBGItem	

DrawBGItem:
	add $a0, $t0, $zero
	jal DrawCloud
	
	addi $a0, $t0, 1664
	jal DrawCloud
	
	addi $a0, $t0, 2084
	jal DrawBird
	
	addi $a0, $t0, 168
	jal DrawSun
DrawPF:
	lw $t1, p1x # Load the x offset location of the branch into a register
	lw $t2, p1y
	add $t3, $t1, $t2 # Add x and y offset together to get final location
	
	add $a0, $t0, $t3 # Add the offset to the displayAddress, and store it as an argument
	jal DrawPlatform # Draw the platform
	
	lw $t1, p2x # Load the x offset location of the branch into a register
	lw $t2, p2y
	add $t3, $t1, $t2 # Add x and y offset together to get final location

	add $a0, $t0, $t3
	jal DrawPlatform
	
	lw $t1, p3x # Load the x offset location of the branch into a register
	lw $t2, p3y
	add $t3, $t1, $t2 # Add x and y offset together to get final location
	
	add $a0, $t0, $t3
	jal DrawPlatform
DrawDD:
	lw $t1, doodlerx # x offset of doodler 
	lw $t2, doodlery # y offset of doodler
	add $t3, $t1, $t2 # Add together to get official offset
	
	add $a0, $t0, $t3
	jal DrawDoodler
Continue:
	# Sleep
	li $v0, 32
	li $a0, 100
	syscall
	
	# Continue looping
	j  main

GameOver:
	# Wait for 
	add $t1, $zero, $zero # Initialize increment variable i
	addi $t2, $zero, 4092
	add $t3, $t0, $zero
	
LOOPGO:	beq $t1, $t2, FinishGO
	
	lw $t5, black # Load the color code
	sw $t5, 0($t3) # Store color into memory at a0
	addi $t3, $t3, 4 # Increment address by 4
	addi $t1, $t1, 1 # Increment loop variable by 1
	j LOOPGO
FinishGO:
	addi $a0, $t0, 24
	jal DrawG
	jal DrawA
	jal DrawM
	jal DrawE
	jal DrawO
	jal DrawV
	jal DrawE2
	jal DrawR
	
	lw $t8, 0xffff0000
	beq $t8, 1, EndGame
	j FinishGO
RestartGame:
	# Resets everything before restarting the game
	
	lw $t0, displayAddress # $t0 stores the base address for display
	
	add $s0, $zero, $zero # 0 means no shift, 1 means shifting is active 
	addi $s1, $zero, 3 # Lowest platform
	add $s2, $zero, $zero # Score counter, min 0, max 99
	add $s3, $zero, $zero # s3 stores the number of times the doodler has shifted up/down
	addi $s4, $zero, 1 # s4 stores the status of the doodler; if it's going up or down
	
	
	j start
EndGame:
	lw $t1, 0xffff0004
	beq $t1, 0x72, RestartGame
	
	j Exit

# Functions

Collision: # Function
	subiu $t3, $a1, 648 # Left of the platform by 2 pixels
	subiu $t4, $a1, 620 # immediate right of the platform
	addi $t5, $zero, 4092
	
	bgt $a0, $t5, GameOver # Falls outside of box
	blt $a0, $t3, FinishCollision
	bgt $a0, $t4, FinishCollision
HandleCollision:
	add $s3, $zero, $zero # Set the counter of how many pixels the doodler has travelled to 0
	addi $s4, $zero, 1 # Set the direction to up
	addi $s2, $s2, 1 # Add 1 to score
FinishCollision:
	jr $ra


InitialPlatforms:
	li $v0, 42 # Random number generator
	li $a0, 0 
	li $a1, 19 # Max number 19 (4 * 19 = 76, the max amount we want)
	syscall
	
	addi $t1, $zero, 4 # Store 4 into t1
	mul $t2, $a0, $t1 # Multiply 4 to get the actual pixel offset
	addi $t2, $t2, 16 # Add 16 to change it into the range we want
	# t2 now has our x-offset
	
	sw $t2, p3x # Store x-offset into memory
	
	addi $t2, $zero, 3968 # Add 2944 
	sw $t2, p3y # Store it into the platform y offset memory
	
	li $v0, 42
	li $a0, 0
	li $a1, 19
	syscall
	
	addi $t1, $zero, 4
	mul $t2, $a0, $t1
	addi $t2, $t2, 16
	# t2 now has our x-offset
	
	sw $t2, p2x # Store into memory

	addi $t2, $zero, 2560
	sw $t2, p2y # Store y value into memory
	
	li $v0, 42
	li $a0, 0
	li $a1, 19
	syscall
	
	addi $t1, $zero, 4
	mul $t2, $a0, $t1
	addi $t2, $t2, 16 
	# t2 now has our x-offset
	sw $t2, p1x
	
	addi $t2, $zero, 1152
	sw $t2, p1y
	
	# Doodler portion
	lw $t1, p3x
	lw $t2, p3y
	
	sw $t1, doodlerx
	
	subi $t2, $t2, 640
	sw $t2, doodlery
	
	jr $ra

DrawBackground:
	add $t1, $zero, $zero # Initialize increment variable i
	lw $t5, azure # Load the color code
L1:	beq $t1, 384, BGL2
	
	sw $t5, 0($a0) # Store color into memory at a0
	addi $a0, $a0, 4 # Increment address by 4
	addi $t1, $t1, 1 # Increment loop variable by 1
	j L1
BGL2:	beq $t1, 768, BGL3
	lw $t5, lightazure # Load the color code
	sw $t5, 0($a0) # Store color into memory at a0
	addi $a0, $a0, 4 # Increment address by 4
	addi $t1, $t1, 1 # Increment loop variable by 1
	j BGL2
BGL3:
	beq $t1, 1024, FinishBG
	lw $t5, lightblue # Load the color code
	sw $t5, 0($a0) # Store color into memory at a0
	addi $a0, $a0, 4 # Increment address by 4
	addi $t1, $t1, 1 # Increment loop variable by 1
	j BGL3
FinishBG:	
	jr $ra

DrawPlatform: 	
	add $t1, $zero, $zero # Loop increment variable, i
      	addi $t2, $zero, 6 # Length of a platform
L2: 	beq $t1, $t2, FinishPlatform # If i == 5, exit the loop
	beqz $t1 IF # If i == 0, do not increment by 4
	addi $a0, $a0, 4 # Increment the "location pointer" by 4 to create another pixel
	
	lw $t3, orange
	
	sw $t3, 0($a0) # Load it into memory
	addi $t1, $t1, 1 # Increment i
	j L2 # Continue looping
IF:	lw $t3, orange
	sw $t3, 0($a0)
	addi $t1, $t1, 1
	j L2
FinishPlatform:	
	jr $ra # Jump back to Draw

DrawDoodler: 
	# Draws the doodler relative to the top LEFT corner of a box that is 3x3
	lw $t1, pink
	lw $t2, red
	lw $t3, sun
	
	
	sw $t2, 0($a0) #Head row 1
	sw $t1, 4($a0) 
	sw $t2, 8($a0) 
	
	lw $t2, magenta
	sw $t2, 128($a0)# Head  row 2
	sw $t2, 132($a0) 
	sw $t2, 136($a0)
	
	sw $t2, 260($a0)
	
	sw $t1, 384($a0)
	sw $t1, 392($a0)
	sw $t3, 512($a0)
	sw $t3, 520($a0)
	jr $ra

DrawCloud:
	lw $t1, white
	add $t2, $zero, $zero
	add $t3, $a0, $zero
LOOPROW1:
	beq $t2, 4, Row1Fin
	sw $t1, 1280($t3)
	addi $t3, $t3, 4
	addi $t2, $t2, 1
	j LOOPROW1
Row1Fin:
	add $t2, $zero, $zero
	add $t3, $a0, $zero
LOOPROW2:
	beq $t2, 6, Row2Fin
	sw $t1, 1408($t3)
	addi $t3, $t3, 4
	addi $t2, $t2, 1
	j LOOPROW2
Row2Fin:
	add $t2, $zero, $zero
	add $t3, $a0, $zero
LOOPROW3:
	beq $t2, 5, Row3Fin
	sw $t1, 1536($t3)
	addi $t3, $t3, 4
	addi $t2, $t2, 1
	j LOOPROW3
Row3Fin:
	add $t2, $zero, $zero
	add $t3, $a0, $zero
LOOPROW4:
	beq $t2, 3, Row4Fin
	sw $t1, 1664($t3)
	addi $t3, $t3, 4
	addi $t2, $t2, 1
	j LOOPROW4
Row4Fin:
	jr $ra

DrawBird:
	lw $t1, bird
	
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t1, 20($a0)
	sw $t1, 24($a0)
	
	sw $t1, 136($a0)
	sw $t1, 144($a0)
	sw $t1, 136($a0)
	
	sw $t1, 268($a0)
	
	jr $ra

DrawSun:
	lw $t1, sun
	
	sw $t1, 4($a0)
	sw $t1, 8($a0)
	sw $t1, 12($a0)
	
	addi $t2, $a0, 128
	add $t3, $zero, $zero
LOOPSUN1:
	beq $t3, 5, Sun1Fin
	sw $t1, 0($t2)
	addi $t2, $t2, 4
	addi $t3, $t3, 1
	j LOOPSUN1
Sun1Fin:
	addi $t2, $a0, 256
	add $t3, $zero, $zero
LOOPSUN2:
	beq $t3, 5, Sun2Fin
	sw $t1, 0($t2)
	addi $t2, $t2, 4
	addi $t3, $t3, 1
	j LOOPSUN2
Sun2Fin:
	sw $t1, 388($a0)
	sw $t1, 392($a0)
	sw $t1, 396($a0)
	
	jr $ra
	
# Letters

DrawG:
	lw $t1, red
	sw $t1, 388($a0) # a0 will contain the value in $t0
	sw $t1, 392($a0)
	sw $t1, 396($a0)
	sw $t1, 512($a0)
	sw $t1, 640($a0)
	sw $t1, 648($a0)
	sw $t1, 652($a0)
	sw $t1, 768($a0)
	sw $t1, 780($a0)
	sw $t1, 900($a0)
	sw $t1, 904($a0)
	sw $t1, 908($a0)
	
	jr $ra

DrawA:
	lw $t1, red
	sw $t1, 408($a0)
	sw $t1, 532($a0)
	sw $t1, 540($a0)
	sw $t1, 660($a0)
	sw $t1, 664($a0)
	sw $t1, 668($a0)
	sw $t1, 788($a0)
	sw $t1, 796($a0)
	sw $t1, 916($a0)
	sw $t1, 924($a0)
	
	jr $ra
	
DrawM:
	lw $t1, red
	sw $t1, 420($a0)
	sw $t1, 548($a0)
	sw $t1, 676($a0)
	sw $t1, 804($a0)
	sw $t1, 932($a0)
	
	sw $t1, 552($a0)
	sw $t1, 560($a0)
	sw $t1, 684($a0)
	
	sw $t1, 436($a0)
	sw $t1, 564($a0)
	sw $t1, 692($a0)
	sw $t1, 820($a0)
	sw $t1, 948($a0)
	
	jr $ra

DrawE:
	lw $t1, red
	sw $t1, 444($a0)
	sw $t1, 448($a0)
	sw $t1, 452($a0)
	sw $t1, 572($a0)
	sw $t1, 700($a0)
	sw $t1, 704($a0)
	sw $t1, 708($a0)
	sw $t1, 828($a0)
	sw $t1, 956($a0)
	sw $t1, 960($a0)
	sw $t1, 964($a0)
	jr $ra

DrawO:
	addi $a0, $a0, 768
	
	lw $t1, red
	sw $t1, 388($a0) # a0 will contain the value in $t0
	sw $t1, 392($a0)
	sw $t1, 396($a0)
	
	sw $t1, 512($a0)
	sw $t1, 640($a0)
	sw $t1, 768($a0)
	
	sw $t1, 528($a0)
	sw $t1, 656($a0)
	sw $t1, 784($a0)
	
	sw $t1, 900($a0)
	sw $t1, 904($a0)
	sw $t1, 908($a0)
	
	jr $ra


DrawV:
	lw $t1, red
	
	sw $t1, 408($a0)
	sw $t1, 536($a0)
	sw $t1, 664($a0)
	sw $t1, 792($a0)
	
	sw $t1, 924($a0)
	
	sw $t1, 416($a0)
	sw $t1, 544($a0)
	sw $t1, 672($a0)
	sw $t1, 800($a0)
	
	jr $ra

DrawE2:
	lw $t1, red
	
	sw $t1, 424($a0)
	sw $t1, 428($a0)
	sw $t1, 432($a0)
	
	sw $t1, 552($a0)
	sw $t1, 680($a0)
	sw $t1, 684($a0)
	sw $t1, 688($a0)
	sw $t1, 808($a0)
	sw $t1, 936($a0)
	sw $t1, 940($a0)
	sw $t1, 944($a0)
	
	jr $ra

DrawR:
	lw $t1, red
	
	sw $t1, 444($a0)
	sw $t1, 568($a0)
	sw $t1, 576($a0)
	sw $t1, 696($a0)
	sw $t1, 700($a0)
	sw $t1, 824($a0)
	sw $t1, 832($a0)
	sw $t1, 952($a0)
	sw $t1, 964($a0)
	
	jr $ra
	
# Numbers

Draw0:
	lw $t1, black
	
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t1, 8($a0)
	sw $t1, 128($a0)
	sw $t1, 136($a0)
	sw $t1, 256($a0)
	sw $t1, 264($a0)
	sw $t1, 384($a0)
	sw $t1, 392($a0)
	
	sw $t1, 512($a0)
	sw $t1, 516($a0)
	sw $t1, 520($a0)
	
	jr $ra
Draw1:
	lw $t1, black
	
	sw $t1, 4($a0)
	sw $t1, 132($a0)
	sw $t1, 260($a0)
	sw $t1, 388($a0)
	sw $t1, 516($a0)
	
	jr $ra
Draw2:
	lw $t1, black
	
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t1, 8($a0)
	sw $t1, 136($a0)
	sw $t1, 264($a0)
	sw $t1, 260($a0)
	sw $t1, 256($a0)

	sw $t1, 384($a0)
	sw $t1, 512($a0)
	sw $t1, 516($a0)
	sw $t1, 520($a0)
	
	jr $ra
Draw3:
	lw $t1, black
	
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t1, 8($a0)
	
	sw $t1, 136($a0)
	
	sw $t1, 264($a0)
	sw $t1, 260($a0)
	sw $t1, 256($a0)
	
	sw $t1, 392($a0)
	sw $t1, 512($a0)
	sw $t1, 516($a0)
	sw $t1, 520($a0)
	
	jr $ra
Draw4:
	lw $t1, black
	
	sw $t1, 0($a0)
	sw $t1, 128($a0)
	sw $t1, 256($a0)
	
	sw $t1, 260($a0)
	
	sw $t1, 8($a0)
	sw $t1, 136($a0)
	sw $t1, 264($a0)
	sw $t1, 392($a0)
	sw $t1, 520($a0)
	
	jr $ra
Draw5:
	lw $t1, black
	
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t1, 8($a0)
	
	sw $t1, 128($a0)
	
	sw $t1, 264($a0)
	sw $t1, 260($a0)
	sw $t1, 256($a0)

	sw $t1, 392($a0)
	
	sw $t1, 512($a0)
	sw $t1, 516($a0)
	sw $t1, 520($a0)
	
	jr $ra
Draw6:
	lw $t1, black
	
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t1, 8($a0)
	
	sw $t1, 128($a0)
	
	sw $t1, 264($a0)
	sw $t1, 260($a0)
	sw $t1, 256($a0)

	sw $t1, 384($a0)
	sw $t1, 392($a0)
	
	sw $t1, 512($a0)
	sw $t1, 516($a0)
	sw $t1, 520($a0)
	
	jr $ra
Draw7:
	lw $t1, black
	
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	
	sw $t1, 8($a0)
	sw $t1, 136($a0)
	sw $t1, 264($a0)
	sw $t1, 392($a0)
	sw $t1, 520($a0)
	
	jr $ra
Draw8:
	lw $t1, black
	
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t1, 8($a0)
	
	sw $t1, 128($a0)
	sw $t1, 136($a0)
	
	sw $t1, 256($a0)
	sw $t1, 260($a0)
	sw $t1, 264($a0)
	
	sw $t1, 384($a0)
	sw $t1, 392($a0)
	sw $t1, 512($a0)
	sw $t1, 516($a0)
	sw $t1, 520($a0)
	
	jr $ra
Draw9:
	lw $t1, black
	
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t1, 8($a0)
	
	sw $t1, 128($a0)
	sw $t1, 136($a0)
	
	sw $t1, 264($a0)
	sw $t1, 260($a0)
	sw $t1, 256($a0)

	sw $t1, 392($a0)
	
	sw $t1, 512($a0)
	sw $t1, 516($a0)
	sw $t1, 520($a0)
	
	jr $ra

DrawNameLetter:
	lw $t1, magenta
	lw $t2, name
	beq $t2, 0x61, DrawNameA
	beq $t2, 0x62, DrawNameB
	beq $t2, 0x63, DrawNameC
	
	jr $ra
DrawNameA:
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t1, 8($a0)

	sw $t1, 128($a0)
	sw $t1, 136($a0)
	
	sw $t1, 256($a0)
	sw $t1, 260($a0)
	sw $t1, 264($a0)
	
	sw $t1, 384($a0)
	sw $t1, 392($a0)
	
	jr $ra
DrawNameB:
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t1, 8($a0)

	sw $t1, 128($a0)
	sw $t1, 136($a0)
	
	sw $t1, 256($a0)
	sw $t1, 260($a0)
	
	sw $t1, 384($a0)
	sw $t1, 392($a0)
	
	sw $t1, 512($a0)
	sw $t1, 516($a0)
	sw $t1, 520($a0)
	
	jr $ra

DrawNameC:
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t1, 8($a0)

	sw $t1, 128($a0)
	sw $t1, 136($a0)
	
	sw $t1, 256($a0)
	
	sw $t1, 384($a0)
	sw $t1, 392($a0)
	
	sw $t1, 512($a0)
	sw $t1, 516($a0)
	sw $t1, 520($a0)
	
	jr $ra

DrawStartScreen:
	lw $t1, bird
	add $t2, $zero, $zero
	add $t3, $t0, $zero
SSLoop:
	beq $t2, 1024, SSLoopFin
	sw $t1, 0($t3)
	addi $t2, $t2, 1
	addi $t3, $t3, 4
	j SSLoop
SSLoopFin:
	lw $t1, black
	
	# N
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t1, 16($a0)
	
	sw $t1, 128($a0)
	sw $t1, 136($a0)
	sw $t1, 144($a0)
	
	sw $t1, 256($a0)
	sw $t1, 268($a0)
	sw $t1, 272($a0)
	
	sw $t1, 384($a0)
	sw $t1, 400($a0)
	
	sw $t1, 512($a0)
	sw $t1, 528($a0)
	
	addi $a0, $a0, 24
	
	# A
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t1, 8($a0)

	sw $t1, 128($a0)
	sw $t1, 136($a0)
	
	sw $t1, 256($a0)
	sw $t1, 260($a0)
	sw $t1, 264($a0)
	
	sw $t1, 384($a0)
	sw $t1, 392($a0)

	sw $t1, 512($a0)
	sw $t1, 520($a0)
	
	addi $a0, $a0, 16
	
	# M
	sw $t1, 0($a0)
	sw $t1, 16($a0)
	
	sw $t1, 128($a0)
	sw $t1, 132($a0)
	sw $t1, 140($a0)
	sw $t1, 144($a0)
	
	sw $t1, 256($a0)
	sw $t1, 264($a0)
	sw $t1, 272($a0)
	
	sw $t1, 384($a0)
	sw $t1, 400($a0)
	sw $t1, 512($a0)
	sw $t1, 528($a0)
	
	addi $a0, $a0, 24

	# E
	
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t1, 8($a0)

	sw $t1, 128($a0)
	
	sw $t1, 256($a0)
	sw $t1, 260($a0)
	sw $t1, 264($a0)
	
	sw $t1, 384($a0)

	sw $t1, 512($a0)
	sw $t1, 516($a0)
	sw $t1, 520($a0)

	jr $ra

Exit:
	li $v0, 10 # terminate the program gracefully
	syscall
