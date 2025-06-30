.data
	CAT_X_POS: .word 16
	
	.eqv KEYBOARD_DATA_ADDR 0xFFFF0004
	.eqv DISPLAY_BASE_ADDR 0x10000000
	.eqv PIXEL_SIZE_BYTES 4
	.eqv DISPLAY_WIDTH 32
	.eqv CAT_Y_POS 31
	.eqv COLOR_CAT_PIXEL 0xFFFFa500 #orange cat for now
	.eqv COLOR_BACKGROUND 0xFF000000
	.eqv DISPLAY_MAX_X 31

.text
.globl main
main:
    	li $s0, 16
    	sw $s0, CAT_X_POS

main_loop:
    	jal clear_screen
    	lw $t0, KEYBOARD_DATA_ADDR #read user input
    
    	# Check if user moved L
    	li $t1, 0x61
    	beq $t0, $t1, check_L_bound
    
  	# Check if user moved R
    	li $t1, 0x64
   	 beq $t0, $t1, check_R_bound
    
    	# No key pressed then render current pos
    	j render_and_delay
    
check_L_bound:
    lw $s0, CAT_X_POS
    bgtz $s0, move_L_logic  
    j render_and_delay
    
move_L_logic:
    # Update the position and save it
    lw $s0, CAT_X_POS
    addi $s0, $s0, -1
    sw $s0, CAT_X_POS
    j render_and_delay
    
check_R_bound:
    lw $s0, CAT_X_POS
    li $t1, DISPLAY_MAX_X
    blt $s0, $t1, move_R_logic
    j render_and_delay
    
move_R_logic:
    # Update the position +  save
    lw $s0, CAT_X_POS
    addi $s0, $s0, 1
    sw $s0, CAT_X_POS
    
render_and_delay:
   # This renders the cat's new pos
    lw $a0, CAT_X_POS
    li $a1, CAT_Y_POS
    li $a2, COLOR_CAT_PIXEL
    jal draw
    ##################
    
    jal delay_loop
    j main_loop

clear_screen:
    li $t0, 0
    li $t1, DISPLAY_WIDTH
    mul $t1, $t1, DISPLAY_WIDTH
    li $t2, DISPLAY_BASE_ADDR
    li $t3, COLOR_BACKGROUND
    
clear_loop:
    mul $t4, $t0, PIXEL_SIZE_BYTES
    add $t4, $t4, $t2
    sw $t3, 0($t4)
    addi $t0, $t0, 1
    blt $t0, $t1, clear_loop
    jr $ra
    
draw:
    mul $t0, $a1, DISPLAY_WIDTH
    add $t0, $t0, $a0
    mul $t0, $t0, PIXEL_SIZE_BYTES
    li $t1, DISPLAY_BASE_ADDR
    add $t0, $t0, $t1
    sw $a2, 0($t0)
    jr $ra

delay_loop:
    li $t0, 50000
    
delay_loop_cont:
    addi $t0, $t0, -1
    bgtz $t0, delay_loop_cont
    jr $ra
