title: Замечательный Bootloader от Microchip для PIC16 / PIC18
category: Embedded
tags: Bootloader, UART


Вы перепрошивали когда-нибудь **BIOS** ? Если нет, то Вам скорее всего, повезло... Вобщем представьте себе **BIOS**, который не умеет прошивать сам себя и если что-то не работает или работает плохо (его разрабатывают люди, точно такие же как и мы с Вами), нужно выключить компьютер, открутить пару шурупов, снять крышку, вытянуть микросхему **BIOS**, найти совместимый программатор, ПРОШИТЬ, после чего сделать всё то же самое в обратном порядке. Пару раз сделать можно, но хотелось бы что-нибудь поудобнее, особенно если предполагается этот процесс часто повторять в процессе разработки.

После того, как микроконтроллеры **Microchip** научились программно считывать/записывать ячейки своей Flash-памяти (появились соответствующие инструкции ассемблера), появление **Bootloader**'ов - это был лишь вопрос времени. Очень хорошо, когда этим вопросом занимается непосредственно производитель микроконтроллеров - кто как не он лучше осведомлён о возможностях своей продукции. На одном из таких Bootloader'ов под названием **AN1310**, ориентированном на линейку **PIC16** / **PIC18** и использующим для коммуникации последовательный интерфейс **UART** давайте остановимся поподробнее. Скачать всё необходимое для работы ПО можно с сайта [производителя](http://www.microchip.com/applicationnotes){:rel="nofollow"}.

<script type="text/javascript" src="{attach}jquery-1.11.2.min.js"> </script>
<script type="text/javascript" src="{attach}slider/easySlider1.7.js"> </script>
<script type="text/javascript" src="{attach}onload.js"> </script>

<div id="slider_bootloder_shots" style="padding-top: .6em;">
<ul>
<li><img src="{attach}shots/start.png" alt="start" /></li>
<li><img src="{attach}shots/settings.png" alt="settings" /></li>
<li><img src="{attach}shots/break.png" alt="break" /></li>
<li><img src="{attach}shots/bootloader_connected.png" alt="bootloader_connected" /></li>
<li><img src="{attach}shots/erase.png" alt="erase" /></li>
<li><img src="{attach}shots/write.png" alt="write" /></li>
<li><img src="{attach}shots/verify.png" alt="verify" /></li>
<li><img src="{attach}shots/read_main.png" alt="read_main" /></li>
<li><img src="{attach}shots/read_eeprom.png" alt="read_eeprom" /></li>
<li><img src="{attach}shots/read_config.png" alt="read_config" /></li>
<li><img src="{attach}shots/run.png" alt="run" /></li>
<li><img src="{attach}shots/validate_balance.png" alt="validate_balance" /></li>
<li><img src="{attach}shots/reboot.png" alt="reboot" /></li>
<li><img src="{attach}shots/reboot_1.png" alt="reboot_1" /></li>
<li><img src="{attach}shots/reboot_2.png" alt="reboot_2" /></li>
</ul>
</div>
<div style="clear: both;">
</div>

Особенности **AN1310**:

+ Использует маленький объём Flash памяти микроконтроллера - в большинстве случаев менее 450 слов

+ Автоматическое согласование скорости передачи данных UART между ПК (host) и микроконтроллером

+ Широкий диапазон для выбора скорости передачи 1,200 Кбит/с - 3 Mбит/с

+ Протокол обмена данными использует 16-бит CRC

+ Имеется возможность записывать Flash только по тем адресам, которые изменились (*Incremental Bootloading*) - это значительно ускоряет процесс разработки

+ Mинимум соединительных элементов - можно обойтись всего тремя проводниками

+ ПО на стороне ПК кроссплатформенное - код написан на **С** / **С++** **Qt** **SDK**, есть исходники

###Шаг первый - схемотехника

В документации предлагаются две схемы. Для согласования уровней используется микросхема MAX3232:

![Скриншот]({attach}cheme_3.3v.png){:style="width:100%; border:1px solid #ddd;"}

Если напряжение питания микроконтроллера отличается от напряжения питания MAX3232, то предлагается ввести дополнительный MOSFET транзистор:

![Скриншот]({attach}cheme_5v.png){:style="width:100%; border:1px solid #ddd;"}

Однако представленные схемы можно значительно упростить / удешевить, если использовать переходник USB-to-serial (например на PL2303 или FT232BM). Уровень логической единицы у PL2303 - 3.3V и если напряжение питания микроконтроллера находится в пределах 3 ... 3.3V, MAX3232 не понадобится. В таком случае необходим только подтягивающий резистор с **Vdd** на **RX**, чтобы избежать случайной загрузки **Bootloader**'а при отключённом переходнике USB-to-serial. Что касается сигнала RTS (см. схемы), то он используется для сброса микроконтроллера (RESET), а поскольку такого же эффекта можно достичь просто отключив/включив питание, то его использование опционально. В случаее с USB-to-serial как правило имеется только RX, TX и GND, поэтому удобней сбрасывать микроконтроллер вручную.

###Шаг второй - прошивка микроконтроллера

![Скриншот]({attach}18f46k22.png){:style="float:left; margin:.5em 1.3em .3em 0;" }Исходники **AN1310** упакованы в исполняемый **\*.exe** файл, так что поначалу необходима ОС *Windows* (как вариант можно ещё попробовать установить *Wine* и запустить инсталляцию там, но Ваш покорный слуга этот способ на практике не проверял). Неприятная ситуация с **Windows** также повторяется и в процессе сборки **Bootloader**'а - для работы с **MPasm** / **MPLAB**, чтобы сгенерировать хекс. После того, как **Bootloader** будет уже в прошит кристалле, об ОС **Windows** можно спокойно забыть.

Cкачанный с сайта **Microchip** инсталлятор **Serial Bootloader AN1310 v1.05r.exe** по умолчанию в процессе установки на ПК распаковывает исходные коды для создания прошивки микроконтроллера сюда:

<div style="clear:both;">
</div> 

    C:\Microchip Solutions\Serial Bootloader AN1310 vX.XX\PICxx Bootloader\

<ol style="padding-top: 1em;">
  <li>
    <p style="padding-top:0; margin-top:0;">Код написан на ассемблере - MPasm, для его редактирования и сборки удобно использовать MPLAB IDE</p>
  </li>
  <li>
    <p>В меню Configure -&gt; Select Device… выбрать модель микроконтроллера (например PIC18F46K22)</p>
  </li>
  <li>
    <p>В меню Configure -&gt; Configuration Bits….</p>

<table style="border: 4px double black; border-collapse: collapse; width: 100%; margin-top: 1.5em; margin-bottom: 1.5em;" cellpadding="5">
<tbody>
<tr>
<td style="padding: .3em;border: 4px double black;">Watchdog Timer</td>
<td style="padding: .3em;border: 4px double black;">“Disabled”, однако его можно задействовать программно</td>
</tr>
<tr>
<td style="padding: .3em;border: 4px double black;">Extended Instruction Set Enable bit</td>
<td style="padding: .3em;border: 4px double black;">“Disabled”</td>
</tr>
<tr>
<td style="padding: .3em;border: 4px double black;">Oscillator Selection bits</td>
<td style="padding: .3em;border: 4px double black;">Чем больше тактовая частота, тем выше предельная скорость UART</td>
</tr>
<tr>
<td style="padding: .3em;border: 4px double black;">Fail-Safe Clock Monitor Enable bit</td>
<td style="padding: .3em;border: 4px double black;">“Enabled”, если имеется</td>
</tr>
<tr>
<td style="padding: .3em;border: 4px double black;">Low-Voltage Program (LVP)</td>
<td style="padding: .3em;border: 4px double black;">“Disabled”, если имеется</td>
</tr>
<tr>
<td style="padding: .3em;border: 4px double black;">Table Read-Protect</td>
<td style="padding: .3em;border: 4px double black;">“Disabled”, если имеется</td>
</tr>
</tbody>
</table>
  
</li>

  <li>
    <p>Собрать проект и прошить микроконтроллер программатором )))</p>
  </li>
</ol>

![Скриншот]({attach}mplab_config_bits.png){:style="width:100%; border:1px solid #ddd;"}

В случае необходимости можно отредактировать код **bootconfig.inc**. Например, **PIC18F46K22** имеет на борту два **USART** модуля, а **Bootloader** по умолчанию использует первый. В этом же файле можно выбрать один из двух режимов работы  **Bootloader**'а:

- По умолчанию, хекс **Bootloader**'а располагается в конце Flash-памяти, в этом случае основная программа микроконтроллера может сама обслуживать прерывания, т.е. фактически её работа ничем не отличается от работы без **Bootloader**'а. Единственное, что необходимо знать компилятору основной программы - участок занятой Flash-памяти, при использовании HI-TECH С для этой цели можно указать в командной строке что-то вроде `--ROM=default,-F800-FBFF`. Однако подобная реализация **Bootloader**'а имеет один существенный недостаток - в случае аппаратного сбоя (например отключили питание) в процессе записи его прошивка может повредиться - в этом случае снова понадобится программатор. Даже если с помощью битов конфигурации аппаратно защитить конец Flash-памяти, остаётся как минимум одна инструкция (**GOTO**), расположенная по адресу 0000h, защитить которую не коснувшись обработки прерываний (0008h, 0018h) мы не можем - аппаратно защищать Flash-память от записи можно только блоками.

- В этой связи целесообразно задействовать второй вариант **Bootloader**'а, в документации он обозначен как **REMAPPED**. Он располагается в начале Flash-памяти и сам обслуживает прерывания, фактически пробрасывает их по другим адресам, например: 0008h => 0808h, 0018h => 0818h. Такой подход добавляет теоретическую(инструкция GOTO) задержку в процесс обработки прерываний, однако имеет два очевидных преимущества. Во-первых, практически у всех микроконтроллеров Flash имеет boot-блок, объём которого меньше других - он как раз ориентирован на **Bootloader**'ы. Это позволяет более рационально и экономно распределить ресурсы Flash-памяти между микроконтроллером и **Bootloader**'ом. Во-вторых, весь код, который необходим для работы **Bootloader**'а можно аппаратно защитить от записи, ничто не cможет его повредить.
Чтобы задействовать **REMAPPED Bootloader**, необходимо в **bootconfig.inc** указать `#define BOOTLOADER_ADDRESS 0`. Также, исходя из размера boot-блока, необходимо указать, куда **Bootloader** должен пробрасывать прерывания, обозначив: `AppVector 0x800`, `AppHighIntVector 0x808`  и `AppLowIntVector 0x818`. Обо всём этом необходимо сообщить компилятору основной программы. Для HI-TECH С это будет выглядеть вот так: `--RUNTIME=default,+download --CODEOFFSET=800 --ROM=default,-0-7FF`

*bootconfig.inc*

    :::text
    ; Copyright (c) 2002-2011,  Microchip Technology Inc.
    ;
    ; Microchip licenses this software to you solely for use with Microchip
    ; products.  The software is owned by Microchip and its licensors, and
    ; is protected under applicable copyright laws.  All rights reserved.
    ;
    ; SOFTWARE IS PROVIDED "AS IS."  MICROCHIP EXPRESSLY DISCLAIMS ANY
    ; WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT
    ; NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS
    ; FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  IN NO EVENT SHALL
    ; MICROCHIP BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR
    ; CONSEQUENTIAL DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR
    ; EQUIPMENT, COST OF PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY
    ; OR SERVICES, ANY CLAIMS BY THIRD PARTIES (INCLUDING BUT NOT LIMITED
    ; TO ANY DEFENSE THEREOF), ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION,
    ; OR OTHER SIMILAR COSTS.
    ;
    ; To the fullest extent allowed by law, Microchip and its licensors
    ; liability shall not exceed the amount of fees, if any, that you
    ; have paid directly to Microchip to use this software.
    ;
    ; MICROCHIP PROVIDES THIS SOFTWARE CONDITIONALLY UPON YOUR ACCEPTANCE
    ; OF THESE TERMS.

    ; Enable this to work around timing bug found in some PIC18Fxx20's
    ;#define TBLWT_BUG

    ; If you don't have an RS232 transceiver, you might want this option
    ;#define INVERT_UART

    ; Sets OSCCON<IRCF2:IRCF0> for maximum INTOSC frequency (8MHz)
    #define USE_MAX_INTOSC

    ; Sets OSCTUNE.PLLEN bit at start up for frequency multiplication.
    #define USE_PLL

    ; RB0 = 1 required to enable MAX3221 TX output on PICDEM LCD 2 demo board
    ;#define PICDEM_LCD2

    ; enable software boot block write protection
    #define USE_SOFTBOOTWP

    ; enable software config words write protection
    ;#define USE_SOFTCONFIGWP

    ; Autobaud will be used by default. 
    ; To save code space or to force a specific baud rate to be used, 
    ; you can optionally define a BAUDRG value instead. 
    ; Most PIC18's support BRG16 mode and use the 
    ; following equation:
    ;       BAUDRG = Fosc / (4 * Baud Rate) - 1
    ;
    ; Old PIC18's without BRG16 mode need this equation instead:
    ;       BAUDRG = Fosc / (16 * Baud Rate) - 1
    ;
    ; Examples:
    ;#define BAUDRG .51  ; 19.2Kbps from 4MHz (BRG16 = 1, BRGH = 1)
    ;#define BAUDRG .103 ; 115.2Kbps from 48MHz (BRG16 = 1, BRGH = 1)
    ;#define BAUDRG .85  ; 115.2Kbps from 40MHz (BRG16 = 1, BRGH = 1)
    ;#define BAUDRG .68  ; 115.2Kbps from 32MHz (BRG16 = 1, BRGH = 1)
    ;#define BAUDRG .16  ; 115.2Kbps from 8MHz (BRG16 = 1, BRGH = 1)
    ;#define BAUDRG .11  ; 1Mbps from 48MHz (BRG16 = 1, BRGH = 1)
    ;#define BAUDRG .9   ; 1Mbps from 40MHz (BRG16 = 1, BRGH = 1)
    ;#define BAUDRG .4   ; 2Mbps from 40MHz (BRG16 = 1, BRGH = 1)
    ;#define BAUDRG .3   ; 3Mbps from 48MHz (BRG16 = 1, BRGH = 1)
    ;#define BAUDRG .12  ; 19.2Kbps from 4MHz (BRG16 = 0, BRGH = 1)
    ;#define BAUDRG .10  ; 115.2Kbps from 19.6608MHz (BRG16 = 0, BRGH = 1)

    ; Bootloader must start at the beginning of a FLASH Erase Block. 
    ; If unspecified, bootloader will automatically be located at the 
    ; end of program memory address space.

    ; bootloader at beginning, application start/ISR vectors
    ; require remapping
    #define BOOTLOADER_ADDRESS   0

    ; useful for running under debugger 
    ; (debug executive wants to reside at the end of memory space too)
    ;#define BOOTLOADER_ADDRESS   END_FLASH - (ERASE_FLASH_BLOCKSIZE * 20)

    ; use on J parts to locate inside flash config erase block
    ;#define BOOTLOADER_ADDRESS  (END_FLASH - ERASE_FLASH_BLOCKSIZE) 

    #ifdef BOOTLOADER_ADDRESS
      #if BOOTLOADER_ADDRESS == 0
        ; For Bootloader located at program memory address 0, 
        ; the application firmware must provide remapped reset
        ; and interrupt vectors outside of the Boot Block. The following 
        ; #defines tell the bootloader firmware where application 
        ; entry points are to be expected:

        ; application start up code should be located here.
        #define AppVector           0x800

        ; application high priority interrupt should be located here
        #define AppHighIntVector    0x808

        ; application low priority interrupt should be located here
        #define AppLowIntVector     0x818
      #endif
    #endif

    ; Define UART pins and registers. 
    ; Modify the following lines if you want to use a different UART module.
    ;
    ; Note: If your UART's RX pin happens to be multiplexed with analog 
    ;       ANx input functionality, you may need to edit the 
    ;      "preprocess.inc" DigitalInput macro. Code there needs to 
    ;       enable the digital input buffer (refer to ADC chapter 
    ;       of your device's datasheet).
    ;
    #define UARTNUM 2
    #if UARTNUM == 1
        #define UxSPBRG         SPBRG
        #define UxSPBRGH        SPBRGH
        #define UxRCSTA         RCSTA
        #define UxTXSTA         TXSTA
        #define UxRCREG         RCREG
        #define UxTXREG         TXREG
        #define UxPIR           PIR1
        #define UxRCIF          RCIF
        #define UxTXIF          TXIF
        #define UxBAUDCON       BAUDCON

    ; RX on RC7 is used by default for most PIC18's.
    ;    #define RXPORT         PORTC
    ;    #define RXPIN          .7

    ;    #define RXPORT          PORTB   ; PIC18F14K50: RX on RB5/AN11
    ;    #define RXPIN           .5

    ; RX/AN11 multiplexed -- must enable digital input buffer
    ;    #define RXANSEL         ANSELH
    ; ANSELH<3> controls AN11 digital input buffer
    ;    #define RXAN            .3
    #endif

    #if UARTNUM == 2
        #define UxSPBRG         SPBRG2
        #define UxSPBRGH        SPBRGH2
        #define UxRCSTA         RCSTA2
        #define UxTXSTA         TXSTA2
        #define UxRCREG         RCREG2
        #define UxTXREG         TXREG2
        #define UxPIR           PIR3
        #define UxRCIF          RC2IF
        #define UxTXIF          TX2IF
        #define UxBAUDCON       BAUDCON2

    ; RG2 is default RX2 pin for some high pin count PIC18's.
    ;    #define RXPORT          PORTG
    ;    #define RXPIN           .2

    ; RX2 pin PPS'ed to RD4/RP21 on PIC18F46J11 for example.
        #define RXPORT          PORTD
        #define RXPIN           .7

    ; On PICs where RX is multiplexed with ANx analog inputs,
        #define RXANSEL         ANSELD
    ; the digital input buffer needs to be enabled via ANSELx SFRs
        #define RXAN            .7

    ; devices that use PPS to remap UART2 pins will need these 
    ; lines defined:

    ; PPS code for TX2/CK2 output function
    ;    #define PPS_UTX         .5
    ;    #define PPS_UTX_PIN     RPOR23  ; UART TX assigned to RP23 pin
    ;    #define PPS_URX_PIN     .21     ; UART RX assigned to RP21 pin
    ; PPS register for RX2/CK2 input function
    ;    #define PPS_URX         RPINR16
    #endif

    ; If you get linker errors complaining 
    ; "can not fit the absolute section," you might want to 
    ; increase BOOTLOADERSIZE below or set the 
    ; BOOTLOADER_ADDRESS above to a smaller address number.

    ; Because we need to know the total size of the 
    ; bootloader before the assembler has finished compiling
    ; the source code, we have to estimate the final bootloader 
    ; size and provide it here as BOOTLOADERSIZE. This number 
    ; is in bytes (twice the instruction word count). 
    ;
    ; If you see the bootloader is reserving more FLASH memory 
    ; than it really needs (you'll see a bunch of FFFF/NOP 
    ; instructions at the end of the bootloader memory region),
    ; you can try reducing BOOTLOADERSIZE.
    #define BOOTLOADERSIZE  .708

    #define MAJOR_VERSION   .1  ; Bootloader Firmware Version
    #define MINOR_VERSION   .5

###Шаг третий - запуск и работа с Bootloader'ом

Итак, может быть два режима работы микроконтроллера: режим выполнения основной программы и режим **Bootloader**'а. После подачи питания на микроконтроллер, либо после *Reset*, загрузчик **Bootloader**'а по некоторым признакам принимает решение, какой из них необходимо запустить. О необходимости запуска **Bootloader**'а говорят следующие признаки:

1. Oсновной программы нет, например первый запуск

2. Если на входе RX логический ноль (в терминах RS-232 состояние “Break")

Таким образом, при необходимости запустить **Bootloader**, можно использавать следующую последовательность действий: физически подключить микроконтроллер к ПК, установить логический ноль на RX, это можно сделать посредством кнопочки ![Кнопка Пауза]({attach}shots/break_btn.png), после чего ввести микроконтроллер в состояние RESET (в простейшем случае - включить/выключить питание). С этого момента к нему можно подключаться со стороны ПК ![Кнопка Пауза]({attach}shots/boot_btn.png)

ПО для ПК поставляеncя в исходниках, при необходимости его можно подкорректировать в **QTCreator**, а для Windows уже есть готовый исполняемый .exe файл. Если при работе в Linux подозрительно работает переходник на PL2303, попробуйте сделать следующее:

    :::bash
    ~$ sudo modprobe -r pl2303
    ~$ sudo modprobe pl2303

Если в **Linux** оболочка для работы с **Bootloader**'ом вообще не видит USB-to-serial переходника (например `/dev/ttyUSB0`), скорее всего текущий пользователь просто не обладает соответствующими правами. Поскольку постоянно запускать программу их-под **root**'a неудобно, ниже описан конкретный случай лечения OpenSUSE 12.1 - полными правами на USB-to-serial обладает группа *dialout*, поэтому в неё нужно добавить текущего пользователя системы, после чего, чтобы изменения вступили в силу, ОБЯЗАТЕЛЬНО перелогиниться:

    :::bash
    oleg@linux-ubuc:~> ls -l /dev/ttyUSB?
    crw-rw---- 1 root dialout 188, 0 марта  1 10:13 /dev/ttyUSB0
    oleg@linux-ubuc:~> sudo /usr/sbin/groupmod -A $USER dialout

В Ubuntu 12.04 добавить пользователя можно так: `sudo adduser $USER dialout`

На этом всё, надёжных девайсов Вам !

На всякий пожарный исходники [тут]({attach}bootloader.zip).
