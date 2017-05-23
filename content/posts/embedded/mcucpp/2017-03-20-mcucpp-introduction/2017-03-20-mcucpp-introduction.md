title:  С++ (18+) для микроконтроллеров - разведка боем
category: Embedded 
tags: msp430

> Большинство С++ программистов не знают, что делает большинство С++ программистов. — Андрей Александреску

Программы для микроконтроллеров де-факто [пишутся]({filename}../../picsim/2017-01-13-picsim-introduction/2017-01-13-picsim-introduction.md) либо на Си либо на ассемблере. Си это процедурный язык программирования со статической слабой типизацией, обладающий простым и понятным синтаксисом, высокой переносимостью (в сравнении с ассемблером), он хорошо подходит для системного программирования и в конце-концов успешно прошел испытание временем. И если у Си всё так хорошо, зачем все ведущие производители микроконтроллеров (PIC32, MSP430, AVR) дружно подтянули в свои инструментарии для разработчиков C++ компиляторы ? В отличие от своего предшественника Си, C++ декларирует поддержку различных парадигм программирования — процедурное, объектно-ориентированное (ООП), обобщённое (шаблоны). Вместе с тем C++ не является серебряной пулей для решения проблем своего предшественника — ручное управление памятью по-прежнему на плечах программиста. C++ добавляет к Си объектно-ориентированные возможности — вводятся классы, которые обеспечивают три самых важных свойства ООП: инкапсуляцию, наследование и полиморфизм. ООП при грамотном использовании призвано повысить производительность труда программистов, чему посвящено немало различной литературы на любой вкус и цвет.

Если отбросить религиозные пристрастия, то стоит признать, что на данный момент C++ это единственный нативный язык без GC (garbage collector), который позволяет легко переключаться от самого низкого уровня, близкого к аппаратуре, до очень высокого, вроде ООП и обобщенного программирования. При этом данный язык снабжен широким набором инструментария, книг и документации, различных интернет-ресурсов. Плюс огромное количество разработчиков во всем мире.

[comment]: <> (byzanz-record --x=397 --y=124 -w 635 -h 636 --delay 3 -d 25 ui.flv)
[comment]: <> (rm -rf frames/* && ffmpeg -i ui.flv -pix_fmt rgb24 -r 10 "frames/frame-%05d.png")
[comment]: <> (ls -1 frames/frame-*.png | xargs -I{} -n1 convert -size 636x636  xc:none -fill {} -draw "circle 318,318 318,1" r_{})
[comment]: <> (convert -monitor -limit memory 1024MiB -limit map 2048MiB -layers removeDups -layers Optimize -delay 10 -loop 0 "r_frames/*.png" ui.gif)

![screenshot]({attach}ui.gif){:style="width:50%; margin: 0 auto; display:block;"}

Запускаться будем на микроконтроллерах MSP430, компилятор как обычно на сайте [производителя](http://www.ti.com/tool/msp430-gcc-opensource){:rel="nofollow"}. MSP430 — семейство 16-разрядных микроконтроллеров фирмы «Texas Instruments», которые имеют фон-Неймановскую архитектуру с единым адресным пространством для команд и данных (для сравнения у Microchip [PIC]({filename}../../picsim/2017-01-13-picsim-introduction/2017-01-13-picsim-introduction.md) и Atmel AVR Гарвардская архитектура).

C++ в большинстве случаев обратно совместим со своим предшественником, так что поначалу всё выглядит как в старом добром Си и совсем нестрашно. Частота микроконтроллеров MSP430 задаётся программно и может меняться в процессе выполнения для снижения энергопотребления. Сетка частот встроенного тактового генератора описана в [документации](http://www.ti.com/lit/ds/symlink/msp430f1611.pdf){:rel="nofollow"} - регистры RSEL служат для грубой настройки, DCO для более точной. Микроконтроллер msp430f1611 имеет шесть восьмибитных портов ввода-вывода, а шесть делится на три и получаем 16 RGB светодиодов.

[elf]({attach}a.out) | [MSP430.js](http://mazko.github.io/MSP430.js/6f9f42f42b3dbdb860b36607e12e34cf) | [исходники]({attach}src.zip)

*main.cpp*

    :::cpp

    /*
    reset && (export GCC_DIR=~/ti/msp430_gcc ; 
        $GCC_DIR/bin/msp430-elf-c++ \
        -I $GCC_DIR/include -L $GCC_DIR/include \
        -Werror -Wall -mmcu=msp430f1611 -O2 *.cpp)
    */

    #include <msp430.h>
    #include "app.h"

    int main(void) {
        WDTCTL = WDTPW | WDTHOLD;     // Stop watchdog timer

        // DCO = 3, RSEL = 0, f = 0.13 MHz
        DCOCTL = /* DCO2 + */ DCO1 + DCO0; 
        BCSCTL1 = XT2OFF /* + RSEL1 + RSEL0 + RSEL2 */;

        constexpr auto O = 0;

        P1OUT = O; P2OUT = O; P3OUT = O; P4OUT = O; P5OUT = O; P6OUT = O;
        P1DIR = P2DIR = P3DIR = P4DIR = P5DIR = P6DIR = 0xFF;

        return app::run();
    }

Тут в коде три интересных момента, касающихся С++:

- `constexpr` - константа на этапе компиляции, в отличие от `const` не занимает физический адрес в памяти

- `auto` - автоматическое выведение типа на этапе компиляции исходя из присваиваемого значения

- `app::run()` - вызов метода из пространства имён app

*app.h*

    :::cpp

    namespace app {
        int run();
    }

*app.cpp*

    :::cpp

    #include <initializer_list>
    #include "rgb.h"

    namespace app {

        int run() {

            // rgb_strip: default initialization
            rgb::RgbStripLayer rgb_strip;

            constexpr auto colors = {
                rgb_strip.RED,    rgb_strip.GREEN,
                rgb_strip.BLUE,   rgb_strip.YELLOW,
                rgb_strip.VIOLET, rgb_strip.CYAN,
                rgb_strip.WHITE,  rgb_strip.BLACK
            };

            for (;;) {
                for (const auto& c : colors) {
                    for (auto& m : rgb_strip.mem) {
                        m = c;
                        rgb_strip.flush();
                        __delay_cycles(10000);
                    }
                }
            }
            return 0;
        }
    }

- функция `run` находится в пространстве имён `namespace app` - в пределах одного пространства имён идентификаторы (имена) должны быть уникальны, тогда как один и тот же идентификатор может быть определён в нескольких пространствах имён

- для переменной `rgb_strip` отсутствует выражение инициализации и поэтому происходит инициализация по умолчанию - для классов, структур и объединений это инициализация с помощью конструктора по умолчанию (до классов мы ещё дойдём)

- цикл по контейнеру `for (const auto& c : colors)` позволяет пройтись по всем элементам без явного указания индекса и стало быть без ошибок, связанных с неправильным индексом за пределами контейнера

- С++ даёт возможность программисту избегать лишних звёздочек - доступ к переменным по ссылке `auto& c` обычно безопаснее и более строго проверяется компилятором чем через разыменовывание указателя `*с` в стиле Си

*hal.h*

    :::cpp
    #include "pin.h"
    #include <msp430.h>
    #include <cstdint>

    namespace pin {
        // MSP430 aliases
        using msp430_port_t = decltype(P1OUT);
        using msp430_pin_t = Pin<msp430_port_t, std::uint8_t>;
    }

- `using msp430_port_t = decltype(P1OUT);` - псевдоним типа, в данном случае можно было бы спокойно заменить на Cи `typedef decltype(P1OUT) msp430_port_t` - это дело вкуса и стиля
 
- `decltype(P1OUT)` - в большинстве случаев нам не нужно знать какой там именно у микроконтроллера порт - 8, 16 или 32 бит, но его тип нам понадобится т.к. проверку типов на этапе компиляции никто не отменял

- `Pin<msp430_port_t, std::uint8_t>` - псевдоним шаблона, кто это такой и зачем он нужен станет понятно чуть дальше

*non-copyable.h*

    :::cpp

    // C++ compile time check idiom: Non-Copyable Class
    // TODO: inheritance approach bloats the code size
    class NonCopyable {
    protected:
        NonCopyable(NonCopyable const&) = delete;
        NonCopyable& operator=(NonCopyable const&) = delete;
        NonCopyable() = default;
    };

Конструктор копирования... В вежливой форме предлагаю его сразу отключать и забыть - для этого достаточно просто наследовать классы от класса `NonCopyable`. В таком случае кривой код, пытающийся создать побитовую копию объекта просто сломает компиляцию и это правильно.

*rgb.h*

    :::cpp
    #include "hal.h"
    #include <array>

    namespace rgb {

        using namespace pin;

        class RgbStripLayer : NonCopyable {

            template<msp430_port_t& p1, msp430_port_t& p2> struct MonoStrip;
            static MonoStrip<P1OUT, P2OUT> red;
            static MonoStrip<P3OUT, P4OUT> green;
            static MonoStrip<P5OUT, P6OUT> blue;

        public:
            // mem: value initialization
            RgbStripLayer(): mem() {}

            static constexpr std::size_t STRIP_SZ = 2*8;

            struct RGB {
                bool r, g, b;
            };

            std::array<RGB, STRIP_SZ> mem;

            static constexpr RGB RED = { 1, 0, 0 }, GREEN  = { 0, 1, 0 }, 
                             BLUE    = { 0, 0, 1 }, YELLOW = { 1, 1, 0 }, 
                             CYAN    = { 0, 1, 1 }, VIOLET = { 1, 0, 1 }, 
                             WHITE   = { 1, 1, 1 }, BLACK  = { 0 };

            void flush();

            RgbStripLayer& operator += (const RgbStripLayer& layer);
        };
    }

Итак ООП.

 - все поля и методы классов `class` (а также структур `struct`) имеют права доступа - по умолчанию все содержимое класса является доступным для чтения и записи только для него самого т.е. закрыто (private), а для структуры `struct` наоборот по умолчанию всё открыто для всех (public)

 - поля red, green, blue в классе `RgbStripLayer` (слой анимации) статические - все экземпляры этого класса используют одну и ту же копию этих полей и тем самым экономится память RAM

 - `std::array` - это контейнер для массива фиксированного размера, имеет ту же семантику, что и Cи массивы плюс знает собственный размер, поддерживает присваивание, итераторы и т.д.

- методы, совпадающие с именем класса это конструкторы, `RgbStripLayer(): mem() {}` это конструктор по умолчанию т.к. не содержит аргументов, в нашем случае в конструкторе контейнер `mem` инициализируется нулями

 - слои анимаций `RgbStripLayer` можно смешивать между собой - для этого перегружен оператор `+=`

*rgb.cpp*

    :::cpp
    #include "rgb.h"

    namespace rgb {

        template<msp430_port_t& p1, msp430_port_t& p2>
        struct RgbStripLayer::MonoStrip : NonCopyable {
            msp430_pin_t leds[STRIP_SZ] = {
                { p1, 0 }, { p1, 1 }, { p1, 2 }, { p1, 3 },
                { p1, 4 }, { p1, 5 }, { p1, 6 }, { p1, 7 },
                { p2, 0 }, { p2, 1 }, { p2, 2 }, { p2, 3 },
                { p2, 4 }, { p2, 5 }, { p2, 6 }, { p2, 7 },
            };
        };

        decltype(RgbStripLayer::red) RgbStripLayer::red;
        decltype(RgbStripLayer::green) RgbStripLayer::green;
        decltype(RgbStripLayer::blue) RgbStripLayer::blue;

        void RgbStripLayer::flush() {
            for (auto i = mem.size(); i--;) {
                red.leds[i].set(mem[i].r);
                green.leds[i].set(mem[i].g);
                blue.leds[i].set(mem[i].b);
            }
        }

        RgbStripLayer& RgbStripLayer::operator += (const RgbStripLayer& layer) {
            for (auto i = mem.size(); i--;) {
                mem[i].r |= layer.mem[i].r;
                mem[i].g |= layer.mem[i].g;
                mem[i].b |= layer.mem[i].b;
            }

            return *this;
        }
    }

- объявление класса и реализация в отдельных файлах в С++ не является обязательной, однако позволяет при необходимости ускорить сборку проекта за счёт т.н. раздельной компиляции - также как и в Си собственно

 - шаблоны C++ позволяют задавать обобщённые алгоритмы без привязки к некоторым параметрам - в случае c `MonoStrip` это конкретные порты ввода вывода p1, p2 различные у каждого цвета, код шаблона сгенерируется на этапе компиляции и в этом они схожи с макросами Си

 - каждый класс в C++ использует свое пространство имен, если внутри класса записано только объявление, реализация должна быть определена в другом месте с помощью операции доступа к области видимости ::

 Ну и последний класс он совсем простой - каждая нога микроконтроллера это объект. За счёт использования шаблонов класс Pin ничего не знает об архитектуре микроконтроллера - тип данных порта ввода-вывода является параметром шаблона:

*pin.h*

    :::cpp
    #include "non-copyable.h"

    namespace pin {
        template<typename port_t, typename pos_t>
        class Pin : NonCopyable {
            port_t& m_port;
            const port_t m_mask;
        public:
            Pin(port_t& port, const pos_t pos): m_port(port), m_mask(1 << pos) {}

            void set(const bool v = true) {
                if (v) {
                    m_port |= m_mask;
                } else {
                    clr();
                }
            }

            void clr() {
                m_port &= ~m_mask;
            }
        };
    }

 - если тело метода определено при объявлении класса, метод автоматически являются встроенным (inline) - обычно встроенными делают короткие методы

 - аргументы функций в С++ могут иметь значения по умолчания как например `const bool v = true` , это же можно было бы сделать и с помощью перегрузки функций

[Далее]({filename}../2017-03-22-mcucpp-decorator/2017-03-22-mcucpp-decorator.md) паттерн декоратор.