@ CONTADOR QUE UTILIZA BOTÕES PARA INICIAR, PAUSAR E REINICIAR A CONTAGEM
@
@ ESSE CÓDIGO FOI ESCRITO EM ASSEMBLY ARMv6 E TESTADO
@ EM UMA RASPBERRY PI ZERO W COM UM DISPLAY LCD HD44780U
@
@ AUTORES: DIEGO ROCHA, LARA ESQUIVEL E ISRAEL BRAITT	
@
@ Esse código contém trechos de códigos retirados do livro:
@ Raspberry Pi Assembly Language Programming - ARM Processor Coding
@ do autor Stephen Smith


@ declaração de constantes
.equ pagelen, 4096	@ tamanho da men
.equ setregoffset, 28	@ offset do "set" do registrador
.equ clrregoffset, 40	@ offset do "clear" do registrador
.equ prot_read, 1 	@ modo de leitura
.equ prot_write, 2 	@ modo de escrita
.equ map_shared, 1 	@ liberar compartilhamento de memória
.equ sys_open, 5	@ syscall para abertura e criação de arquivos
.equ sys_map, 192	@ syscall para mapeamento de memória (gera endereço virtual)
.equ nano_sleep, 162	@ syscall para realizar uma pausa na execução do programa
.equ level, 52


.global _start

@ macro para pausar a execução do programa (em ms)
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

@ macro que define a função de um pino como saída de dados
.macro GPIODirectionOut pin
        LDR R2, =\pin 	 @ pega o valor da base de dados dos pinos
        LDR R2, [R2] 	 @ carrega o valor dos pinos
        LDR R1, [R8, R2] @ carrega o endereço de memória do registrador
        LDR R3, =\pin 	 @ endereço da tabela de pinos
        ADD R3, #4 	 @ valor da quantidade de carga a ser deslocada
        LDR R3, [R3] 	 @ carrega o valor do deslocamento
        MOV R0, #0b111 	 @ mascara para limpar os 3 bits
        LSL R0, R3 	 @ realiza o deslocamento para a posição
        BIC R1, R0 	 @ realiza a limpeza dos 3 bits
        MOV R0, #1 	 @ 1 bit para realizar o deslocamento para a posição
        LSL R0, R3 	 @ desloca pelo valor da tabela
        ORR R1, R0 	 @ define o bit
        STR R1, [R8, R2] @ salva o valor do registrador
.endm

@ macro que define o pino como ligado/sinal alto (1)
.macro GPIOTurnOn pin
        MOV R2, R8 	      @ endereço dos registradores do gpio
        ADD R2, #setregoffset @ offset do "set" do registrador
        MOV R0, #1 	      @ 1 bit para realizar o deslocamento para a posição
        LDR R3, =\pin 	      @ base da tabela de informações de pinos
        ADD R3, #8 	      @ adicona offset para o deslocamento
        LDR R3, [R3] 	      @ carrega o deslocamento da tabela
        LSL R0, R3 	      @ faz o deslocamento
        STR R0, [R2] 	      @ escreve no registrador

@ macro que define o pino como desligado/sinal baixo (0)
.macro GPIOTurnOff pin
        MOV R2, R8 	      @ endereço dos registradores do gpio
        ADD R2, #clrregoffset @ offset do "clear" do registrador
        MOV R0, #1 	      @ 1 bit para realizar o deslocamento para a posição
        LDR R3, =\pin 	      @ base da tabela de informações de pinos
        ADD R3, #8	      @ adicona offset para o deslocamento
        LDR R3, [R3]	      @ carrega o deslocamento da tabela
        LSL R0, R3	      @ faz o deslocamento
        STR R0, [R2]	      @ escreve no registrador
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

@ Este bloco de codigo ira fazer a leitura do botão 10 vezes a cada 100 ms. 
@ Totalizando o timer de 1s e captando mais precisamente as ações do botao start/stop e restart.
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