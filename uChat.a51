					T2CON	EQU 0C8H			; TF2 EXF2 RCLK TCLK EXEN2 TR2 C/!T2 CP/!RL2
					T2MOD	EQU 0C9H
					RCAP2L	EQU 0CAH
					RCAP2H	EQU 0CBH
					TL2		EQU 0CCH
					TH2		EQU 0CDH
					TR2		EQU 0CAH
					TF2		EQU 0CFH

					;Banderas
					ALTF	EQU 00H
					ALTDAT	EQU 01H
					INFOM   EQU 02H
					;TOKEN	EQU 03H
					;SENDING	EQU 04H

					;Acceso bit a bit
					EDANT	EQU 22H
					EDSIG	EQU 23H
					ACUM	EQU 24H
					ACUM2	EQU 25H
					INFOBY	EQU 26H

					YO		EQU 02H

					;I/O
					LCDDATA	EQU P2 ;Salida al LCD
					TECLADO	EQU P0 ;Entrada de 4 bits, del teclado matricial
					RSLCD	EQU P3.6
					ELCD	EQU P3.7
					ALTB	EQU P1.1 ;Entrada del boton ALT
					SENDB	EQU P3.3 ;Entrada del boton SEND
					HISTB	EQU P1.2
					BKSPCB	EQU P1.0


					;Memoria de proposito general (bytes)
					MYMSG	EQU 80H
					LASTMSG	EQU 8EH
					SECMSG	EQU 9CH
					THIRMSG	EQU 0AAH


					;Accesibles bit a bit (Mensajes guardados) (bytes)
					LASTCNT	EQU 2AH
					LSTSNDR EQU	2BH
					SECCNT	EQU 2CH
					SECSNDR EQU 2DH
					THIRCNT	EQU 2EH
					THRSNDR EQU 2FH

;					/*
;					** BANCO DE REGISTROS 0:
;					** R4 - Digito alto de ALT
;					** R1 - Indice de DATOs
;					** R2 - Contador de DATOs
;					** R3 - Contador auxiliar
;					** R0 - Indice auxiliar
;					*/
;
					ORG 0000H
					JMP main
					ORG 0003H ;EX0
					JMP SEND
					ORG 000BH
					JMP T0ISR
					ORG 0013H ;EX1
					JMP DECO
					ORG 0023H
					JMP SERIAL
					ORG 002BH
					JMP T2ISR
					ORG 0040H

main:
					;CLR P0.5
					; Inicializar puerto serial
					MOV SP, #3FH
					MOV IE, #10110111b;MOV IE, #10100111b
					MOV IP, #00110010b
					SETB IT0
					SETB IT1
					CLR INFOM

					;SETB TOKEN ; Solo micro 0
					;CLR TOKEN ; Micros 1 y 2

					;CLR SENDING
					CLR RI
					MOV EDANT, #00H
					MOV EDSIG, #00H
					SETB ALTF
					; Inicializar timer 2
					MOV T2CON, #00H
					MOV T2MOD, #00H
					; Poner valores de autorrecarga desborde T2 cada 10 ms
					MOV RCAP2L, #0F0H
					MOV RCAP2H, #0D8H
					; Inicializar timer 0 y 1
					MOV TMOD, #00100001b
					MOV TH1, #0FDH
					SETB TR1
					MOV TH0, #00H
					MOV TL0, #00H
					SETB TR0
					MOV SCON, #01010000b ;MOV SCON, #01000000b
					;MOV SP, #3FH
					MOV R1, #80H
					MOV R2, #00H
					ACALL INLCD
					CLR TI
					JMP $

W10MS:
					SETB TR2
					JNB TF2, $
					CLR TR2
					RET


T2ISR:
					CLR TF2
					RETI
INLCD:
					CLR RSLCD					; modo de instruccion
					ACALL W10MS
					ACALL W10MS
					MOV LCDDATA, #38H
					SETB ELCD
					NOP
					CLR ELCD
					ACALL W10MS
					MOV LCDDATA, #38H
					SETB ELCD
					NOP
					CLR ELCD
					ACALL W10MS
					MOV LCDDATA, #38H
					SETB ELCD
					NOP
					CLR ELCD
					ACALL W10MS
					MOV LCDDATA, #01H
					SETB ELCD
					NOP
					CLR ELCD
					ACALL W10MS
					MOV LCDDATA, #0FH			; Mostrar cursor parpadeando
					SETB ELCD
					NOP
					CLR ELCD
					ACALL W10MS
					CLR RSLCD
					;Muestra Yo y pone el cursor en la segunda linea
					MOV LCDDATA, #0C0H
					SETB ELCD
					NOP
					CLR ELCD
					ACALL W10MS
					SETB RSLCD
					MOV A, #YO
					ORL A, #30H
					MOV LCDDATA, A
					SETB ELCD
					NOP
					CLR ELCD
					ACALL W10MS
					MOV LCDDATA, #3AH
					SETB ELCD
					NOP
					CLR ELCD
					ACALL W10MS
					RET

DATO:
					MOV ACUM, A
					;Manda DATOs al LCD
					INC R2
					MOV @R1, A
					INC R1
					; Mostrar DATO el LCD
					SETB RSLCD
					MOV LCDDATA, A
					SETB ELCD
					NOP
					CLR ELCD
					ACALL W10MS
					MOV A, ACUM
					RET

SEND:
					CLR EX0
					ACALL W10MS
					ACALL W10MS
					ACALL W10MS
					ACALL W10MS
					ACALL W10MS
					MOV C, SENDB
					JC retsnd

					CLR RS0
					CLR RS1
					;Contador total de chars escritos al contador temporal R3
					MOV R3, 02H
					;Pointer al inicio de datos del mensaje local
					MOV R0, #MYMSG

					CJNE R3, #00H, genctrlbyte

					JMP retsnd

genctrlbyte:
					;SETB SENDING
					;JNB TOKEN, $
					;Genera el byte de protocolo y lo manda
					CLR A
					MOV A, #YO
					RL A
					RL A
					RL A
					RL A
					RL A
					RL A
					ORL A, #00110000B
					ORL A, R2
					;SETB TI
					MOV SBUF, A
					JNB TI, $
					CLR TI
					ACALL w10ms
					ACALL W10MS
					ACALL W10MS
					ACALL W10MS
					ACALL W10MS
					ACALL W10MS

sdata:
					MOV SBUF, @R0
					JNB TI, $
					CLR TI
					ACALL W10MS
					ACALL W10MS
					ACALL W10MS
					ACALL W10MS
					ACALL W10MS
					ACALL W10MS
					INC R0
					DJNZ R3, sdata
					ACALL WRITEOWN
					ACALL KLAR

					;CLR SENDING

retsnd:
					SETB EX0
					RETI


WRITEOWN:
					CLR RSLCD
					MOV LCDDATA, #80H
					SETB ELCD
					NOP
					CLR ELCD
					ACALL w10ms
					ACALL w10ms
					ACALL w10ms

					MOV R5, #10H
writeonwclr:
					SETB RSLCD
					MOV LCDDATA, #20H
					SETB ELCD
					NOP
					CLR ELCD
					ACALL w10ms
					ACALL w10ms
					ACALL w10ms
					DJNZ R5, writeonwclr

					CLR RSLCD
					MOV LCDDATA, #80H
					SETB ELCD
					NOP
					CLR ELCD
					ACALL w10ms
					ACALL w10ms
					ACALL w10ms

					MOV A, #YO
					ORL A, #30H
					SETB RSLCD
					MOV LCDDATA, A
					SETB ELCD
					NOP
					CLR ELCD
					ACALL w10ms
					ACALL w10ms
					ACALL w10ms

					SETB RSLCD
					MOV LCDDATA, #3AH
					SETB ELCD
					NOP
					CLR ELCD
					ACALL w10ms
					ACALL w10ms
					ACALL w10ms

					MOV R3, 02H
					MOV R0, #MYMSG

writeowncic:
					SETB RSLCD
					MOV LCDDATA, @R0
					SETB ELCD
					NOP
					CLR ELCD
					ACALL w10ms
					ACALL w10ms
					ACALL w10ms
					INC R0
					DJNZ R3, writeowncic

					RET

KLAR:
					;Limpia la parte del LCD donde se escribe,
					;despues de mandar el dato en sdata
					MOV R1, #MYMSG
					MOV R2, #00H
					CLR RSLCD
					MOV LCDDATA, #0C0H
					SETB ELCD
					NOP
					CLR ELCD
					ACALL w10ms
					;R5 = Contador de chars a escribir
					MOV R5, #10H
					SETB RSLCD
klarcic:
					MOV LCDDATA, #20H
					SETB ELCD
					NOP
					CLR ELCD
					ACALL w10ms
					DJNZ R5, klarcic

					CLR RSLCD
					MOV LCDDATA, #0C0H
					SETB ELCD
					NOP
					CLR ELCD
					ACALL w10ms

					SETB RSLCD
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


FORWARD:
					; Cambiamos a banco de registros 2
					CLR RS0
					SETB RS1

					MOV A, INFOBY
					ANL A, #30H
					RR A
					RR A
					RR A
					RR A
					DEC A
					CJNE A, #01H, contfw
					JMP retfw0
contfw:
					RL A
					RL A
					RL A
					RL A
					ANL A, #30H
					MOV R3, A
					MOV A, INFOBY
					ANL A, #0CFH
					ORL A, R3
					MOV INFOBY, A

					MOV SBUF, INFOBY
					JNB TI, $
					CLR TI
					ACALL W10MS
					ACALL W10MS
					ACALL W10MS
					ACALL W10MS
					ACALL W10MS
					ACALL W10MS

					MOV R0, #LASTMSG
					MOV R2, LASTCNT

fwcic:
					MOV SBUF, @R0
					JNB TI, $
					CLR TI
					INC R0
					ACALL W10MS
					ACALL W10MS
					ACALL W10MS
					ACALL W10MS
					ACALL W10MS
					ACALL W10MS
					DJNZ R2, fwcic
					JMP retfw
retfw0:
					;CLR SENDING
retfw:
					; Cambiamos a banco de registros 0
					CLR RS0
					CLR RS1
					RET


SERIAL:
					MOV ACUM2, A
					;Banco registros 1
					SETB RS0
					CLR RS1

;					/*Si fue TI, salimos de la interrupcion, y lo
;					maneja SEND*/
					MOV C, TI
					JC retserial

					;CLR P1.7
					CLR RI
					;Verifica si recibimos el token y lo guarda
					;MOV A, SBUF
					;CJNE A, #0FFH, contin
					;SETB TOKEN
					;JMP retserial

contin:
					;Si INFOM esta prendido, ya recibimos el byte del protocolo
					;y guardamos el mensaje
					JB INFOM, savemsg

					SETB INFOM

					MOV INFOBY, SBUF

					;;DEBUGG
					;MOV A, INFOBY
					;ACALL DATO
					;DEC R1
					;DEC R2

					;Guarda los 4 bits de conteo del protocolo en R3
					MOV A, INFOBY
					ANL A, #0FH
					MOV R3, A

					;Inicializamos el contador R5 (datos ya recibidos)
					;y el apuntador de donde inicia LASTMSG para guardar los chars
					MOV R5, #00H
					MOV R0, #LASTMSG

					JMP retserial

savemsg:

recievedata:
					;Si todavia no acabamos de recibir, guardamos el dato y salimos
					;de la interrupcion SERIAL
					MOV A, R5
					CJNE A, 0BH, revdat ;CJNE R5, R3, revdat

endrecieve:
					;Ya recibimos todos los chars. Limpiamos todas las banderas de control
					;para dejarlo listo para otra recepcion de chars.
					;SETB LASTF
					MOV LASTCNT, R3

					;Guardamos el micro remitente
					MOV A, INFOBY
					ANL A, #0C0H
					RR A
					RR A
					RR A
					RR A
					RR A
					RR A
					MOV LSTSNDR, A

					CLR INFOM
					;SETB P1.7
					;Mandamos lo recibido al LCD
					ACALL TOLCD
					;Reenvia el mensaje al siguiente micro
					ACALL FORWARD
					JMP retserial
revdat:
					MOV @R0, SBUF
					INC R0
					INC R5

					;DEBUGG
					;MOV A, SBUF
					;ACALL DATO
					;DEC R1
					;DEC R2

					MOV A, R5
					CJNE A, 0BH, retserial

					JMP endrecieve

retserial:
					;Banco registros 0
					CLR RS0
					CLR RS1
					MOV A, ACUM2
					RETI

TOLCD:
					;Limpia la parte del LCD donde se recibe,
					;despues de recibir el dato en sdata
					CLR RSLCD
					MOV LCDDATA, #80H
					SETB ELCD
					NOP
					CLR ELCD
					ACALL w10ms

					MOV R5, #10H

tolcdclr:
					SETB RSLCD
					ACALL w10ms
					ACALL w10ms
					ACALL w10ms
					MOV LCDDATA, #20H
					SETB ELCD
					NOP
					CLR ELCD
					ACALL w10ms
					ACALL w10ms
					ACALL w10ms
					DJNZ R5, tolcdclr

					ACALL w10ms
					ACALL w10ms
					ACALL w10ms
					CLR RSLCD
					MOV LCDDATA, #80H
					SETB ELCD
					NOP
					CLR ELCD
					ACALL w10ms

					ACALL w10ms
					ACALL w10ms
					ACALL w10ms
					MOV A, LSTSNDR
					ORL A, #30H
					SETB RSLCD
					MOV LCDDATA, A
					SETB ELCD
					NOP
					CLR ELCD
					ACALL w10ms

					ACALL w10ms
					ACALL w10ms
					ACALL w10ms
					MOV LCDDATA, #3AH
					SETB ELCD
					NOP
					CLR ELCD
					ACALL w10ms

					MOV R5, LASTCNT
					MOV R1, #LASTMSG

tolcdloop:
					ACALL w10ms
					ACALL w10ms
					ACALL w10ms
					SETB RSLCD
					MOV LCDDATA, @R1
					SETB ELCD
					NOP
					NOP
					NOP
					NOP
					NOP
					NOP
					CLR ELCD
					ACALL w10ms
					INC R1
					DJNZ R5, tolcdloop

					ACALL w10ms
					ACALL w10ms
					ACALL w10ms
					MOV A, #0C2H
					ADD A, 02H
					CLR RSLCD
					MOV LCDDATA, A
					SETB ELCD
					NOP
					CLR ELCD
					ACALL w10ms

					RET

DECO:
					;Recibe DATO del teclado matricial y lo decodifica
					;Verifica que no se hayan escrito los 14 chars disponibles
					MOV ACUM, A
					CLR RS0
					CLR RS1
					CJNE R2, #0EH, agr
					JMP retdec1
agr:
					MOV C, ALTF
					JNC alt
					MOV A, TECLADO
					ANL A, #0FH
					MOV DPTR, #Val
					MOVC A, @A+DPTR
					JMP retdec
alt:
					MOV A, TECLADO
					ANL A, #0FH
					MOV DPTR, #Val2
					MOVC A, @A+DPTR
					JB ALTDAT, DATO2
DATO1:
					SWAP A
					MOV R4, A
					SETB ALTDAT
					JMP retdec1
DATO2:
					ORL A, R4
					CLR ALTDAT
					MOV R4, #00H
					JB ALTF, $
retdec:
					ACALL DATO
retdec1:
					MOV A, ACUM
					CLR RS0
					CLR RS1
					RETI

T0ISR:
					MOV ACUM, A
					CLR TF0

					;Verifica si ya puede mandar el token
					;JNB TOKEN, contT0
					;JB SENDING, contT0
					;MOV SBUF, #0FFH
					;JNB TI, $
					;CLR TI
					;CLR TOKEN

contT0:
					MOV C, ALTB
					MOV EDSIG.0, C
					MOV C, BKSPCB
					MOV EDSIG.1, C
					MOV A, EDANT
					XRL A, EDSIG
					MOV C, ACC.0
					JNC bakspchk
					CPL ALTF
bakspchk:
					MOV C, ACC.1
					JNC ret0
					MOV C, EDSIG.1
					JC ret0
					ACALL BACKSPACE

ret0:
					MOV EDANT, EDSIG
					MOV A, ACUM
					RETI

BACKSPACE:
					CJNE R2, #00H, bcksp
					JMP retbcksp
bcksp:
					DEC R2
					DEC R1
					CLR RSLCD
					MOV LCDDATA, #10H
					SETB ELCD
					NOP
					CLR ELCD
					ACALL W10MS
retbcksp:
					RET

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
