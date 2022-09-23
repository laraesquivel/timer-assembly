.equ pagelen, 4096
.equ setregoffset, 28
.equ clrregoffset, 40
.equ prot_read, 1
.equ prot_write, 2
.equ map_shared, 1
.equ sys_open, 5
.equ sys_map, 192
.equ nano_sleep, 162
.equ level, 52

.global _start


.macro nanoSleep
        LDR R0,=timespecsec
        LDR R1,=timespecnano
        MOV R7, #nano_sleep
        SVC 0
.endm

.macro nanoSleep2 time
        LDR R0,=\time
        LDR R1,=\time
        MOV R7, #nano_sleep
        SVC 0
.endm


.macro GPIODirectionOut pin
        LDR R2, =\pin
        LDR R2, [R2]
        LDR R1, [R8, R2]
        LDR R3, =\pin @ address of pin table
        ADD R3, #4 @ load amount to shift from table
        LDR R3, [R3] @ load value of shift amt
        MOV R0, #0b111 @ mask to clear 3 bits
        LSL R0, R3 @ shift into position
        BIC R1, R0 @ clear the three bits
        MOV R0, #1 @ 1 bit to shift into pos
        LSL R0, R3 @ shift by amount from table
        ORR R1, R0 @ set the bit
        STR R1, [R8, R2] @ save it to reg to do work
.endm


.macro GPIOTurnOn pin
        MOV R2, R8 @ address of gpio regs
        ADD R2, #setregoffset @ off to set reg
        MOV R0, #1 @ 1 bit to shift into pos
        LDR R3, =\pin @ base of pin info table
        ADD R3, #8 @ add offset for shift amt
        LDR R3, [R3] @ load shift from table
        LSL R0, R3 @ do the shift
        STR R0, [R2] @ write to the register
.endm


.macro GPIOTurnOff pin
        MOV R2, R8 @ address of gpio regs
        ADD R2, #clrregoffset @ off set of clr reg
        MOV R0, #1 @ 1 bit to shift into pos
        LDR R3, =\pin @ base of pin info table
        ADD R3, #8
        LDR R3, [R3]
        LSL R0, R3
        STR R0, [R2]
.endm

.macro GPIOTurn pin, value
	MOV R1, \value
        MOV R2, R8 @ address of gpio regs
        cmp R1, #0
        ADDEQ R2, #clrregoffset @ off set of clr reg
        cmp R1, #1
        ADDEQ R2, #setregoffset @ off to set reg
        MOV R0, #1 @ 1 bit to shift into pos
        LDR R3, =\pin @ base of pin info table
        ADD R3, #8
        LDR R3, [R3]
        LSL R0, R3
        STR R0, [R2]
.endm


.macro pinDisplay
        GPIODirectionOut pinE
        GPIODirectionOut pinRS
        GPIODirectionOut pinDB7
        GPIODirectionOut pinDB6
        GPIODirectionOut pinDB5
        GPIODirectionOut pinDB4
.endm

.macro enable
        GPIOTurn pinE, #0
        nanoSleep2 time15ms
        GPIOTurn pinE, #1
        nanoSleep2 time15ms
        GPIOTurn pinE, #0
.endm


.macro functionSet
        GPIOTurnOff pinRS
        GPIOTurnOff pinDB7
        GPIOTurnOff pinDB6
        GPIOTurnOn pinDB5
        GPIOTurnOff pinDB4
        enable
.endm


.macro display
        GPIOTurnOff pinRS
        GPIOTurnOff pinDB7
        GPIOTurnOff pinDB6
        GPIOTurnOff pinDB5
        GPIOTurnOff pinDB4
        enable

        GPIOTurnOff pinRS
        GPIOTurnOn pinDB7
        GPIOTurnOn pinDB6
        GPIOTurnOn pinDB5
        GPIOTurnOn pinDB4
        enable
.endm


.macro displayOff
        GPIOTurnOff pinRS
        GPIOTurnOff pinDB7
        GPIOTurnOff pinDB6
        GPIOTurnOff pinDB5
        GPIOTurnOff pinDB4
        enable

        GPIOTurnOff pinRS
        GPIOTurnOn pinDB7
        GPIOTurnOff pinDB6
        GPIOTurnOff pinDB5
        GPIOTurnOff pinDB4
        enable	
.endm


.macro displayClear
        GPIOTurnOff pinRS
        GPIOTurnOff pinDB7
        GPIOTurnOff pinDB6
        GPIOTurnOff pinDB5
        GPIOTurnOff pinDB4
        enable

        GPIOTurnOff pinRS
        GPIOTurnOff pinDB7
        GPIOTurnOff pinDB6
        GPIOTurnOff pinDB5
        GPIOTurnOn pinDB4
        enable
.endm


.macro entrySetMode
        GPIOTurnOff pinRS
        GPIOTurnOff pinDB7
        GPIOTurnOff pinDB6
        GPIOTurnOff pinDB5
        GPIOTurnOff pinDB4
        enable

        GPIOTurnOff pinRS
        GPIOTurnOff pinDB7
        GPIOTurnOn pinDB6
        GPIOTurnOn pinDB5
        GPIOTurnOff pinDB4
        enable

.endm

.macro prefixNumberDisplay
	GPIOTurnOn pinRS
        GPIOTurnOff pinDB7
        GPIOTurnOff pinDB6
        GPIOTurnOn pinDB5
        GPIOTurnOn pinDB4
        enable
.endm


.macro writeNumber value

	@displayClear
        prefixNumberDisplay
	
	GPIOTurn pinRS, #1

        MOV R2,#1
	LSL R2,#3
	AND R1,\value,R2
	LSR R1,#3
        GPIOTurn pinDB7, R1

        MOV R2,#1
	LSL R2,#2
	AND R1,\value,R2
	LSR R1,#2
        GPIOTurn pinDB6, R1

        MOV R2,#1
	LSL R2,#1
	AND R1,\value,R2
	LSR R1,#1
        GPIOTurn pinDB5, R1


        MOV R2,#1
	AND R1,\value,R2
        GPIOTurn pinDB4, R1
        enable
        .ltorg
	
.endm


_start:
	@ opening the file
	LDR R0, = fileName
	MOV R1, #0x1b0
	ORR R1, #0x006
	MOV R2, R1
	MOV R7, #sys_open
	SVC 0
	MOVS R4, R0

	@ preparing the mapping
	LDR R5, =gpioaddr
	LDR R5, [R5]
	MOV R1, #pagelen
	MOV R2, #(prot_read + prot_write)
	MOV R3, #map_shared
	MOV R0, #0
	MOV R7, #sys_map
	SVC 0
	MOVS R8, R0

	pinDisplay
	displayClear
	functionSet
	functionSet
	functionSet
	display
	entrySetMode
       
	.ltorg	
	
restart:
        mov R6, #9
        mov R5, #9
        displayClear
	writeNumber R5
	writeNumber R6
delay:
	nanoSleep2 time100ms
	nanoSleep2 time100ms
loop:
	
        GPIODirectionOut pin6
        GPIOTurn pin6, #1
        LDR R9, [R8, #level]
        MOV R11, #1
	LSL R11, #5
	MOV R12, #1
	LSL R12, #19
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
        cmp R10, #0
	bne loop
	
delay2:
	nanoSleep2 time500ms
temporizador:
	displayClear
	writeNumber R5
	writeNumber R6
	GPIODirectionOut pin6
        GPIOTurn pin6, #0
        MOV R11, #1
        LSL R11, #5
	MOV R12, #1
	LSL R12, #19
@----------------------------------------------------------------
@este bloco de codigo ira fazer a leitura do botão 10 vezes a cada 100 ms. 
@Totalizando o timer de 1 s e captando mais precisamente as acoes do botao start/stop e restart.
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	bleq delay
	
	nanoSleep2 time100ms @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	bleq delay
	
	nanoSleep2 time100ms @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	bleq delay
	
	nanoSleep2 time100ms @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	bleq delay
	
	nanoSleep2 time100ms @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	bleq delay
	
	nanoSleep2 time100ms @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	bleq delay
	
	nanoSleep2 time100ms @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	bleq delay
	
	nanoSleep2 time100ms @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	bleq delay
	
	nanoSleep2 time100ms @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	bleq delay
	
	nanoSleep2 time100ms @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	bleq delay
	
	nanoSleep2 time100ms @wait 100 ms
@------------------------------------------------------------------
	
	CMP R6, #0
	SUBNE R6, #1
	BGT temporizador
	
	CMP R5, #0
	SUBNE R5, #1
	MOVNE R6, #9
	BNE temporizador
	
	@cmp R5, #0
	@bne temporizador
	@CMP R6, #0
	@BGE temporizador
        GPIOTurn pin6, #0
        B restart
        

_end:
        MOV R7,#1
        SVC 0


.data


timespecsec: .word 0
timespecnano: .word 015000000
timespecsecT: .word 1
timespecnanoT: .word 000000000

time1s:
	.word 1
	.word 000000000
	
time1ms:
	.word 001000000
	
time15ms:
	.word 0
	.word 1500000
time100s:
	.word 0
	.word 100000000

time500ms:
	.word 0
	.word 500000000
time150ms:
	.word 0
	.word 150000000
time100ms: .word 1000000000
time300ms: .word 3000000000

on: .word 1
off: .word 0 

fileName: .asciz "/dev/mem"
gpioaddr: .word 0x20200

pin6: .word 0
        .word 18
        .word 6
        
@ LCD

pinRS:	@ LCD Display RS pin - GPIO25
	.word 8 @ offset to select register
	.word 15 @ bit offset in select register
	.word 25 @ bit offset in set & clear register

pinE:	@ LCD Display E pin - GPIO1
	.word 0 @ offset to select register
	.word 3 @ bit offset in select register
	.word 1 @ bit offset in set & clr register

pinDB4:	@ LCD Display DB4 pin - GPIO12
	.word 4 @ offset to select register
	.word 6 @ bit offset in select register
	.word 12 @ bit offset in set & clr register

pinDB5:	@ LCD Display DB5 pin - GPIO16
	.word 4 @ offset to select register
	.word 18 @ bit offset in select register
	.word 16 @ bit offset in set & clr register

pinDB6:	@ LCD Display DB6 pin - GPIO20
	.word 8 @ offset to select register
	.word 0 @ bit offset in select register
	.word 20 @ bit offset in set & clr register

pinDB7:	@ LCD Display DB7 pin - GPIO21
	.word 8 @ offset to select register
	.word 3 @ bit offset in select register
	.word 21 @ bit offset in set & clr register

