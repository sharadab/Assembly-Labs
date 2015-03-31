;shows my student number
$MODDE2

org 0000H
	ljmp myprogram
	

WaitHalfSec:
	mov R2, #90
L3: mov R1, #250
L2: mov R0, #250
L1: djnz R0, L1
	djnz R1, L2
	djnz R2, L3
	ret
	
myprogram:
	mov SP, #7FH
	
	mov HEX7, #30H
	lcall WaitHalfSec
	mov HEX7, #7FH
	
	mov HEX6, #78H
	lcall WaitHalfSec
	mov HEX6, #7FH

	mov HEX5, #10H
	lcall WaitHalfSec
	mov HEX5, #7FH

	mov HEX4, #30H
	lcall WaitHalfSec
	mov HEX4, #7FH

	mov HEX3, #40H
	lcall WaitHalfSec
	mov HEX3, #7FH

	mov HEX2, #79H
	lcall WaitHalfSec
	mov HEX2, #7FH

	mov HEX1, #24H
	lcall WaitHalfSec
	mov HEX1, #7FH

	mov HEX0, #40H
	lcall WaitHalfSec
	mov HEX0, #7FH

	
	mov HEX7, #30H
	mov HEX6, #78H
	mov HEX5, #10H
	mov HEX4, #30H
	mov HEX3, #40H
	mov HEX2, #79H
	mov HEX1, #24H
	mov HEX0, #40H
	
	ljmp myprogram

END