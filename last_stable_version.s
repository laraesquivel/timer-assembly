@ CONTADOR QUE EXIBE A CONTAGEM NO DISPLAY E UTILIZA
@ BOTÕES PARA INICIAR, PAUSAR E REINICIAR A CONTAGEM
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
.equ prot_read, 1	@ modo de leitura
.equ prot_write, 2	@ modo de escrita
.equ map_shared, 1	@ liberar compartilhamento de memória
.equ sys_open, 5	@ syscall para abertura e criação de arquivos
.equ sys_map, 192	@ syscall para mapeamento de memória (gera endereço virtual)
.equ nano_sleep, 162	@ syscall para realizar uma pausa na execução do programa
.equ level, 52

.global _start

@ pausa a execução do programa
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


@ define a função do pino como saída de dados
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


@ ativa o pino selecionado
.macro GPIOTurnOn pin
        MOV R2, R8 	      @ endereço dos registradores do gpio
        ADD R2, #setregoffset @ offset do "set" do registrador
        MOV R0, #1 	      @ 1 bit para realizar o deslocamento para a posição
        LDR R3, =\pin 	      @ base da tabela de informações de pinos
        ADD R3, #8 	      @ adicona offset para o deslocamento
        LDR R3, [R3] 	      @ carrega o deslocamento da tabela
        LSL R0, R3 	      @ faz o deslocamento
        STR R0, [R2] 	      @ escreve no registrador
.endm


@ desativa o pino selecionado
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


@ passa um determinado valor para o pino selecionado
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


@ define os pinos do display como saída de dados
.macro pinDisplay
        GPIODirectionOut pinE
        GPIODirectionOut pinRS
        GPIODirectionOut pinDB7
        GPIODirectionOut pinDB6
        GPIODirectionOut pinDB5
        GPIODirectionOut pinDB4
.endm


@ ativa o enable do display
.macro enable
        GPIOTurn pinE, #0
        nanoSleep2 time15ms
        GPIOTurn pinE, #1
        nanoSleep2 time15ms
        GPIOTurn pinE, #0
.endm


@ ativa o display para receber outros conjuntos de instruções
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


@ desliga o display
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


@ limpa os caracteres do display
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


@ define a direção de movimentação do cursor
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
        @ abrindo o arquivo
        LDR R0, = fileName
        MOV R1, #0x1b0
        ORR R1, #0x006
        MOV R2, R1
        MOV R7, #sys_open
        SVC 0
        MOVS R4, R0

        @ preparando o mapeamento
        LDR R5, =gpioaddr
        LDR R5, [R5]
        MOV R1, #pagelen
        MOV R2, #(prot_read + prot_write)
        MOV R3, #map_shared
        MOV R0, #0
        MOV R7, #sys_map
        SVC 0
        MOVS R8, R0
        
        @ sequência de inicialização do display
        pinDisplay
        displayClear
        functionSet
        functionSet
        functionSet
        functionSet
        display
        entrySetMode
        .ltorg
	
@branch que define o tempo de contagem e é utilizada para reiniciar a contagem
restart:
        mov R6, #0
        mov R5, #5
        displayClear
        writeNumber R5
        writeNumber R6
	
@branch que "segura" a execução do código se o botão de pause estiver pressionado
delay:
        LDR R9, [R8, #level]
        MOV R11, #1
        LSL R11, #5
        AND R10, R11, R9
        cmp R10, #0
        beq delay
        
        nanoSleep2 time100ms

@loop para só permitir iniciar a contagem quando o botão de start/pause for pressionado
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

@branch que faz com que a contagem só inicie quando soltar o botão start/pause
delay2:
        LDR R9, [R8, #level]
        MOV R11, #1
        LSL R11, #5
        AND R10, R11, R9
        cmp R10, #0
        beq delay2

@branch do contador que faz a temporização
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
@ Este bloco de codigo irá fazer a leitura dos botões start/pause e restart 10 vezes a cada 100 ms. 
@ Totalizando o timer de 1 s e captando mais precisamente as ações dos botões.

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

	@se o registrador de unidades for maior que 1, subtrai 1 e volta pro inicio da branch
        CMP R6, #0
        SUBNE R6, #1
        BGT temporizador

	@se o registrador de unidades for zero estas instruções são executadas
	@é verificado se o registrador de dezenas também é zero
	@se não for zero, subtrai 1 do registrador de dezena e atribui 9 ao registrador de unidade
	@se for zero é feito um desvio para a branch de restart
        CMP R5, #0
        SUBNE R5, #1
        MOVNE R6, #9
        BNE temporizador

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

time100ms:
        .word 0
        .word 100000000

time500ms:
        .word 0
        .word 500000000

time150ms:
        .word 0
        .word 150000000

time300ms:
        .word 3000000000


on: .word 1
off: .word 0


fileName: .asciz "/dev/mem"
gpioaddr: .word 0x20200


@ Pino conectado ao botão

pin6: 	@ Pino do botão
	.word 0	 @ offset para selecionar o registrador
	.word 18 @ bit offset no registrador selecionado
	.word 6	 @ bit offset no registrador set & clr


@ Pinos conectados ao display LCD

pinRS:	@ Pino RS do display LCD - GPIO25
	.word 8  @ offset para selecionar o registrador
	.word 15 @ bit offset no registrador selecionado
	.word 25 @ bit offset no registrador set & clr

pinE:	@ Pino E do display LCD - GPIO1
	.word 0 @ offset para selecionar o registrador
	.word 3 @ bit offset no registrador selecionado
	.word 1 @ bit offset no registrador set & clr

pinDB4:	@ Pino DB4 do display LCD - GPIO12
	.word 4  @ offset para selecionar o registrador
	.word 6  @ bit offset no registrador selecionado
	.word 12 @ bit offset no registrador set & clr

pinDB5:	@ Pino DB5 do display LCD - GPIO16
	.word 4  @ offset para selecionar o registrador
	.word 18 @ bit offset no registrador selecionado
	.word 16 @ bit offset no registrador set & clr

pinDB6:	@ Pino DB6 do display LCD - GPIO20
	.word 8  @ offset para selecionar o registrador
	.word 0  @ bit offset no registrador selecionado
	.word 20 @ bit offset no registrador set & clr

pinDB7:	@ Pino DB7 do display LCD - GPIO21
	.word 8  @ offset para selecionar o registrador
	.word 3  @ bit offset no registrador selecionado
	.word 21 @ bit offset no registrador set & clr
