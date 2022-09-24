# Aplicação de temporização (timer) com Raspberry Pi Zero

Este projeto consiste na implementação de uma aplicação em Assembly responsável por implementar um temporizador com contagem regressiva (timer) e mostrar os dígitos em um display LCD. O controle da aplicação é realizado com botões que tem as funções de iniciar/parar a contagem e reiniciar a partir de um tempo definido.

## Equipe de desenvolvimento
- [Lara Esquivel](github.com/laraesquivel)
- [Diego Rocha](github.com/Diego10Rocha)
- [Israel Braitt](github.com/israelbraitt)

## Descrição do problema
É necessário desenvolver um aplicativo de temporização (timer) que apresente a contagem num display LCD. O tempo inicial deverá ser configurado diretamente no código. Além disso, deverão ser usados 2 botões de controle: 1 para iniciar/parar a contagem e outro para reiniciar a partir do tempo definido.

## Solução
#### Recursos utilizados
- Raspberry Pi Zero W
- Display LCD Hitachi HD44780U
- Botões
- GPIO Extension Board

A placa Raspberry Pi Zero será responsável por controlar as informações enviadas para o display, além de executar os comandos necessários para a execução da aplicação e processar os sinais recebidos pelos botões. O display e os botões estão ligados à Raspberry Pi Zero por meio da GPIO Extension Board.

#### GPIO do Raspberry Pi Zero
A Raspberry Pi Zero possui 40 pinos de GPIO (General Purpose Input/Output), que são portas programáveis de entrada e saída de dados, utilizadas para promover uma interface entre os periféricos.

A pinagem dos periféricos é feitas de acordo com as informações descritas à seguir.

##### Push-Buttons:
   	1 - GPIO-5
	2 - GPIO-19
	3 - GPIO-26

##### Display LCD:
	RS: GPIO-25
	RW: GND
	E:  GPIO-01
	D4: GPIO-12
	D5: GPIO-16
	D6: GPIO-20
	D7: GPIO-21

#### Arquitetura ARMv6
O processador da Raspberry Pi Zero possui arquitetura ARMv6, isso implica na utilização do conjunto de instruções da linguagem assembly desta arquitetura para a solução do problema.

#### Display
Para a utilização do display LCD HD44780U foram implementadas as instruções presentes na [documentação oficial](https://www.google.com/url?sa=t&source=web&rct=j&url=https://www.sparkfun.com/datasheets/LCD/HD44780.pdf&ved=2ahUKEwjso46tlqn6AhVGL7kGHSe6BMEQFnoECGIQAQ&usg=AOvVaw076YT-P88DM3oFFvTDUv43) do mesmo através de código em assembly, de forma que os bits fossem tranferidos pelos pinos do display.

As instruções implementadas incluem: inicializar, limpar, escrever um dígito no display, entre outras descritas na documentação. Além dessas, também foram implementadas outras que possibilitam a realização da contagem.

O código em assembly responsável por controlar o display está presente em [display.s]().

#### Lógica do contador

#### Materiais de referência
[Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#raspberry-pi-zero-w)

[Display LCD HD44780U](https://www.google.com/url?sa=t&source=web&rct=j&url=https://www.sparkfun.com/datasheets/LCD/HD44780.pdf&ved=2ahUKEwjso46tlqn6AhVGL7kGHSe6BMEQFnoECGIQAQ&usg=AOvVaw076YT-P88DM3oFFvTDUv43)

[BCM2835 ARM Peripherals](https://www.raspberrypi.org/app/uploads/2012/02/BCM2835-ARM-Peripherals.pdf)
