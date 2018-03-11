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

Никогда не полагайтесь на определенный порядок оповещения наблюдателей. Метод `addObserver` класса `state::Container` добавляет новый наблюдателя в начало связного списка. А если добавлять не в начало а в конец ? Какой порядок считать правильным ? **Любой**. Нужно писать код таким образом, чтобы порядок обхода наблюдателей никак не влиял на поведение программы. Чем меньше компоненты системы знают друг о друге, тем проще их изменять и развивать. О силе слабых связей чуть ниже.

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