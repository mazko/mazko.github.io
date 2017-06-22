title:  С++ для микроконтроллеров - «Декоратор»
category: Embedded 
tags: msp430, Паттерн


> Есть два способа создания дизайна программы. Один из них, это сделать его настолько простым, что в нем, очевидно, не будет недостатков. Другой способ — сделать его настолько запутанным, что в нем не будет очевидных недостатков. — C.A. R. Hoare


«Приемы объектно-ориентированного проектирования. Паттерны проектирования» — эпохальная книга 1994 года об инженерии программного обеспечения, описывающая решения некоторых частых проблем в проектировании ПО. Коллектив авторов Э. Гамма, Р. Хелм, Р. Джонсон, Дж. Влиссидес также известен как «Банда четырёх», Gang of Four, GoF.

GoF даёт следующее классическое определение: декоратор (англ. Decorator) — паттерн, структурирующий объекты. Динамически добавляет объекту новые обязанности. Является гибкой альтернативой порождению подклассов с целью расширения функциональности.

Объект, который предполагается использовать (в нашем случае [слой]({filename}../2017-03-20-mcucpp-introduction/2017-03-20-mcucpp-introduction.md) для лампочек), выполняет основные функции. Однако может потребоваться добавить к нему некоторую дополнительную функциональность ([анимации]({filename}../2017-03-20-mcucpp-introduction/2017-03-20-mcucpp-introduction.md)), которая будет выполняться до, после или даже вместо основной функциональности объекта.

[comment]: <> (byzanz-record --x=397 --y=124 -w 635 -h 636 --delay 3 -d 33 ui.flv)
[comment]: <> (rm -rf frames/* && ffmpeg -i ui.flv -pix_fmt rgb24 -r 10 "frames/frame-%05d.png")
[comment]: <> (ls -1 frames/frame-*.png | xargs -I{} -n1 convert -size 636x636  xc:none -fill {} -draw "circle 318,318 318,1" r_{})
[comment]: <> (convert -monitor -limit memory 1024MiB -limit map 2048MiB -layers removeDups -layers Optimize -delay 10 -loop 0 "r_frames/*.png" ui.gif)

![screenshot]({attach}ui.gif){:style="width:50%; margin: 0 auto; display:block;"}

Поскольку анимации и их последовательность заранее известны на этапе компиляции, декоратор легко реализуется на С++ шаблонах. Такая реализация позволяет не использовать виртуальные функции и будет занимать больше памяти ROM (code bloat), но работать должна шустрее - хотя для мигающих лампочек это не критично. Ещё использование шаблонов даёт удобную возможность делать простые проверки `static_assert()` на этапе компиляции. Нечто подобное [можно]({filename}../../2012-10-08-ansi-c-idioms/2012-10-08-ansi-c-idioms.md) конечно же соорудить и на Си с помощью макросов, но в С++ `static_assert()` это уже встроенный и весьма полезный механизм так что не приходится заново изобретать велосипед.

Все классы для создания анимаций реализуют интерфейс Декоратора - методы `void draw(RgbStripLayer& layer);` и `void set_color(const auto& co)`. Работая в цепочке каждый последовательно добавляет (декорирует) к слою `RgbStripLayer` новые свойства. Эти классы взаимозаменяемы, их последовательность определяет конкретную анимацию. В прилагаемых исходниках добавлено больше анимаций плюс пример использования стандартной библиотекой шаблонов (STL) в С++ - алгоритм `std::rotate` для массивов.

[elf]({attach}a.out) | [MSP430.js](http://mazko.github.io/MSP430.js/3523e01e3e6c96088d0ac6a4c335609b) | [исходники]({attach}src.zip)

*app.cpp*

    :::cpp

    #include "animation.h"

    namespace app {

        using namespace animation;

        constexpr auto SZ = RgbStripLayer::STRIP_SZ;

        int run() {

            RgbStripLayer l1;

            for (;;) {
                EachColor< DynFill< 0, SZ - 1, Flush< Sleep< 55555, Nop >>>>().draw(l1);
                EachColor< FillCW< Sleep< 4444, Flush<> >>>().draw(l1);
                EachColor< FillCCW< Sleep< 4444, Flush<> >>>().draw(l1);
            }

            return 0;
        }
    }

*animation.h*

    :::cpp

    #include "rgb.h"

    namespace animation {

        using namespace rgb;

        struct Nop : NonCopyable {
            void draw(RgbStripLayer& layer) {}
        };

        template<class A = Nop>
        class Flush : NonCopyable {
            A m_stream;
        public:
            void draw(RgbStripLayer& layer) {
                layer.flush();
                m_stream.draw(layer);
            }
        };

        template<const std::int32_t cycles, class A>
        class Sleep : NonCopyable {
            A m_stream;
        public:
            void draw(RgbStripLayer& layer) {
                static_assert(cycles > 0);
                __delay_cycles(cycles);
                m_stream.draw(layer);
            }
        };

        template<class A, const RgbStripLayer::RGB& c = RgbStripLayer::RED>
        class FillCW : NonCopyable /* clockwise */ {
            A m_stream;
            RgbStripLayer::RGB m_color = c;
        public:
            void draw(RgbStripLayer& layer) {
                for (auto& m : layer.mem) {
                    m = m_color;
                    m_stream.draw(layer);
                }
            }

            void set_color(const auto& co) {
                m_color = co;
            }
        };

        template<class A, const RgbStripLayer::RGB& c = RgbStripLayer::RED>
        class FillCCW : NonCopyable /* counterclockwise */ {
            A m_stream;
            RgbStripLayer::RGB m_color = c;
        public:
            void draw(RgbStripLayer& layer) {
                // while a pointer is a form of iterator,
                // not all iterators have the same functionality of pointer
                for (auto it = layer.mem.rbegin(); it != layer.mem.crend(); it++) {
                    *it = m_color;
                    m_stream.draw(layer);
                }
            }

            void set_color(const auto& co) {
                m_color = co;
            }
        };

        template<class A>
        class EachColor : NonCopyable {
            A m_stream;
            static constexpr auto colors = {
                RgbStripLayer::RED,    RgbStripLayer::GREEN,
                RgbStripLayer::BLUE,   RgbStripLayer::YELLOW,
                RgbStripLayer::VIOLET, RgbStripLayer::CYAN,
                RgbStripLayer::WHITE,  
            };

        public:
            void draw(RgbStripLayer& layer) {
                for (const auto& c : colors) {
                    m_stream.set_color(c);
                    m_stream.draw(layer);
                }
            }
        };

        template<const std::int8_t f, const std::int8_t l, class A>
        class DynFill : NonCopyable {
            A m_stream;
            RgbStripLayer::RGB m_color = RgbStripLayer::RED;
        public:
            void draw(RgbStripLayer& layer) {
                static_assert(f >= 0);
                static_assert(l > f);
                static_assert(l < layer.mem.size());
                for (auto i = f; i <= l; i++) {
                    layer.mem[i] = m_color;
                }
                m_stream.draw(layer);
            }

            void set_color(const auto& co) {
                m_color = co;
            }
        };
    }

Применение паттернов и ООП в микроконтроллерах имеет свою специфику, накладываемую в основном моделью управления памятью. Неважно на чём писать — Си или С++ для встраиваемых систем предпочтительней использовать память в стеке т.к. она проверяется компилятором. В свою очередь динамическое выделение памяти на куче **не проверяется компилятором** и как следствие её наличие в нужный момент времени выполнения программы не гарантируется. ООП же больше любит динамическое выделение памяти — операторы `new`, `malloc`, умные указатели. Не стоит этого всего использовать в микроконтроллерах без ясного понимания возможных последствий.

[Далее]({filename}../2017-06-22-mcucpp-memory/2017-06-22-mcucpp-memory.md) игра «Змейка» где работа с памятью будет описана более подробно.