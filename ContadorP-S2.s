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

.macro timer
        LDR R0,=timespecsecT
        LDR R1,=timespecnanoT
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

.macro GPIOTurnOff pin, value
        MOV R2, R8 @ address of gpio regs
        ADD R2, #setregoffset @ off to set reg
        MOV R0, #1 @ 1 bit to shift into pos
        LDR R3, =\pin @ base of pin info table
        ADD R3, #8 @ add offset for shift amt
        LDR R3, [R3] @ load shift from table
        LSL R0, R3 @ do the shift
        STR R0, [R2] @ write to the register
.endm

.macro GPIOTurnOn pin, value
        MOV R2, R8 @ address of gpio regs
        ADD R2, #clrregoffset @ off set of clr reg
        MOV R0, #1 @ 1 bit to shift into pos
        LDR R3, =\pin @ base of pin info table
        ADD R3, #8
        LDR R3, [R3]
        LSL R0, R3
        STR R0, [R2]
.endm

_start:
        LDR R0, = fileName
        MOV R1, #0x1b0
        ORR R1, #0x006
        MOV R2, R1
        MOV R7, #sys_open
        SVC 0
        MOVS R4, R0

        LDR R5, =gpioaddr
        LDR R5, [R5]
        MOV R1, #pagelen
        MOV R2, #(prot_read + prot_write)
        MOV R3, #map_shared
        MOV R0, #0
        MOV R7, #sys_map
        SVC 0
        MOVS R8, R0

	MOV R11, #1
	LSL R11, #5
	MOV R12, #1
	LSL R12, #19
restart:
        mov R6, #15
delay:
	nanoSleep
	nanoSleep
	nanoSleep
loop:
	
	GPIODirectionOut pin6
        GPIOTurnOff pin6
        LDR R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
        cmp R10, #0
	bne loop
delay2:
	nanoSleep
	nanoSleep
	nanoSleep
temporizador:
	GPIODirectionOut pin6
        GPIOTurnOn pin6
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
	beq delay
	
	nanoSleep @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	beq delay
	
	nanoSleep @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	beq delay
	
	nanoSleep @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	beq delay
	
	nanoSleep @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	beq delay
	
	nanoSleep @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	beq delay
	
	nanoSleep @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	beq delay
	
	nanoSleep @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	beq delay
	
	nanoSleep @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	beq delay
	
	nanoSleep @wait 100 ms
	
	ldr R9, [R8, #level]
	AND R10, R12, R9
	cmp R10, #0
	beq restart
	AND R10, R11, R9
	CMP R10, #0
	beq delay
	
	nanoSleep @wait 100 ms
@------------------------------------------------------------------
	
	sub R6, #1
	cmp R6, #0
	bge temporizador
	
        GPIOTurnOff pin6

fim:   MOV R0, #0
        MOV R7, #1
        SVC 0


.data
timespecsec: .word 0
timespecnano: .word 100000000
timespecsecT: .word 1
timespecnanoT: .word 000000000
fileName: .asciz "/dev/mem"
gpioaddr: .word 0x20200
pin6: .word 0
        .word 18
        .word 6
