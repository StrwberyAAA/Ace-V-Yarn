.data
CAT_X_POS:      .word 16 # middle of the dispaly
CAT_Y_POS:      .word 31 # bottom of the dispaly
YARN_X_POS:     .word 10
YARN_Y_POS:     .word 0
YARN_DIR_X:     .word 1
YARN_DIR_Y:     .word 1
TIME_LEFT:      .word 600 # Around 10 seconds countdown
RAND_SEED:      .word 12345
YARN_MOVE_COUNTER: .word 0

# --- My strings used ---
STR_INFO:       .asciiz "Ace, catch the yarn ball before your owner gets home!\n"
STR_WIN:        .asciiz "Yarn caught! Ace wins!\n"
STR_LOSE:       .asciiz "Owner came home! Ace loses!\n"

# ---- Nicknames --------
.eqv DISPLAY_BASE_ADDR 0x10000000
.eqv KEYBOARD_DATA_ADDR 0xFFFF0004
.eqv PIXEL_SIZE_BYTES 4
.eqv DISPLAY_WIDTH 32
.eqv COLOR_CAT_PIXEL 0xFFFFa500  # orange cat
.eqv COLOR_YARN_PIXEL 0xFF0000 # green yarn
.eqv COLOR_BACKGROUND 0xFF000000
.eqv DISPLAY_MAX_X 31
.eqv DISPLAY_MAX_Y 31

.text
.globl main

main:
    li $t0, 16
    sw $t0, CAT_X_POS
    li $t1, 31
    sw $t1, CAT_Y_POS
    li $t2, 10
    sw $t2, YARN_X_POS
    li $t3, 0
    sw $t3, YARN_Y_POS
    li $t4, 1
    sw $t4, YARN_DIR_X
    sw $t4, YARN_DIR_Y
    li $t5, 600 #time         
    sw $t5, TIME_LEFT
    li $t6, 12345
    sw $t6, RAND_SEED

    li $v0, 4
    la $a0, STR_INFO
    syscall

main_loop:
    jal clear_screen

    # Read user keyboard i.e wasd input for cat movement
    lw $t0, KEYBOARD_DATA_ADDR
    li $t1, 0x61            #a
    beq $t0, $t1, move_L
    li $t1, 0x64            #d
    beq $t0, $t1, move_R
    li $t1, 0x77            #w
    beq $t0, $t1, move_T
    li $t1, 0x73            #s
    beq $t0, $t1, move_D
    j update_yarn           # no movement then update the yarn

move_L:
    lw $t2, CAT_X_POS
    bgtz $t2, do_L
    j update_yarn
do_L:
    addi $t2, $t2, -1
    sw $t2, CAT_X_POS
    j update_yarn

move_R:
    lw $t2, CAT_X_POS
    li $t3, DISPLAY_MAX_X
    blt $t2, $t3, do_right
    j update_yarn
do_right:
    addi $t2, $t2, 1
    sw $t2, CAT_X_POS
    j update_yarn

move_T:
    lw $t2, CAT_Y_POS
    bgtz $t2, do_up
    j update_yarn
do_up:
    addi $t2, $t2, -1
    sw $t2, CAT_Y_POS
    j update_yarn

move_D:
    lw $t2, CAT_Y_POS
    li $t3, DISPLAY_MAX_Y
    blt $t2, $t3, do_D
    j update_yarn
do_D:
    addi $t2, $t2, 1
    sw $t2, CAT_Y_POS

# YARN
update_yarn:
#move yarn at slower speed
    lw   $t8, YARN_MOVE_COUNTER
    addi $t8, $t8, 1
    sw   $t8, YARN_MOVE_COUNTER
    
    li   $t9, 3
    blt  $t8, $t9, draw_all
    sw   $zero, YARN_MOVE_COUNTER
#start movement logic 
    lw $t4, YARN_X_POS
    lw $t5, YARN_Y_POS
    lw $t6, YARN_DIR_X
    lw $t7, YARN_DIR_Y
    jal random_change_dir
    add $t4, $t4, $t6
    add $t5, $t5, $t7
    bltz $t4, bounce_L
    li $t8, DISPLAY_MAX_X
    bgt $t4, $t8, bounce_R
    j check_y_bounds
    
bounce_L:
    li $t4, 0
    sub $t6, $zero, $t6
    sw $t6, YARN_DIR_X
    j check_y_bounds
    
bounce_R:
    li $t4, DISPLAY_MAX_X
    sub $t6, $zero, $t6
    sw $t6, YARN_DIR_X
    
check_y_bounds:
    bltz $t5, bounce_T
    li $t8, DISPLAY_MAX_Y
    bgt $t5, $t8, bounce_D
    j save_yarn
bounce_T:
    li $t5, 0
    sub $t7, $zero, $t7
    sw $t7, YARN_DIR_Y
    j save_yarn
bounce_D:
    li $t5, DISPLAY_MAX_Y
    sub $t7, $zero, $t7
    sw $t7, YARN_DIR_Y
save_yarn:
    sw $t4, YARN_X_POS
    sw $t5, YARN_Y_POS
    
 # YARN DONE

draw_all:
    move $a0, $t4
    move $a1, $t5
    li $a2, COLOR_YARN_PIXEL
    jal safe_draw
    lw $t9, CAT_X_POS
    lw $s0, CAT_Y_POS
    move $a0, $t9
    move $a1, $s0
    li $a2, COLOR_CAT_PIXEL
    jal safe_draw

    # Collision chcker
    lw $s0, CAT_X_POS
    lw $s1, CAT_Y_POS
    lw $s2, YARN_X_POS
    lw $s3, YARN_Y_POS
    bne $s0, $s2, skip_col
    bne $s1, $s3, skip_col
#-------------------------------
    li $v0, 4
    la $a0, STR_WIN
    syscall
    li $v0, 10
    syscall

skip_col:
    lw $t0, TIME_LEFT
    addi $t0, $t0, -1
    sw $t0, TIME_LEFT
    blez $t0, game_over

    jal delay_loop
    j main_loop

game_over:
    li $v0, 4
    la $a0, STR_LOSE
    syscall
    li $v0, 10
    syscall

random_change_dir:
    lw $t8, RAND_SEED
    li $t9, 1103515245
    mult $t8, $t9
    mflo $t8
    addi $t8, $t8, 12345
    sw $t8, RAND_SEED
    andi $t1, $t8, 0xFF
    li $t2, 26
    bge $t1, $t2, no_change
    andi $t3, $t8, 1
    beqz $t3, flip_x
flip_y:
    sub $t7, $zero, $t7
    sw $t7, YARN_DIR_Y
    jr $ra
flip_x:
    sub $t6, $zero, $t6
    sw $t6, YARN_DIR_X
no_change:
    jr $ra

safe_draw:
    bltz $a0, skip_draw
    bltz $a1, skip_draw
    li $t0, 32
    bge $a0, $t0, skip_draw
    bge $a1, $t0, skip_draw
    mul $t1, $a1, DISPLAY_WIDTH
    add $t1, $t1, $a0
    mul $t1, $t1, PIXEL_SIZE_BYTES
    li $t2, DISPLAY_BASE_ADDR
    add $t1, $t1, $t2
    sw $a2, 0($t1)
skip_draw:
    jr $ra

delay_loop:
    li $t0, 10000
delay_loop_top:
    addi $t0, $t0, -1
    bgtz $t0, delay_loop_top
    jr $ra

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
