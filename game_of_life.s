MAGIC_NUMBER = 11			!hashing range, 11 is optimal for 16-bit
SIDE_LENGTH = 50
MATRIX_LENGTH = 2500			!field size is customizable, MATRIX_LENGTH = SIDE_LENGTH^2
HASH_ARRAY_BYTES = 20
HASH_ARRAY_ITEMS = 10

_EXIT = 1
_PRINTF = 127
_PUT_CHAR = 122

.SECT	.TEXT
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!! MAIN CODE !!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!!!!!!!!!!!!! PREPARATION !!!!!!!!!!!!!!!!!!

	PUSH	about
	PUSH	_PRINTF
	SYS
	ADD	SP,4

	MOV	BX,main_f
	MOV	CX,MATRIX_LENGTH
		
clear:	MOVB	(BX),0			!clearing of array in BSS - for safety, not important and can be removed for better perfomance 
	INC	BX	
	LOOP	clear	

	MOV	BX,hash_f
	MOV	CX,HASH_ARRAY_BYTES
	SHR	CX,1
		
clear_h:MOV	(BX),0			!clearing of hash array in BSS
	ADD	BX,2	
	LOOP	clear_h

!!!!!!!! ALIVE CELLS INITIALIZATION !!!!!!!!

	MOV	CX,end_arr-alive
	SHR	CX,1
	SHR	CX,1			!every cycle step - one pair of coordinates		
	MOV	BX,main_f		!array pointer  
	MOV	SI,alive
	MOV	DI,0			!shift in bytes
	
a_1:	MOV 	AX,(SI)			!transformation: (y,x)->[index]
	MOV	DX,SIDE_LENGTH		!in C-style: index = alive[i] * SIDE + alive[i+1]
	MUL	DX
	ADD	SI,2
	ADD	AX,(SI)
	MOV	DI,AX
	ADD	SI,2

	MOVB	(BX)(DI),1		!writing of value	
	LOOP	a_1

	PUSH	main_f
	PUSH	curr_f
	CALL	COPY_FIELDS		!initialization of current field
	ADD	SP,4

	PUSH	mess_1
	PUSH	_PRINTF			
	SYS
	ADD	SP,4

	PUSH	main_f
	CALL	DRAW_FIELD		!printing of initial generation
	ADD	SP,2
	
	PUSH	mess_3
	PUSH	_PRINTF
	SYS
	ADD	SP,4			

!!!!!!!!!!!!!!!!! GAME !!!!!!!!!!!!!!!!!!!!!
	
	MOV	CX,(N)			!counter for game_loop (outer)

	CMP	CX,3
	JL	N_fail			!incorrect input check
	CMP	CX,16384
	JGE	N_fail
	
	MOV	BX,main_f		!array pointer to analyse
	MOV	SI,0			!current array index
	MOV	DI,curr_f		!array pointer to change
	PUSH	BP
	PUSH	0			!variable for storing current state of cell (-4(BP))
	PUSH	1			!variable for storing current step
	PUSH	0			!variable for storing hash array shift
	
game_l:	MOV	DX,MATRIX_LENGTH	!counter for matrix_loop (inner)

!!!!!!!!!!!!!! INNER CYCLE BEGIN !!!!!!!!!!!			
matr_l:	MOVB	AL,(BX)(SI)
	MOVB	-4(BP),AL		!current cell state is saved	
	
	PUSH	CX			!saving CX,DX before function call
	PUSH	DX

	PUSH	SI	
	PUSH	BX
	CALL	CHECK_SURROUND		!neighbor count in AX
	ADD	SP,4

	POP	DX
	POP	CX

	CMP	-4(BP),0
	JE	born			

	CMP	AX,2			!if cell is alive now and it can die
	JNE	cond_1
	JMP	next_c			!cell stay alive
	
cond_1:	CMP	AX,3
	JNE	cond_2
	JMP	next_c			!cell stay alive

cond_2:	PUSH	BX			!change of addresses
	MOV	BX,DI	
	MOVB	(BX)(SI),0		!cell died
	POP	BX		
	JMP	next_c	
	
born:	CMP	AX,3			!if cell can born
	JE	born_s			!if borth successful
	JMP	next_c

born_s:	PUSH	BX
	MOV	BX,DI	
	MOVB	(BX)(SI),1		!cell born
	POP	BX

next_c:	INC	SI
	DEC	DX
	CMP	DX,0
	JNE	matr_l
!!!!!!!!!!!!!! INNER CYCLE END !!!!!!!!!!!!!!	
	
	PUSH	CX	
	PUSH	DI			!copy from current to main
	PUSH	BX
	CALL	COPY_FIELDS
	ADD	SP,4
	POP	CX

	PUSH	-6(BP)
	PUSH	mess_2
	PUSH	_PRINTF
	SYS
	ADD	SP,6

	INC	-6(BP)

	PUSH	CX
	PUSH	BX
	CALL	GET_HASH
	ADD	SP,2
	POP	CX

	CMP	AX,0			!if hash-code is 0: happens when input is incorrect, or all cells died
	JE	empty
	
	PUSH	CX
	PUSH	AX
	PUSH	hash_f
	CALL	IF_EXIST		!checking exisiting of current hash in hash array
	ADD	SP,2
	
	CMP	AX,1			!if exist
	JE	exist			
	
	POP	AX
	POP	CX
	PUSH	SI			!making isolated section of code
	PUSH	BX	

	MOV	BX,hash_f
	MOV	SI,-8(BP)
	MOV	(BX)(SI),AX		!adding new hash to hash array
	ADD	-8(BP),2
	CMP	-8(BP),HASH_ARRAY_ITEMS
	JG	greater
	JMP	end_8

greater:MOV 	-8(BP),0
	
end_8:	POP	BX
	POP	SI

	PUSH	AX
	PUSH	mess_4
	PUSH	_PRINTF
	SYS
	ADD	SP,6
	
	PUSH	CX
	PUSH	main_f
	CALL	DRAW_FIELD
	ADD	SP,2
	POP	CX

	PUSH	mess_3
	PUSH	_PRINTF
	SYS
	ADD	SP,4
	MOV	SI,0

	DEC	CX
	CMP	CX,0
	JG	game_l			!using JG instead of LOOP to prevent "too big warning"

	POP	AX
	POP	AX
	POP	BP
	JMP	exit

exist:	PUSH	mess_7
	PUSH	_PRINTF
	SYS
	ADD	SP,4
	JMP	exit	

empty:	PUSH	mess_6
	PUSH	_PRINTF
	SYS
	ADD	SP,4
	JMP	exit

N_fail:	PUSH	mess_5
	PUSH	_PRINTF
	SYS
	ADD	SP,4
		
exit:	PUSH	0
	PUSH	_EXIT
	SYS

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!! FUNCTIONS !!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!using _cdecl
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! getHash - returns hash-code (16-bit) for storing alive cells combination. Arguments: array pointer
GET_HASH:
	PUSH	BP
	MOV	BP,SP
	PUSH	BX
	PUSH	SI
	PUSH	DI

	MOV	BX,4(BP)		!array pointer in BX
	MOV	CX,MATRIX_LENGTH
	DEC	CX			

	MOV	DI,(BX)			!hash-code in DI, initial value = first state
	MOV	SI,1			!array index in bytes

a_2:    MOV	AX,(BX)(SI)		!direct read from array
	CMP	AX,1
	JE	st_1
	JMP	end_4

st_1:	MOV	AX,SI			!hash = hash ^ (index*MAGIC_NUMBER ^ hash)
	MOV	DX,MAGIC_NUMBER		
	MUL	DX

	MOV	DX,DI	
	XOR	AX,DX
	
end_7:	MOV	DX,DI
	XOR	DX,AX
	MOV	DI,AX			!updating of hash	 	

end_4:	INC	SI	
	LOOP	a_2		
	
	MOV	AX,DI
	POP	DI
	POP	SI
	POP	BX
	MOV	SP,BP
	POP	BP
	RET

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! checkSurround - returns count of alive neighbor cells. Arguments: array pointer, index of cell to check
CHECK_SURROUND:
	PUSH	BP
	MOV	BP,SP
	PUSH	BX
	PUSH	SI
	PUSH	DI
	
	MOV	DX,6(BP)		!index of cell
	MOV	BX,4(BP)		!array pointer
	MOV	DI,0			!DI for counting alive neighbor cells
	
	MOV	SI,DX
	CMP	SI,0			!if index == 0 (left-top corner)
	JE	i_1
	JMP	i_2
	
i_1:	INC	SI
	MOVB	AL,(BX)(SI)		!to the right			
	ADD	DI,AX

	DEC	SI
	ADD	SI,SIDE_LENGTH
	MOVB	AL,(BX)(SI)		!under
	ADD	DI,AX	
	
	INC	SI
	MOVB	AL,(BX)(SI)		!under-right
	ADD	DI,AX
	JMP	final

i_2:	MOV	SI,DX			!if index == SIDE_LENGTH-1 (right-top corner)
	MOV	CX,SIDE_LENGTH		
	DEC	CX	
	CMP	SI,CX
	JE	i_3
	JMP	i_4

i_3:	DEC	SI
	MOVB	AL,(BX)(SI)		!to the left	
	ADD	DI,AX

	INC	SI
	ADD	SI,SIDE_LENGTH
	MOVB	AL,(BX)(SI)		!under
	ADD	DI,AX	
	
	DEC	SI
	MOVB	AL,(BX)(SI)		!under-left
	ADD	DI,AX
	JMP	final

i_4:	MOV	SI,DX			!if index == MATRIX_LENGTH-SIDE_LENGTH (left-bottom corner)
	MOV	CX,MATRIX_LENGTH		
	SUB	CX,SIDE_LENGTH	
	CMP	SI,CX
	JE	i_5
	JMP	i_6

i_5:	INC	SI
	MOVB	AL,(BX)(SI)		!to the right
	ADD	DI,AX

	DEC	SI
	SUB	SI,SIDE_LENGTH
	MOVB	AL,(BX)(SI)		!to the top
	ADD	DI,AX	
	
	INC	SI
	MOVB	AL,(BX)(SI)		!top-right
	ADD	DI,AX
	JMP	final	

i_6:	MOV	SI,DX			!if index == MATRIX_LENGTH-1 (right-bottom corner)
	MOV	CX,MATRIX_LENGTH
	DEC	CX		
	CMP	SI,CX
	JE	i_7
	JMP	i_8

i_7:	DEC	SI
	MOVB	AL,(BX)(SI)		!to the left
	ADD	DI,AX

	INC	SI
	SUB	SI,SIDE_LENGTH
	MOVB	AL,(BX)(SI)		!to the top
	ADD	DI,AX	
	
	DEC	SI
	MOVB	AL,(BX)(SI)		!top-left
	ADD	DI,AX
	JMP	final	

i_8:	MOV	SI,DX			!if index / SIDE_LENGTH == 0 (top border)
	MOV	CX,SIDE_LENGTH
	MOV	AX,SI			!index in AX, SIDE in CX
	PUSH	DX			!backuping DX
	CWD
	DIV	CX
	POP	DX
	CMP	AX,0
	JE	i_9
	JMP	i_10

i_9:	DEC	SI
	MOVB	AL,(BX)(SI)		!to the left
	ADD	DI,AX

	ADD	SI,2
	MOVB	AL,(BX)(SI)		!to the right
	ADD	DI,AX	
	
	DEC	SI
	ADD	SI,SIDE_LENGTH
	MOVB	AL,(BX)(SI)		!under
	ADD	DI,AX

	DEC	SI
	MOVB	AL,(BX)(SI)		!under-left
	ADD	DI,AX
	
	ADD	SI,2
	MOVB	AL,(BX)(SI)		!under-right
	ADD	DI,AX
	JMP	final

i_10:	MOV	SI,DX			!if index % SIDE_LENGTH == 0 (left border)
	MOV	CX,SIDE_LENGTH
	MOV	AX,SI			!index in AX, SIDE in CX
	PUSH	DX			!backuping DX
	CWD
	DIV	CX
	CMP	DX,0
	JE	i_11
	JMP	i_12

i_11:	POP	DX
	INC	SI
	MOVB	AL,(BX)(SI)		!to the right
	ADD	DI,AX

	DEC	SI
	SUB	SI,SIDE_LENGTH
	MOVB	AL,(BX)(SI)		!to the top
	ADD	DI,AX	
	
	INC	SI
	MOVB	AL,(BX)(SI)		!top-right
	ADD	DI,AX

	DEC	SI
	ADD	SI,SIDE_LENGTH
	ADD	SI,SIDE_LENGTH
	MOVB	AL,(BX)(SI)		!under
	ADD	DI,AX
	
	INC	SI
	MOVB	AL,(BX)(SI)		!under-right
	ADD	DI,AX
	JMP	final

i_12:	POP	DX
	MOV	SI,DX			!if index % SIDE_LENGTH == SIDE_LENGTH-1 (right border)
	MOV	CX,SIDE_LENGTH
	MOV	AX,SI			!index in AX, SIDE in CX
	PUSH	DX			!backuping DX
	CWD
	DIV	CX
	MOV	CX,SIDE_LENGTH
	DEC	CX
	CMP	DX,CX
	JE	i_13
	JMP	i_14

i_13:	POP	DX
	DEC	SI
	MOVB	AL,(BX)(SI)		!to the left
	ADD	DI,AX

	INC	SI
	SUB	SI,SIDE_LENGTH
	MOVB	AL,(BX)(SI)		!to the top
	ADD	DI,AX	
	
	DEC	SI
	MOVB	AL,(BX)(SI)		!top-left
	ADD	DI,AX

	INC	SI
	ADD	SI,SIDE_LENGTH
	ADD	SI,SIDE_LENGTH
	MOVB	AL,(BX)(SI)		!under
	ADD	DI,AX
	
	DEC	SI
	MOVB	AL,(BX)(SI)		!under-left
	ADD	DI,AX
	JMP	final

i_14:	POP	DX			!if index / SIDE_LENGTH == SIDE_LENGTH-1 (bottom border)
	MOV	SI,DX			
	MOV	CX,SIDE_LENGTH
	MOV	AX,SI			!index in AX, SIDE in CX
	PUSH	DX			!backuping DX
	CWD
	DIV	CX
	POP	DX
	MOV	CX,SIDE_LENGTH
	DEC	CX
	CMP	AX,CX
	JE	i_15
	JMP	i_16

i_15:	DEC	SI
	MOVB	AL,(BX)(SI)		!to the left
	ADD	DI,AX

	ADD	SI,2
	MOVB	AL,(BX)(SI)		!to the right
	ADD	DI,AX	
	
	DEC	SI
	SUB	SI,SIDE_LENGTH
	MOVB	AL,(BX)(SI)		!to the top
	ADD	DI,AX

	DEC	SI
	MOVB	AL,(BX)(SI)		!top-left
	ADD	DI,AX
	
	ADD	SI,2
	MOVB	AL,(BX)(SI)		!top-right
	ADD	DI,AX
	JMP	final

i_16:	MOV	SI,DX			!in the middle
	
	DEC	SI
	MOVB	AL,(BX)(SI)		!to the left
	ADD	DI,AX	

	ADD	SI,2
	MOVB	AL,(BX)(SI)		!to the right
	ADD	DI,AX

	DEC	SI
	SUB	SI,SIDE_LENGTH
	MOVB	AL,(BX)(SI)		!to the top
	ADD	DI,AX

	INC	SI
	MOVB	AL,(BX)(SI)		!top-right
	ADD	DI,AX

	SUB	SI,2
	MOVB	AL,(BX)(SI)		!top-left
	ADD	DI,AX

	INC	SI
	ADD	SI,SIDE_LENGTH
	ADD	SI,SIDE_LENGTH
	MOVB	AL,(BX)(SI)		!under
	ADD	DI,AX

	DEC	SI
	MOVB	AL,(BX)(SI)		!under-left
	ADD	DI,AX

	ADD	SI,2
	MOVB	AL,(BX)(SI)		!under-right
	ADD	DI,AX

final:	MOV	AX,DI
	POP	DI
	POP	SI
	POP	BX
	MOV	SP,BP
	POP	BP
	RET

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! drawField - draws field to standard output, making the matrix tabulation. Arguments: array pointer
DRAW_FIELD:
	PUSH	BP
	MOV	BP,SP
	PUSH	BX
	PUSH	SI
	PUSH	DI
	
	MOV	SI,0			!current index in array
	MOV	BX,4(BP)		!array pointer in BX
	MOV	CX,MATRIX_LENGTH

cycle:	MOVB	AL,(BX)
	CMP	AX,1
	JE	p_a	
	
	PUSH	symb_2			!printing symbol of dead cell
	PUSH	_PRINTF
	SYS
	ADD	SP,4
	JMP	end_1
	
p_a:	PUSH	symb_1			!printing symbol of alive cell
	PUSH	_PRINTF
	SYS
	ADD	SP,4  

end_1:	MOV	AX,SI			!checking of line's end 
	INC	AX
	CWD
	PUSH	CX

	MOV	CX,SIDE_LENGTH		!AX % SIZE == 0 
	DIV	CX

	POP	CX
	CMP	DX,0
	JE	last
	JMP	end_2

last:   PUSH	'\n'			!if the end of line
	PUSH	_PUT_CHAR
	SYS
	ADD	SP,4
	
end_2:	INC	BX
	INC	SI	
	LOOP	cycle	

	POP	DI
	POP	SI
	POP	BX
	MOV	SP,BP
	POP	BP
	RET

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! copyFields - copies elements of one array to another (with same size). Arguments: array_pointer_to, array_pointer_from
COPY_FIELDS:
	PUSH	BP
	MOV	BP,SP
	PUSH	BX
	PUSH	SI
	PUSH	DI

	MOV	DI,4(BP)			!destination - to
	MOV	SI,6(BP)			!source - from
	MOV	CX,MATRIX_LENGTH

a_3:	MOVB	AL,(SI)
	MOVB	(DI),AL
	INC	SI
	INC	DI		
	LOOP	a_3

	POP	DI
	POP	SI
	POP	BX
	MOV	SP,BP
	POP	BP
	RET

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! ifExist - checks existing of argument in sent array. Returns 1, if arg is exist, else 0. Arguments: array pointer, value to check
IF_EXIST:
	PUSH	BP
	MOV	BP,SP
	PUSH	BX
	PUSH	SI
	PUSH	DI
	
	MOV	BX,4(BP)		!array pointer
	MOV	DX,6(BP)		!value to check
	MOV	CX,HASH_ARRAY_ITEMS		

a_4:	MOV	AX,(BX)				
	CMP	DX,AX			!compare current value with argument value	
	JE	end_5
	JMP     end_6

end_5:	MOV	AX,1			!if value found
	JMP	final_1

end_6:	ADD	BX,2			!next step
	LOOP	a_4
	
	MOV	AX,0			!if value not found
	
final_1:POP	DI
	POP	SI
	POP	BX
	MOV	SP,BP
	POP	BP
	RET

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
.SECT	.DATA
N:	.WORD	1000
alive:	.WORD	2,0,2,1,2,2,0,1,1,2
end_arr:.WORD	0	

symb_1:	.ASCIZ	"#"
symb_2:	.ASCIZ	"-"

about:	.ASCIZ	"\n %%%% Game of Life. Anton Fedyashov, MMCS 2.3 %%%% \n\n"
mess_1:	.ASCIZ	"Initial generation: \n"
mess_2:	.ASCIZ	"Generation %d: \n"
mess_3:	.ASCIZ	"\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n"
mess_4: .ASCIZ	"Hash: %d\n"
mess_5:	.ASCIZ	"Incorrect N used!\n"
mess_6:	.ASCIZ	"Everything died!\n"
mess_7:	.ASCIZ	"Periodical construction detected. Calculation halted!\n"

.SECT	.BSS
main_f:	.SPACE	MATRIX_LENGTH		!main game field, for analysing cells - 1 byte for 1 element
curr_f: .SPACE	MATRIX_LENGTH		!current game field - for current iteration (generation) of game - will be copied from main field
hash_f:	.SPACE	HASH_ARRAY_BYTES	!hash-code history array, current size - 10 codes
