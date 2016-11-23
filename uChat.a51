		T2CON	EQU 0C8H			; TF2 EXF2 RCLK TCLK EXEN2 TR2 C/!T2 CP/!RL2
		T2MOD	EQU 0C9H
		RCAP2L	EQU 0CAH
		RCAP2H	EQU 0CBH
		TL2		EQU 0CCH
		TH2		EQU 0CDH
		TR2		EQU 0CAH
		TF2		EQU 0CFH
		LCDDATA	EQU P2
		TECLADO	EQU P0
		RSLCD	EQU P3.6
		ELCD	EQU P3.7
		ALTB	EQU P3.4
		SENDB	EQU P3.2
		ALTF	EQU 00H
		ALTDAT	EQU 01H
		EDANT	EQU 21H
		EDSIG	EQU 22H
		ACUM	EQU 23H
				
				ORG 0000H
				JMP main
				ORG 0003H
				JMP SEND
				ORG 000BH
				JMP T0ISR
				ORG 0013H
				JMP DECO
				ORG 002BH
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
				MOV IE, #10100111b
				MOV IP, #00100010b
				SETB IT0
				SETB IT1
				SETB TI
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
				; Inicializar puerto serial
				MOV SCON, #01010000b
				MOV SP, #5FH
				MOV R1, #80H
				MOV R2, #00H
				ACALL inlcd
				JMP $
					
w10ms:			SETB TR2
				CLR F0
				JNB F0, $
				CLR TR2		
				RET

inlcd:			CLR RSLCD					; modo de instruccion
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
				RET
				END