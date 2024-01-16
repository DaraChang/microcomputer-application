	ORG 00H
	JMP MAIN
	ORG 0BH					;address of timer0 interrupt event
	JMP AGAIN
	ORG 13H					;INT1
	JMP GET					;retrieve timer0 value 
	ORG	1BH					;address timer1 interrupt event
	JMP BIP
	ORG 50H
MAIN:
	SETB IT1				;interrupt 1 falling edge trigger
	SETB EX1				;enable external interrupt 1
	SETB EA					;interrupt enable
	SETB ET0				;enable timer0 interrupt
	SETB ET1				;enable timer1 interrupt
	MOV TMOD,#00010010B		;T0:MODE2 timer gate=0/T1:MODE1 timer gate=0
	CLR TF0					;clear T0 overflow flag
	MOV TH0, #0				;TH0 = 0
	MOV TL0, #0				;TL0 = 0
	MOV R5, #0				;R5 records single digit of the displayed num
	MOV R4, #0				;R4 records tens digit of the displayed num
	MOV	R6,	#2				;there are 2 half cycle in a complete square wave
	MOV	R2,	#0				;R2 records the index to which the pointer is currently pointing in TABLE
	MOV	DPTR,#TABLE			;DPTR points to TABLE
	SETB TR0				;timer0 start
	SETB TR1      		    ;timer1 start
GENERATE:
	CALL SHOW
COL0:						;scan the keyboard
	MOV R0,#01H				;col=1
	MOV P1,#0F7H			;scan col0 with 11110111
	CALL DELAY2
	MOV A,P1				;status of col0 (pressed/not pressed) is stored in A
	ANL A,#0F0H				;clear the last four digits
	CJNE A,#0F0H,ROW0		;if A == 11110000, col0 is not pressed，otherwise jump to ROW0
COL1:
	MOV R0,#02H				;col=2
	MOV P1,#0FBH			;scan col1 with 11111011
	CALL DELAY2
	MOV A,P1				
	ANL A,#0F0H				
	CJNE A,#0F0H,ROW0		;if A == 11110000, col1 is not pressed，otherwise jump to ROW0
COL2:
	MOV R0,#03H				;col=3
	MOV P1,#0FDH			;scan col2 with 11111101
	CALL DELAY2
	MOV A,P1				
	ANL A,#0F0H				
	CJNE A,#0F0H,ROW0		;if A == 11110000, col2 is not pressed，otherwise jump to ROW0
COL3:
	MOV R0,#04H				;col=4
	MOV P1,#0FEH			;scan col3 with 11111110
	CALL DELAY2
	MOV A,P1				
	ANL A,#0F0H				
	CJNE A,#0F0H,ROW0		;if A == 11110000, col3 is not pressed，otherwise jump to ROW0
	JMP GENERATE
JUMPLONG:
	JMP GENERATE
ROW0:
	MOV R1,#00H				;row=0
	CJNE A,#70H,ROW1		;if A != 01110000, row0 is not pressed，jump to ROW1
	JMP PLUS
ROW1:
	MOV R1,#04H				;row=4
	CJNE A,#0B0H,ROW2		;if A != 10110000, row1 is not pressed，jump to ROW2
	JMP PLUS
ROW2:
	MOV R1,#08H				;row=8
	CJNE A,#0D0H,ROW3		;if A != 11010000, row2 is not pressed，jump to ROW3
	JMP PLUS
ROW3:
	MOV R1,#0CH				;row=12
	CJNE A,#0E0H,GENERATE	;if A != 11100000, row3 is not pressed，jump to GENERATE
	JMP PLUS
AGAIN:						;timer0 interrupt event
	CLR TF0                 ;clear T0 overflow flag
	RETI
GET:                        ;INT1 interrupt event
	CLR IE1					;clear INT1 overflow flag
	MOV A,TL0               ;random number from timer0 is stored in A
	MOV B,#16				;B is set to 16
	DIV AB                  ;A is divided by B(16)
	MOV R3, B               ;The remainder is stored in R3
	INC R3                  ;R3++ (1-16)
	MOV B, #10              ;B is set to 10
	MOV A, R3               ;The remainder is stored in A
	DIV AB                  ;A is divided by B(10)
	MOV R5, B               ;Set the single digit of the displayed num
	MOV R4, A               ;Set the tens digit of the displayed num
	RETI
PLUS:
	MOV A, R0
	ADD A, R1               ;A+B
	SUBB A, R3              
	CJNE A, #0,GENERATE     ;if A != R3, guess the num wrong, jump to GENERATE
	JMP SETINFO
SHOW:
	MOV A,R5				;display the single digit
	ADD	A,#01110000B
	MOV P2,A
	CALL DELAY2				
	MOV A,R4				;display the tens digit
	ADD	A,#10110000B
	MOV P2,A
	CALL DELAY2
	RET	
SETINFO:		            ;assign data read from TABLE to TH1,TL1 and set the duration of sound
	SETB TR1
	CLR 	P0.0	
	CALL 	DELAY2		
	MOV	A,R2
	MOVC 	A,@A+DPTR		
	MOV	R5,A			     ;the R2th data in TABLE is stored in R5
	INC		R2				 ;R2++
	MOV	A,R2
	MOVC 	A,@A+DPTR
	MOV	R3,A			     ;the R2th data in TABLE is stored in R3
	INC		R2
	MOV	A,R2
	MOVC 	A,@A+DPTR
	MOV	R0,A			     ;the R2th data in TABLE is stored in R0
	INC		R2	
	MOV	TH1,R5			     
	MOV	TL1,R3			     
	CALL 	SOUND
	CJNE 	R2,#114,SETINFO	 ;check if the entire song has been played through
	JMP		MAIN			 ;restart the game
SOUND:                       ;play the sound
	CJNE 	R0,#0,SOUND	     
	RET	
BIP:
	CLR 	TF1				
	MOV	TH1,R5			
	MOV	TL1,R3	
	CPL		P0.0			 ;generate square wave
	DJNZ	R6,RETURN		 ;if R6 == 0，a square wave ends
	MOV	R6,#2
	DEC	R0				     ;R0--
RETURN:
	RETI					
				

DELAY2:
	MOV R7,#0FFH
DELAY3:
	DJNZ R7,DELAY3
	RET
	
DELAY:
	MOV	R4,#0FFH
DELAY1:
	MOV	R7,#0AH
DELAY4:
	DJNZ	R7,DELAY4
	DJNZ	R4,DELAY1
	RET

TABLE:                        ;Carmen
	DB 246,9,49				  ;So
	DB 241,23,33		      ;Do
	DB 242,183,37			  ;Re
    DB 244,42,41			  ;Mi
	DB 246,9,49				  ;So
    DB 244,42,41			  ;Mi
	DB 242,183,37			  ;Re
	DB 241,23,33			  ;Do
	DB 242,183,37			  ;Re
    DB 244,42,41			  ;Mi	
    DB 244,215,44			  ;Fa
	DB 246,9,49				  ;So
	DB 246,9,49				  ;So
	DB 246,9,49				  ;So
	DB 246,9,49				  ;So
    DB 247,31,110			  ;La
	DB 246,9,49				  ;So
    DB 244,215,44			  ;Fa
    DB 247,31,110			  ;La
	DB 242,183,37			  ;Re
    DB 244,42,41			  ;Mi	
    DB 244,215,44			  ;Fa
    DB 247,31,110			  ;La
    DB 244,215,44			  ;Fa	
    DB 244,42,41			  ;Mi	
	DB 242,183,37			  ;Re
    DB 244,42,41			  ;Mi	
    DB 244,215,44			  ;Fa	
	DB 246,9,49				  ;So
	DB 248,24,123	
    DB 247,31,110			  ;La
    DB 244,42,41			  ;Mi	
	DB 246,9,49				  ;So
	DB 248,24,123
	DB 242,183,37			  ;Re
    DB 244,42,41			  ;Mi
	DB 242,183,37			  ;Re
	DB 241,23,33			  ;Do	



END

