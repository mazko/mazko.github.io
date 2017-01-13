title:  Симуляция микроконтроллеров PICSim.js
category: Embedded 
tags: picsim

PIC (**P**eripheral **I**nterface **C**ontroller) - серия микроконтроллеров, имеющих гарвардскую архитектуру и производимых компанией Microchip. Под маркой PIC выпускаются 8 (PIC10/12/16/18), 16 (PIC24, dsPIC30, dsPIC33F) и 32-битные PIC32 микроконтроллеры. PIC10 линейка отличается низкой стоимостью за счёт ограниченного набора периферии (обычно АЦП и ШИМ) и невысокой производительности. В свою очередь PIC32 на данный момент является флагманом компании Microchip на рынке микроконтроллеров, обладая наиболее высокой производительностью и наиболее продвинутой периферией на борту. Ниже изображена блок-схема микроконтроллера PIC16F648. В принципе за исключением количества портов ввода-вывода PORTA, PORTB... и набора периферийных модулей Timer, CCP1... этот рисунок у большинства современных PIC16 будет идентичен.

![screenshot]({attach}PIC16F648.svg){:style="width:100%;"}

Микроконтроллеры PIC16 имеют очень эффективный набор команд - всего 35. Большинство выполняются за один цикл, в некоторых случаях (условные переходы) 2. Для выполнения одного цикла требуется 4 периода тактовой частоты. Несмотря на небольшой набор команд на их основе можно реализовать любую логику или если выражаться по-умному то такой набор команд является полным по Тьюрингу. На каком языке бы ни была написана программа для PIC16 микроконтроллера, после компиляции она будет представлена определённой последовательностью различных команд из 35. Скачать C-компилятор xc8 можно c сайта Microchip.

[hex]({attach}blink.hex) | [picsim.js](http://mazko.github.io/picsim.js/91b059197905b07da98f64848ac9d4f1)

    :::c

    /*
      xc8 --chip=16f628A blink.c
    */

    // __delay_ms legacy code
    #include <htc.h>

    // http://microchip.wikidot.com/faq:26
    // The delay amount must be a constant (cannot be a variable).
    #define _XTAL_FREQ 5e4 // 50 kHz

    #pragma config WDTE = OFF

    int main() {

      RB0 = 0;             // RB0 initial value
      TRISB = 0xFF-1;      // RB0 as Output PIN

      while(42)
      {
        RB0 = 1;           // LED ON
        __delay_ms(1000);  // 1 Second Delay
        RB0 = 0;           // LED OFF
        __delay_ms(1000);  // 1 Second Delay
      }
      return 0;
    }

Макрос ```#define _XTAL_FREQ 1e6``` нужен компилятору для расчёта ```__delay_ms```. При старте микроконтроллера все порты ввода-вывода настроены на вход, а чтобы мигать лампочкой RB0 должен работать на выход поэтому ```TRISB = 0xFF-1```. Далее бесконечных цикл - переключение, временная задержка. На выходах RA1-RA3 подтягивающие резисторы, поэтому лампочки такие зелёные.

Если не полениться и взглянуть на ```blink.asm``` файл (ассемблерный листинг), сгенерированный компилятором xc8 рядом с blink.hex, то можно увидеть команды типа ```bcf```, ```movlw``` и т.д. которые собственно и входят в те 35, упомянутых ранее.

[comment]: <> (byzanz-record --x=240 --y=100 -w 950 --delay 5 -d 3 ui.flv)
[comment]: <> (ffmpeg -i ui.flv -pix_fmt rgb24 -r 10 "frames/frame-%05d.png")
[comment]: <> (convert -monitor -limit memory 1024MiB -limit map 2048MiB -layers removeDups -layers Optimize -delay 10 -loop 0 "frames/*.png" ui.gif)

![screenshot]({attach}ui.gif){:style="width:100%; border:1px solid #ddd;"}

Следующая сложная программа уже взаимодействует с пользователем посредством кнопок RA1-RA3. Каждая кнопка сигнализирует о нажатии своей комбинацией светодиодов на PORTB.

[hex]({attach}buttons.hex) | [picsim.js](http://mazko.github.io/picsim.js/651d7b511656cac141c52941dffeb5a3)

    :::c

    /*
      xc8 --chip=16f628A buttons.c
    */

    #include <xc.h>
    #include <stdbool.h>

    #pragma config WDTE = OFF

    int main() {

      PORTB = TRISB = 0;

      while(true) {
        if (!RA1) {
          RB0 = true;
        } else if (!RA2) {
          RB0 = RB1 = true;
        } else if (!RA3) {
          RB0 = RB1 = RB2 = true;
        } else if (!RA4) {
          RB0 = RB1 = RB2 = RB3 = true;
        } else {
          PORTB = 0;
        }
      }

      return 0;
    }

[comment]: <> (byzanz-record -c --x=240 --y=100 -w 950 --delay 3 -d 15 ui.flv)
[comment]: <> (ffmpeg -i ui.flv -pix_fmt rgb24 -r 10 "frames/frame-%05d.png")
[comment]: <> (convert -monitor -limit memory 1024MiB -limit map 2048MiB -layers removeDups -layers Optimize -delay 10 -loop 0 "frames/*.png" ui.gif)

![screenshot]({attach}ui-b.gif){:style="width:100%; border:1px solid #ddd;"}

P.S. Таблица периферийных модулей реализованных в симуляторе [PICSim](https://github.com/lcgamboa/picsim){:rel="nofollow"}.