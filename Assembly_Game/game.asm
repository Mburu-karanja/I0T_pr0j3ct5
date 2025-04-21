#####################################################################
#
# CSCB58 Winter 2022 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Lyam Katz, 1008908210, katzlyam, l.katz@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4 (update this as needed)
# - Unit height in pixels: 4 (update this as needed)
# - Display width in pixels: 256 (update this as needed)
# - Display height in pixels: 256 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 3
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. Health and score (score is coins)(2pts)
# 2. double jump (1)
# 3. moving platforms (2)
# 4. fail condition (die)(1)
# 5. win condition (collect all coins)(1)
# 6. moving objects (enemy/spikes) (2)
# 2 + 1 + 2 + 1 + 1 + 2 = 9pts.
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
# https://youtu.be/wZO2sqAsRyY
# Are you OK with us sharing the video with people outside course staff?
# - yes, and please share this project github link as well!
# https://github.com/Lyam-Katz/Assembly_Game
# Private until after final exam
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################
.data
    #Define the necessary variables to be stored in static data.
    coin2: .word 1
    coin3: .word 1
    coin4: .word 1
    health: .word 3
    health_temp: .word 3
   
    score: .word 0
    score_temp: .word 0
    last_coin: .word 260
    last_heart: .word 400
    on_backwards: .word 1
    enemy: .word 15632
    enemy_mult: .word 1
.eqv BASE_ADDRESS 0x10008000
.text
main:
	#Store the starting game data
	li $s7, 1
	sw $s7, coin2
	sw $s7, coin3
	sw $s7, coin4
	
	li $s7, 3
	sw $s7, health
	
	li $s7, 0
	sw $s7, score
	
	li $s7, 15688
	sw $s7, enemy
	
	li $s7, 1
	sw $s7, enemy_mult
	
    	li $t7, 15620
    	li $t6, 15640#moving platform 1
    	li $s1, 0 #velocity
    	li $s2, 0 #acceleration
    	li $s0, 0 #height
    	li $s3, 0 #canJump
    	li $s4, 1 #directionMultiplierOb3
    	li $s5, 1 #onMovingPlatform1
    	li $s6, 0 #coin1Grabbed
    	
    	jal game_loop
    	#j terminate

game_loop:
	#Perform the actions to be performed every frame
	lw $s7, score
	bge, $s7, 4, win_screen
	lw $s7, health
	ble, $s7, 0, lose_screen
    	li $t9, 0xffff0000 
	lw $t8, 0($t9)
	beq $t8, 1, keypress_happened
    	j processed
   	 #jal draw_frame

processed:
	#draw the frame, wait for it to finish, and then do the post frame actions before returning to came loop through check1
    	jal draw_game
    	li $v0, 32
	li $a0, 25 # Wait one frame
	syscall
	#addi $t7, $t7, 8
	add $s0, $s0, $s1
	#height of head is higher than platform so heigher than or equal 1024 but less than 1792 and
	#legs are under platform or on platorm level and
	#correct x position 132 to 160
	#then we don't go up
	add $s1, $s1, $s2
	jal terminal_velocity
	li $t0, 4
	mul $t0, $t0, $s4
	add $t6, $t6, $t0
	jal move_with_block
	li $t0, 4
	lw $s7, enemy_mult
	mul $t0, $t0, $s7
	lw $s7, enemy
	add $s7, $s7, $t0
	sw $s7, enemy
	li $s5, 1
	li $s7, 1
	sw $s7, on_backwards
	jal update_multiplier
	jal clear_screen
	ble $s0, $zero, floor
	
    	j check1
terminal_velocity:
	#check if the player reached terminal velocity
	ble $s1, -1500, constant_velocity
	jr $ra
constant_velocity:
	#undo acceleration since the player is moving at terminal velocity
	sub $s1, $s1, $s2
	jr $ra
move_with_block:
	#make sure the user moves with the moving platform if they are on one
	blez $s5, on
	lw $s7, on_backwards
	blez $s7, on_reverse
	jr $ra
on:
	#move the player with the moving platform
	add $t7, $t7, $t0
	jr $ra
on_reverse:
	#move the player with the reverse platform
	sub $t7, $t7, $t0
	jr $ra
update_multiplier:
	#Flip the platforms and/or enemy if necessary
	ble $t6, 15636, flip
	bge $t6, 15832, flip
	lw $s7, enemy
	ble $s7, 15644, flip_enemy
	bge $s7, 15832, flip_enemy
	jr $ra
	
flip:
	#flip the platforms and enemy if necessary
	mul $s4, $s4, -1
	lw $s7, enemy
	ble $s7, 15644, flip_enemy
	bge $s7, 15832, flip_enemy
	jr $ra
flip_enemy:
	#flip the enemy
	lw $s7, enemy_mult
	mul $s7, $s7, -1
	sw $s7, enemy_mult
	jr $ra
floor:
	#if the player hit the floor, reset the physics and set the height to 0
	li $s0, 0
	li $s1, 0 #velocity
    	li $s2, 0 #acceleration
    	#li $s0, 0 #height
    	li $s3, 0
    	j check1
#Perform all collision checks between the player and all other game objects
#This includes platforms, enemys, coins. For platforms, it also checks
#velocity to see if the player hit from above or below for collision logic
#from below or above
check3:
	
	bge $s0, 1024, check4
	j ob2_check1
check4:
	ble $s0, 2400, hit_ob1
	j ob2_check1
check1:
	move $t0, $t7
    	rem $t0, $t0, 256
    	bge $t0, 132, check2
    	j ob2_check1
check2:
    	ble $t0, 156, check3
    	j ob2_check1
on_ob1:
	li $s0, 1792
	li $s1, 0 #velocity
    	#li $s0, 0 #height
    	li $s3, 0
    	j ob2_check1
hit_ob1:
	
	sub $t3, $s1, $s2
	blez $t3, on_ob1
	sub $s0, $s0, $t3
	j ob2_check1
	
ob2_check1:
	bge $t0, 116, ob2_check2
    	j ob3_check1

ob2_check2:
	ble $t0, 124, ob2_check3
    	j ob3_check1
    
ob2_check3:
	bge $s0, 2048, ob2_check4
	j ob3_check1

ob2_check4:
	ble $s0, 3424, hit_ob2
	j ob3_check1
hit_ob2:
	sub $t3, $s1, $s2
	blez $t3, on_ob2
	sub $s0, $s0, $t3
	j ob3_check1
on_ob2:
	li $s0, 2816
	li $s1, 0 #velocity
    	#li $s0, 0 #height
    	li $s3, 0
    	j ob3_check1
    	
ob3_check1:
	rem $t1, $t6, 256
	bge $t0, $t1, ob3_check2
    	j ob4_check1

ob3_check2:
	addi $t1, $t1, 12
	ble $t0, $t1, ob3_check3
    	j ob4_check1
    
ob3_check3:
	bge $s0, 4096, ob3_check4
	j ob4_check1

ob3_check4:
	ble $s0, 5472, hit_ob3
	j ob4_check1
hit_ob3:
	sub $t3, $s1, $s2
	blez $t3, on_ob3
	sub $s0, $s0, $t3
	j ob4_check1
on_ob3:
	li $s5, 0
	li $s0, 4864
	li $s1, 0 #velocity
    	#li $s0, 0 #height
    	li $s3, 0
    	j ob4_check1	   	
    	   	  	
ob4_check1:
	#j game_loop
	rem $t1, $t6, 256
	addi $t1, $t1, 4
	bge $t0, $t1, ob4_check2
    	j ob5_check1

ob4_check2:
	addi $t1, $t1, 4
	ble $t0, $t1, ob4_check3
    	j ob5_check1
    
ob4_check3:
	bge $s0, 4352, ob4_check4
	j ob5_check1

ob4_check4:
	ble $s0, 5376, hit_ob4
	j ob5_check1
hit_ob4:
	bge $s6, 1, ob5_check1
	li $s6, 1
	lw $s7, score
	addi $s7, $s7, 1
	sw $s7, score
	j ob5_check1
	
	   	  	  	 
	   	  	  	    	  	  	  	
ob5_check1:

	bge $t0, 144, ob5_check2
    	j ob6_check1

ob5_check2:

	ble $t0, 148, ob5_check3
    	j ob6_check1
    
ob5_check3:
	bge $s0, 1024, ob5_check4
	j ob6_check1

ob5_check4:
	ble $s0, 2048, hit_ob5
	j ob6_check1
hit_ob5:
	lw $s7, coin2
	blez $s7, ob6_check1
	li $s7, 0
	sw $s7, coin2
	lw $s7, score
	addi $s7, $s7, 1
	sw $s7, score
	j ob6_check1

   	  	  	    	  	  	  	   	  	  	  	
   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	
   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	
ob6_check1:
	rem $s7, $t6, 256
    	sub $t4, $t4, $s7
    	sub $s7, $s7, 256
    	mul $s7, $s7, -1
	bge $t0, $s7, ob6_check2
    	j ob7_check1

ob6_check2:
	addi $s7, $s7, 12
	ble $t0, $s7, ob6_check3
    	j ob7_check1
    
ob6_check3:
	bge $s0, 6156, ob6_check4
	j ob7_check1

ob6_check4:
	ble $s0, 7788, hit_ob6
	j ob7_check1
hit_ob6:
	sub $t3, $s1, $s2
	blez $t3, on_ob6
	sub $s0, $s0, $t3
	j ob7_check1
on_ob6:
	li $s7, 0
	sw $s7, on_backwards
	li $s0, 6924
	li $s1, 0 #velocity
    	#li $s0, 0 #height
    	li $s3, 0
    	j ob7_check1	   
    	
    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	
    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	
    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	
    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	
    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	
ob7_check1:
	rem $t1, $t6, 256
	bge $t0, $t1, ob7_check2
    	j ob8_check1

ob7_check2:
	addi $t1, $t1, 12
	ble $t0, $t1, ob7_check3
    	j ob8_check1
    
ob7_check3:
	bge $s0, 8192, ob7_check4
	j ob8_check1

ob7_check4:
	ble $s0, 9824, hit_ob7
	j ob8_check1
hit_ob7:
	sub $t3, $s1, $s2
	blez $t3, on_ob7
	sub $s0, $s0, $t3
	j ob8_check1
on_ob7:
	li $s5, 0
	li $s0, 8960
	li $s1, 0 #velocity
    	#li $s0, 0 #height
    	li $s3, 0
    	j ob8_check1
    	
    	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	
    	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	
    	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	
    	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	
    	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	
ob8_check1:
	#j game_loop
	rem $t1, $t6, 256
	addi $t1, $t1, 4
	bge $t0, $t1, ob8_check2
    	j ob9_check1

ob8_check2:
	addi $t1, $t1, 4
	ble $t0, $t1, ob8_check3
    	j ob9_check1
    
ob8_check3:
	bge $s0, 8348, ob8_check4
	j ob9_check1

ob8_check4:
	ble $s0, 9372, hit_ob8
	j ob9_check1
hit_ob8:
	lw $s7, coin3
	blez $s7, ob9_check1
	li $s7, 0
	sw $s7, coin3
	lw $s7, score
	addi $s7, $s7, 1
	sw $s7, score
	j ob9_check1   	 

   		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	
   		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	
   		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	
   		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	    		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  		  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	   	  	  	    	  	  	  	   	  	  	  	
ob9_check1:
	#j game_loop
	rem $s7, $t6, 256
    	sub $t4, $t4, $s7
    	sub $s7, $s7, 256
    	mul $s7, $s7, -1
	addi $s7, $s7, 4
	bge $t0, $s7, ob9_check2
    	j ob10_check1

ob9_check2:
	addi $s7, $s7, 4
	ble $t0, $s7, ob9_check3
    	j ob10_check1
    
ob9_check3:
	bge $s0, 6412, ob9_check4
	j ob10_check1

ob9_check4:
	ble $s0, 7436, hit_ob9
	j ob10_check1
hit_ob9:
	lw $s7, coin4
	blez $s7, ob10_check1
	li $s7, 0
	sw $s7, coin4
	lw $s7, score
	addi $s7, $s7, 1
	sw $s7, score
	j ob10_check1
	
ob10_check1:
	#j game_loop
	lw $s7, enemy
	rem $s7, $s7, 256
	subi $s7, $s7, 16
	bge $t0, $s7, ob10_check2
    	j game_loop

ob10_check2:
	addi $s7, $s7, 32
	ble $t0, $s7, ob10_check3
    	j game_loop
    
ob10_check3:
	bge $s0, 0, ob10_check4
	j ob10_check5

ob10_check4:
	ble $s0, 512, hit_ob10
	j ob10_check5
ob10_check5:
	bge $s0, 10500, ob10_check6
	j game_loop

ob10_check6:
	ble $s0, 11020, hit_ob10
	j game_loop
hit_ob10:
	lw $s7, health
	subi $s7, $s7, 1
	sw $s7, health
	li $s1, 0 #velocity
    	li $s2, 0 #acceleration
    	li $s0, 0 #height
    	li $s3, 0 #canJump
    	li $t7, 15620
	j game_loop	    	  	  	  	   	  	  	  	   	  	  	  	

reset_physics:
	#reset the player's physics and allowable jumps
	li $s1, 0 #velocity
    	li $s2, 0 #acceleration
    	#li $s0, 0 #height
    	li $s3, 0
    	j game_loop
keypress_happened:
    	lw $t8, 4($t9)
    	beq $t8, 0x77, jump   	 #w
   	beq $t8, 0x61, move_left    #a
    	beq $t8, 0x64, move_right    #d
   	beq $t8, 0x70, restart   #p
   	beq $t8, 0x71, quit   	 #q
    	j processed
jump:
	#If the player did not jump twice yet, allow them to jump again nad decrement their remaining jumps
	bge $s3, 2, processed
	li $s2, -256
	li $s1, 1024
	addi $s3, $s3, 1
	j processed
restart:
    	jal clear_screen
    	j main
quit:
	jal clear_screen
    	j terminate
move_left:
    #if the player is not too close to the edge, let them move left
    move $t0, $t7
    rem $t0, $t0, 256 

    
    li $t1, 9
    blt $t0, $t1, non_moveable

    
    addi $t7, $t7, -8
    j processed

move_right:
    #if the player is not too close to the edge, let them move right
    move $t0, $t7
    rem $t0, $t0, 256  

    
    li $t1, 243
    bgt $t0, $t1, non_moveable

   
    addi $t7, $t7, 8
    j processed

non_moveable:
    
    j processed
#clear the screen and draw the header
clear_screen:
    li $t0, BASE_ADDRESS
    li $t1, 1024   

clear_loop:
    li $s7, 0x440044
    sw $s7, 0($t0)   

    addi $t0, $t0, 4  
    addi $t1, $t1, -1  

    bgtz $t1, clear_loop  

    j clear2
clear2:
    li $t1, 3072
clear3:
    sw $zero, 0($t0)   

    addi $t0, $t0, 4  
    addi $t1, $t1, -1  

    bgtz $t1, clear3

    jr $ra        
#draw the game
draw_game:
    	li $t0, BASE_ADDRESS # $t0 stores the base address for display
    	li $t1, 0xffffff # $t1 stores the white colour code
    	li $t2, 0x00ff00 # $t2 stores the green colour code
    	li $t3, 0xffB0ff # $t3 stores the light pink colour code
    	li $t5, 0xffff00 # $t3 stores the yellow colour code
    	li $a1, 0xff0000 # stores the red color code
    	
    	
    	# hero
    	add $t4, $t0, $t7 
    	sub $t4, $t4, $s0
    	sw $t3, 0($t4)
    	sw $t2, 256($t4)
    	sw $t2, 512($t4)
    	
    	# moving platform
    	add $t4, $t0, $t6
    	subi $t4, $t4, 4096
    	sw $t1, 0($t4)
    	sw $t1, 4($t4)
    	sw $t1, 8($t4)
    	sw $t1, 12($t4)
    	
    	#draw the enemies
    	lw $s7, enemy
    	add $t4, $t0, $s7
    	sw $a1, 0($t4)
    	sw $a1, 252($t4)
    	sw $a1, 256($t4)
    	sw $a1, 260($t4)
    	sw $a1, 504($t4)
    	sw $a1, 508($t4)
    	sw $a1, 512($t4)
    	sw $a1, 516($t4)
    	sw $a1, 520($t4)
    	
    	add $t4, $t0, $s7
    	subi $t4, $t4, 11520
    	sw $a1, 0($t4)
    	sw $a1, 4($t4)
    	sw $a1, 8($t4)
    	sw $a1, -4($t4)
    	sw $a1, -8($t4)
    	sw $a1, 256($t4)
    	sw $a1, 252($t4)
    	sw $a1, 260($t4)
    	sw $a1, 512($t4)
    	

    	# moving platform 3
    	add $t4, $t0, $t6
    	subi $t4, $t4, 8192
    	sw $t1, 0($t4)
    	sw $t1, 4($t4)
    	sw $t1, 8($t4)
    	sw $t1, 12($t4)
    	
    	# moving platform 2
    	add $t4, $t0, $t6
    	rem $s7, $t6, 256
    	sub $t4, $t4, $s7
    	sub $s7, $s7, 256
    	mul $s7, $s7, -1
    	add $t4, $t4, $s7
    	subi $t4, $t4, 6156
    	sw $t1, 0($t4)
    	sw $t1, 4($t4)
    	sw $t1, 8($t4)
    	sw $t1, 12($t4)
    	
    	addi $t4, $t0, 14724
    	#draw the first stationary platform
    	sw $t1, 0($t4)
    	sw $t1, 4($t4)
    	sw $t1, 8($t4)
    	sw $t1, 12($t4)
    	sw $t1, 16($t4)
    	sw $t1, 20($t4)
    	sw $t1, 24($t4)
    	
    	addi $t4, $t0, 13684
    	#draw the second stationary platform
    	sw $t1, 0($t4)
    	sw $t1, 4($t4)
    	sw $t1, 8($t4)
    	lw $s7, coin2
    	blez $s7, draw2

    	addi $t4, $t0, 14224
    	sw $t5, 0($t4)
    	sw $t5, 4($t4)
    	sw $t5, 256($t4)
    	sw $t5, 260($t4)
    	
    	j draw2
#this draws the coins collected and hearts remaining
draw_coins_collected:
	lw $s7, score_temp
	blez $s7, draw_hearts
	subi $s7, $s7, 1
	sw $s7, score_temp
	lw $s7, last_coin
	add $t4, $t0, $s7
    	sw $t5, 0($t4)
    	sw $t5, 4($t4)
    	sw $t5, 256($t4)
    	sw $t5, 260($t4)
    	addi $s7, $s7, 20
    	sw $s7, last_coin
    	j draw_coins_collected
draw_hearts:
	lw $s7, health
	sw $s7, health_temp
	li $s7, 400
	sw $s7, last_heart
	j heart_loop

heart_loop:
	lw $s7, health_temp
	blez $s7, return
	subi $s7, $s7, 1
	sw $s7, health_temp
	lw $s7, last_heart
	add $t4, $t0, $s7
	li $a1, 0xff0077
    	sw $a1, 4($t4)
    	sw $a1, 8($t4)
    	sw $a1, 16($t4)
    	sw $a1, 20($t4)
    	sw $a1, 256($t4)
    	sw $a1, 260($t4)
    	sw $a1, 264($t4)
    	sw $a1, 268($t4)
    	sw $a1, 272($t4)
    	sw $a1, 276($t4)
    	sw $a1, 280($t4)
    	sw $a1, 516($t4)
    	sw $a1, 520($t4)
    	sw $a1, 524($t4)
    	sw $a1, 528($t4)
    	sw $a1, 532($t4)
    	sw $a1, 776($t4)
    	sw $a1, 780($t4)
    	sw $a1, 784($t4)
    	sw $a1, 1036($t4)
    	addi $s7, $s7, 36
    	sw $s7, last_heart
    	j heart_loop
return:
	jr $ra
draw2:
	blez $s6, draw_coin
    	li $s7, 260
    	sw $s7, last_coin
    	
    	lw $s7, score
    	sw $s7, score_temp
    	j draw3
draw_coin:
	
    	add $t4, $t0, $t6
    	subi $t4, $t4, 4604
    	sw $t5, 0($t4)
    	sw $t5, 4($t4)
    	sw $t5, 256($t4)
    	sw $t5, 260($t4)
    	li $s7, 260
    	sw $s7, last_coin
    	
    	lw $s7, score
    	sw $s7, score_temp
    	j draw3
draw3:
	lw $s7, coin3
	blez $s7, draw4
	add $t4, $t0, $t6
    	subi $t4, $t4, 8700
    	sw $t5, 0($t4)
    	sw $t5, 4($t4)
    	sw $t5, 256($t4)
    	sw $t5, 260($t4)
    	li $s7, 260
    	sw $s7, last_coin
    	
    	lw $s7, score
    	sw $s7, score_temp
    	j draw4
draw4:
	lw $s7, coin4
	blez $s7, draw_coins_collected
	add $t4, $t0, $t6
    	rem $s7, $t6, 256
    	sub $t4, $t4, $s7
    	sub $s7, $s7, 256
    	mul $s7, $s7, -1
    	add $t4, $t4, $s7
    	subi $t4, $t4, 6664
    	sw $t5, 0($t4)
    	sw $t5, 4($t4)
    	sw $t5, 256($t4)
    	sw $t5, 260($t4)
    	li $s7, 260
    	sw $s7, last_coin
    	
    	lw $s7, score
    	sw $s7, score_temp
	j draw_coins_collected
	
	#draw the win screen
win_screen:
	jal clear_screen
	li $t0, BASE_ADDRESS # $t0 stores the base address for display
    	li $t5, 0xffff00 # $t3 stores the yellow colour code
    	li $t1, 0xff0000 # $t1 stores the red colour code
    	li $t2, 0x00ff00 # $t2 stores the green colour code
    	li $t3, 0xff00ff # $t3 stores the pink colour code
    	addi $t4, $t0, 7768
    	
    	#letters of win
    	sw $t1, 0($t4)
    	sw $t1, 260($t4)
    	sw $t1, 520($t4)
    	sw $t1, 268($t4)
    	sw $t1, 16($t4)
    	sw $t1, 276($t4)
    	sw $t1, 536($t4)
    	sw $t1, 284($t4)
    	sw $t1, 32($t4)
    	
    	sw $t1, 44($t4)
    	sw $t1, 300($t4)
    	sw $t1, 556($t4)
    	
    	sw $t1, 56($t4)
    	sw $t1, 312($t4)
    	sw $t1, 568($t4)
    	
    	sw $t1, 60($t4)
    	sw $t1, 320($t4)
    	sw $t1, 580($t4)
    	
    	sw $t1, 72($t4)
    	sw $t1, 328($t4)
    	sw $t1, 584($t4)
    	
    	
    	
    	lw $s7, score
    	sw $s7, score_temp
    	li $s7, 260
    	sw $s7, last_coin
	jal draw_coins_collected
	j end_screen_loop
	#print you win
end_screen_loop:
	
	li $t9, 0xffff0000 
	lw $t8, 0($t9)
	beq $t8, 1, keypress_happened_end_screen
end_screen_end:
	j end_screen_loop
lose_screen:
	jal clear_screen
	li $t0, BASE_ADDRESS # $t0 stores the base address for display
    	li $t5, 0xffff00 # $t3 stores the yellow colour code
    	li $t1, 0xff0000 # $t1 stores the red colour code
    	li $t2, 0x00ff00 # $t2 stores the green colour code
    	li $t3, 0xff00ff # $t3 stores the pink colour code
    	addi $t4, $t0, 7768
    	
    	#Letters of lose
    	sw $t1, 0($t4)
    	sw $t1, 256($t4)
    	sw $t1, 512($t4)
    	sw $t1, 768($t4)
    	sw $t1, 772($t4)
    	sw $t1, 776($t4)
    	
    	
    	sw $t1, 16($t4)
    	sw $t1, 20($t4)
    	sw $t1, 24($t4)
    	sw $t1, 272($t4)
    	sw $t1, 280($t4)
    	sw $t1, 528($t4)
    	sw $t1, 536($t4)
    	sw $t1, 784($t4)
    	sw $t1, 788($t4)
    	sw $t1, 792($t4)
    	
    	
    	sw $t1, 32($t4)
    	sw $t1, -220($t4)
    	sw $t1, 40($t4)
    	sw $t1, 288($t4)
    	sw $t1, 548($t4)
    	sw $t1, 808($t4)
    	sw $t1, 1056($t4)
    	sw $t1, 1316($t4)
    	sw $t1, 1064($t4)
    	
    	sw $t1, 48($t4)
    	sw $t1, 52($t4)
    	sw $t1, 304($t4)	
    	sw $t1, 560($t4)
    	sw $t1, 564($t4)
    	sw $t1, 816($t4)
    	sw $t1, 1072($t4)
    	sw $t1, 1076($t4)
    	
    	
    	
    	lw $s7, score
    	sw $s7, score_temp
    	li $s7, 260
    	sw $s7, last_coin
	jal draw_coins_collected
	j end_screen_loop
keypress_happened_end_screen:
    	lw $t8, 4($t9)
   	beq $t8, 0x70, restart   #p
   	beq $t8, 0x71, quit   	 #q
    	j end_screen_end
	
terminate:
    li $v0, 10
    syscall



