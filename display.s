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
        LDR R0,=timespecsec  @ carrega o valor da variável timespecsec
        LDR R1,=timespecnano @ parametro da macro
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

.macro GPIOTurn pin
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

@ macro que ativa os pinos do display e define eles como saída
.macro pinDisplay
        GPIODirectionOut pinE
        GPIODirectionOut pinRS
        GPIODirectionOut pinDB7
        GPIODirectionOut pinDB6
        GPIODirectionOut pinDB5
        GPIODirectionOut pinDB4
.endm

@ macro para habilitar o display
.macro enable
	mov R1, #0
        GPIOTurn pinE
        nanoSleep
        mov R1, #1
        GPIOTurn pinE
        nanoSleep
        mov R1, #0
        GPIOTurn pinE
.endm

@ macro da função "function set" do display
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

@ macro para desligar o display
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

@ macro para limpar as informações do display
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

@ macro da função "entry set mode" do display
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
        GPIOTurnOn pinRS
.endm

.macro writeNumber
	prefixNumber
	
	GPIOTurnOff pinDB7
        GPIOTurnOff pinDB6
        GPIOTurnOff pinDB5
        GPIOTurnOff pinDB4
        enable
	
.endm

@ macro para escrever o número 0 (zero)
.macro writeNumber0
        prefixNumberDisplay

        GPIOTurnOff pinDB7
        GPIOTurnOff pinDB6
        GPIOTurnOff pinDB5
        GPIOTurnOff pinDB4
        enable
.ltorg
.endm

@ macro para escrever o número 1 (um)
.macro writeNumber1
        prefixNumberDisplay

        GPIOTurnOff pinDB7
        GPIOTurnOff pinDB6
        GPIOTurnOff pinDB5
        GPIOTurnOn pinDB4
        enable
.ltorg
.endm

@ macro para escrever o número 2 (dois)
.macro writeNumber2
        prefixNumberDisplay

        GPIOTurnOff pinDB7
        GPIOTurnOff pinDB6
        GPIOTurnOn pinDB5
        GPIOTurnOff pinDB4
        enable
.ltorg
.endm

@ macro para escrever o número 3 (três)
.macro writeNumber3
        prefixNumberDisplay

        GPIOTurnOff pinDB7
        GPIOTurnOff pinDB6
        GPIOTurnOn pinDB5
        GPIOTurnOn pinDB4
        enable
.ltorg
.endm

@ macro para escrever o número 4 (quatro)
.macro writeNumber4
        prefixNumberDisplay
        
        GPIOTurnOff pinDB7
        GPIOTurnOn pinDB6
        GPIOTurnOff pinDB5
        GPIOTurnOff pinDB4
        enable
.ltorg
.endm

@ macro para escrever o número 5 (cinco)
.macro writeNumber5
        prefixNumberDisplay

        GPIOTurnOff pinDB7
        GPIOTurnOn pinDB6
        GPIOTurnOff pinDB5
        GPIOTurnOn pinDB4
        enable
.ltorg
.endm

@ macro para escrever o número 6 (seis)
.macro writeNumber6
        prefixNumberDisplay

        GPIOTurnOff pinDB7
        GPIOTurnOn pinDB6
        GPIOTurnOn pinDB5
        GPIOTurnOff pinDB4
        enable
.ltorg
.endm

@ macro para escrever o número 7 (sete)
.macro writeNumber7
        prefixNumberDisplay

        GPIOTurnOff pinDB7
        GPIOTurnOn pinDB6
        GPIOTurnOn pinDB5
        GPIOTurnOn pinDB4
        enable
.ltorg
.endm

@ macro para escrever o número 8 (oito)
.macro writeNumber8
        prefixNumberDisplay

        GPIOTurnOn pinDB7
        GPIOTurnOff pinDB6
        GPIOTurnOff pinDB5
        GPIOTurnOff pinDB4
        enable
.ltorg
.endm

@ macro para escrever o número 9 (nove)
.macro writeNumber9
        prefixNumberDisplay

        GPIOTurnOn pinDB7
        GPIOTurnOff pinDB6
        GPIOTurnOff pinDB5
        GPIOTurnOn pinDB4
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
	writeNumber0

	writeNumber1
       
	writeNumber2
       
	writeNumber3	


_end:
        MOV R7,#1
        SVC 0


.data

time1ms:
        .word 0
        .word 070000000

timespecsec: .word 0
timespecnano: .word 100000000
timespecsecT: .word 1
timespecnanoT: .word 000000000

on: .word 1
off: .word 0 

fileName: .asciz "/dev/mem"
gpioaddr: .word 0x20200
@ LCD

pinRS:	@ pino RS do Display LCD - GPIO25
	.word 8	 @ offset para selecionar o registrador
	.word 15 @ bit offset no registrador selecionado
	.word 25 @ bit offset no registrador set & clear

pinE:	@ pino E do Display LCD - GPIO1
	.word 0  @ offset para selecionar o registrador
	.word 3  @ bit offset no registrador selecionado
	.word 1  @ bit offset no registrador set & clear

pinDB4:	@ pino DB4 do Display LCD - GPIO12
	.word 4  @ offset para selecionar o registrador
	.word 6  @ bit offset no registrador selecionado
	.word 12 @ bit offset no registrador set & clear

pinDB5:	@ pino DB5 do Display LCD - GPIO16
	.word 4  @ offset para selecionar o registrador
	.word 18 @ bit offset no registrador selecionado
	.word 16 @ bit offset no registrador set & clear

pinDB6:	@ pino DB6 do Display LCD - GPIO20
	.word 8  @ offset para selecionar o registrador
	.word 0  @ bit offset no registrador selecionado
	.word 20 @ bit offset no registrador set & clear

pinDB7:	@ pino DB7 do Display LCD - GPIO21
	.word 8  @ offset para selecionar o registrador
	.word 3  @ bit offset no registrador selecionado
	.word 21 @ bit offset no registrador set & clear