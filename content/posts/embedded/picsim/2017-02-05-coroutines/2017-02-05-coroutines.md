title:  PICSim.js - сопрограммы и простейшая многозадачность
category: Embedded
tags: picsim, RTOS

Микроконтроллеры выполняют только одну машинную инструкцию в каждый момент времени (многоядерные микроконтроллеры я пока не встречал). Традиционно простейшая [программа]({filename}../2017-01-13-picsim-introduction/2017-01-13-picsim-introduction.md) для микроконтроллера это *суперцикл* - одна точка входа ```main``` с бесконечным циклом, где крутится какая-то задача. Архитектура большинства микроконтроллеров также предусматривает механизм [прерываний]({filename}../2017-01-16-seven-segment-interrupts/2017-01-16-seven-segment-interrupts.md) - немедленную обработку событий, что позволяет решать более сложные задачи, причём в случае PIC18 это даже двухуровневая система прерываний. Обычно всего этого достаточно для реализации простой логики, однако при увеличении требований к системе традиционный подход теряет привлекательность. Альтернативный метод структурирования приложений состоит в том, чтобы выделить и отделить независимые подзадачи друг от друга и использовать некий программный каркас, который управляет этими подзадачами согласно набору ясно определенных правил. При таком подходе могут одновременно выполняться несколько (псевдо)параллельных задач, сообщающихся между собой и управляемых единым ядром. Этот подход к программированию - RTOS (операционная система реального времени), а многозадачность бывает 2 видов:

 - кооперативная - следующая задача выполняется только после того, как текущая задача явно передаст управление

 - вытесняющая - планировщик операционной системы сам передает управление от одной задачи другой

Кооперативная многозадачность является наиболее простой с точки зрения реализации и хорошо подходит для слабых микроконтроллеров.

[config.h]({attach}config-4620.h) | [coroutine.h]({attach}coroutine.h) | [hex]({attach}main.hex) | [picsim.js](http://mazko.github.io/picsim.js/56fd34dfd1c731a3d6eee89ccd6ee25b)

[comment]: <> (byzanz-record --x=98 --y=100 -w 1233 -h 665 --delay 3 -d 22 ui.flv)
[comment]: <> (rm -rf frames/* && ffmpeg -i ui.flv -pix_fmt rgb24 -r 10 "frames/frame-%05d.png")
[comment]: <> (convert -monitor -limit memory 1024MiB -limit map 2048MiB -layers removeDups -delay 10 -loop 0 "frames/*.png" ui.gif)

![screenshot]({attach}ui.gif){:style="width:100%; border:1px solid #ddd;"}

Простейшую кооперативную многозадачность в чистом С можно реализовать с помощью [сопрограмм](http://www.chiark.greenend.org.uk/~sgtatham/coroutines.html){:rel="nofollow"}(coroutine). Это очень практичная и интересная реализация, где каждая функция сохраняет своё внутреннее [состояние]({filename}../../2012-10-09-finite-state-machine/2012-10-09-finite-state-machine.md) между вызовами, хитрое применением оператора ```switch``` и парочки макросов даёт возможность этой функции приостанавливаться, а при последующем вызове продолжать выполнение с предыдущего места - именно так и ведут себя сопрограммы.

*task_r.c*

    :::c
    #include <xc.h>
    #include <stdint.h>
    #include "coroutine.h"

    #define YIELD scrReturnV // just readability

    static void task_leds_r() {
      scrBegin;

      static uint8_t i, port;

      // infinite task loop
      while (1) {
        // chasing leds
        if (!port) {
          port = (1 << 7);
        } else if (port == (1 << 5)) {
          port = (1 << 2);
        } else {
          port >>= 1;
        }
        if (port) {
          PORTA &= ~0x80;
        } else {
          PORTA |= 0x80;
        }
        PORTC = (PORTC & TRISC) | port;
        for (i = 0; i < 240; i++) { 
          YIELD; /* cooperate delay */ 
        }
      }

      scrFinishV;
    }

*task_l.c*

    :::c
    #include <xc.h>
    #include <stdint.h>
    #include <stdlib.h>
    #include "coroutine.h"

    #define YIELD scrReturnV // just readability

    static void task_leds_l() {
      scrBegin;

      static uint8_t i, port;

      // infinite task loop
      while (1) {
        // chasing leds
        if (!port) {
          port = 1;
        } else {
          port <<= 1;
        }
        PORTA = (PORTA & 0x80) | port;
        for(i = 0; i < 240; i++) { 
          YIELD; /* cooperate delay */ 
        }

        // blink random leds
        if (port == (1 << 6)) {
          for (port = 7; port; port--) {
            uint8_t random6;
            do {
              random6 = 1 << /* 0..6 */ rand() % 7;
            } while (random6 == (PORTA & ~0x80));
            PORTA = (PORTA & 0x80) | random6;
            for (i = 0; i < 240; i++) { 
              YIELD; /* cooperate delay */ 
            }
          }
        }
      }

      scrFinishV;
    }

*main.c*

    :::c
    /*
      xc8 --chip=18f4620 main.c
    */

    #include <xc.h>
    #include "config-4620.h"

    // non-reentrant tasks examples

    #include "task_l.c"
    #include "task_r.c"

    int main() {
      // leds
      PORTA = TRISA = 0;
      PORTC = TRISC = 0x18;

      // simplest cooperative scheduler
      while(1) {
        task_leds_l();
        task_leds_r();
      }

      return 0;
    }

Тут две задачи - левые светодиоды и правые. Каждая задача представляет из себя бесконечный цикл - и будь это обычные функции всё процессорное время ушло бы на ```task_leds_l()```, тогда как до ```task_leds_r()``` очередь бы так и не дошла. Но мы имеем дело не с простыми функциями, а сопрограммами - макрос YIELD возвращает управление обратно вызывающей функции, а она в свою очередь просто поочерёдно вызывает задачи, выполняя тем самым функцию простейшего планировщика.

При работе с сопрограммами следует особое внимание уделять переменным. Если переменная должна сохранять своё значение между вызовами, то необходимо объявлять её ```static``` - например ```static uint8_t i, port```, в то время как к ```uint8_t random6``` это самая обычная (автоматическая) переменная.

А что произойдёт, если к этим двум задачам досыпать ещё парочку ? Очевидно, что тогда временные интервалы придётся перебирать заново:

    :::c
    // delay
    for(i = 0; i < 240 /* new value */; i++) { 
      YIELD; /* cooperate delay */ 
    }

И это плохо - такие проекты тяжело сопровождать и развивать. Существует достаточно простой способ избежать этого нежелательного эффекта, если привязать временные интервалы к какому-нибудь аппаратному таймеру. В следующем примере запускается таймер, постоянно отсчитывается время с момента включения. Это время не зависит от загрузки процессора и количества выполняемых задач.

[hex]({attach}main2.hex) | [picsim.js](http://mazko.github.io/picsim.js/a8ff2394bb5884738bbee3ce613be1ce)

*isr.c*

    :::c
    #include <xc.h>
    #include <stdint.h>

    // up time since the start of the system
    static uint32_t _uptime;

    // http://www.microchip.com/forums/m890404.aspx
    uint32_t get_uptime() {
      if (GIE) {
        GIE = 0; // critical section
        const uint32_t copy = _uptime;
        GIE = 1; // critical section end
        return copy;
      } else {
        return _uptime;
      }
    }

    // High priority interrupt
    void interrupt isr() {
      if (INTCONbits.T0IF && INTCONbits.T0IE) {                               
        INTCONbits.T0IF = 0;
        _uptime++;
      }
    }

Поскольку разрядность счётчика времени ```uint32_t``` больше разрядности микроконтроллера - операции над переменной ```_uptime``` не атомарны, поэтому в функцию ```get_uptime()``` вводится простейший механизм синхронизации через GIE. Теперь во всех задачах при формировании временных интервалов более целесообразно пользоваться функцией ```get_uptime()```:

    :::c
    static uint32_t i;

    // delay
    for (i = get_uptime() + 10; i > get_uptime();) {
      YIELD; /* cooperate delay */ 
    }

*main.c*

    :::c
    /*
      xc8 --chip=18f4620 main.c isr.c
    */

    #include <xc.h>
    #include "config-4620.h"

    // non-reentrant tasks examples

    #include "task_l.c"
    #include "task_r.c"

    int main() {
      // leds
      PORTA = TRISA = 0;
      PORTC = TRISC = 0x18;

      // TMR0 high priority Interrupt, 8 bit, 1:32 Prescale
      RCONbits.IPEN = 1;
      T0CON = 0;
      T0CONbits.T08BIT = 1;
      T0CONbits.T0PS2 = 1;
      INTCONbits.T0IE = 1;
      INTCONbits.T0IF = 0;
      INTCON2bits.TMR0IP = 1;        
      T0CONbits.TMR0ON = 1;
      INTCONbits.GIE = 1;

      // simplest cooperative scheduler
      while(1) {
        task_leds_l();
        task_leds_r();
      }

      return 0;
    }

Несмотря на свою простоту описанное решение характеризуется прекрасной переносимостью - тут чистый С без ассемблерных вставок и оно вполне подходит для реальных проектов и особенно хорошо подходит для очень слабых микроконтроллеров.

[Далее]({filename}../2017-02-14-rpn/2017-02-14-rpn.md) калькулятор выражений в обратной польской нотации.