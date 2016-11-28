				T2CON	EQU 0C8H			; TF2 EXF2 RCLK TCLK EXEN2 TR2 C/!T2 CP/!RL2
				T2MOD	EQU 0C9H
				RCAP2L	EQU 0CAH
				RCAP2H	EQU 0CBH
				TL2		EQU 0CCH
				TH2		EQU 0CDH
				TR2		EQU 0CAH
				TF2		EQU 0CFH

				YO		EQU 00H

				;I/O
				LCDDATA	EQU P2 ;Salida al LCD
				TECLADO	EQU P0 ;Entrada de 4 bits, del teclado matricial
				RSLCD	EQU P3.6
				ELCD	EQU P3.7
				ALTB	EQU P3.4 ;Entrada del boton ALT
				SENDB	EQU P3.2 ;Entrada del boton SEND
				HISTB	EQU P3.4
				BKSPCB	EQU P0.4

				;Banderas
				ALTF	EQU 00H
				ALTDAT	EQU 01H
				TOKEN	EQU 02H
				INFOM	EQU 03H
				LASTF	EQU 04H
				SECNDF	EQU 05H
				THIRDF	EQU 06H
				FIRSTBY	EQU 07H
				SENDING	EQU 28H
				HISTF	EQU 29H

				;Registros accesibles bit a bit
				EDANT	EQU 21H
				EDSIG	EQU 22H
				ACUM	EQU 23H
				INFOBY	EQU 24H

				;Memoria de proposito general (bytes)
				MYMSG	EQU 80H
				LASTMSG	EQU 8EH
				LASTCNT	EQU 9CH
				SECMSG	EQU 9DH
				SECCNT	EQU 0ABH
				THIRMSG	EQU 0ACH
				THIRCNT	EQU 0BAH


				ORG 0000H
				JMP main
				ORG 0003H ;IEX0
				JMP SEND
				ORG 000BH ;T0
				JMP T0ISR
				ORG 0013H ;IE1
				JMP DECO
				ORG 001BH ;T1
				JMP T1ISR
				ORG 0023H ;RI / TI
				JMP SERIAL
				ORG 002BH ;T2
				JMP T2ISR
				ORG 0040H

				/*
				** BANCO DE REGISTROS 0:
				** R4 - Digito alto de ALT
				** R1 - Indice de datos
				** R2 - Contador de datos
				** R3 - Contador auxiliar
				** R0 - Indice auxiliar
				** R5 - Limpiar escritura
				*/

				/*
				** BANCO DE REGISTROS 1:
				** R0 - Direccion lectura
				** R1 - Direccion copiado
				** R2 - Contador lectura
				** R3 - Contador recepcion total
				** R5 - Contador recepcion parcial
				*/

				/*
				** BANCO DE REGISTROS 3:
				** R0 - DIRECCION LECTURA
				*/

main:
				;Configurar interrupciones
				MOV IE, #10111111b
				MOV IP, #00111000b
				;Inicializar Banderas
				SETB IT0
				SETB IT1
				SETB TI
				SETB RI
				SETB TOKEN ;SOLO SI ES EL MICRO 00
				CLR INFOM
				CLR LASTF
				CLR SECNDF
				CLR THIRDF
				CLR FIRSTBY
				CLR SENDING
				CLR HISTF
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
				MOV TMOD, #00101001b
				MOV TH1, #HIGH(-5000)
				MOV TH0, #LOW(-5000)
				SETB TR1
				MOV TH0, #00H
				MOV TL0, #00H
				SETB TR0
				; Inicializar puerto serial modo 2 UART 9 bits velocidad fija
				MOV SCON, #10010000b
				MOV SP, #5FH
				MOV R1, #MYMSG
				MOV R2, #00H
				ACALL inlcd
				JMP $

SERIAL:
				MOV ACUM, A
				PUSH ACUM
				/*Si fue TI, salimos de la interrupcion, y lo
				maneja SEND*/
				MOV C, TI
				JC retserial

				CLR RI
				;Verifica si recibimos el token y lo guarda
				MOV A, SBUF
				CJNE A, #0FFH, contin
				MOV C, RB8
				MOV TOKEN, C
				JMP retserial
				;Si INFOM esta prendido, ya recibimos el byte del protocolo
				;y guardamos el mensaje
contin:
				MOV C, INFOM
				JC savemsg

				SETB INFOM
				ACALL PROTOCOL ;Guarda el byte de informacion del protocolo
retserial:
				POP ACUM
				MOV A, ACUM
				RETI

savemsg:
				JB FIRSTBY, recievedata
				;Si ya tenemos guardado un lastMSG, lo movemos a SCNDMSG
				JB LASTF, mvmsg1

				;Guardamos cuantos chars vamos a recibir en R3
				SETB RS0
				MOV A, INFOBY
				ANL A, #0FH
				MOV R3, A
				;Inicializamos el contador R5 (datos ya recibidos)
				;y el apuntador de donde inicia LASTMSG para guardar los chars
				MOV R5, #00H
				MOV R0, #LASTMSG
recievedata:
				;Si todavia no acabamos de recibir, guardamos el dato y salimos
				;de la interrupcion SERIAL
				CJNE R5, #0BH, revdat
				;Ya recibimos todos los chars. Limpiamos todas las banderas de control
				;para dejarlo listo para otra recepcion de chars.
				SETB LASTF
				MOV LASTCNT, R3
				CLR INFOM
				CLR FIRSTBY
				;Mandamos lo recibido al LCD
				ACALL TOLCD
				;Reenvia el mensaje al siguiente micro
				ACALL FORWARD
				JMP retserial
revdat:
				MOV @R0, SBUF
				INC R0
				INC R5
				JMP retserial
mvmsg1:
				;Si ya tenemos guardado un SCNDMSG, lo movemos al THIRDMSG
				JB SECNDF, mvmsg2
mvmsg1A:
				;Copiamos del primer mensaje, al segundo
				SETB RS0			; Cambio a banco de registros 1
				;Establecer apuntadores de lectura y copia
				MOV R0, #LASTMSG
				MOV R1, #SECMSG
				MOV R2, LASTCNT
mv1cic:
				;MOV @R1, @R0
				MOV A, @R0
				MOV @R1, A
				;Copiamos el contador de chars del LAST al SCND
				INC R0
				INC R1
				DJNZ R2, mv1cic
				MOV R0, #SECCNT
				MOV @R0, LASTCNT
				SETB SECNDF
				JMP retmov
mvmsg2:
				SETB RS0			; Cambio a banco de registros 1
				;Establecer apuntadores para lectura y copia
				MOV R0, #SECMSG
				MOV R1, #THIRMSG
				MOV R2, SECCNT
mv2cic:
				;MOV @R1, @R0
				MOV A, @R0
				MOV @R1, A

				INC R0
				INC R1
				DJNZ R2, mv2cic
				;Copiamos el contador de chars del SCND al THIRD
				MOV R0, #THIRCNT
				MOV @R0, SECCNT
				SETB THIRDF
				JMP mvmsg1A
retmov:
				SETB FIRSTBY
				;Copiar un byte de mensaje, inicializaci�n de registros
				; Recibir el dato
				SETB RS0			; Cambio a banco de registros 1

				MOV A, INFOBY
				ANL A, #0FH
				MOV R3, A
				MOV R5, #00H
				MOV R0, #LASTMSG

				MOV @R0, SBUF
				INC R0
				INC R5
				CLR RS0				; Cambio a banco de registros 0
				JMP retserial


PROTOCOL:
				MOV INFOBY, SBUF
				RET

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
				SETB RSLCD
clarcic1:
				MOV LCDDATA, #20H
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				DJNZ R5, clarcic1

				CLR RSLCD
				MOV LCDDATA, #80H
				MOV A, INFOBY
				ANL A, #0C0H
				RR A
				RR A
				RR A
				RR A
				RR A
				ORL A, #30H
				SETB RSLCD
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
				SETB RS0				; Cambiar a banco de registros 3
				SETB RS1
				MOV R0, #LASTMSG
				MOV R2, LASTCNT
tolcdcic:
				MOV LCDDATA, @R0
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				INC R0
				DJNZ R2, tolcdcic
				CLR RS0
				CLR RS1
				MOV A, R2
				ADD A, #0C2H
				CLR RSLCD
				MOV LCDDATA, A
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				RET

FORWARD:
				MOV A, INFOBY
				ANL A, #20H
				RR A
				RR A
				RR A
				RR A
				DEC A
				CJNE A, #00H, contfw
				JMP retfw
contfw:
				RL A
				RL A
				RL A
				RL A
				MOV C, INFOBY.7
				MOV ACC.7, C
				MOV C, INFOBY.6
				MOV ACC.6, C
				MOV C, INFOBY.0
				MOV ACC.0, C
				MOV C, INFOBY.1
				MOV ACC.1, C
				MOV C, INFOBY.2
				MOV ACC.2, C
				MOV C, INFOBY.3
				MOV ACC.3, C
				MOV SBUF, A
				JNB TI, $
				CLR TI
				ACALL w10ms
fwcic:
				SETB RS1 					; cambio banco de registros 2
				CLR RS0
				MOV R0, #LASTMSG
				MOV R2, LASTCNT
fwcic0:
				MOV SBUF, @R0
				JNB TI, $
				CLR TI
				INC R0
				DJNZ R2, fwcic0
				CLR RS1						; cambio banco de registros 0
				CLR RS0
retfw:
				RET

SEND:
				CLR EX0
				SETB SENDING
				ACALL w10ms
				ACALL w10ms
				ACALL w10ms
				ACALL w10ms
				ACALL w10ms
				MOV C, SENDB
				JC retsnd
				JNB TOKEN, $
				MOV R3, 02H
				MOV R0, #MYMSG
				CJNE R3, #00H, sdata0
				JMP retsnd
sdata0:
				;Genera el byte de protocolo y lo manda
				CLR A
				MOV A, #YO
				RL A
				RL A
				RL A
				RL A
				RL A
				RL A
				ORL A, #30H
				ORL A, R2
				MOV SBUF, A
				JNB TI, $
				CLR TI
				ACALL w10ms
sdata:
				;Envia todos los chars que se hayan escrito
				MOV SBUF, @R0
				JNB TI, $
				CLR TI
				ACALL w10ms
				INC R0
				DEC R3
				CJNE R3, #00H, sdata
retsnd:
				ACALL clar
				CLR SENDING
				SETB EX0
				RETI

clar:
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
				MOV LCDDATA, #0C0H
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
				;Manda datos al LCD
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
				;Verifica que no se hayan escrito los 14 chars disponibles
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
				MOV C, HISTB
				MOV EDSIG.1, C
				MOV C, BKSPCB
				MOV EDSIG.2, C
				MOV A, EDANT
				XRL A, EDSIG
				MOV C, ACC.0
				JNC hischk
				CPL ALTF
hischk:
				MOV C, ACC.1
				JNC bkcheck
				CPL HISTF
				ACALL HISTORY
bkcheck:
				MOV C, ACC.2
				JNC ret0
				ACALL BACKSPACE
ret0:
				MOV EDANT, EDSIG
				MOV TH0, #00H
				MOV TL0, #00H
				POP ACUM
				MOV A, ACUM
				RETI

HISTORY:
				SETB RS0					; Cambiar a banco de registros 3
				SETB RS1
				JNB HISTF, restlcd
				JMP conthist
restlcd:
				MOV R0, #10H
				CLR RSLCD
shiftright:
				MOV LCDDATA, #1CH
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				DJNZ R0, shiftright
				JMP retlcd

conthist:
				CLR RSLCD
				MOV LCDDATA, #90H
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms

				MOV R0, #10H
				SETB RSLCD
clrhist0:
				MOV LCDDATA, #20H
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				DJNZ R0, clrhist0

				CLR RSLCD
				MOV LCDDATA, #0D0H
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				MOV R0, #10H
				SETB RSLCD
clrhist1:
				MOV LCDDATA, #20H
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				DJNZ R0, clrhist1

				CLR RSLCD
				MOV LCDDATA, #90H
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms

				MOV R0, #SECMSG
				MOV R2, SECCNT
				SETB RSLCD
cpy2msg:
				MOV LCDDATA, @R0
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				INC R0
				DJNZ R2, cpy2msg

				CLR RSLCD
				MOV LCDDATA, #0D0H
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms

				MOV R0, #THIRMSG
				MOV R2, THIRCNT
				SETB RSLCD
cpy3msg:
				MOV LCDDATA, @R0
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				INC R0
				DJNZ R2, cpy3msg

				MOV R0, #10H
				CLR RSLCD
shiftleft:
				MOV LCDDATA, #18H
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				DJNZ R0, shiftleft
				JMP retlcd
retlcd:
				CLR RS0
				CLR RS1
				RET

BACKSPACE:
				CJNE R2, #00H, bcksp
				JMP retbcksp
bcksp:
				CLR RSLCD
				MOV LCDDATA, #10H
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				SETB RSLCD
				MOV LCDDATA, #20H
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				CLR RSLCD
				MOV LCDDATA, #10H
				SETB ELCD
				NOP
				CLR ELCD
				ACALL w10ms
				DEC R2
retbcksp:
				RET

T1ISR:
				;Verifica si tenemos el token, y si no estamos enviando, para
				;saber si mandar el token al siguiente micro
				CLR TF1
				MOV TL1, #LOW(-5000)
				MOV TH1, #HIGH(-5000)
				JNB TOKEN, retT1
				JB SENDING, retT1
				SETB TB8
				CLR TOKEN
				MOV SBUF, #0FFH
				JNB TI, $
				CLR TI
retT1:
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
