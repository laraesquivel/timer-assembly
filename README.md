# Aplicação de temporização (timer) com Raspberry Pi Zero

Este projeto consiste na implementação de uma aplicação em Assembly responsável por implementar um temporizador com contagem regressiva (timer) e mostrar os dígitos em um display LCD. O controle da aplicação é realizado com botões que tem as funções de iniciar/parar a contagem e reiniciar a partir de um tempo definido.

## Equipe de desenvolvimento
- [Lara Esquivel](github.com/laraesquivel)
- [Diego Rocha](github.com/Diego10Rocha)
- [Israel Braitt](github.com/israelbraitt)

## Descrição do problema
É necessário desenvolver um aplicativo de temporização (timer) que apresente a contagem num display LCD. O tempo inicial deverá ser configurado diretamente no código. Além disso, deverão ser usados 2 botões de controle: 1 para iniciar/parar a contagem e outro para reiniciar a partir do tempo definido.

## Como Executar


## Solução
### Requisitos Concluidos
[x] Código Escrito em Assembly
[x] O sistema deve permitir configurar o tempo de contagem
[x] Usar os botões para configurar iniciar, parar e reiniciar a contagem
[x] Usar os mesmsos botões para iniciar/parar a contagem
[x] Limpar Display
[x] Escrever caractere
[x] Posicionar Cursor
[ ] Biblioteca


### Recursos utilizados
- Raspberry Pi Zero W
- Display LCD Hitachi HD44780U
- Botões
- GPIO Extension Board

	<div id="image11" style="display: inline_block" align="center">
		<img src="/raspberry.jpg"/><br>
		<p>
		Raspberry Pi Zero W
		</p>
	</div>

	<div id="image11" style="display: inline_block" align="center">
		<img src="/raspberrykit.jpeg"/><br>
		<p>
			Kit Completo do Laboratório.
		</p>
	</div>

A placa Raspberry Pi Zero será responsável por controlar as informações enviadas para o display, além de executar os comandos necessários para a execução da aplicação e processar os sinais recebidos pelos botões. O display e os botões estão ligados à Raspberry Pi Zero por meio da GPIO Extension Board.

### GPIO do Raspberry Pi Zero
A Raspberry Pi Zero possui 40 pinos de GPIO (General Purpose Input/Output), que são portas programáveis de entrada e saída de dados, utilizadas para promover uma interface entre os periféricos.

A pinagem dos periféricos é feitas de acordo com as informações descritas à seguir.

#### Push-Buttons:
   	1 - GPIO-5
	2 - GPIO-19

#### Display LCD:
	RS: GPIO-25
	RW: GND
	E:  GPIO-01
	D4: GPIO-12
	D5: GPIO-16
	D6: GPIO-20
	D7: GPIO-21

### Display
Para a utilização do display LCD HD44780U foram implementadas as instruções presentes na [documentação oficial](https://www.google.com/url?sa=t&source=web&rct=j&url=https://www.sparkfun.com/datasheets/LCD/HD44780.pdf&ved=2ahUKEwjso46tlqn6AhVGL7kGHSe6BMEQFnoECGIQAQ&usg=AOvVaw076YT-P88DM3oFFvTDUv43) do mesmo através de código em assembly, de forma que os bits fossem tranferidos pelos pinos do display.

As instruções implementadas incluem: inicializar, limpar, escrever um dígito no display, entre outras descritas na documentação. Além dessas, também foram implementadas outras que possibilitam a realização da contagem.

O código em assembly responsável por controlar o display está presente em [display.s]().

### Temporizador

Foi implementado um temporizador, o qual é controlado atráves dos butões da placa: um para iniciar e pausar a contagem(GPIO-5) e outro para reiniciar. O temporizador conta a partir de números com no máximo duas casas deciamais.

### Arquitetura ARMv6
O processador da Raspberry Pi Zero possui arquitetura ARMv6, isso implica na utilização do conjunto de instruções da linguagem assembly desta arquitetura para a solução do problema. O ARMv6 é uma arquitetura RISC, o que implica em um conjunto de instruções mais simples e pequeno. Os processadores ARM fornecem registradores de propósito geral e de propósito especial. Alguns registros adicionais estão disponíveis em modos de execução privilegiados.

Em todos os processadores ARM, os seguintes registradores estão disponíveis e acessíveis em qualquer modo de processador:

13 registradores de uso geral R0-R12.
Um ponteiro de pilha (SP) R13.
Registro de um link (LR) R14.
Um contador de programa (PC) R15.
Um Registro de Status do Programa de Aplicativo (APSR).

Os processadores ARM suportam os seguintes tipos de dados na memória:

Byte - 8 bits

Half Word -16 bits

Word - 32 bits

Doubleword - 64 bits.

Os registradores do processador têm 32 bits de tamanho.

### Como Executar
Os arquivos base do códgio assembly encontra-se no caminho diretório (timer-assembly). Em conjunto está em anexo, o arquivo com o display e os botões, ContadorP-2P.s e display.s, os quais não fazem parte da versão final do projeto, todavia foram códigos base para a constução da versão final. ara executar o produto desenvolvido, utiliza-se o arquivo makefile. Para isso, dentro de um terminal linux, abra o diretório que contém os arquivos bases mencionados anteriormente e execute os seguinte comando:

-	make all
- sudo ./last_stable_version


### Tipos de Instruçoes

#### Instruções aritméticas 
	Instruções aritméticas fornecem a capacidade computacional para processamento de dados numéricos. Abaixo estão as instruções utilizadas no código:
	-ADD - adição
	-SUB - subtração

#### Instruções lógicas (booleanas) operam sobre bits de uma palavra, como bits e não como números
Instruções lógicas (booleanas) operam sobre bits de uma palavra, como bits e não como números. Abaixo estão as instruções utilizadas no código:
	-AND - função lógica "and"
	-ORR - função lógica "or"
	-LSL - deslocamento de bits para a esquerda

#### Transferência de dados 
Transferência de dados move dados entre a memória e os registradores. Abaixo estão as instruções utilizadas no código:

	-LDR - carrega da memória para o registrador
	-STR - carrega do registrador para a memória
	-MOV - move valor para os registradores

#### Instruções de desvio são utilizadas para desviar a execução do programa para uma nova instrução
Instruções de desvio são utilizadas para desviar a execução do programa para uma nova instrução. Todas as instruções utilizadas estão abaixo:

	-B - desvio incondicional
	-BEQ - desvio se condição for igual a zero
	-BLEQ - desvia e depois retorna para onde parou se a condição for igual a zero
	-BGT - desvia se a condição for maior que zero
	-BNE - desvia se a condição for diferente de zero

#### Instruções aritmética com logicas e com desvio.
Instruções que convenientemente se associam a outras criando um desvio a partir de uma condicional. As instruções utilizadas estão abaixo:

	-ADDEQ - adição se o a flag levantada for de valores igual 
	-SUBNE - subtração se a flag levantada for de valores diferentes
	-MOVNE- movimentação de dados se a flag levantada for de valores diferentes
 
## Testes
Teste do projeto em geral foram feitos a partir de casos de testes.

1- Iniciar contagem clicando o botão
2- Inciar contagem segurando o botão 
3- Pausar a contagem clicando o botão
4- Pausar a contagem segurando o botão
5- Reiniciar a contagem clicando o botão 
6- Reiniciar a contagrm segurando o botão
7- Contagem de um dígito visivel no display
8- Contagem de dois dígitos visivel no display
9- Trocar contagem de dois dígitos para um 
10- Trocar contagem de um dígito para dois
11- Clear deve ocorrer ao iniciar o display
12- Clear deve ocorrer antes de escrever um dígito

## Conclusão

Um aplicativo de temporização foi desenvolvido em Assembly em uma Raspberry Pi Zero W, a qual possui um processador de arquitetura ARMv6. Por meio desta aplicação é possível realizar contagens regressivadas de um segundo de 0 a 99. Além de  iniciar e parar a contagem no mesmo botão, e em outro reiniciar a contagem. A qual a partir do código é possível modificar o valor que será contato e todo o processo pode ser visualizado do display LCD em anexo a Raspberry.

Todavia, o código está fortemente acoplado, e não foi possível no momento fazer a biblioteca sem que o código parasse de funcionar, precisariamos de mais tempo, em torno de uma semana para tornar a parte do display como uma biblioteca, além de aumentar a quantidade de dígitos do display. Com esses ajustes futuros, o código pode ser corrigido e reutilizado como biblioteca em breve.


## Materiais de referência
[Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#raspberry-pi-zero-w)

[Display LCD HD44780U](https://www.google.com/url?sa=t&source=web&rct=j&url=https://www.sparkfun.com/datasheets/LCD/HD44780.pdf&ved=2ahUKEwjso46tlqn6AhVGL7kGHSe6BMEQFnoECGIQAQ&usg=AOvVaw076YT-P88DM3oFFvTDUv43)

[BCM2835 ARM Peripherals](https://www.raspberrypi.org/app/uploads/2012/02/BCM2835-ARM-Peripherals.pdf)
