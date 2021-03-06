title:  С++ для микроконтроллеров - «Наблюдатель»
category: Embedded 
tags: msp430, Паттерн


Продолжаем присматриваться к [C++ для микроконтроллеров]({filename}../2017-03-20-mcucpp-introduction/2017-03-20-mcucpp-introduction.md).

Наблюдатель – это [паттерн]({filename}../2017-03-22-mcucpp-decorator/2017-03-22-mcucpp-decorator.md) проектирования, который создаёт механизм подписки, позволяющий одним объектам следить и реагировать на события, происходящие в других объектах. Данный шаблон часто применяют в ситуациях, в которых отправителя сообщений не интересует, что делают получатели с предоставленной им информацией.

[GoF]({filename}../2017-03-22-mcucpp-decorator/2017-03-22-mcucpp-decorator.md) даёт следующее классическое определение: наблюдатель (англ. Observer) – паттерн поведения объектов. Определяет зависимость типа «один ко многим» между объектами таким образом, что при изменении состояния одного объекта все зависящие от него оповещаются об этом и автоматически обновляются.

Аналогия из жизни: после того как вы оформили подписку на газету или журнал, вам больше не нужно ездить в супермаркет и проверять, не вышел ли очередной номер. Вместо этого, издательство будет присылать новые номера сразу после выхода прямо к вам домой. Издательство ведёт список подписчиков и знает, кому какой журнал слать. Вы можете в любой момент отказаться от подписки, и журнал перестанет к вам приходить.


[MSP430.js](http://mazko.github.io/MSP430.js/8490b771b5c0189e639726f219cb2b16) | [исходники]({attach}msp430-observer.zip)

[comment]: <> (byzanz-record --x=313 --y=132 -w 803 --delay 3 -d 55 ui.flv)
[comment]: <> (rm -rf frames/* && ffmpeg -i ui.flv -pix_fmt rgb24 -r 10 "frames/frame-%05d.png")
[comment]: <> (convert -monitor -limit memory 1024MiB -limit map 2048MiB -layers Optimize -layers removeDups -delay 10 -loop 0 "frames/*.png" ui.gif)

![screenshot]({attach}ui.gif){:style="width:55%; margin: 0 auto; display:block;"}

Давайте называть «издателями» те объекты, которые содержат важное или интересное для других состояние. Остальные объекты, которые хотят отслеживать изменения этого состояния, назовём «подписчиками».

Паттерн «Наблюдатель» предлагает хранить внутри объекта «издателя» (контейнера) список ссылок на объекты «подписчиков». Причём, «издатель» не должен вести список подписки самостоятельно. Он должен предоставить методы, с помощью которых «подписчики» могли бы добавлять или убирать себя из списка.

Когда в «издателе» будет происходить важное событие, он будет проходиться по списку «подписчиков» и оповещать их об этом, вызывая определённый метод объектов-подписчиков.

*observers/state.h*

    :::cpp
    #include "DoublyLinkedList.h"
    #include "non-copyable.h"

    namespace obsevers {

        // alias
        template<class T> using DLLE = mozilla::DoublyLinkedListElement<T>;

        namespace state {

            typedef enum {
                left_active,
                left_sleep
            } state_t;

            struct IObserver : public DLLE<IObserver>, NonCopyable
            {
                virtual void observe(state_t) = 0;
            };


            class Container : NonCopyable
            {
                mozilla::DoublyLinkedList<IObserver> mList;

            public:
                void addObserver(IObserver* aObserver)
                {
                    // Will assert if |aObserver| is part of another list.
                    mList.pushFront(aObserver);
                }

                void removeObserver(IObserver* aObserver)
                {
                    // Will assert if |aObserver| is not part of |list|.
                    mList.remove(aObserver);
                }

                void notifyObservers(state_t aState)
                {
                    for (IObserver& o : mList) {
                        o.observe(aState);
                    }
                }
            };

            extern Container event;
        }
    }

В приведенной реализации «подписчики» образуют двусвязный список, что позволяет обойтись без динамического выделения памяти. Почему это важно для микроконтроллеров описано [тут]({filename}../2017-03-22-mcucpp-decorator/2017-03-22-mcucpp-decorator.md). Используется готовая реализация двусвязного списка взятая из исходников mozilla.

Шаблон «Наблюдатель» работает синхронно. Обычно выделяется главный цикл приложения, тело которого состоит из двух частей: выборки события и обработки события. Как правило, в реальных задачах оказывается недопустимым длительное выполнение обработчика события, поскольку при этом программа не может реагировать на другие события.

*app.cpp*

    :::cpp
    #include "app.h"
    #include "hal.h"
    #include "observers/buttons.h"
    #include "observers/state.h"
    #include "tasks/left.h"
    #include "tasks/right.h"
    #include "tasks/counter.h"

    using namespace obsevers;

    buttons::Container obsevers::buttons::event;
    state::Container   obsevers::state::event;

    namespace app {

        int run() {

            tasks::left::start();
            tasks::right::start();
            tasks::counter::start();

            char lastBtns = 0;
            volatile uint16_t longPress = 0; // TODO: use timer
            state::state_t lastState = state::left_sleep;

            for (;;) {

                char btns = hal::get_buttons();

                if (!lastBtns && btns) {
                    buttons::event.notifyObservers(btns);
                }

                if (btns & 1 /* left first button */) {
                    if (longPress && !--longPress) 
                    {
                        switch (lastState) {
                            case state::left_active:
                                lastState = state::left_sleep;
                                break;
                            case state::left_sleep:
                                lastState = state::left_active;
                                break;
                        }
                        state::event.notifyObservers(lastState);
                    }
                } else {
                    longPress = 5000;
                }

                lastBtns = btns;

                // other events like timer e.t.c...
            }

            return 0;
        }
    }

В данном примере два события: изменение состояния и нажатие на кнопки. При изменении состояния (длительное нажатие) левые лампочки динамически подписываются / отписываются от события нажатия на кнопки. Правые лампочки и счётчик нажатий подписаны на событие кнопок всегда.

Никогда не полагайтесь на определенный порядок оповещения «подписчиков». Метод `addObserver` класса `state::Container` добавляет нового «подписчика» в начало связного списка. А если добавлять не в начало а в конец ? Какой порядок считать правильным ? **Любой**. Нужно писать код таким образом, чтобы порядок обхода «подписчиков» никак не влиял на поведение программы. Чем меньше компоненты системы знают друг о друге, тем проще их изменять и развивать. О силе слабых связей чуть ниже.

*tasks/left.cpp*

    :::cpp
    #include "left.h"
    #include "color-observer.h"
    #include "observers/state.h"
    #include "draw.h"
    #include "hal.h"

    using namespace obsevers;
    using namespace tasks;

    class LockerObserver : public state::IObserver {

        ColorObserver<hal::LeftLeds, 1, 2, 3, 0> o;

        void observe(state::state_t aState) override {
            switch (aState) {
                case state::left_active:
                    str("left subscribed  ");
                    buttons::event.addObserver(&o);
                    break;
                case state::left_sleep:
                    str("left unsubscribed");
                    buttons::event.removeObserver(&o);
                    break;
            }
        }

        public: 
            void str(const char* str) {
              draw::str(draw::PAGE_0, str);
            }
    };

    static LockerObserver observer;

    namespace tasks {
        namespace left {
            void start() {
                observer.str("left unsubscribed");
                state::event.addObserver(&observer);
            }
        }
    }

Если объекты могут взаимодействовать, не обладая практически никакой информацией друг о друге, такие объекты называют слабосвязанными. Единственное, что знает «издатель» о «подписчиках», – то, что они реализует некоторый интерфейс (IObserver). Ему не нужно знать ни конкретный класс «подписчика», ни его функциональность. Добавление новых типов «подписчиков» не требует модификации «издателя». 

На базе слабосвязанных архитектур строятся гибкие системы, которые хорошо адаптируются к изменениям благодаря минимальным зависимостям между объектами.

> Есть всего два типа языков программирования: те, на которые люди всё время ругаются, и те, которые никто не использует. — Bjarne Stroustrup

Как вы думаете, что выведет следующая команда ?

    :::text
    ~$ strings a.out | grep alloc
    # output
    lib_a-malloc.o
    lib_a-nano-mallocr.o
    malloc
    _malloc_r
    __malloc_sbrk_start
    __malloc_free_list

Как только мы начали использовать **виртуальные функции**, компилятор решил помочь и молча добавил в исполняемый файл `malloc` и это [явно не то]({filename}../2017-03-22-mcucpp-decorator/2017-03-22-mcucpp-decorator.md), что мы хотим использовать в микроконтроллерах. Можно ли это как-то обойти ?

У нас тут GCC-подобный компилятор, компоновщик которого позволяет ставить свои обёртки на интересующие функции. Можно попробовать сломать компиляцию при вызове функций динамического выделения памяти `malloc`, `calloc`, `realloc`, `free`:

    -fno-builtin -Wl,--wrap=malloc  -Wl,--wrap=calloc \
                 -Wl,--wrap=realloc -Wl,--wrap=free -Wl,--wrap=sbrk

Теперь при вызове `malloc` будет вызвана `__wrap_malloc` и т.д. Поскольку мы не предоставляем реализацию `__wrap_malloc`, компиляция сломается. Если же `malloc` нигде не вызывается в коде компилятор выдаст прошивку.

[MSP430.js](http://mazko.github.io/MSP430.js/9bdb1cd8da54384ba5b6211ea135b7f8) | [исходники]({attach}msp430-observer-static-polymorphism.zip)

В старом добром Cи полиморфизм представлен в виде указателей на функции. Наиболее распространенное применение указателей на функции в Cи – это использование библиотечных функций, таких как qsort. Реализация указателей на функции проста: это всего лишь «указатели на код», в них содержится начальный адрес участка ассемблерного кода. Различные типы указателей существуют лишь для уверенности в корректности применяемого соглашения о вызове.

*observers/state.h*

    :::cpp
    #include "DoublyLinkedList.h"
    #include "non-copyable.h"

    namespace obsevers {

        // alias
        template<class T> using DLLE = mozilla::DoublyLinkedListElement<T>;

        namespace state {

            typedef enum {
                left_active,
                left_sleep
            } state_t;

            class Observer : public DLLE<Observer>, NonCopyable
            {
                typedef void (*ObserveFunc) (state_t, Observer*);

                ObserveFunc m_observe_func_ptr;

            public:
                void observe(state_t aState) {
                    (*m_observe_func_ptr)(aState, this);
                }

                Observer(ObserveFunc f): m_observe_func_ptr(f){}
            };

            template<class T>
            class Adapter : public Observer
            {
                T m_observer_impl;

            public:
                Adapter(): Observer(
                    [](state_t aState, Observer* aThis)
                    {
                        auto self = static_cast<Adapter*>(aThis);
                        self->m_observer_impl.observe(aState);
                    }){/* empty constructor */}
            };
        }
    }

*tasks/left.cpp*

    :::cpp
    #include "left.h"
    #include "color-observer.h"
    #include "observers/state.h"
    #include "draw.h"
    #include "hal.h"

    using namespace obsevers;
    using namespace tasks;

    static void str(const char* str) {
        draw::str(draw::PAGE_0, str);
    }

    struct LockerObserver : NonCopyable {

        buttons::Adapter<ColorObserver<hal::LeftLeds, 1, 2, 3, 0>> o;

        void observe(state::state_t aState) {
            switch (aState) {
                case state::left_active:
                    str("left subscribed  ");
                    buttons::event.addObserver(&o);
                    break;
                case state::left_sleep:
                    str("left unsubscribed");
                    buttons::event.removeObserver(&o);
                    break;
            }
        }
    };

    static state::Adapter<LockerObserver> observer;

    namespace tasks {
        namespace left {
            void start() {
                str("left unsubscribed");
                state::event.addObserver(&observer);
            }
        }
    }

Возможно существует какое-то более элегантный способ отучить виртуальные функции от вызова malloc, но в целом представленное решение выглядит вполне съедобным.