;A 32 bit calculator operated using switches and pushbuttons on the Altera Board
;Does addition, subtraction, multiplication, division
;7 segment displays

$modde2

	CSEG at 0
	ljmp mycode

dseg at 30h
x: ds 4
y: ds 4
bcd: ds 5
operation: ds 1

bseg
mf: dbit 1
$include(math32.asm)

	CSEG

; Look-up table for 7-seg displays
myLUT:
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H        ; 0 TO 4
    DB 092H, 082H, 0F8H, 080H, 090H        ; 4 TO 9
    DB 088H, 083H, 0C6H, 0A1H, 086H, 08EH  ; A to F

showBCD MAC
	; Display LSD
    mov A, %0
    anl a, #0fh
    movc A, @A+dptr
    mov %1, A
	; Display MSD
    mov A, %0
    swap a
    anl a, #0fh
    movc A, @A+dptr
    mov %2, A
ENDMAC

Display:
	mov dptr, #myLUT
	showBCD(bcd+0, HEX0, HEX1)
	showBCD(bcd+1, HEX2, HEX3)
	showBCD(bcd+2, HEX4, HEX5)
	showBCD(bcd+3, HEX6, HEX7)
    ret

MYRLC MAC
	mov a, %0
	rlc a
	mov %0, a
ENDMAC

Shift_Digits:
	mov R0, #4 ; shift left four bits
Shift_Digits_L0:
	clr c
	MYRLC(bcd+0)
	MYRLC(bcd+1)
	MYRLC(bcd+2)
	MYRLC(bcd+3)
	MYRLC(bcd+4)
	djnz R0, Shift_Digits_L0
	; R7 has the new bcd digit	
	mov a, R7
	orl a, bcd+0
	mov bcd+0, a
	; bcd+4 doesn't fit in the 7-segment displays so make it zero
	clr a
	mov bcd+4, a
	ret

Wait50ms:
;33.33MHz, 1 clk per cycle: 0.03us
	mov R0, #30
L3: mov R1, #74
L2: mov R2, #250
L1: djnz R2, L1 ;3*250*0.03us=22.5us
    djnz R1, L2 ;74*22.5us=1.665ms
    djnz R0, L3 ;1.665ms*30=50ms
    ret
    
WaitOneSec:
		mov R3, #4
W4:		mov R2, #90
W3:		mov R1, #250
W2:		mov R0, #250
W1:		djnz R0, W1 ; 3 machine cycles-> 3*30ns*250=22.5us
		djnz R1, W2 ; 22.5us*250=5.625ms
		djnz R2, W3 ; 5.625ms*90=0.506s (approximately)
		djnz R3, W4
		ret

; Check if SW0 to SW15 are toggled up.  Returns the toggled switch in
; R7.  If the carry is not set, no toggling switches were detected.
ReadNumber:
	mov r4, SWA ; Read switches 0 to 7
	mov r5, SWB ; Read switches 8 to 15
	mov a, r4
	orl a, r5
	jz ReadNumber_no_number
	lcall Wait50ms ; debounce
	mov a, SWA
	clr c
	subb a, r4
	jnz ReadNumber_no_number ; it was a bounce
	mov a, SWB
	clr c
	subb a, r5
	jnz ReadNumber_no_number ; it was a bounce
	mov r7, #16 ; Loop counter
ReadNumber_L0:
	clr c
	mov a, r4
	rlc a
	mov r4, a
	mov a, r5
	rlc a
	mov r5, a
	jc ReadNumber_decode
	djnz r7, ReadNumber_L0
	sjmp ReadNumber_no_number	
ReadNumber_decode:
	dec r7
	setb c
ReadNumber_L1:
	mov a, SWA
	jnz ReadNumber_L1
ReadNumber_L2:
	mov a, SWB
	jnz ReadNumber_L2
	ret
ReadNumber_no_number:
	clr c
	ret
	
mycode:
	mov SP, #7FH
	clr a
	mov LEDRA, a
	mov LEDRB, a
	mov LEDRC, a
	mov LEDG, a
	mov bcd+0, a
	mov bcd+1, a
	mov bcd+2, a
	mov bcd+3, a
	mov bcd+4, a
	lcall Display

studentNumber: ;shows my student number for a second and then clears all displays
mov HEX7, #30H
mov HEX6, #78H
mov HEX5, #10H
mov HEX4, #30H
mov HEX3, #40H
mov HEX2, #79H
mov HEX1, #24H
mov HEX0, #40H
lcall WaitOneSec
mov HEX7, #7FH
mov HEX6, #7FH
mov HEX5, #7FH
mov HEX4, #7FH
mov HEX3, #7FH
mov HEX2, #7FH
mov HEX1, #7FH
mov HEX0, #7FH

forever:
;addition check
jb KEY.3, no_add ; If '+' key not pressed, skip
jnb KEY.3, $ ; Wait for user to release '+' key
lcall addition

;subtraction check
no_add:
jb KEY.2, no_sub
jnb KEY.2, $
lcall sub

;multiplication check (the multiply button is a switch)
no_sub:
mov a, SWC
jnb acc.1, no_multiply 
	wait_for_switch:
	mov a, SWC
	jb acc.1, wait_for_switch 
lcall multiply

;division check (divide button is a switch)
no_multiply:
mov a, SWC
jnb acc.0, no_div 
	wait_for_switch1:
	mov a, SWC
	jb acc.0, wait_for_switch1 
lcall divide

;"equal key" check
no_div:
jb KEY.1, no_equal ; If '=' key not pressed, skip
jnb KEY.1, $ ; Wait for user to release '=' key
lcall equal

no_equal:
; get more numbers
lcall ReadNumber
jnc no_new_digit ; indirect jump to 'forever'
lcall Shift_Digits
lcall Display
no_new_digit:
ljmp forever 

addition:
lcall bcd2hex ; Convert the BCD number to hex, saves to x
mov y+0, x+0
mov y+1, x+1
mov y+2, x+2
mov y+3, x+3
mov x+0, #0
mov x+1, #0
mov x+2, #0
mov x+3, #0
lcall hex2bcd ; Convert binary x to BCD
lcall Display ; Display our new number in BCD
mov operation, #00000001B
ljmp forever ; go check for more input

sub:
lcall bcd2hex ; Convert the BCD number to hex, saves to x
mov y+0, x+0
mov y+1, x+1
mov y+2, x+2
mov y+3, x+3
mov x+0, #0
mov x+1, #0
mov x+2, #0
mov x+3, #0
lcall hex2bcd ; Convert binary x to BCD
lcall Display ; Display our new number in BCD
mov operation, #00000010B
ljmp forever ; go check for more input

multiply:
lcall bcd2hex ; Convert the BCD number to hex, saves to x
mov y+0, x+0
mov y+1, x+1
mov y+2, x+2
mov y+3, x+3
mov x+0, #0
mov x+1, #0
mov x+2, #0
mov x+3, #0
lcall hex2bcd ; Convert binary x to BCD
lcall Display ; Display our new number in BCD
mov operation, #00000100B
ljmp forever ; go check for more input

divide:
lcall bcd2hex ; Convert the BCD number to hex, saves to x
mov y+0, x+0
mov y+1, x+1
mov y+2, x+2
mov y+3, x+3
mov x+0, #0
mov x+1, #0
mov x+2, #0
mov x+3, #0
lcall hex2bcd ; Convert binary x to BCD
lcall Display ; Display our new number in BCD
mov operation, #00001000B
ljmp forever ; go check for more input

equal:
lcall bcd2hex ; Convert the BCD number to hex in x
mov a, operation
jb acc.0, do_addition
jb acc.1, do_sub
jb acc.2, do_mul
jb acc.3, do_div

do_addition:
lcall add32 ; Add the numbers stored in x and y
lcall hex2bcd ; Convert result in x to BCD
lcall Display ; Display BCD using 7-segment displays
ljmp forever ; go check for more input

do_sub:
lcall xchg_xy
lcall sub32 ; Add the numbers stored in x and y
lcall hex2bcd ; Convert result in x to BCD
lcall Display ; Display BCD using 7-segment displays
ljmp forever ; go check for more input

do_mul:
lcall mul32
lcall hex2bcd
lcall Display
ljmp forever

do_div:
lcall xchg_xy
lcall div32
lcall hex2bcd
lcall Display
ljmp forever


	
end


