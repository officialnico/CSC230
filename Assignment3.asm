;Nicolas Rodriguez
;V00919074

;Displays the Collatz sequence on Arduino Board and LCD screen, with varying speeds
;Speeds are handled by Timer3
;Users can move around with buttons, select different inputs, and press go
;Collatz is displayed at certain rate with live update speed from the speeds inputs
;The current number is updated based on the current speed every x seconds

;Programmed on Atmel Studio

;CSC230 Fall 2019
;Nov 23 2019

.equ TIMER1_DELAY = 7813
.equ TIMER1_MAX_COUNT = 0xFFFF
.equ TIMER1_COUNTER_INIT=TIMER1_MAX_COUNT-TIMER1_DELAY


.cseg
.org 0x0000

	rjmp setup
.org 0x0046
	jmp timer3_ISR

.org 0x0094

setup:
	clr r16
	clr r23

	; set the stack pointer (we're using functions here)
	ldi r16, 0x21
	out SPH, r16
	ldi r16, 0xFF
	out SPL, r16

	call lcd_init			; call lcd_init to Initialize the LCD (line 689 in lcd.asm)
	call init_strings
	call display_strings
	call delay
	call lcd_clr
	call init_template
	call display_template

	call timer3_setup

	ldi XL, low(numbers_register)
	ldi XH, high(numbers_register)

		;First initialize built-in Analog to Digital Converter
	; initialize the Analog to Digital converter
	ldi r16, 0x87
	sts ADCSRA, r16
	ldi r16, 0x40
	sts ADMUX, r16

	; initialize PORTB and PORTL for ouput
	ldi	r16, 0b00001010
	out DDRB, r16
	ldi	r16, 0b10101010
	sts DDRL, r16

	ldi temp, 0b10101010
	sts PORTL, temp
	call delay

	clr button
	clr prev_button

	call timer3_setup

	ldi XL, low(numbers_register)
	ldi XH, high(numbers_register)


	ldi r18, 3
	sts index_register, r18
	ldi r18, 4
	sts index_register+1, r18
	ldi r18, 5
	sts index_register+2, r18
	ldi r18, 6
	sts index_register+3, r18
	ldi r18, 14
	sts index_register+4, r18

	ldi r18, '+'
	sts numbers_register + 3, r18

	clr r18
	ldi r18, 0
	sts TCNT3H, r16
	ldi r18, 0
	sts TCNT3L, r18

	ldi r19, 4
	sts collatz_space, r19
	ldi r19, 2
	sts collatz_space+1, r19
	ldi r19, 7
	sts collatz_space+2, r19

	;call display_collatz

	rjmp main_loop

main_loop:

	ldi temp1, 0b00100000
	sts PORTL, temp1

	call display_screen
	call update_speed


	call check_button
	;Comparator
		cp button, prev_button
		breq main_loop
		mov prev_button, button
		cpi button, 5
		breq go_right
		cpi button, 4
		breq go_up
		cpi button, 3
		breq go_down
		cpi button, 2
		breq go_left
		cpi button, 1
	;end comparator

	ldi temp1, 0b00100100
	sts PORTL, temp1
	rjmp main_loop



lp:	rjmp lp

;checkbuttons

.def temp1 = r24
.def prev1 = r20
.def prev2 = r21
.def button = r22
.def prev_button = r23

	;First initialize built-in Analog to Digital Converter
	; initialize the Analog to Digital converter
	ldi r16, 0x87
	sts ADCSRA, r16
	ldi r16, 0x40
	sts ADMUX, r16

	; initialize PORTB and PORTL for ouput
	ldi	r16, 0b00001010
	out DDRB, r16
	ldi	r16, 0b10101010
	sts DDRL, r16

	ldi temp, 0b10101010
	sts PORTL, temp1
	call delay_buttons

	clr button
	clr prev_button

go_collatz:
	call collatz_first_time

	;call display_outputs

	rjmp go_done

go_right:
	push r16
		cpi XL, 4
		breq go_done
		ldi temp1, 0b10001000
		ld r16, X+
	rjmp go_done

go_up:
	ldi temp1, 0b00001000
	push r16
		cpi XL, 3
		breq go_collatz
		ld r16, X
		cpi r16, 9
		breq go_done
		inc r16
		ST X, r16
	rjmp go_done

go_down:

	ldi temp1, 0b10100000
	push r16
		cpi XL, 3
		breq go_collatz
		ld r16, X
		cpi r16, 0
		breq go_done
		dec r16
		ST X, r16
	rjmp go_done

go_left:
ldi temp1, 0b00100000
	push r16
		cpi XL, 0
		breq go_done
		ld r16, -X
	rjmp go_done

go_done:
	pop r16
	sts PORTL, temp1
	;call delay_buttons

	call display_screen
	call delay_buttons


	push r18
		lds r18, count
		inc r18
		sts count, r18
		cpi r18, 255
	pop r18
		breq counts_finished
		;call display_cursor

	rjmp main_loop

counts_finished:
	push r19
	push r18
		ldi r18, 1
		lds r19, visibility
		eor r19, r18
		sts visibility, r19
		ldi r18, 0
		sts count, r18

	pop r18
	pop r19

	rjmp main_loop

.equ UP	    = 0x0C3
.equ DOWN	= 0x17C
.equ LEFT	= 0x22B
.equ SELECT	= 0x316
.equ RIGHT	= 0x032
check_button:
;rjmp skip1
	; start a2d conversion
	lds	temp1, ADCSRA	  ; get the current value of SDRA
	ori temp1, 0x40     ; set the ADSC bit to 1 to initiate conversion
	sts	ADCSRA, temp1

	; wait for A2D conversion to complete
wait1:
	lds temp1, ADCSRA
	andi temp1, 0x40     ; see if conversion is over by checking ADSC bit
	brne wait1          ; ADSC will be reset to 0 is finished

	; read the value available as 10 bits in ADCH:ADCL
	lds prev1, ADCL
	lds prev2, ADCH

	; check RIGHT
	LDI temp1, high(RIGHT)
	CPI prev1, low(RIGHT)
	CPC prev2, temp1
	BRLO set_right

	; check UP
	LDI temp1, high(UP)
	CPI prev1, low(UP)
	CPC prev2, temp1
	BRLO set_up

	; check DOWN
	LDI temp1, high(DOWN)
	CPI prev1, low(DOWN)
	CPC prev2, temp1
	BRLO set_down

	; check LEFT
	LDI temp1, high(LEFT)
	CPI prev1, low(LEFT)
	CPC prev2, temp1
	BRLO set_left


	; NO button
	CLR button
	RJMP done_checking

set_right:
	LDI button, 5
	RJMP done_checking

set_up:
	LDI button, 4
	RJMP done_checking

set_down:
	LDI button, 3
	RJMP done_checking

set_left:
	LDI button, 2
	RJMP done_checking

set_select:
	LDI button, 1

done_checking:
	ret

;
; delay
;
; this function uses registers:
;
;	r20
;	r21
;	r22
;
delay_buttons:
	push r20
	push r21
	push r22
	; Nested delay loop
	ldi r20, 0x15
x8:
		ldi r21, 0xFF
x9:
			ldi r22, 0xFF
x10:
				dec r22
				brne x10
			dec r21
			brne x9
		dec r20
		brne x8
	pop r22
	pop r21
	pop r20
	ret

;end checkbuttons

timer3_setup:
	; timer mode
	push r16
		ldi r16, 0x00		; normal operation
		sts TCCR3A, r16

		; prescale
		; Our clock is 16 MHz, which is 16,000,000 per second
		;
		; scale values are the last 3 bits of TCCR1B:
		;
		; 000 - timer disabled
		; 001 - clock (no scaling)
		; 010 - clock / 8
		; 011 - clock / 64
		; 100 - clock / 256
		; 101 - clock / 1024
		; 110 - external pin Tx falling edge
		; 111 - external pin Tx rising edge
		ldi r16, (1<<CS32)|(1<<CS30)	; clock / 1024
		sts TCCR3B, r16

		; set timer counter to TIMER3_COUNTER_INIT (defined above)
		ldi r16, high(TIMER31_COUNTER_INIT)
		sts TCNT3H, r16 	; must WRITE high byte first
		ldi r16, low(TIMER31_COUNTER_INIT)
		sts TCNT3L, r16		; low byte

		; allow timer to interrupt the CPU when it's counter overflows
		ldi r16, 1<<TOIE3
		sts TIMSK3, r16

		ldi temp1, 0b011111111
		sts PORTL, temp1


	pop r16
	sei
	ret


;--------------Timer 3 Speeds----------------------
.equ TIMER31_DELAY=977
.equ TIMER3_MAX_COUNT = 0XFFFF
.equ TIMER31_COUNTER_INIT=TIMER3_MAX_COUNT-TIMER31_DELAY

.equ TIMER32_DELAY = 1953
.equ TIMER32_COUNTER_INIT=TIMER3_MAX_COUNT-TIMER32_DELAY

.equ TIMER33_DELAY = 3906
.equ TIMER33_COUNTER_INIT=TIMER3_MAX_COUNT-TIMER33_DELAY

.equ TIMER34_DELAY = 7813
.equ TIMER34_COUNTER_INIT=TIMER3_MAX_COUNT-TIMER34_DELAY

.equ TIMER35_DELAY = 15625
.equ TIMER35_COUNTER_INIT=TIMER3_MAX_COUNT-TIMER35_DELAY

.equ TIMER36_DELAY = 23338
.equ TIMER36_COUNTER_INIT=TIMER3_MAX_COUNT-TIMER36_DELAY

.equ TIMER37_DELAY = 31250
.equ TIMER37_COUNTER_INIT=TIMER3_MAX_COUNT-TIMER37_DELAY

.equ TIMER38_DELAY = 39063
.equ TIMER38_COUNTER_INIT=TIMER3_MAX_COUNT-TIMER38_DELAY

.equ TIMER39_DELAY = 36875
.equ TIMER39_COUNTER_INIT=TIMER3_MAX_COUNT-TIMER39_DELAY
;--------------ISR-----------------------------------
timer3_ISR:

	push r16
	lds r16, SREG
	push r16
	.def temp3 = r17
		; RESET timer counter to TIMER3_COUNTER_INIT (defined above)
		ldi r16, high(TIMER31_COUNTER_INIT)
		sts TCNT3H, r16 	; must WRITE high byte first
		ldi r16, low(TIMER31_COUNTER_INIT)
		sts TCNT3L, r16		; low byte

		;write code here for what to do when interrupted
		call collatz
		call display_collatz

		ldi temp1, 0b10001000
		sts PORTL, temp3

	pop r16
	sts SREG, r16
	pop r16
	reti

; copy two strings: msg1_p from program memory to msg1 in data memory and
;                   msg2_p from program memory to msg2 in data memory
; subroutine str_init is defined in lcd.asm at line 893
init_strings:
	push r16
		; copy strings from program memory to data memory
		ldi r16, high(msg1)		; address of the destination string in data memory
		push r16
		ldi r16, low(msg1)
		push r16
		ldi r16, high(msg1_p << 1) ; address the source string in program memory
		push r16
		ldi r16, low(msg1_p << 1)
		push r16
		call str_init			; copy from program to data
		pop r16					; remove the parameters from the stack
		pop r16
		pop r16
		pop r16


		; copy strings from program memory to data memory
		ldi r16, high(msg2)		; address of the destination string in data memory
		push r16
		ldi r16, low(msg2)
		push r16
		ldi r16, high(msg2_p << 1) ; address the source string in program memory
		push r16
		ldi r16, low(msg2_p << 1)
		push r16
		call str_init			; copy from program to data
		pop r16					; remove the parameters from the stack
		pop r16
		pop r16
		pop r16

	pop r16
	ret

init_template:
	push r16
		; copy strings from program memory to data memory
		ldi r16, high(template1)		; address of the destination string in data memory
		push r16
		ldi r16, low(template1)
		push r16
		ldi r16, high(template1_p << 1) ; address the source string in program memory
		push r16
		ldi r16, low(template1_p << 1)
		push r16
		call str_init			; copy from program to data
		pop r16					; remove the parameters from the stack
		pop r16
		pop r16
		pop r16

		ldi r16, high(template2)
		push r16
		ldi r16, low(template2)
		push r16
		ldi r16, high(template2_p << 1)
		push r16
		ldi r16, low(template2_p << 1)
		push r16
		call str_init
		pop r16
		pop r16
		pop r16
		pop r16

	pop r16
	ret


display_template:

	; This subroutine sets the position the next
	; character will be on the lcd
	;
	; The first parameter pushed on the stack is the Y (row) position
	;
	; The second parameter pushed on the stack is the X (column) position
	;
	; This call moves the cursor to the top left corner (ie. 0,0)
	; subroutines used are defined in lcd.asm in the following lines:
	; The string to be displayed must be stored in the data memory
	; - lcd_clr at line 661
	; - lcd_gotoxy at line 589
	; - lcd_puts at line 538
	push r16

		call lcd_clr

		ldi r16, 0x00
		push r16
		ldi r16, 0x00
		push r16
		call lcd_gotoxy
		pop r16
		pop r16

		; Now display template1 on the first line
		ldi r16, high(template1)
		push r16
		ldi r16, low(template1)
		push r16
		call lcd_puts
		pop r16
		pop r16

		; Now move the cursor to the second line (ie. 0,1)
		ldi r16, 0x01
		push r16
		ldi r16, 0x00
		push r16
		call lcd_gotoxy
		pop r16
		pop r16

		; Now display template2 on the second line
		ldi r16, high(template2)
		push r16
		ldi r16, low(template2)
		push r16
		call lcd_puts
		pop r16
		pop r16




	pop r16
	ret



delay:
	clr r20
	clr r21
	clr r22

	push r20
	push r21
	push r22
	; Nested delay loop
	ldi r20, 0xFF
x1:
		ldi r21, 0xDF
x2:
			ldi r22, 0xAA
x3:
				dec r22
				brne x3
			dec r21
			brne x2
		dec r20
		brne x1
	pop r22
	pop r21
	pop r20
	ret


display_strings:

	push r16
		ldi temp1, 0b00001111
		sts PORTL, temp1
		call delay_buttons
		call lcd_clr

		ldi r16, 0x00
		push r16
		ldi r16, 0x00
		push r16
		call lcd_gotoxy
		pop r16
		pop r16

		; Now display msg1 on the first line
		ldi r16, high(msg1)
		push r16
		ldi r16, low(msg1)
		push r16
		call lcd_puts
		pop r16
		pop r16

		; Now move the cursor to the second line (ie. 0,1)
		ldi r16, 0x01
		push r16
		ldi r16, 0x00
		push r16
		call lcd_gotoxy
		pop r16
		pop r16

		; Now display msg1 on the second line
		ldi r16, high(msg2)
		push r16
		ldi r16, low(msg2)
		push r16
		call lcd_puts
		pop r16
		pop r16

		;;;;
		ldi r16, 0x00
		push r16
		ldi r16, 0x00
		push r16
		call lcd_gotoxy
		pop r16
		pop r16

		; Now display msg1 on the first line
		ldi r16, high(msg1)
		push r16
		ldi r16, low(msg1)
		push r16
		call lcd_puts
		pop r16
		pop r16

		ldi r16, 0x00
		push r16
		ldi r16, 0x00
		push r16
		call lcd_gotoxy
		pop r16
		pop r16

		; Now display msg1 on the first line
		ldi r16, high(msg1)
		push r16
		ldi r16, low(msg1)
		push r16
		call lcd_puts
		pop r16
		pop r16

	pop r16
	ret

;COLLATZ
collatz_first_time:
	push r17
	push r19
	push r20
	push r21

		;stores characters in collatz_space as CH:CM:CL
		ldi ZL, low(numbers_register)
		ldi ZH, high(numbers_register)
		ld r21, Z
		ldd r20, Z+1
		ldd r19, Z+2


		ldi r17, 10
		mov r5, r20
		mov r4, r17
		mul r5, r4 ; Multiply unsigned r5 and r4
		mov r20 ,r0

		add r20, r19
		ldi ZL, low(collatz_space)
		ldi ZH, high(collatz_space)

		ldi r17, 0
		st Z, r17
		adiw ZH:ZL, 1
		st Z, r21

		ldi r17, 0
		adiw ZH:ZL, 1
		st Z, r20


	pop r21
	pop r20
	pop r19
	pop r17

	rjmp collatz

collatz:

	push r20
	push r21
	push r22


		ldi ZL, low(collatz_space)
		ldi ZH, high(collatz_space)
		;CH:CM:CL
		ldd r20, Z +2 ;CL
		ldd r21, Z +1 ;CM
		ld r22, Z	  ;CH

		push r20
		push r21
		push r22

		call collatz_nextInt

		pop r20
		pop r20
		pop r20

	pop r22
	pop r21
	pop r20

	ret

	finish:
		push r16
		push r20
			lds r16, TCCR4B
			ldi r20, 0b11111000
			and r20, r16
			sts TCCR4B, r16
		pop r20
		pop r16
			jmp lp

collatz_nextInt: ;(R17, R16, r23)

	push r18
		in ZH, SPH
		in ZL, SPL

		ldd r23, Z+7 ;CL
		ldd r16, Z+6 ;CM
		ldd r17, Z+5 ;CH

		ldi r18, 0
		cpi r23, 1
		cpc r16, r18
		cpc r17, r18

		breq finish
		ldi r18, 0x01
		and r18, r23 ;checks if even or odd
		cpi r18, 0x01
	pop r18
	brne even
	breq odd

even:
	push r18
		ldi r18, 1
		and r18, r17
		cpi r18, 1
	pop r18
		breq overflow_bit_high
	push r18
		ldi r18, 1
		and r18, r16
		cpi r18, 1
	pop r18
		breq overflow_bit

		call div2
		;cpi r16, 1
		;breq carry_1

	rjmp collatz_next_end



odd:
	push r18
	push r19
	push r20

		mov r18, r23
		mov r19, r16
		mov r20, r17

		add r23, r18
		adc r16, r19
		adc r17, r20
		;carryforward
		cpi r23, 100
		brsh r23_carry100
		rjmp collatz_middle

r23_carry100:
	subi r23, 100
	inc r16
	rjmp collatz_middle

collatz_middle:
		add r23, r18
		adc r16, r19
 		adc r17, r20

		clr r17
		ldi r18, 1
		add r23, r18
		adc r16, r17
		adc r17, r17


		;for the sake of programming
		mov r18, r23
		mov r19, r16
		mov r20, r17

	pop r20
	pop r19
	pop r18

		cpi r23, 99
		brsh carry_99

	rjmp collatz_next_end

overflow_bit:
	push r18
		lsr r16
		lsr r23
		ldi r18, 50
		add r23, r18

		ldi r18, 1
		and r18, r16
		cpi r18, 1

	pop r18


	rjmp collatz_next_end

overflow_bit_high:
	push r18
		lsr r17
		lsr r16
		ldi r18, 50
		add r16, r18

		ldi r18, 4
		add r23, r18

		ldi r18, 1
		and r18, r16
		cpi r18, 1
	pop r18
		breq overflow_bit

	rjmp collatz_next_end

carry_1:
	push r18
		lsr r16
		lsr r23
		ldi r18, 50
		add r23, r18
	pop r18

	rjmp collatz_next_end

carry_1high:
	push r18
		dec r17
		inc r16
	pop r18
	cpi r23, 200
	brsh sub_two
	cpi r23, 100
	brsh sub_one
	rjmp end_carry1
	rjmp collatz_next_end

end_carry1:
	call div2
	rjmp collatz_next_end

sub_one:
	push r18
		ldi r18, 100
		sub r23, r18
		inc r16
	pop r18
	rjmp collatz_next_end

sub_two:
	push r18
		call div2
		ldi r18, 200
		sub r23, r18
		inc r16
		inc r16
	pop r18
	rjmp collatz_next_end

carry_99:
	push r18
		subi r23, 100
		inc r16
	pop r18
	cpi r16, 99
	brsh carry_99high
	rjmp collatz_next_end

carry_99high:
	push r18
		subi r16, 100
		inc r17
	pop r18
	rjmp collatz_next_end

carry_99rot:
	push r18


collatz_next_end:

	cpi r23, 200
	brsh r23_200

	cpi r23, 100
	brsh r23_100

	cpi r16, 200
;	brsh r16_200

	cpi r16, 100
;	brsh r16_100

 	rjmp collatz_golden_finish

collatz_golden_finish:
	ldi ZL, low(collatz_space)
	ldi ZH, high(collatz_space)
	;CH:CM:CL
	STD Z +1, r16  ;CL
	STD Z +2, r23 ;CM
	ST  Z, r17	  ;CH
	ret

r23_200:
	push r18
		ldi r18, 2
		add r16, r18
		subi r23, 200
	pop r18
	rjmp collatz_golden_finish

r23_100:
	push r18
		ldi r18, 1
		add r16, r18
		subi r23, 100
	pop r18
	rjmp collatz_golden_finish


r16_100: ;TODO finish this
	push r18
		ldi r18, 1
		add r16, r18
		subi r23, 100
	pop r18
	rjmp collatz_golden_finish

div2:
	lsr r17 ;CH
	lsr r16 ;CM
	ror r23 ;CL
	ret

;Cool songs:
;BASSTIME WINTER:
;Wooked on a feeling
;Caspa deja vu
;Alien Technilogy shlump

;Shanic Bokeh
;aint no mountain
;END WITH: i am that i am

display_screen:

	push r17

		ldi r17, 0
		call display_inputs ;BROKEN

		ldi r17, 1
		call display_outputs ;also BROKEN

	pop r17

	ret


display_count:

	push r18
	push r16


		ldi r17, 1

		;high count
		ldi r20, 5 ;xpos
		ldi r21, 4 ;screen_pos
		push r20
		push r21
		call load_char
		pop r20
		pop r20


		;low count
		ldi r20, 6 ;xpos
		ldi r21, 5 ;screen_pos
		push r20
		push r21
		call load_char
		pop r20
		pop r20

	pop r16
	pop r18

	ret




display_inputs:

	push r18
	push r16
	push r17

		;first
		ldi r17, 0
		ldi r16, 0
		ldi r18, 3
		push r16
		push r18
		call load_char
		pop r16
		pop r16

		;second
		ldi r17, 0
		ldi r16, 1
		ldi r18, 4
		push r16
		push r18
		call load_char
		pop r16
		pop r16

		;third
		ldi r17, 0
		ldi r16, 2
		ldi r18, 5
		push r16
		push r18
		call load_char
		pop r16
		pop r16

		;fourth symbol
		ldi r17, 0
		ldi r16, 3
		ldi r18, 6
		push r16
		push r18
		;call load_char
		pop r16
		pop r16

		;fifth speed
		ldi r17, 0
		ldi r16, 4
		ldi r18, 14
		push r16
		push r18
		call load_char
		pop r16
		pop r16



		;call second
		;call third
		;call fourth

	pop r17
	pop r16
	pop r18

	ret



load_char: ;load_char method (xpos, screen_pos) ;WORKS

	push r23
	push r22
	push r21
	push r20
	push r19;not used
	push r18;not used

		clr r19

		in ZH, SPH
		in ZL, SPL
		ldd r23, Z+11 ;xpos
		ldd r22, Z+10 ;sc_pos

		cpi r23, 3
		breq on_symbol
		ldi r21, '0'
		jmp end_load_char

on_symbol:
	ldi r21, 0
	jmp end_load_char

end_load_char:
		ldi YL, low(numbers_register)
		ldi YH, high(numbers_register)

		add YL, r23
		adc YH, r19

		ld r20, Y
		add r21, r20

		push r17
		push r22
		call lcd_gotoxy
		pop r20
		pop r20

		push r21
		call lcd_putchar
		pop r20

	pop r18
	pop r19
	pop r20
	pop r21
	pop r22
	pop r23

	ret

display_cursor: ;TODO: FIX THIS
	push r21
	push r20
	push r19
	push r18
	push r17
	push r16

		clr r17
		clr r18

		mov r21, XL
		ld r17, X
		ldi r18, '0'
		add r17, r18
		clr r18
		sts character2, r17
		clr r17

		ldi ZL, low(index_register)
		ldi ZH, high(index_register)
		add ZL, r21
		adc ZH, r18
		ld r21, Z

		lds r16, character2

		lds r20, visibility
		cpi r20, 0
		breq turn_off
		cpi r20, 1
		breq turn_on


turn_on:
		clr r17
		lds r16, character2
		push r17
		push r21
		call lcd_gotoxy
		pop r19
		pop r19

		push r16
		call lcd_putchar
		pop r19
		rjmp cursor_end

turn_off:

		ldi r16, ' '
		push r17
		push r21
		call lcd_gotoxy
		pop r19
		pop r19
		push r16
		call lcd_putchar
		pop r19
		rjmp cursor_end

cursor_end:

	pop r16
	pop r17
	pop r18
	pop r19
	pop r20
	pop r21
	ret

display_outputs:
	ldi r19, 1
	call display_count
	call display_collatz_main
	ldi r19, 0
	sts numy, r19
	sts numy+1, r19
	sts numy+2, r19
	sts numy+3, r19
	sts numy+4, r19
	sts numy+5, r19

	ret

; start of int to string
int_to_string:
	.def dividend=r0
	.def divisor=r1
	.def quotient=r2
	.def tempt=r21
	.def char0=r3
	;preserve the values of the registers
	push dividend
	push divisor
	push quotient
	push tempt
	push char0
	push ZH
	push ZL

	;store '0' in char0
	ldi tempt, '0'
	mov char0, tempt
	;Z points to first character of num in SRAM
	ldi ZH, high(num)
	ldi ZL, low(num)
	adiw ZH:ZL, 3 ;Z points to null character
	clr tempt
	st Z, tempt ;set the last character to null
	sbiw ZH:ZL, 1 ;Z points the last digit location

	;initialize values for dividend, divisor
	lds tempt, toTranslate
	mov dividend, tempt
	ldi tempt, 10
	mov divisor, tempt

	clr quotient
	digit2str:
		cp dividend, divisor
		brlo finish1
		division:
			inc quotient
			sub dividend, divisor
			cp dividend, divisor
			brsh division
		;change unsigned integer to character integer
		add dividend, char0
		st Z, dividend;store digits in reverse order
		sbiw r31:r30, 1 ;Z points to previous digit
		mov dividend, quotient
		clr quotient
		jmp digit2str
	finish1:
	add dividend, char0
	st Z, dividend ;store the most significant digit

	;restore the values of the registers
	pop ZL
	pop ZH
	pop char0
	pop tempt
	pop quotient
	pop divisor
	pop dividend
	ret
	.undef dividend
	.undef divisor
	.undef quotient
	.undef tempt
	.undef char0
;end of int_to_string

;To display the collatz just call display_collatz_main

;begining of display collatz
display_collatz_main:

	lds r18, collatz_space+2
	sts CL, r18
	lds r18, collatz_space+1
	sts CM, r18
	lds r18, collatz_space
	sts CH, r18

	lds r18, CL
	sts toTranslate, r18
	call int_to_string
	ldi r18, 14
	sts col_pos1, r18
	ldi r18, 15
	sts col_pos2, r18
	call display_collatz

	lds r18, CM
	sts toTranslate, r18
	call int_to_string
	ldi r18, 12
	sts col_pos1, r18
	ldi r18, 13
	sts col_pos2, r18
	call display_collatz

	lds r18, CH
	sts toTranslate, r18
	call int_to_string
	ldi r18, 10
	sts col_pos1, r18
	ldi r18, 11
	sts col_pos2, r18
	call display_collatz



	ret


display_collatz:
	ldi r18, 0
	push r18
	ldi r18, 2
	push r18
	call lcd_gotoxy
	pop r18
	pop r18



	ldi r18, 1
	push r18
	lds r18, col_pos1
	push r18
	call lcd_gotoxy
	pop r18
	pop r18

	lds r18, num + 1
	push r18
	call lcd_putchar
	pop r18

	ldi r18, 1
	push r18
	lds r18, col_pos2
	push r18
	call lcd_gotoxy
	pop r18
	pop r18

	lds r18, num + 2
	push r18
	call lcd_putchar
	pop r18


	ret
;end of display collatz

speed_eight:

		ldi r18, high(TIMER38_COUNTER_INIT)
		sts TCNT3H, r16
		ldi r18, low(TIMER38_COUNTER_INIT)
		sts TCNT3L, r18
	pop r18
	ret


speed_nine:

		ldi r18, high(TIMER39_COUNTER_INIT)
		sts TCNT3H, r16
		ldi r18, low(TIMER39_COUNTER_INIT)
		sts TCNT3L, r18
	pop r18
	ret

update_speed:
	push r18
		lds r18, numbers_register+4
		cpi r18, 0
		breq speed_zero
		cpi r18, 1
		breq speed_one
		cpi r18, 2
		breq speed_two
		cpi r18, 3
		breq speed_three
		cpi r18, 4
		breq speed_four
		cpi r18, 5
		breq speed_five
		cpi r18, 6
		breq speed_six
		cpi r18, 7
		breq speed_seven
		cpi r18, 8
		breq speed_eight
		cpi r18, 9
		breq speed_nine

speed_zero:

		ldi r18, 0
		sts TCNT3H, r16
		ldi r18, 0
		sts TCNT3L, r18
	pop r18
	ret

speed_one:

		ldi r18, high(TIMER31_COUNTER_INIT)
		sts TCNT3H, r16
		ldi r18, low(TIMER31_COUNTER_INIT)
		sts TCNT3L, r18
	pop r18
	ret

speed_two:

		ldi r18, high(TIMER32_COUNTER_INIT)
		sts TCNT3H, r16
		ldi r18, low(TIMER32_COUNTER_INIT)
		sts TCNT3L, r18
	pop r18
	ret

speed_three:

		ldi r18, high(TIMER33_COUNTER_INIT)
		sts TCNT3H, r16
		ldi r18, low(TIMER33_COUNTER_INIT)
		sts TCNT3L, r18
	pop r18
	ret

speed_four:

		ldi r18, high(TIMER34_COUNTER_INIT)
		sts TCNT3H, r16
		ldi r18, low(TIMER34_COUNTER_INIT)
		sts TCNT3L, r18
	pop r18
	ret

speed_five:

		ldi r18, high(TIMER35_COUNTER_INIT)
		sts TCNT3H, r16
		ldi r18, low(TIMER35_COUNTER_INIT)
		sts TCNT3L, r18
	pop r18
	ret


speed_six:

		ldi r18, high(TIMER36_COUNTER_INIT)
		sts TCNT3H, r16
		ldi r18, low(TIMER36_COUNTER_INIT)
		sts TCNT3L, r18
	pop r18
	ret


speed_seven:

		ldi r18, high(TIMER37_COUNTER_INIT)
		sts TCNT3H, r16
		ldi r18, low(TIMER37_COUNTER_INIT)
		sts TCNT3L, r18
	pop r18
	ret




msg1_p:	.db "Nico Rodriguez   ", 0
msg2_p: .db "CSC230-Fall 2019 " , 0
template1_p: .db " n=000+  SPD: 0 ", 0
template2_p: .db "cnt:000 v:000000", 0



.dseg
.org 0x200
;
; The program copies the strings from program memory
; into data memory.  These are the strings
; that are actually displayed on the lcd
;
numbers_register: .byte 15


speed: .byte 1
visibility_count: .byte 1
collatz_space: .byte 3
CM: .byte 1
CH: .byte 1
CL: .byte 1

num: 	.byte 4
toTranslate: .byte 1
col_pos1: .byte 1
col_pos2: .byte 1

visibility: .byte 1
template1: .byte 17
template2: .byte 17
msg1:	.byte 17
msg2:	.byte 17
current_xpoint:		.byte 1
index_register: .byte 15
input_index: .byte 5
count: .byte 2
character1: .byte 1
character2: .byte 1
numy: .byte 1
collatz_v: .byte 3

;
; Include the HD44780 LCD Driver for ATmega2560
;
; This library has it's own .cseg, .dseg, and .def
; which is why it's included last, so it would not interfere
; with the main program design.
#define LCD_LIBONLY
.include "lcd.asm"
