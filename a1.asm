;
; CSC 230: Assignment 1
;  
; YOUR NAME GOES HERE: Nicolas Rodriguez
;	Date: 9/29/2019
;
; This program generates each number in the Collatz sequence and stops at 1. 
; It retrieves the number at which to start the sequence from data memory 
; location labeled "input", then counts how many numbers there are in the 
; sequence (by generating them) and stores the resulting count in data memory
; location labeled "output". For more details see the related PDF on conneX.
;
; Input:
;  (input) Positive integer with which to start the sequence (8-bit).
;
; Output: 
;  (output) Number of items in the sequence as 16-bit little-endian integer.
;
; The code provided below already contains the labels "input" and "output".
; In the AVR there is no way to automatically initialize data memory, therefore
; the code that initializes data memory with values from program memory is also
; provided below.
;
.cseg
.org 0
	ldi ZH, high(init<<1)		; initialize Z to point to init
	ldi ZL, low(init<<1)
	lpm r0, Z+					; get the first byte
	sts input, r0				; store it in data memory
	lpm r0, Z					; get the second byte
	sts input+1, r0				; store it in data memory
	clr r0

;*** Do not change anything above this line ***

;****
; YOUR CODE GOES HERE:
;	
	;r16 = count
	;r17 = high count

	;r20 = n
	;r21 = n high




	;initialize variables
	ldi r23, 0
	ldi r19, 0
	ldi r16, 1
	ldi r17, 0
	ldi r25, 1 ;constant 1
	ldi r26, 0 ;constant 0
	

	
	lds r20, input
	lds r21, input+1



	loop:
		add r16, r25; R16 + 1
		adc r17, r26
		clr r18
		mov   r18, r20  ;copies r20 into r18(disposable)
		andi   r18, 01	;bitwise mask of 01 and r18, stores 1 in r18 if odd, 0 if even
		cpi r18, 0
		breq if
		brne else
			if: ;if n%2==0 divide by 2, + 1
				clr r18
				mov r18, r21
				andi r18, 1 
				

				lsr r21
				lsr r20

				cpi r18, 1
				breq highCarry	;if number needs to be carried jmp to highCarry
				brne compare

				highCarry:	
					ori r20, 128	;add carry bit using or mask to most significant bit
					jmp compare

				jmp compare

			else:		;If n is odd, n=n*3+1
				add r19, r20
				adc r23, r21	;multiplying r21 by 3, and adding the carry from prev operation

				add r19, r20	
				adc r23, r21	

				add r19, r20
				adc r23, r21

				add r19, r25 
				adc r21, r26

				mov r20, r19 
				mov r21, r23
				clr r23
				ldi r19, 0
				jmp compare
	compare: 

		cpi r20, 1 
		brne loop ; n!= 1, go to loop
		breq ifHighEmpty; n==1 check if high empty

		ifHighEmpty: ;checks if high n is empty before assuming n is 1
			cpi r21, 0	
			breq finish	;if empty, go to finish
			brne loop	;if not go back to loop
	
finish:
	sts output, r16
	sts output+1, r17
	jmp done



;
; YOUR CODE FINISHES HERE
;****

;*** Do not change anything below this line ***

done:	jmp done

; This is the constant for initializing the "input" data memory location
; Note that program memory must be specified in double-bytes (words).
init:	.db 0x07, 0x00

; This is in the data memory segment (i.e. SRAM)
; The first real memory location in SRAM starts at location 0x200 on
; the ATMega 2560 processor. Locations below 0x200 are reserved for
; memory addressable registers and I/O
;
.dseg
.org 0x200
input:	.byte 2
output:	.byte 2
