;Nicolas Rodriguez
;10/20/2019
;V00919074
;CSC230
;This program steps throught pascals triangle using the buttons on the Arduino
;Displays the ending 6 lowest bits of the current number on the Arduino LED's
;

.cseg
.org 0

;Uses registers:
;				r16, r17, r18, r19, r21, r22, r23, r24, r25, r26

;INITIALIZER


CLR R16
CLR R17
CLR R18
CLR R19
CLR R21
CLR R22
CLR R25
CLR R26


CLR R20 ;clear regs
CLR R23
CLR R24

ldi r16, 1
sts 0x200, r16 ;loads all the pascal numbers into the memory
sts 0x20a, r16
sts 0x214, r16
sts 0x21E, R16
STS 0X228, R16
STS 0X232, R16
STS 0X23C, R16
STS 0X246, R16
STS 0X250, R16
STS 0X25A, R16

STS 0X20B, R16
STS 0X216, R16
STS 0X221, R16
STS 0X22C, R16
STS 0X237, R16
STS 0X242, R16
STS 0X24D, R16
STS 0X258, R16
STS 0X263, R16

LDI R16, 2
STS 0X215, R16
LDI R16, 3
STS 0X21F, R16
STS 0X220, R16
LDI R16, 4
STS 0X229, R16
STS 0X22B, R16
LDI R16, 5
STS 0X233, R16
STS 0X236, R16
LDI R16, 6
STS 0X22A, R16
STS 0X23D, R16
STS 0X241, R16
LDI R16, 7
STS 0X247, R16
STS 0X24C, R16
LDI R16, 8
STS 0X251, R16
STS 0X257, R16
LDI R16, 9
STS 0X25B, R16
STS 0X262, R16

LDI R16, 10
STS 0X234, R16
STS 0X235, R16
LDI R16, 15
STS 0X23E, R16
STS 0X240, R16
LDI R16, 21
STS 0X248, R16
STS 0X24B, R16
LDI R16, 28
STS 0X252, R16
STS 0X256, R16
LDI R16, 36
STS 0X25C, R16
STS 0X261, R16

LDI R16, 20
STS 0X23F, R16
LDI R16, 35
STS 0X249, R16
STS 0X24A, R16
LDI R16, 56
STS 0X253, R16
STS 0X255, R16
LDI R16, 84
STS 0X25D, R16
STS 0X260, R16
LDI R16, 70
STS 0X254, R16
LDI R16, 126
STS 0X25E, R16
STS 0X25F, R16

LDI  R16, 0


clr R16

LDI XL, low(triangle)
LDI XH, high(triangle)

ldi r16, 0x87

sts ADCSRA, r16
ldi r16, 0x40
sts ADMUX, r16

; initialize PORTB and PORTL for ouput
ldi	r16, 0b10101010
out DDRB, r16
ldi	r16, 0b00001010
sts DDRL, r16

clr r26

firstOne:
	ldi r26, 0b00000010
	OUT PORTB, r26
	clr r26
	jmp mainLoop


mainLoop:

	clr r24
	clr r22
	jmp checkButton


checkButton:

	lds r16, ADCSRA
	ori r16, 0x40
	sts ADCSRA, r16

wait:
	lds r16, ADCSRA
	andi r16, 0x40
	brne wait

	lds r16, ADCL
	lds r17, ADCH

	clr r24
	cpi r17, 0

mrFixIt:

;decides what button has been pressed
	clr r24

	cpi r16, 0x32
	cpc r17, r24
	brlo right

	cpi r16, 0xC3
	cpc r17, r24
	brlo up

	clr r25
	ldi r25, 0x01
	cpi r16, 0x7c
	cpc r17, r25
	brlo down

	clr r25
	ldi r25, 0x02
	cpi r16, 0x2B
	cpc r17, r25
	brlo left

	jmp mainLoop

up:
	LD r19, -X
	LD r19, -X
	LD r19, -X
	LD r19, -X
	LD r19, -X
	LD r19, -X
	LD r19, -X
	LD r19, -X
	LD r19, -X
	LD r19, -X
	call separatists
	jmp mainLoop

down:
	LD r19, X+
	LD r19, X+
	LD r19, X+
	LD r19, X+
	LD r19, X+
	LD r19, X+
	LD r19, X+
	LD r19, X+
	LD r19, X+
	LD r19, X+
	LD r19, X
	call separatists
	jmp mainLoop

left:
	LD r19, -X
	call separatists
	jmp mainLoop

right:
	LD r19, X+
	call separatists
	jmp mainLoop




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
		ldi r21, 0xAF
x2:
			ldi r22, 0x0E
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


skip:
	jmp mainLoop


separatists: ;separates the binary into something readable for the ports, then outputs
	clr r24
	clr r23
	clr r20
	OUT PORTB, r20
	STS PORTL, r20

	mov R20, R19
	mov R23, R20
	ANDI R20, 0b00000011
	ANDI R23, 0B00111100

	;PORT B
		LDI R24, 0 ;Initialize
		LSL R20
		MOV R24, R20
		ANDI R24, 0B00000010
		LSR R24
		OR R20, R24
		ANDI R20, 0B11111101
		LSL r20
		OUT PORTB, R20
		LDI R24, 0


	;PORTL
		LDI R24, 0B00100000
		AND R24, R23
		LSL R24
		OR R23, R24
		ANDI R23, 0B11011111
			;R23 = 0B01011100

		LDI R24, 0B00000100
		AND R24, R23
		LSR R24
		LSR R24
		OR R23, R24
		ANDI R23, 0B11111011
			;R23 = 0B01011001

		LDI R24, 0B00001000
		AND R24, R23
		LSR R24
		OR R23, R24
		ANDI R23, 0B11110111
		LSL R23
		STS PORTL, R23
		LDI R24, 0


		call delay
		jmp mainLoop



.dseg
.org 0x200
triangle: .byte 100
