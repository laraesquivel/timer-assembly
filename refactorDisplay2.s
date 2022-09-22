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

.macro nanoSleep time
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
        BL GPIOTurn pinE, #0
	nanoSleep time1ms
	
        BL GPIOTurn pinE, #1
	nanoSleep time1ms
	
        BL GPIOTurn pinE, #0
	.ltorg
.endm

.macro functionSet
        GPIOTurn pinRS, #0
        GPIOTurn pinDB7, #0
        GPIOTurn pinDB6, #0
        GPIOTurn pinDB5, #1
        GPIOTurn pinDB4, #0
        enable
        .ltorg
.endm

.macro display
        GPIOTurn pinRS, #0
        GPIOTurn pinDB7, #0
        GPIOTurn pinDB6, #0
        GPIOTurn pinDB5, #0
        GPIOTurn pinDB4, #0
        enable

        GPIOTurn pinRS, #0
        GPIOTurn pinDB7, #1
        GPIOTurn pinDB6, #1
        GPIOTurn pinDB5, #1
        GPIOTurn pinDB4, #0
        enable
        .ltorg
.endm

.macro entrySetMode
        GPIOTurn pinRS, #0
        GPIOTurn pinDB7, #0
        GPIOTurn pinDB6, #0
        GPIOTurn pinDB5, #0
        GPIOTurn pinDB4, #0
        enable

        GPIOTurn pinRS, #0
        GPIOTurn pinDB7, #0
        GPIOTurn pinDB6, #1
        GPIOTurn pinDB5, #1
        GPIOTurn pinDB4, #0
        enable
	.ltorg
.endm

.macro displayOff
        GPIOTurn pinRS, #0
        GPIOTurn pinDB7, #0
        GPIOTurn pinDB6, #0
        GPIOTurn pinDB5, #0
        GPIOTurn pinDB4, #0
        enable

        GPIOTurn pinRS, #0
        GPIOTurn pinDB7, #1
        GPIOTurn pinDB6, #0
        GPIOTurn pinDB5, #0
        GPIOTurn pinDB4, #0
        enable
        .ltorg
.endm

.macro displayClear
        GPIOTurn pinRS, #0
        GPIOTurn pinDB7, #0
        GPIOTurn pinDB6, #0
        GPIOTurn pinDB5, #0
        GPIOTurn pinDB4, #0
        enable

        GPIOTurn pinRS, #0
        GPIOTurn pinDB7, #0
        GPIOTurn pinDB6, #0
        GPIOTurn pinDB5, #0
        GPIOTurn pinDB4, #1
        enable
        .ltorg
.endm

.macro prefixNumberDisplay
	GPIOTurn pinRS, #1
        GPIOTurn pinDB7, #0
        GPIOTurn pinDB6, #0
        GPIOTurn pinDB5, #1
        GPIOTurn pinDB4, #1
        enable
.endm

.macro writeNumber

	displayClear
        prefixNumber
	
	GPIOTurn pinRS, #1

        MOV R2,#1
	LSL R2,#3
	AND R1,R6,R2
	LSR R1,R0
        GPIOTurn pinDB7, R1

        MOV R2,#1
	LSL R2,#2
	AND R1,R6,R2
	LSR R1,R0
        BL GPIOTurn pinDB6, R1

        MOV R2,#1
	LSL R2,#1
	AND R1,R6,R2
	LSR R1,R0
        BL GPIOTurn pinDB5, R1


        MOV R2,#1
	AND R1,R6,R2
	LSR R1,R0
        BL GPIOTurn pinDB4, R1
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
	functionSet
	functionSet
	functionSet
	display
	entrySetMode

        MOV R11, #1
	LSL R11, #5
	MOV R12, #1
	LSL R12, #19

restart:
        mov R6, #15
        BL delay
loop:
	
        GPIODirectionOut pin6
        GPIOTurn pin6, #0
        LDR R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
        cmp R10, #0
	bne loop
        BL delay

temporizador:
	GPIODirectionOut pin6
        GPIOTurn pin6, #1
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
	
	nanoSleep time100ms @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	bleq delay
	
	nanoSleep time100ms @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	bleq delay
	
	nanoSleep time100ms @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	bleq delay
	
	nanoSleep time100ms @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	bleq delay
	
	nanoSleep time100ms @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	bleq delay
	
	nanoSleep time100ms @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	bleq delay
	
	nanoSleep time100ms @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	bleq delay
	
	nanoSleep time100ms @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	bleq delay
	
	nanoSleep time100ms @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	bleq delay
	
	nanoSleep time100ms @wait 100 ms
@------------------------------------------------------------------
	
	sub R6, #1
	cmp R6, #0
	bge temporizador
	
        GPIOTurn pin6, #0
        B restart
        
delay:
	LDR R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq delay
	AND R10, R11, R9
	CMP R10, #0
        beq delay
	BX LR

_end:
        MOV R7,#1
        SVC 0
        
.data
time1s:
	.word 1
	.word 000000000

time500ms:
	.word 0
	.word 500000000
time150ms:
	.word 0
	.word 150000000
time100ms: .word 1000000000
time300ms: .word 3000000000
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
