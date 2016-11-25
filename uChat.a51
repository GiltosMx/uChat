				T2CON	EQU 0C8H			; TF2 EXF2 RCLK TCLK EXEN2 TR2 C/!T2 CP/!RL2
				T2MOD	EQU 0C9H
				RCAP2L	EQU 0CAH
				RCAP2H	EQU 0CBH
				TL2		EQU 0CCH
				TH2		EQU 0CDH
				TR2		EQU 0CAH
				TF2		EQU 0CFH
				LCDDATA	EQU P2 ;Salida al LCD
				TECLADO	EQU P0 ;Entrada de 4 bits, del teclado matricial
				RSLCD	EQU P3.6
				ELCD	EQU P3.7
				ALTB	EQU P3.4 ;Entrada del boton ALT
				SENDB	EQU P3.2 ;Entrada del boton SEND
				ALTF	EQU 00H
				ALTDAT	EQU 01H
				EDANT	EQU 21H
				EDSIG	EQU 22H
				ACUM	EQU 23H
				TOKEN	EQU 24H
				YO		EQU 00H

				ORG 0000H
				JMP main
				ORG 0003H ;IEX0
				JMP SEND
				ORG 000BH ;T0
				JMP T0ISR
				ORG 0013H ;IE1
				JMP DECO
				ORG 002BH ;T2F
				JMP T2ISR
				ORG 0040H

				/*
				** BANCO DE REGISTROS 0:
				** R4 - Digito alto de ALT
				** R1 - Indice de datos
				** R2 - Contador de datos
				** R3 - Contador auxiliar
				** R0 - Indice auxiliar
				*/
main:
				MOV IE, #10110111b
				MOV IP, #00110010b
				SETB IT0
				SETB IT1
				SETB TI
				SETB RI
				MOV EDANT, #00H
				MOV EDSIG, #00H
				SETB ALTF
				; Inicializar timer 2
				MOV T2CON, #00H
				MOV T2MOD, #00H
				; Poner valores de autorrecarga desborde T2 cada 10 ms
				MOV RCAP2L, #LOW(-10000)
				MOV RCAP2H, #HIGH(-10000)
				; Inicializar timer 0 y 1
				MOV TMOD, #00100001b
				MOV TH1, #0FDH
				SETB TR1
				MOV TH0, #00H
				MOV TL0, #00H
				SETB TR0
				; Inicializar puerto serial modo 2 UART 9 bits velocidad fija
				MOV SCON, #10010000b
				MOV SP, #5FH
				MOV R1, #80H
				MOV R2, #00H
				ACALL inlcd
				JMP $

SEND:
				CLR EX0
				ACALL w10ms
				ACALL w10ms
				ACALL w10ms
				ACALL w10ms
				ACALL w10ms
				MOV C, SENDB
				JC retsnd
				MOV R3, 02H 
				MOV R0, #80H
				CJNE R3, #00H, sdata0
				JMP retsnd
sdata0:			
				CLR A
				MOV A, #YO
				RL A
				RL A
				RL A
				RL A
				RL A
				RL A
				RL A
				ORL A, #30H
				ORL A, R2
				MOV C, TOKEN
				MOV TB8, C
				MOV SBUF, A
				JNB TI, $
				CLR TI
sdata:			
				MOV SBUF, @R0
				JNB TI, $
				CLR TI
				INC R0
				DEC R3
				CJNE R3, #00H, sdata
retsnd:			
				ACALL clar
				SETB EX0
				RETI
				
clar:			
				MOV R1, #80H
				MOV R2, #00H
				CLR RSLCD
				MOV LCDDATA, #80H
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				MOV R5, #10H
				SETB RSLCD
clarcic:		
				MOV LCDDATA, #20H
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				DJNZ R5, clarcic
				CLR RSLCD
				MOV LCDDATA, #80H
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				MOV A, #YO
				ORL A, #30H
				MOV LCDDATA, A
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				MOV LCDDATA, #3AH
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				RET

w10ms:
				SETB TR2
				CLR F0
				JNB F0, $
				CLR TR2
				RET

inlcd:
				CLR RSLCD					; modo de instruccion
				ACALL w10ms
				ACALL w10ms
				MOV LCDDATA, #38H
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				MOV LCDDATA, #38H
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				MOV LCDDATA, #38H
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				MOV LCDDATA, #01H
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				MOV LCDDATA, #0FH			; Mostrar cursor parpadeando
				SETB ELCD
				NOP
				CLR ELCD
				
				CLR RSLCD
				MOV LCDDATA, #80H
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				MOV A, #YO
				ORL A, #30H
				MOV LCDDATA, A
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				MOV LCDDATA, #3AH
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				RET

dato:
				INC R2
				MOV @R1, A
				INC R1
				; Mostrar dato el LCD
				SETB RSLCD
				MOV LCDDATA, A
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				RET

DECO: ;Recibe dato del teclado matricial y lo decodifica
				CJNE R2, #0EH, agr
				JMP retdec1
agr:		
				MOV C, ALTF
				JC alt
				MOV A, TECLADO
				ANL A, #0FH
				MOV DPTR, #Val
				MOVC A, @A + DPTR
				JMP retdec
alt:
				MOV A, TECLADO
				ANL A, #0FH
				MOV DPTR, #Val2
				MOVC A, @A + DPTR
				JB ALTDAT, dato2
dato1:
				SWAP A
				MOV R4, A
				SETB ALTDAT
				JMP retdec1
dato2:
				ORL A, R4
				CLR ALTDAT
				MOV R4, #00H
				JB ALTF, $
retdec:
				ACALL dato
retdec1:
				RETI

T2ISR:
				CLR TF2
				SETB F0
				RETI

T0ISR: ;Checa si el boton ALT sigue presionado
				MOV ACUM, A
				PUSH ACUM
				CLR TF0
				MOV C, ALTB
				MOV EDSIG.0, C
				MOV A, EDANT
				XRL A, EDSIG
				MOV C, ACC.0
				JNC ret0
				CPL ALTF
ret0:
				MOV EDANT, EDSIG
				MOV TH0, #00H
				MOV TL0, #00H
				POP ACUM
				MOV A, ACUM
				RETI

Val:
				DB 31H			; 1
				DB 32H			; 2
				DB 33H			; 3
				DB 41H			; A
				DB 34H			; 4
				DB 35H			; 5
				DB 36H			; 6
				DB 42H			; B
				DB 37H			; 7
				DB 38H			; 8
				DB 39H			; 9
				DB 43H			; C
				DB 45H			; E
				DB 30H			; 0
				DB 46H			; F
				DB 44H			; D

Val2:
				DB 01H
				DB 02H
				DB 03H
				DB 0AH
				DB 04H
				DB 05H
				DB 06H
				DB 0BH
				DB 07H
				DB 08H
				DB 09H
				DB 0CH
				DB 0EH
				DB 00H
				DB 0FH
				DB 0DH
				END
