$modde2

org 0000H
ljmp myprogram
	
$include(lab8lookup.asm)
$include(math16.asm)

dseg at 30h
x: ds 2
y: ds 2
bcd: ds 4 

bseg
mf: dbit 1

CSEG

; Look-up table for 7-seg displays
myLUT:
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H        ; 0 TO 4
    DB 092H, 082H, 0F8H, 080H, 090H        ; 4 TO 9

ReadNumber: ;shortened version of ReadNumber from calculator lab
mov x+0, SWA ;x+0 takes value of first 8 switches		
clr a				
mov a, SWB	;acc gets value of next 8 switches		
anl a, #00000011B		
mov x+1, a	;putting second set of switches in x+1		
ret
	
Display: ;code comes from calculator lab!
mov dptr, #myLUT
mov a, bcd+0 ;unpacking the LSD. This is digit 0
anl a, #0fh
movc a, @a+dptr
mov HEX0, a ;show in HEX0
mov A, bcd+0 ;still unpacking this part. Digit 1.
swap a
anl a, #0fh
movc a, @a+dptr
mov HEX1, a ;show in HEX1
mov a, bcd+1 ;next part of BCD
anl a, #0fh
movc a, @a+dptr
mov HEX2, a ;show in HEX2
mov a, bcd+1 ;unpacking
swap a
anl a, #0fh
movc a, @a+dptr ;not showing this! This is the indicator for whether it's -ve.
ret

myprogram:
mov SP, #7FH
clr a
mov LEDRA, a
mov LEDRB, a
mov LEDRC, a
mov LEDG, a
mov bcd+0, a
mov bcd+1, a
mov bcd+2, a

forever:
lcall ConvertToOutput
lcall hex2bcd
lcall Display
lcall forever

ADCToTemp:
mov dptr, #ADC_LUT ;get to the ADC lookup table value
mov y, #2 
lcall mul16 ;multiplies value by 2
mov y+1, dph ;the MSD is the high part		
mov y+0, dpl ;the LSD is the low part		
lcall add16	;add these two		
mov dph, x+1 ;remember x+1 has value of switches!		
mov dpl, x+0 ;x+0 has value of switches!		
clr a
movc a, @a+dptr	;get to the value of temp from table	
mov x+1, a	;first 8 bits of temp value in x+1		
inc dptr ;increment dptr- get to next value			
clr a 
movc a, @a+dptr	;put this new value in a	
mov x+0, a	;next 8 bits of temp value in x+0		
ret

ConvertToOutput:
lcall ReadNumber
lcall ADCToTemp
lcall CheckNeg
ret

CheckNeg:
mov a, x+1 ;put the MSD part in accumulator
jb acc.7, Negative ;if there is a 1 in the most significant pos, go to Negative
mov HEX3, #0FFH ;otherwise it's positive, so turn off HEX3
ret

Negative:
mov HEX3, #03FH ;we know it's -ve, so put a "-" sign in HEX3
lcall unNegative ;apply 2s complement to fix this
ret

unNegative: ;finds the actual value (without the -ve)
push acc ;store accumulator in stack		
push psw ;store psw in stack			
clr c				
clr a				
subb a, x+0	;subtract LSD from 0	
mov x+0, a	;put this new value in x+0: basically 2s complement		
clr a
subb a, x+1	;subtract MSD from 0		
mov x+1, a	;put this back in x+1: basically 2s complement		
pop psw				
pop acc				
ret

END