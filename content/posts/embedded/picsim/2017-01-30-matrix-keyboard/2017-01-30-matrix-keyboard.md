title:  PICSim.js - матричная клавиатура
category: Embedded 
tags: picsim

Матричная клавиатура состоит и [обычных]({filename}../2017-01-13-picsim-introduction/2017-01-13-picsim-introduction.md) кнопок, только соединённых в определённом порядке - сгруппированных в ряды и столбцы, образуя матрицу. Такое включение позволяет опрашивать большее количество кнопок, задействовав при этом меньшее количество ног микроконтроллера - например для считывания 16 простых кнопок понадобилось бы целых два 8-битных порта ввода, тогда как матрицирование позволяет обойтись всего одним т.к. ```4*4=16```.

Матричная клавиатура на рисунке подключена к порту PORTB, все ноги подтянуты резисторами к напряжению питания - т.е. читаются как 1 если ничего не нажато. Алгоритм опроса матричной клавиатуры на 16 кнопок сводится к следующим шагам:

 - инициализация - четыре сканирующие ноги RB0...RB3 на выход, четыре считывающие RB4...RB7 на вход. Ничто не запрещает поменять сканирующие/считывающие выводы, только после этого нужно поменять пару строчек в приведенной ниже функции ```_keyboard_scan()```

 - опрос - на первой итерации выставляется ноль на RB0, на RB1..RB3 единицы, если это привело к посадке подтягивающего напряжения например на входе RB5, это указывает на нажатие кнопки 3. Если пересечение не найдено, итерация продолжается - теперь уже RB1 в ноль, ```RB0=RB2=RB3=1``` и так вплоть до RB3

[config.h]({attach}config-4620.h) | [liquid-crystal.c]({filename}../2017-01-27-hd44780/2017-01-27-hd44780.md) | [hex]({attach}main.hex) | [picsim.js](http://mazko.github.io/picsim.js/8ec71b12144755531dd59a243e3061bb)

[comment]: <> (byzanz-record --x=97 --y=100 -w 1235 -h 665 --delay 3 -d 22 ui.flv)
[comment]: <> (rm -rf frames/* && ffmpeg -i ui.flv -pix_fmt rgb24 -r 10 "frames/frame-%05d.png")
[comment]: <> (convert -monitor -limit memory 1024MiB -limit map 2048MiB -layers removeDups -delay 10 -loop 0 "frames/*.png" ui.gif)

![screenshot]({attach}ui.gif){:style="width:100%; border:1px solid #ddd;"}

Работа с символьным дисплеем описывалась в предыдущем [материале]({filename}../2017-01-27-hd44780/2017-01-27-hd44780.md). Тут размер массива на этапе компиляции определяется с помощью расписанной ранее [идиомы]({filename}../../2012-10-08-ansi-c-idioms/2012-10-08-ansi-c-idioms.md) ```sizeof x / sizeof x[0]```. Функция считывания клавиши ```keyboad_get_or_0()``` неблокирующая - если клавиша нажата (после чего отпущена), возвращается код символа, если же ничего не нажато, возвращается 0. Неблокирующую функцию всегда можно сделать при желании блокирующей, если поместить в цикл, а вот с блокирующими функциями не всё так просто.

*keyboard.c*

    :::c

    #include <xc.h>
    #include <stdint.h>

    static char _keyboard_scan() {

      const char key_code[4][4] = {
        {'1','2','3','+'},
        {'4','5','6','-'},
        {'7','8','9','/'},
        {'*','0','#','$'}};

      for(uint8_t r = 0; r < sizeof key_code / sizeof *key_code; r++) {
        // set PORTB and some delay for voltage to rise / fall
        PORTB = ~(1 << r);
        __delay_ms(1);

        for(uint8_t c = 0; c < sizeof *key_code / sizeof **key_code; c++) {
          if (!(PORTB & (0x80 >> c))) {
            return key_code[r][c];
          }
        }
      }

      return 0;
    }

    char keyboad_get_or_0() {
      static char _last_key;

      const char key = _keyboard_scan();
      if (key) {
        _last_key = key;
      } else if (_last_key) {
        const char key = _last_key;
        _last_key = 0;
        return key;
      }
      return 0;
    }

*main.c*

    :::c
    /*
      xc8 -Werror --chip=18f4620 main.c
    */

    #define _XTAL_FREQ 5e4

    #include <xc.h>
    #include "config-4620.h"

    #include "liquid-crystal.c"
    #include "keyboard.c"

    int main() {
      // lcd
      PORTD = TRISD = 0;
      PORTE = TRISE = 0;

      // matrix keyboard: PORTB AN8..AN12 as digital
      ADCON1bits.PCFG0 = ADCON1bits.PCFG1 =
      ADCON1bits.PCFG2 = 1;
      PORTB = TRISB = 0xF0;

      lcd_init();
      lcd_no_cursor();
      lcd_no_blink();
      lcd_print("Keyboard:");
      lcd_set_cursor(0, 1); // row 2

      while(1) {
        const char key = keyboad_get_or_0();
        if (key) {
          lcd_dat(key);
        }
      }

      return 0;
    }

Алгоритм, используемый в матричной клавиатуре, прекрасно масштабируется в сторону увеличения - например 8 бит для считывания и 8 для сканирования даст ```8*8=64``` комбинации, это один порт ввода-вывода для 16-битных pic24 или два порта для pic18...pic10 микроконтроллеров. В теории матричная клавиатура несколько уступает по скорости сканирования простым кнопкам и расходует какую-то незначительную чать процессорного времени, но всё это с лихвой компенсируется более рациональным использованием портов ввода вывода. 

[Далее]({filename}../2017-02-02-rtc/2017-02-02-rtc.md) часы реального времени.