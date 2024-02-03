;    set game state memory location
.equ    HEAD_X,         0x1000  ; Snake head's position on x
.equ    HEAD_Y,         0x1004  ; Snake head's position on y
.equ    TAIL_X,         0x1008  ; Snake tail's position on x
.equ    TAIL_Y,         0x100C  ; Snake tail's position on Y
.equ    SCORE,          0x1010  ; Score address
.equ    GSA,            0x1014  ; Game state array address

.equ    CP_VALID,       0x1200  ; Whether the checkpoint is valid.
.equ    CP_HEAD_X,      0x1204  ; Snake head's X coordinate. (Checkpoint)
.equ    CP_HEAD_Y,      0x1208  ; Snake head's Y coordinate. (Checkpoint)
.equ    CP_TAIL_X,      0x120C  ; Snake tail's X coordinate. (Checkpoint)
.equ    CP_TAIL_Y,      0x1210  ; Snake tail's Y coordinate. (Checkpoint)
.equ    CP_SCORE,       0x1214  ; Score. (Checkpoint)
.equ    CP_GSA,         0x1218  ; GSA. (Checkpoint)

.equ    LEDS,           0x2000  ; LED address
.equ    SEVEN_SEGS,     0x1198  ; 7-segment display addresses
.equ    RANDOM_NUM,     0x2010  ; Random number generator address
.equ    BUTTONS,        0x2030  ; Buttons addresses

; button state
.equ    BUTTON_NONE,    0
.equ    BUTTON_LEFT,    1
.equ    BUTTON_UP,      2
.equ    BUTTON_DOWN,    3
.equ    BUTTON_RIGHT,   4
.equ    BUTTON_CHECKPOINT,    5

; array state
.equ    DIR_LEFT,       1       ; leftward direction
.equ    DIR_UP,         2       ; upward direction
.equ    DIR_DOWN,       3       ; downward direction
.equ    DIR_RIGHT,      4       ; rightward direction
.equ    FOOD,           5       ; food

; constants
.equ    NB_ROWS,        8       ; number of rows
.equ    NB_COLS,        12      ; number of columns
.equ    NB_CELLS,       96      ; number of cells in GSA
.equ    RET_ATE_FOOD,   1       ; return value for hit_test when food was eaten
.equ    RET_COLLISION,  2       ; return value for hit_test when a collision was detected
.equ    ARG_HUNGRY,     0       ; a0 argument for move_snake when food wasn't eaten
.equ    ARG_FED,        1       ; a0 argument for move_snake when food was eaten

; initialize stack pointer
addi    sp, zero, LEDS

; main
; arguments
;     none
;
; return values
;     This procedure should never return.
; BEGIN:main
main:
        addi    sp, sp, -8				; 2 words to store ra and s0
        stw     ra, 4(sp)				; push ra into the stack
        stw     s0, 0(sp)				; push s0 into the stack

init_game_main:

;;;        call    test
        call    init_game

get_input_main:
        call    get_input
		addi 	s0, zero, 5
        beq 	v0, s0, restore_checkpoint_main 
	
		call    hit_test
		addi 	s0, zero, 1
        beq 	v0, s0, eat_food_main 

		addi 	s0, zero, 2
        beq 	v0, s0, terminate_game_main


;;;;;;; check this
		addi 	a0, zero, 0
		call	move_snake
		br 		clear_and_draw_main

eat_food_main:
		ldw 	s0, SCORE(zero)
		addi    s0, s0, 1
		stw 	s0, SCORE(zero)
		call	display_score
		call	move_snake
		call	create_food

		br 		save_checkpoint_main


clear_and_draw_main:
        call    clear_leds
		call	draw_array
		br 		get_input_main

save_checkpoint_main:
	
		call	save_checkpoint
        beq 	v0, zero, clear_and_draw_main 
		br 		blink_score_main

restore_checkpoint_main:

		call	restore_checkpoint
        beq 	v0, zero, blink_score_main 
		br 		get_input_main

blink_score_main:
		call 	blink_score
		br 		clear_and_draw_main

terminate_game_main:

        ldw     s0, 0(sp)				; Pop s0 from the stack
        ldw     ra, 4(sp) 				; Pop ra from the stack
        addi    sp, sp, 8
        ret

; END:main


;---------------------------------------------------------------------------------------------------------------------------
; test
; arguments
;     none
;
; return values
;     none
; BEGIN:test
test:

        addi    sp, sp, -8				; 2 words to store ra and s0
        stw     ra, 4(sp)				; push ra into the stack
        stw     s0, 0(sp)				; push s0 into the stack

;		addi 	a0, zero, 5
;		addi 	a1, zero, 5
;		call 	set_pixel

		call 	init_game

;wait_here1:
;        beq s7, zero, wait_here1
;		call 	hit_test

;		call	create_food
;		call 	draw_array

        ldw     s0, 0(sp)				; Pop s0 from the stack
        ldw     ra, 4(sp) 				; Pop ra from the stack
        addi    sp, sp, 8
        ret
	ret

;---------------------------------------------------------------------------------------------------------------------------
; init_game
; arguments
;     none
;
; return values
;     none
; BEGIN:init_game
init_game:

        addi    sp, sp, -12					; Stack size
        stw     ra, 8(sp)					; push ra into the stack
        stw     s0, 4(sp)					; push s0 into the stack
        stw     s1, 0(sp)					; push s1 into the stack

		; clear leds and initialize score to 0
		call 	clear_leds 					
		stw 	zero, SCORE(zero) 		
	
		; reset position of head and tail
    	stw 	zero, HEAD_X(zero) 			
		stw 	zero, HEAD_Y(zero)
		stw 	zero, TAIL_X(zero)
		stw 	zero, TAIL_Y(zero)

		; initialize the GSA starting from the end of the GSA array
		addi 	s0, zero, NB_CELLS 			; number of cells 
	
    reset_gsa:
        addi 	s0, s0, -1 					; decrement cell number
        slli 	s1, s0, 2 					; multiply cell number by 4 to get GSA address
        stw 	zero, GSA(s1)				
        bne 	s0, zero, reset_gsa 		; We are done when the cell at index 0 was initialized

    	; initial snake has one cell at (0, 0) and is heading right
    set_init_gsa:
        addi 	s0, zero, DIR_RIGHT 		; snake goes right to begin with
        stw 	s0, GSA(zero)

		call 	create_food 				; place food
		call 	draw_array 					; draw the newly initialised array
		call 	display_score 				; show score

        ldw     s1, 0(sp)					; Pop s1 from the stack
        ldw     s0, 4(sp)					; Pop s0 from the stack
        ldw     ra, 8(sp) 					; Pop ra from the stack
        addi    sp, sp, 12
		ret
; END:init_game

;---------------------------------------------------------------------------------------------------------------------------
; clear_leds
; arguments
;     none
;
; return values
;     none;
;
; BEGIN:clear_leds
clear_leds:

        addi    sp, sp, -4				; Stack of one word to store ra
        stw     ra, 0(sp)				; push ra into the stack

		stw 	zero, LEDS+0(zero)
		stw 	zero, LEDS+4(zero)
		stw 	zero, LEDS+8(zero)

        ldw     ra, 0(sp) 				; Pop ra from the stack
        addi    sp, sp, 4

		ret
; END:clear_leds

;---------------------------------------------------------------------------------------------------------------------------
; set_pixel
; arguments
;     a0: the pixel's x-coordinate
;     a1: the pixel's y-coordinate
;
; return values
;     none;
;
; BEGIN:set_pixel
set_pixel:

        addi    sp, sp, -16				; 4 words to store ra and s0, and two arguments
        stw     ra, 12(sp)				; push ra into the stack
        stw     s0, 8(sp)				; push s0 into the stack
		stw   	s1, 4(sp)				; push s1 into the stack
		stw   	s2, 0(sp)				; push s2 into the stack

                                        ; a0 = x-coordinate.  C'est aussi le offset du byte a partir de LEDS. 
                                        ; a1 = y-coordinate.  C'est aussi le bit a changer dans le byte correspondant a a0. 

		andi 	s0, a0, 3 				; Je fais a0 mod 4 et je le met dans t0
		slli 	s0, s0, 3 				; Je multiplie t0 par 8. Donc la j'obtient la colonne voulue
		add 	s0, s0, a1 				; J'ajoute a1 a t0. Donc la j'obtient la ligne voulue aussi
		addi 	s1, zero, 1 			; J'initialise t1 a 00...01
		sll 	s1, s1, s0 				; Je shift t1 de t0 pour avoir le mask voulu
		ldw 	s2, LEDS+0(a0) 			; Je prend le word sur lequel j'effectut le changement
		or 		s3, s1, s2 				; Je fais word or mask ce qui reveint a allumer le bit du mask au word
		stw 	s3, LEDS+0(a0) 			; Je store le tout pour allumer (a0 me permet de decaler vers la colonne voulue)

        ldw     s2, 0(sp)				; Pop s2 from the stack
        ldw     s1, 4(sp)				; Pop s1 from the stack
        ldw     s0, 8(sp)				; Pop s0 from the stack
        ldw     ra, 12(sp) 				; Pop ra from the stack
        addi    sp, sp, 16
        ret


; END:set_pixel

;---------------------------------------------------------------------------------------------------------------------------
; get_input
; arguments
;     none
;
; return values
;     v0: register containing the code of the button that was pressed;
;
; BEGIN:get_input
get_input:

        addi    sp, sp, -36									; Enough space in the stack
        stw     ra, 32(sp)									; push ra into the stack
        stw     s0, 28(sp)									; push s0 into the stack
        stw     s1, 24(sp)									; push s1 into the stack
        stw     s2, 20(sp)									; push s2 into the stack
        stw     s3, 16(sp)									; push s3 into the stack
        stw     s4, 12(sp)									; push s3 into the stack
        stw     a0, 8(sp)									; push a0 into the stack
        stw     a1, 4(sp)									; push a1 into the stack
        stw     a2, 0(sp)									; push a2 into the stack

		; s0 = 5 LSB de edgecapture
		ldw 	s0, BUTTONS+4(zero) 						; On initialise t0 a edgecapture
		andi 	s0, s0, 31 									; On fait un masque pour ne garder que les 5 LSB

        ; s1 = get current HEAD direction.  To be used later
		ldw 	a0, HEAD_X(zero)
		ldw 	a1, HEAD_Y(zero)
		call 	get_gsa_value_get_input
		add 	s1, zero, v0

        ; s2 = Masque du boutton sur edgecapture
        ; s3 = s0 & button mask.  Using mask handles case where more than one bit in edgecapture is on
		;
		addi 	s2, zero, 16 								; s2 = 0...10000 Checkpoint (correspond au button 4)-- Prioritaire
        and     s3, s0, s2									; handles case where more than one bit in edgecapture is on
		beq 	s3, s2, checkpoint_get_input
					
		addi 	s2, zero, 1 								; s2 = 0...00001 Left (correspond au button 0)
        and     s3, s0, s2
		beq 	s3, s2, left_get_input

		addi 	s2, zero, 2 								; s2 = 0...00010 Up (correspond au button 1)
        and     s3, s0, s2
		beq 	s3, s2, up_get_input

		addi 	s2, zero, 4 								; s2 = 0...00100 Down (correspond au button 2)
        and     s3, s0, s2
		beq 	s3, s2, down_get_input

		addi 	s2, zero, 8 								; s2 = 0...01000 Right (correspond au button 3)
        and     s3, s0, s2
		beq 	s3, s2, right_get_input

	no_edge_get_input:
		; s0 = 5 LSB de status
		ldw 	s0, BUTTONS(zero) 							; On initialise 00 a status
		andi 	s0, s0, 15 									; On fait un masque pour ne garder que les 4 LSB

		addi 	s2, zero, 15 								; s2 = 0...1111 = none of the buttons is pressed
        and     s3, s0, s2									
		beq 	s3, s2, none_get_input

		addi 	s2, zero, 14 								; s2 = 0...1110 Left (correspond au button 0)
        and     s3, s0, s2
		beq 	s3, s2, left_get_input

		addi 	s2, zero, 13 								; s2 = 0...1101 Up (correspond au button 1)
        and     s3, s0, s2
		beq 	s3, s2, up_get_input

		addi 	s2, zero, 11 								; s2 = 0...1011 Down (correspond au button 2)
        and     s3, s0, s2
		beq 	s3, s2, down_get_input

		addi 	s2, zero, 7									; s2 = 0...0111 Right (correspond au button 3)
        and     s3, s0, s2
		beq 	s3, s2, right_get_input

	none_get_input:
		addi 	v0, zero, BUTTON_NONE
		br 		done_get_input

       ;s4 is the direction opposite of the pressed button.  
	left_get_input:
		addi 	v0, zero, BUTTON_LEFT						; v0 = direction demandée après le clique
		addi 	s4, zero, DIR_RIGHT							; s3 = direction opposée à celle demandée donc RIGHT
		bne 	s1, s4, update_gsa_get_input				; Si ancienne direction ≠ RIGHT, sauter a update_GSA pour update le GSA. Sinon on ret à la ligne suivante
		br 		done_get_input

	up_get_input:
		addi 	v0, zero, BUTTON_UP
		addi 	s4, zero, DIR_DOWN
		bne 	s1, s4, update_gsa_get_input
		br 		done_get_input

	down_get_input:
		addi 	v0, zero, BUTTON_DOWN
		addi 	s4, zero, BUTTON_UP
		bne 	s1, s4, update_gsa_get_input
		br 		done_get_input

	right_get_input:
		addi 	v0, zero, BUTTON_RIGHT
		addi 	s4, zero, DIR_LEFT
		bne 	s1, s4, update_gsa_get_input
		br 		done_get_input

	checkpoint_get_input:
		addi 	v0, zero, BUTTON_CHECKPOINT
		stw 	zero, BUTTONS+4(zero)
		br 		done_get_input

   update_gsa_get_input:
		ldw 	a0, HEAD_X(zero)
		ldw 	a1, HEAD_Y(zero)
		add 	a2, zero, v0							; Car on a la valeur de get input dans v0 et on veut initialiser pour set_gsa
		call 	set_gsa_value_get_input
		br 		done_get_input

   done_get_input:
		stw 	zero, BUTTONS+4(zero)					; On met edge capture à 00000 car : 3.1 The bit i of edgecapture stays at 1 until it is explicitly cleared by your program

        ldw     a2, 0(sp)								; Pop a2 from the stack
        ldw     a1, 4(sp)								; Pop a1 from the stack`
        ldw     a0, 8(sp)								; Pop a0 from the stack
        ldw     s4, 12(sp)								; Pop s4 from the stack
        ldw     s3, 16(sp)								; Pop s3 from the stack
        ldw     s2, 20(sp)								; Pop s2 from the stack
        ldw     s1, 24(sp)								; Pop s1 from the stack
        ldw     s0, 28(sp)								; Pop s0 from the stack
        ldw     ra, 32(sp) 								; Pop ra from the stack
        addi    sp, sp, 36
		ret

	set_gsa_value_get_input: 							; parameters : a0 = x, a1 = y, a2 = valeur a mettre

        addi    sp, sp, -8								; 2 words to store ra and s0
        stw     ra, 4(sp)								; push ra into the stack
        stw     s0, 0(sp)								; push s0 into the stack

		slli 	s0, a0, 3
		add 	s0, s0, a1
		slli	s0, s0, 2
		stw 	a2, GSA(s0) ;

        ldw     s0, 0(sp)								; Pop s0 from the stack
        ldw     ra, 4(sp) 								; Pop ra from the stack
        addi    sp, sp, 8
        ret

	get_gsa_value_get_input: 							; parameters : a0 = x, a1 = y

        addi    sp, sp, -8								; 2 words to store ra and s0
        stw     ra, 4(sp)								; push ra into the stack
        stw     s0, 0(sp)								; push s0 into the stack

		slli 	s0, a0, 3
		add 	s0, s0, a1
		slli 	s0, s0, 2
		ldw 	v0, GSA(s0) 							; output : v1 = GSA between 0 and 5.

        ldw     s0, 0(sp)								; Pop s0 from the stack
        ldw     ra, 4(sp) 								; Pop ra from the stack
        addi    sp, sp, 8
        ret

; END:get_input

;---------------------------------------------------------------------------------------------------------------------------
; move_snake
; arguments
;     register a0 = 1 if the snake's head collides with the food 
;
; return values
;     v0: register containing the code of the button that was pressed;
;
; BEGIN:move_snake
move_snake:
        addi    sp, sp, -20				; Stack size
        stw     ra, 16(sp)				; push ra into the stack
        stw     s0, 12(sp)				; push s0 into the stack
        stw     s1, 8(sp)				; push s1 into the stack
        stw     a0, 4(sp)				; push a0 into the stack
        stw     a1, 0(sp)				; push a1 into the stack

        ; store the value of the calling agrument in s1
        add s1, zero, a1

;wait_here:
;        beq s7, zero, wait_here
;		call 	hit_test

	update_head:
		ldw a0, HEAD_X(zero) 		; Lire le GSA du head
		ldw a1, HEAD_Y(zero)
		call get_gsa_value_move_snake

		; En fonction de la valeur trouvée, on met le nouveau head
		addi s0, zero, DIR_LEFT
		beq v0, s0, set_head_left

		addi s0, zero, DIR_UP
		beq v0, s0, set_head_up

		addi s0, zero, DIR_RIGHT
		beq v0, s0, set_head_right

		addi s0, zero, DIR_DOWN
		beq v0, s0, set_head_down

	set_head_left:								; changer la valeur de Head_X a une vers la gauche
		ldw s0, HEAD_X(zero)
		addi s0, s0, -1
		stw s0, HEAD_X(zero)
		br update_GSA_head

	set_head_up:								; changer la valeur de Head_Y a une vers le haut
		ldw s0, HEAD_Y(zero)
		addi s0, s0, -1
		stw s0, HEAD_Y(zero)
		br update_GSA_head

	set_head_right:								; changer la valeur de Head_X a une vers la droite
		ldw s0, HEAD_X(zero)
		addi s0, s0, 1
		stw s0, HEAD_X(zero)
		br update_GSA_head

	set_head_down:								; changer la valeur de Head_Y a une vers le bas
		ldw s0, HEAD_Y(zero)
		addi s0, s0, 1
		stw s0, HEAD_Y(zero)
		br update_GSA_head

	update_GSA_head:
		ldw 	a0, HEAD_X(zero)
		ldw 	a1, HEAD_Y(zero)
		add 	a2, zero, v0 						; On initialise le paramètre nouvelle valeur du GSA du nouveau head. 
		call 	set_gsa_value_move_snake

		addi 	s0, zero, ARG_FED
		bne 	s1, s0, done_move_snake 			; if a0 a l'appel etait 0 (s1=a0)  <=> il n'a pas eu collision avec le food. Donc tail ne change pas
 
   update_tail:
		ldw 	a0, TAIL_X(zero)
		ldw 	a1, TAIL_Y(zero)
		call 	get_gsa_value_move_snake ; La on a que v1 = valeur du gsa

		; En fonction de la valeur trouvée, on met le nouveau tail
		addi 	s0, zero, DIR_LEFT
		beq 	v0, s0, set_tail_left

		addi 	s0, zero, DIR_UP
		beq 	v0, s0, set_tail_up

		addi 	s0, zero, DIR_RIGHT
		beq 	v0, s0, set_tail_right

		addi 	s0, zero, DIR_DOWN
		beq 	v0, s0, set_tail_down

	set_tail_left:							; changer la valeur de Tail_X a une vers la gauche
		ldw 	s0, TAIL_X(zero)
		addi 	s0, s0, -1
		stw 	s0, TAIL_X(zero)			
		br 		update_GSA_tail

	set_tail_up:							; changer la valeur de Tail_X a une vers le haut
		ldw 	s0, TAIL_Y(zero)
		addi 	s0, s0, -1
		stw 	s0, TAIL_Y(zero)
		br 		update_GSA_tail


	set_tail_right:							; changer la valeur de Tail_X a une vers la droite
		ldw 	s0, TAIL_X(zero)
		addi 	s0, s0, 1
		stw 	s0, TAIL_X(zero)
		br 		update_GSA_tail

	set_tail_down:							; changer la valeur de Tail_X a une vers le bas
		ldw 	s0, TAIL_Y(zero)
		addi 	s0, s0, 1
		stw 	s0, TAIL_Y(zero)
		br 		update_GSA_tail

	update_GSA_tail:
		addi a2, zero, 0					; a2 = 0 nouvelle valeur GSA à mettre (= none)
		call set_gsa_value_move_snake
		br done_move_snake

	done_move_snake:
        ldw     a1, 0(sp)								; Pop a1 from the stack
        ldw     a0, 4(sp)								; Pop a0 from the stack
        ldw     s1, 8(sp)								; Pop s1 from the stack
        ldw     s0, 12(sp)								; Pop s0 from the stack
        ldw     ra, 16(sp) 								; Pop ra from the stack
        addi    sp, sp, 20
        ret

	get_gsa_value_move_snake: 							; parameters : a0 = x, a1 = y

        addi    sp, sp, -8								; 2 words to store ra and s0
        stw     ra, 4(sp)								; push ra into the stack
        stw     s0, 0(sp)								; push s0 into the stack

		slli 	s0, a0, 3
		add 	s0, s0, a1
		slli 	s0, s0, 2
		ldw 	v0, GSA(s0) 							; output : v1 = GSA between 0 and 5.

        ldw     s0, 0(sp)				; Pop s0 from the stack
        ldw     ra, 4(sp) 				; Pop ra from the stack
        addi    sp, sp, 8
        ret

	set_gsa_value_move_snake: 							; parameters : a0 = x, a1 = y, a2 = valeur a mettre

        addi    sp, sp, -8								; 2 words to store ra and s0
        stw     ra, 4(sp)								; push ra into the stack
        stw     s0, 0(sp)								; push s0 into the stack

		slli 	s0, a0, 3
		add 	s0, s0, a1
		slli	s0, s0, 2
		stw 	a2, GSA(s0) ;

        ldw     s0, 0(sp)				; Pop s0 from the stack
        ldw     ra, 4(sp) 				; Pop ra from the stack
        addi    sp, sp, 8
        ret

; END:move_snake

;---------------------------------------------------------------------------------------------------------------------------
; draw_array
; arguments
;     none
;
; return values
;     none;
;
; BEGIN:draw_array
draw_array:

        addi    sp, sp, -12				; 2 words to store ra and s0
        stw     ra, 8(sp)				; push ra into the stack
        stw     s0, 4(sp)				; push s0 into the stack
        stw     s1, 0(sp)				; push s1 into the stack

		addi 	s0, zero, NB_COLS 		; Première valeur de x trop grande
		addi 	s1, zero, NB_ROWS 		; Première valeur de y trop grande

		add 	a0, zero, zero
		add 	a1, zero, zero

	L0:
		bge 	a0, s0, done_draw_array 		; Si x n'est pas trop grand je refais la loop. Sinon je continue à la ligne suivante.

    L1: 
		bge 	a1, s1, next_a0 			; Si x n'est pas trop grand je refais la loop. Sinon je continue à la ligne suivante.		

		call 	get_gsa_value_draw_array	; La dans v0 j'ai la valeur de gsa
		beq 	v0, zero, next_a1 		; Si la valeur de gsa v1 est = 0 alors je saute la prochaine ligne
		
		call 	set_pixel

	next_a1:
		addi 	a1, a1, 1
		br 		L1

	next_a0:
		addi 	a0, a0, 1
		addi 	a1, zero, 0
		br		L0

    done_draw_array:

        ldw     s1, 0(sp)				; Pop s0 from the stack
        ldw     s0, 4(sp)				; Pop s0 from the stack
        ldw     ra, 8(sp) 				; Pop ra from the stack
        addi    sp, sp, 12
        ret


	get_gsa_value_draw_array: 							; parameters : a0 = x, a1 = y

        addi    sp, sp, -8								; 2 words to store ra and s0
        stw     ra, 4(sp)								; push ra into the stack
        stw     s0, 0(sp)								; push s0 into the stack

		slli 	s0, a0, 3
		add 	s0, s0, a1
		slli 	s0, s0, 2
		ldw 	v0, GSA(s0) 							; output : v1 = GSA between 0 and 5.

        ldw     s0, 0(sp)								; Pop s0 from the stack
        ldw     ra, 4(sp) 								; Pop ra from the stack
        addi    sp, sp, 8
        ret

	set_gsa_value_draw_array: 							; parameters : a0 = x, a1 = y, a2 = valeur a mettre

        addi    sp, sp, -8								; 2 words to store ra and s0
        stw     ra, 4(sp)								; push ra into the stack
        stw     s0, 0(sp)								; push s0 into the stack

		slli 	s0, a0, 3
		add 	s0, s0, a1
		slli	s0, s0, 2
		stw 	a2, GSA(s0) ;

        ldw     s0, 0(sp)								; Pop s0 from the stack
        ldw     ra, 4(sp) 								; Pop ra from the stack
        addi    sp, sp, 8
        ret

; END:draw_array

;---------------------------------------------------------------------------------------------------------------------------
; create_food
; arguments
;     none
;
; return values
;     none;
;
; BEGIN:create_food
create_food:

        addi    sp, sp, -12				; Stack size
        stw     ra, 8(sp)				; push ra into the stack
        stw     s0, 4(sp)				; push s0 into the stack
        stw     s1, 0(sp)				; push s1 into the stack


   get_new_rnd:
		ldw 	s0, RANDOM_NUM(zero)	; get a random number
		andi 	s0, s0, 0xFF 			; mask to get lowest byte of this number
	
		blt 	s0, zero, get_new_rnd 	; if slot number is smaller than 0, get a new one
		
        addi 	s1, zero, NB_CELLS 		; beyond edge of led display, (instructions only have >=)
		bge 	s0, s1, get_new_rnd 	; if random number is beyond edge of led display, get a new number

		slli	s1, s0, 2 				; multiply the random number by 4 as this is the bias to add to the gsa
	
		ldw 	s0, GSA(s1) 			; gsa element corresponding to the random number(location)
		bne 	s0, zero, get_new_rnd 	; if the gsa is not 0 (meaning its unoccupied), get a new number

		addi 	s0, zero, FOOD 			; 5 is the number corresponding to food
		stw 	s0, GSA(s1) 			; store 5 into location

        ldw     s1, 0(sp)				; Pop s1 from the stack
        ldw     s0, 4(sp)				; Pop s0 from the stack
        ldw     ra, 8(sp) 				; Pop ra from the stack
        addi    sp, sp, 12
        ret

; END:create_food


;---------------------------------------------------------------------------------------------------------------------------
; hit_test
; arguments
;     none
;
; return values
;     none;
;
; BEGIN:hit_test
hit_test:

        addi    sp, sp, -36				; Stack size
        stw     ra, 32(sp)				; push ra into the stack
        stw     s0, 28(sp)				; push s0 into the stack
        stw     s1, 24(sp)				; push s1 into the stack
        stw     s2, 20(sp)				; push s2 into the stack
        stw     s3, 16(sp)				; push s3 into the stack
        stw     s4, 12(sp)				; push s4 into the stack
        stw     s5, 8(sp)				; push s5 into the stack
        stw     a0, 4(sp)				; push a0 into the stack
        stw     a1, 0(sp)				; push a1 into the stack

		; setting registers for values needed in comparisons
		add 	s0, zero, zero  								; 0
		addi 	s1, zero, DIR_LEFT     							; 1
		addi 	s2, zero, DIR_UP       							; 2
		addi 	s3, zero, DIR_DOWN     							; 3
		addi 	s4, zero, DIR_RIGHT   							; 4
		addi 	s5, zero, FOOD	       							; 5


		; calculating gsa address of the head to determine direction of snake
		ldw 	a0, HEAD_X(zero) 								; positions of the x and y coordinates... 
		ldw 	a1, HEAD_Y(zero) 								; ...of the snake head (used to see what they run into)
		call 	get_gsa_value_hit_test  						; a number between (1 and 4) corresponding to the direction: 1: left, 2: up, 3: down, 4: right

		; seeing what direction it corresponds to 
		beq 	s1, v0, left_h 
		beq 	s2, v0, up_h
		beq	 	s3, v0, down_h
		beq 	s4, v0, right_h
	
	left_h:	
		addi 	a0, a0, -1 										; shift x coordinate 1 cell to the left
		blt 	a0, s0, boundary_body_hit 						; if x is smaller than  0, x is out of bounds of the array
		br      check_food

	up_h:
		addi 	a1, a1, -1 										; shift x coordinate 1 cell to the left
		blt 	a1, s0, boundary_body_hit 						; if x is smaller than  0, x is out of bounds of the array
		br      check_food

	right_h:
		addi 	a0, a0, 1 										; shift x coordinate 1 cell to the right
		addi 	s0, zero, NB_COLS
		bge 	a0, s0, boundary_body_hit 						; if x is greater than 11, x is out of bounds of the array
		br      check_food
					
	down_h:
		addi 	a1, a1, 1 										; shift x coordinate 1 cell downwards
		addi 	s0, zero, NB_ROWS
		bge 	a1, s0, boundary_body_hit 						; if y is greater than  7, y is out of bounds of the array
		br      check_food


	boundary_body_hit: 
		addi 	v0, zero, RET_COLLISION 						; return 2 for end of game
		br 		done_hit_test

    check_food:
		call 	get_gsa_value_hit_test 							; calculate gsa of new coordinate stored in v0
		beq 	v0, s5, food_hit 								; checking if cell is food
		addi 	v0, zero, 0
		br 		done_hit_test
	
	food_hit:
		addi 	v0, zero, RET_ATE_FOOD ; return 1 for score increment
		br 		done_hit_test

    done_hit_test:

        ldw     a1, 0(sp)								; Pop a1 from the stack
        ldw     a0, 4(sp)								; Pop a0 from the stack
        ldw     s5, 8(sp)								; Pop s5 from the stack
        ldw     s4, 12(sp)								; Pop s4 from the stack
        ldw     s3, 16(sp)								; Pop s3 from the stack
        ldw     s2, 20(sp)								; Pop s2 from the stack
        ldw     s1, 24(sp)								; Pop s1 from the stack
        ldw     s0, 28(sp)								; Pop s0 from the stack
        ldw     ra, 32(sp) 								; Pop ra from the stack
        addi    sp, sp, 36
        ret


	get_gsa_value_hit_test: 							; parameters : a0 = x, a1 = y

        addi    sp, sp, -8								; 2 words to store ra and s0
        stw     ra, 4(sp)								; push ra into the stack
        stw     s0, 0(sp)								; push s0 into the stack

		slli 	s0, a0, 3
		add 	s0, s0, a1
		slli 	s0, s0, 2
		ldw 	v0, GSA(s0) 							; output : v1 = GSA between 0 and 5.

        ldw     s0, 0(sp)								; Pop s0 from the stack
        ldw     ra, 4(sp) 								; Pop ra from the stack
        addi    sp, sp, 8
        ret

; END:hit_test


;---------------------------------------------------------------------------------------------------------------------------
; display_score
; arguments
;     none
;
; return values
;     none;
;
; BEGIN:display_score
display_score:

        addi    sp, sp, -28				; Enoush stack
        stw     ra, 24(sp)				; push ra into the stack
        stw     s0, 20(sp)				; push s0 into the stack
        stw     s1, 16(sp)				; push s1 into the stack
        stw     s2, 12(sp)				; push s2 into the stack
        stw     s3, 8(sp)				; push s3 into the stack
        stw     s4, 4(sp)				; push s4 into the stack
        stw     s5, 0(sp)				; push s5 into the stack

		ldw 	s0, SCORE(zero) 		; current score of the game (comment out for testing)
		addi 	s1, zero, 10 			; 10
		addi 	s2, zero, 100 			; 100
		add 	s3, zero, zero 			; initializing a counter to be used for the tens digit
	
	decrement_100_score:
		blt s0, s2, decompose_score 		; score is calculated modulo 100, if its less than 100, the score can be decomposed and displayed
		addi s0, s0, -100 					; if its larger than 100, subtract 100...
		br 	decrement_100_score 			; ...and try again

	decompose_score:
		blt 	s0, s1, store_score 		; if the score is less than 10, we know to initialize the displays to t0 and t3
		addi 	s3, s3, 1 					; if its not, increment the tens counter
		addi 	s0, s0, -10 				; and subtract 10 from the score
		br 		decompose_score 			; repeat  

	store_score:
		ldw 	s4, digit_map(s0) 			; unit digit address
		ldw 	s5, digit_map(s3) 			; tens digit address
		stw 	zero, SEVEN_SEGS(zero) 		; display 0 is always 0
		stw 	zero, SEVEN_SEGS+4(zero) 	; display 1 is always 0
		stw 	s5, SEVEN_SEGS+8(zero) 		; store tens digit in display
		stw 	s4, SEVEN_SEGS+12(zero)		; store unit digit in display

        ldw     s5, 0(sp)				; Pop s5 from the stack
        ldw     s4, 4(sp)				; Pop s4 from the stack
        ldw     s3, 8(sp)				; Pop s3 from the stack
        ldw     s2, 12(sp)				; Pop s2 from the stack
        ldw     s1, 16(sp)				; Pop s1 from the stack
        ldw     s0, 20(sp)				; Pop s0 from the stack
        ldw     ra, 24(sp) 				; Pop ra from the stack
        addi    sp, sp, 28
        ret

digit_map: 
	.word 0xFC ; 0
	.word 0x60 ; 1
	.word 0xDA ; 2
	.word 0xF2 ; 3
	.word 0x66 ; 4
	.word 0xB6 ; 5
	.word 0xBE ; 6
	.word 0xE0 ; 7
	.word 0xFE ; 8
	.word 0xF6 ; 9

; END:display_score


;---------------------------------------------------------------------------------------------------------------------------
; blink_score
; arguments
;     none
;
; return values
;     none;
;
; BEGIN:blink_score
blink_score:

        addi    sp, sp, -8				; 2 words to store ra and s0
        stw     ra, 4(sp)				; push ra into the stack
        stw     s0, 0(sp)				; push s0 into the stack

		addi 	s0, zero, 3				; number of blinks + 1
	
   blink:		
        stw zero, SEVEN_SEGS(zero) 		; since 0 is not part of the words it should display nothing/clear?
		stw zero, SEVEN_SEGS+4(zero)
		stw zero, SEVEN_SEGS+8(zero)
		stw zero, SEVEN_SEGS+12(zero)

		call wait 
		call display_score
		call wait
		
		addi s0, s0, -1 				; decrement counter
		bge s0, zero, blink 			; if counter is at 0, exit

	end_blink: 

        ldw     s0, 0(sp)				; Pop s1 from the stack
        ldw     ra, 4(sp) 				; Pop ra from the stack
        addi    sp, sp, 8
        ret

; END:blink_score

;---------------------------------------------------------------------------------------------------------------------------
; wait
; arguments
;     none
;
; return values
;     none;
;
; BEGIN:wait
wait:

        addi    sp, sp, -8				; 2 words to store ra and s0
        stw     ra, 4(sp)				; push ra into the stack
        stw     s0, 0(sp)				; push s0 into the stack

    	addi 	s0, zero, 30000 		;counter start value 

    wait_loop:
        beq 	s0, zero, end_wait 		;if counter reaches 0, exit procedure
        addi 	s0, s0, -1 				;decrease counter by 1
        br 		wait_loop 				;repeat

    end_wait: 
    
        ldw     s0, 0(sp)				; Pop s0 from the stack
        ldw     ra, 4(sp) 				; Pop ra from the stack
        addi    sp, sp, 8
        ret

; END:wait

;---------------------------------------------------------------------------------------------------------------------------
; save_checkpoint
; arguments
;     none
;
; return values
;     none;
;
; BEGIN:save_checkpoint
save_checkpoint:

        addi    sp, sp, -16				; Enough space for the stack
        stw     ra, 12(sp)				; push ra into the stack
        stw     s0, 8(sp)				; push s0 into the stack
        stw     s1, 4(sp)				; push s1 into the stack
        stw     s2, 0(sp)				; push s2 into the stack

    	addi 	s0, zero, SCORE
    	addi 	s1, zero, 10 				;to use for mod 10
    
    ;same idea as for display_score
    mod_score_cp:
        blt 	s0, s1, check_mod10 		; if score less than 10, need to check if equal to 0 (is a multiple of 10)
        addi 	s0, s0, -10 				; subtract 10
        br 		mod_score_cp 				; retry

    check_mod10:
        beq 	s0, zero, valid_cp 			; if score is a multiple of 10, we can create checkpoint

    ;no_checkpoint_required
;       stw 	zero, CP_VALID(zero) 		; else no checkpoint created
        addi 	v0, zero, 0 				; setting return value to 0
        br 		save_done 					; nothing more to do in this case

    valid_cp:
        addi 	s0, zero, 1 				; 1 = checkpoint created
        stw 	s0, CP_VALID(zero) 			; checkpoint is valid
        addi 	v0, zero, 1 				; setting return value to 1

        ;storing game data into checkpoint addresses

        ldw 	s0, SCORE(zero)
        stw 	s0, CP_SCORE(zero)

        ldw 	s0, HEAD_X(zero)
        stw 	s0, CP_HEAD_X (zero)

        ldw 	s0, HEAD_Y(zero)
        stw 	s0, CP_HEAD_Y (zero)

        ldw 	s0, TAIL_X(zero)
        stw 	s0, CP_TAIL_X (zero)

        ldw 	s0, TAIL_Y(zero)
        stw 	s0, CP_TAIL_Y (zero)


        ;need to do the same for the gsa
        addi s1, zero, NB_CELLS ;number of cells
    
      copy_gsa_save:
        addi s1, s1, -1 					;decrement cell number
        slli s2, s1, 2 						;multiply cell number by 4 to get gsa address
        ldw s0, CP_GSA(s2)
        stw s0, GSA (s2)

        beq s1, zero, save_done 			;once finished setting all cells to 0, can set initial cell
        br copy_gsa_save

    save_done:

        ldw     s2, 0(sp)				; Pop s2 from the stack
        ldw     s1, 4(sp)				; Pop s1 from the stack
        ldw     s0, 8(sp)				; Pop s0 from the stack
        ldw     ra, 12(sp) 				; Pop ra from the stack
        addi    sp, sp, 16
        ret

; END:save_checkpoint


;---------------------------------------------------------------------------------------------------------------------------
; restore_checkpoint
; arguments
;     none
;
; return values
;     none;
;
; BEGIN:restore_checkpoint
restore_checkpoint:

        addi    sp, sp, -16				; Enough space for the stack
        stw     ra, 12(sp)				; push ra into the stack
        stw     s0, 8(sp)				; push s0 into the stack
        stw     s1, 4(sp)				; push s1 into the stack
        stw     s2, 0(sp)				; push s2 into the stack

    	ldw 	s0, CP_VALID(zero)
        beq 	s0, zero, restore_done 		; No checkpoint can be restored if CP_VALID is zero.

        ;restoring game data into checkpoint addresses

        ldw 	s0, CP_SCORE(zero)
        stw 	s0, SCORE(zero)

        ldw 	s0, CP_HEAD_X(zero)
        stw 	s0, HEAD_X (zero)

        ldw 	s0, CP_HEAD_Y(zero)
        stw 	s0, HEAD_Y (zero)

		ldw 	s0, CP_TAIL_X(zero)
        stw 	s0, TAIL_X (zero)

        ldw 	s0, CP_TAIL_Y(zero)
        stw 	s0, TAIL_Y (zero)


        ;need to do the same for the gsa
        addi s1, zero, NB_CELLS ;number of cells
    
      copy_gsa_restore:
        addi s1, s1, -1 					;decrement cell number
        slli s2, s1, 2 						;multiply cell number by 4 to get gsa address
        ldw s0, CP_GSA(s2)
        stw s0, GSA (s2)

        beq s1, zero, restore_done 			;once finished setting all cells to 0, can set initial cell
        br copy_gsa_restore

    restore_done:

        ldw     s2, 0(sp)				; Pop s2 from the stack
        ldw     s1, 4(sp)				; Pop s1 from the stack
        ldw     s0, 8(sp)				; Pop s0 from the stack
        ldw     ra, 12(sp) 				; Pop ra from the stack
        addi    sp, sp, 16
        ret

; END:restore_checkpoint




;---------------------------------------------------------------------------------------------------------------------------
; XXXXXXXXX
; arguments
;     none
;
; return values
;     none;
;
; BEGIN:get_input
XXXXXXXXX:

        addi    sp, sp, -8				; 2 words to store ra and s0
        stw     ra, 4(sp)				; push ra into the stack
        stw     s0, 0(sp)				; push s0 into the stack

        ldw     s0, 0(sp)				; Pop s0 from the stack
        ldw     ra, 4(sp) 				; Pop ra from the stack
        addi    sp, sp, 8
        ret

; END:XXXXXXXXX