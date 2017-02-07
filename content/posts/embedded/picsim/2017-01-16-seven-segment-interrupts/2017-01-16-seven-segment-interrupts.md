title:  PICSim.js - семисегментный индикатор и прерывания
category: Embedded 
tags: picsim

Семисегментные индикаторы - наиболее простой способ для представления цифровой информации в виде арабских цифр и даже некоторых букв (для полноценного отображения букв используются более сложные многосегментные и матричные индикаторы). Светодиодные семисегментные индикаторы имеют высокую яркость, широкий диапазон рабочих температур, низкую стоимость и очень просты в управлении. Главными недостатками светодиодных индикаторов являются относительно высокое энергопотребление и слабая видимость при ярком освещении, хотя на нашем модном цветном мобильном телефоне тоже ничего не видно на солнышке днём :)

Конструктивно светодиодный семисегментный индикатор представляет собой группу из семи светодиодов, расположенных в определенном порядке. Включая их в различных комбинациях можно составить упрощённые изображения цифр 0..9. Индикаторы различаются по размеру, типу соединения светодиодов - общий анод, общий катод, по количеству отображаемых разрядов - одноразрядные, двухразрядные и более, по яркости свечения и по цвету - красные, желтые, зеленые и т.д. 

[hex]({attach}7.hex) | [picsim.js](http://mazko.github.io/picsim.js/69cc6064062b774abdb3734521cf01a8)

*display7.c*

    :::c

    #include <stdint.h>

    static uint8_t display7(uint8_t value) {
      switch(value) {
        case 0:
          return 0xEE;
        case 1:
          return 0x28;
        case 2:
          return 0xCD;
        case 3:
          return 0x6D;
        case 4:
          return 0x2B;
        case 5:
          return 0x67;
        case 6:
          return 0xE7;
        case 7:
          return 0x2C;
        case 8:
          return 0xEF;
        case 9:
          return 0x6F;
        case 10:
          return 0xAF;
        case 11:
          return 0xE3;
        case 12:
          return 0xC6;
        case 13:
          return 0xE9;
        case 14:
          return 0xC7;
        case 15:
          return 0x87;
        default:
          return 0;
      }
    }

*main.c*

    :::c

    /*
      xc8 --chip=16f648A main.c
    */

    #include <xc.h>
    #include <stdint.h>
    #include "display7.c"

    #pragma config WDTE = OFF

    const uint8_t porta_btn_mask = 0b11110;

    int main() {

      uint8_t display_data = 0,
              last_buttons = 0;

      PORTB = TRISB = 0;

      while(1) {
        uint8_t buttons = PORTA & porta_btn_mask;
        if (last_buttons != buttons) {
          last_buttons = buttons;
          if (!RA1) {
            display_data += 2;
          } else if (!RA2) {
            display_data += 1;
          } else if (!RA3) {
            display_data -= 1;
          } else if (!RA4) {
            display_data -= 2;
          }
          PORTB = display7(display_data & 0xF);
        }
      }

      return 0;
    }

[comment]: <> (byzanz-record -c --x=240 --y=100 -w 950 --delay 3 -d 22 ui.flv)
[comment]: <> (ffmpeg -i ui.flv -pix_fmt rgb24 -r 10 "frames/frame-%05d.png")
[comment]: <> (convert -monitor -limit memory 1024MiB -limit map 2048MiB -layers removeDups -layers Optimize -delay 10 -loop 0 "frames/*.png" ui.gif)

В данном примере используется наиболее простой вид индикации - *статическая индикация*, в таком режиме каждый сегмент индикатора постоянно находится в одном из двух состояний - включен или выключен. Функция ```display7``` приводит двоичное число в код семисегментного индикатора и позволяет отображать шестнадцатиричное число 0..F.

![screenshot]({attach}ui.gif){:style="width:100%; border:1px solid #ddd;"}

Для одновременной работы нескольких разрядов семисегментного индикаторов часто используют *динамическую индикацию* (динамическое управление), которое подразумевает поочередное переключение разрядов с частотой, не воспринимаемой человеческим глазом. Для динамической индикации требуется меньшее количество ног микроконтроллера и меньшее количество внешних элементов. На исследуемой плате нога RB4 как раз и занимается поочерёдным переключением двух разрядов - при нуле на RB4 данные с PORTB попадают на левый индикатор, при единице соответственно на правый.

Задача переключения разрядов семисегментных довольно критична ко времени - при его неравномерном распределении один разряд будет ярче другого, что приведёт к неприятным для человеческого глаза эффектам, мерцаниям. Для задач, критичных ко времени реакции на возникшие события в микроконтроллерах предусмотрены прерывания - основной цикл ```main()``` приостанавливается (прерывается), сохраняя свой контекст выполнения, отрабатывает логика обработчика прерывания, после чего управление снова передаётся ```main()```, при этом сохранённый ранее контекст выполнения восстанавливается.

[hex]({attach}main.hex) | [picsim.js](http://mazko.github.io/picsim.js/d7c032cf6e1c90c841d5f42e9130b22f)

*isr.c*

    :::c

    #include <xc.h>
    #include <stdint.h>
    #include <stdbool.h>
    #include "display7.c"

    // C89, section 6.5.7 Initialization.
    // If an object that has static storage duration is not initialized explicitly, then:
    // - if it has arithmetic type, it is initialized to (positive or unsigned) zero; 

    // interface
    volatile uint8_t display_data;

    // http://microchip.wikidot.com/faq:31

    void interrupt _int_7(void)   // interrupt function 
    {
      static bool current_7;

      if(INTCONbits.T0IF && INTCONbits.T0IE) 
      {                           // if timer flag is set & interrupt enabled
        INTCONbits.T0IF = 0;      // clear the interrupt flag 
        uint8_t data = display7(current_7 ? display_data & 0xF : display_data >> 4);
        PORTB = current_7 ? data | 0b10000 /* RB4 */ : data;
        current_7 = !current_7;
      }
    }

*main.c*

    :::c

    /*
      xc8 --chip=16f648A main.c isr.c
    */

    #include <xc.h>
    #include <stdint.h>

    #pragma config WDTE = OFF

    const uint8_t porta_btn_mask = 0b11110;
    extern uint8_t display_data;

    int main() {

      uint8_t last_buttons = 0;

      OPTION_REGbits.T0CS = 0;     // Timer0 increments on instruction clock
      OPTION_REGbits.PSA = 0;      // Prescaler is assigned to the Timer0 module
      OPTION_REGbits.PS0 = 1;
      OPTION_REGbits.PS1 = 0;
      OPTION_REGbits.PS2 = 0;      // Prescaler 1:4; T0IF each 256*4 cycle
      INTCONbits.T0IE = 1;         // Enable interrupt on TMR0 overflow
      INTCONbits.GIE = 1;          // Global interrupt enable

      PORTB = TRISB = 0;

      while(1) {
        uint8_t buttons = PORTA & porta_btn_mask;
        if (last_buttons != buttons) {
          last_buttons = buttons;
          if (!RA1) {
            display_data += 10;
          } else if (!RA2) {
            display_data += 1;
          } else if (!RA3) {
            display_data -= 1;
          } else if (!RA4) {
            display_data -= 10;
          }
        }
      }

      return 0;
    }

В файле ```isr.c``` реализована логика, отвечающая за отображение информации на семисегментном дисплее. Интерфейс взаимодействия ```isr.c``` с другими программными модулями, такими как *main.c*, только через переменную ```display_data``` - проектирование на уровне интерфейсов позволяет распределить для модулей зоны ответственности и инкапсулировать их реализацию. 
Модули, полученные в на этапе проектирования системы, должны быть минимально связанны друг с другом (Слабая Связанность, Low Coupling). При правильном проектировании в случае изменении одного модуля не придется править другие или эти изменения будут минимальными. Чем слабее связанность, тем легче писать/понимать/расширять/чинить любую программу на любом языке программирования.

![screenshot]({attach}ui-int.gif){:style="width:100%; border:1px solid #ddd;"}

Так как [скважность]({filename}../2017-01-14-pwm/2017-01-14-pwm.md) импульсов на RB4 равна двум яркость свечения каждого из разрядов семисегментного распределяется поровну от максимальной.

[Далее]({filename}../2017-01-17-wdt/2017-01-17-wdt.md) сторожевой таймер.