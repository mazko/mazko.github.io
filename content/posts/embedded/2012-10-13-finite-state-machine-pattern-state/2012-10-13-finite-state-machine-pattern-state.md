title: Паттерны в ANSI C. State
category: Embedded
tags: Паттерн, UML, Конечный Автомат


> "Шаблоны предназначены для объектно ориентированного проектирования и реализации."
>
> Это заблуждение относится к разряду тех, где возможности шаблонов чересчур ограничиваются.
>
> Шаблоны не представляют собой никакой ценности, если они не содержат практического опыта. Какой опыт будет заключен в шаблоне, зависит от его разработчика. Безусловно, в объектно ориентированном проектировании существует огромный опыт, но не менее ценные наработки имеются в проектировании, не основанном на объектно ориентированной парадигме...
>
> **Джон Влиссидес** *Применение шаблонов проектирования ISBN 5-8459-0393-9 (рус.)*

Наверно каждый специалист в процессе работы периодически испытывает чувство [дежавю](http://ru.wikipedia.org/wiki/%D0%94%D0%B5%D0%B6%D0%B0%D0%B2%D1%8E){:rel="nofollow"}. Где-то уже решалась похожая задачка. В принципе большинство задач уже когда-то решалось. *Паттерн* - повторимая архитектурная конструкция, представляющая собой *удачное* решение проблемы проектирования в рамках некоторого часто возникающего контекста.

Самый лучший способ разобраться в [шаблонах](http://ru.wikipedia.org/wiki/%D0%A8%D0%B0%D0%B1%D0%BB%D0%BE%D0%BD_%D0%BF%D1%80%D0%BE%D0%B5%D0%BA%D1%82%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8F){:rel="nofollow"} проектирования, это попытаться их использовать, потому как дать чёткое неоспоримое определение паттерну непросто, ну разве что повторить слова *Alfred North Whitehead*, сказанные в 1943 году: "*Искусство — это наложение шаблона на опыт и наше эстетическое наслаждение от узнавания этого шаблона...*".

Чистый (ANSI) **С** не является объектно ориентированным языком - из трёх китов *ООП* в нём напрямую не поддерживается наследование, полиморфизм представлен только в виде указателей на функцию. Инкапсуляции в большинстве случаев всё же можно добиться, например с помощью ключевого слова `static` или очень хитрых `typedef`. В общем негусто. Но давайте всё же рискнём и попытаемся реализовать один из паттернов - **State** на **С**. В [прошлый]({filename}../2012-10-09-finite-state-machine/2012-10-09-finite-state-machine.md) раз мы вспомнили теорию *конечных автоматов*, теперь продолжим поддерживать <span style="text-decoration: line-through;">китайскую</span> отечественную промышленность по производству гирлянд.

###Определение

С чего начать ? Начнём с определения. Официальная формулировка паттерна *Состояние* (*State*) от [Банды Четырёх](http://ru.wikipedia.org/wiki/Design_Patterns){:rel="nofollow"} звучит так: "*Позволяет объекту варьировать свое поведение в зависимости от внутреннего состояния. Из­вне создается впечатление, что изменился класс объекта*".

В ANSI **С** конечно нету классов, но пока для простоты можно считать что класс и модуль (файл) в нашем примере одно и тоже. Теперь попробуем набросать [UML](http://ru.wikipedia.org/wiki/UML){:rel="nofollow"} - диаграмму для нашей гирлянды (если вы не очень сильны в *UML*, не волнуйтесь - я тоже):

![UML]({attach}UML.png){:style="width:100%; border:1px solid #ddd;"}

Изначально *UML* создавался с прицелом на *ООП*, поэтому "сишник" взглянув на данный рисунок может испугаться раньше времени. Не стоит волноваться, мы не будем погружаться в такую тёмную сторону **С** как [эмуляция](http://www.cs.rit.edu/~ats/books/ooc.pdf){:rel="nofollow"} наследования или виртуальных функций. Этим должен заниматься компилятор. Самое время представить участников паттерна *State*:

- `GarlandContext`: или просто контекст - единственный модуль, с которым (точнее с его интерфейсом - функциями `garlandTick` и `garlandNext`) будет работать программа - клиент. Ромб справа от `GarlandContext` в терминах *UML* означает агрегирование - контекст хранит текущее состояние в переменной `_garlandState` (минус слева означает видимость только в пределах своего модуля). Поведение `GarlandContext` напрямую зависит от текущего состояния - это отражено в комментарии стрелочкой слева.

- `GarlandState`: интерфейс для инкапсуляции поведения `GarlandContext`. Контекст работает только с этим интерфейсом, не зная какое именно состояние тот представляет на данный момент.

- `RightToLeftState` и `LeftToRightState`: конкретные состояния - реализации `GarlandState`. Каждое состояние представляет из себя отдельный модуль, который реализует своё поведение. Кто управляет переходами между состояниями ? В нашем случае этим занимаются сами состояния, однако, как будет продемонстрировано чуть позже, существуют и другие вариации шаблона *State*.

###Реализация

Как и в [табличном]({filename}../2012-10-09-finite-state-machine/2012-10-09-finite-state-machine.md) решении, полиморфизма можно добиться воспользовавшись указателями на функцию - это позволит менять поведение объекта в процессе выполнения. Интерфейс состояний в нашем случае состоит из двух функций:

*/StatePatternC/Simple/src/GarlandState.h*

    :::cpp
    #ifndef __GARLAND_STATE_H
    #define __GARLAND_STATE_H

    /* Неполный тип GarlandStatePtr для компиляции Events typedefs */

    typedef struct GarlandState* GarlandStatePtr;

    /* Events typedefs */

    typedef void (*EventTickFunc)(GarlandStatePtr);
    typedef void (*EventNextFunc)(GarlandStatePtr);

    struct GarlandState {
        EventTickFunc tickFunc;
        EventNextFunc nextFunc;
    };

    /* Обработчики событий по умолчанию */

    void defaultEventHandlersImpl(GarlandStatePtr);

    #endif

Зачем нужен `defaultEventHandlersImpl` ? Как уже упоминалась чуть ранее, возможности полиморфизма ввиду отсутствия наследования в **С** очень ограничены. Каждое конкретное состояние должно реализовывать своё поведение путём динамического присваивания полям структуры `GarlandState` указателей на соответствующие поведению функции. Это означает, что каждый раз при добавлении в систему нового события (метода в интерфейс состояния) необходимо вносить изменения и во все уже реализованные на данный момент состояния - в противном случае поведение системы может оказаться непредсказуемым. Тут на помощь приходит `defaultEventHandlersImpl` - реализация обработчиков событий по-умолчанию, которая *ослабляет зависимость* реализации состояния от новых событий. При таком подходе в случае добавления в системе нового события достаточно реализовать только один соответствующий обработчик по умолчанию, после чего каждое состояние может по мере необходимости переопределять этот обработчик своим собственным:

*/StatePatternC/Simple/src/GarlandState.с*

    :::cpp
    #include "GarlandState.h"

    static void defaultTick(GarlandStatePtr statePtr) {
        /* Обработка события Tick по умолчанию */
    }

    static void defaultNext(GarlandStatePtr statePtr) {
        /* Обработка события Next по умолчанию */
    }

    void defaultEventHandlersImpl(GarlandStatePtr statePtr) {
        statePtr->tickFunc = defaultTick;
        statePtr->nextFunc = defaultNext;
    }

Реализация конкретных состояний (некоторые детали реализации железа вынесены в модуль HAL):

*/StatePatternC/Simple/src/RightToLeftState.h*

    :::cpp
    #ifndef __RIGHT_TO_LEFT_STATE_H
    #define __RIGHT_TO_LEFT_STATE_H

    #include "GarlandState.h"

    void setStateRightToLeft(GarlandStatePtr);

    #endif

*/StatePatternC/Simple/src/RightToLeftState.c*

    :::cpp
    #include "RightToLeftState.h"
    #include "LeftToRightState.h"
    #include "HAL.h"

    static void onRightToLeftTickImpl(GarlandStatePtr statePtr) {
        nextLeftLed(); // in HAL.h
    }

    static void onRightToLeftNextImpl(GarlandStatePtr statePtr) {
        resetLeds(); // in HAL.h
        setStateLeftToRight(statePtr);
    }

    void setStateRightToLeft(GarlandStatePtr statePtr) {
        defaultEventHandlersImpl(statePtr);
        statePtr->tickFunc = onRightToLeftTickImpl;
        statePtr->nextFunc = onRightToLeftNextImpl;
    }

*/StatePatternC/Simple/src/LeftToRightState.h*

    :::cpp
    #ifndef __LEFT_TO_RIGHT_STATE_H
    #define __LEFT_TO_RIGHT_STATE_H

    #include "GarlandState.h"

    void setStateLeftToRight(GarlandStatePtr);

    #endif

*/StatePatternC/Simple/src/LeftToRightState.c*

    :::cpp
    #include "LeftToRightState.h"
    #include "RightToLeftState.h"
    #include "HAL.h"

    static void onLeftToRightTickImpl(GarlandStatePtr statePtr) {
        nextRightLed(); // in HAL.h
    }

    static void onLeftToRightNextImpl(GarlandStatePtr statePtr) {
        resetLeds(); // in HAL.h
        setStateRightToLeft(statePtr);
    }

    void setStateLeftToRight(GarlandStatePtr statePtr) {
        defaultEventHandlersImpl(statePtr);
        statePtr->tickFunc = onLeftToRightTickImpl;
        statePtr->nextFunc = onLeftToRightNextImpl;
    }

Теперь `GarlandContext`, с которым будет сотрудничать программа - клиент, в нашем случае это суперцикл в *main.c*:

*/StatePatternC/Simple/src/GarlandContext.h*

    :::cpp
    #ifndef __GARLAND_CONTEXT_H
    #define __GARLAND_CONTEXT_H

    /* Интерфейс управления гирляндой */

    void garlandTick();

    void garlandNext();

    #endif

*/StatePatternC/Simple/src/GarlandContext.с*

    :::cpp
    #include "GarlandContext.h"
    #include "GarlandState.h"
    #include "RightToLeftState.h"

    /* Начальное состояние справа налево */

    static void tick_ctor(GarlandStatePtr statePtr) {
        setStateRightToLeft(statePtr);
        garlandTick();
    }

    static void next_ctor(GarlandStatePtr statePtr) {
        setStateRightToLeft(statePtr);
        garlandNext();
    }

    /* 
       В _garlandState хранится текущее состояние.
       HI-TECH не понимает {.tickFunc=tick_ctor, .nextFunc=next_ctor}.
       (C99) разрешает "tagged" инициализацию полей структуры по имени.
    */

    static struct GarlandState _garlandState = {tick_ctor, next_ctor};

    void garlandTick() {
        _garlandState.tickFunc(&_garlandState);
    }

    void garlandNext() {
        _garlandState.nextFunc(&_garlandState);
    }

По сравнению с [предыдущими]({filename}../2012-10-09-finite-state-machine/2012-10-09-finite-state-machine.md) реализациями размер *main.c* уменьшается до неприлично малого размера:

*/StatePatternC/Simple/src/main.с*

    :::cpp
    #include "HAL.h"
    #include "GarlandContext.h"

    void main (void) {

        initHardware(); // in HAL.h

        for (;;) {

            /* Сканируем кнопку. Если нажата событие NEXT */

             for (unsigned int i = 5000; i; i--) {
                if (isNextButtonPressed()) {
                    garlandNext();
                    i = 5000;
                } 
            }

            /* Пришло время события TICK */

            garlandTick();
        }
    }

Сборка проекта с помощью компилятора HI-TECH PICC:

    :::bash
    /usr/hitech/picc/9.83/bin/PICC -q --opt=all --chip=16F1823 --ASMLIST \
    main.c GarlandState.c LeftToRightState.c RightToLeftState.c          \
    GarlandContext.c HAL.c

###Расширяемость

Добавим состояние, в котором лампочки плавно меняют яркость:

*/StatePatternC/Scale/src/RightToLeftBrightState.h*

    :::cpp
    #ifndef __RIGHT_TO_LEFT_BRIGHT_STATE_H
    #define __RIGHT_TO_LEFT_BRIGHT_STATE_H

    #include "GarlandState.h"

    void setStateRightToLeftBright(GarlandStatePtr);

    #endif

*/StatePatternC/Scale/src/RightToLeftBrightState.c*

    :::cpp
    #include "RightToLeftBrightState.h"
    #include "LeftToRightState.h"
    #include "HAL.h"

    static void onRightToLeftBrightTickImpl(GarlandStatePtr statePtr) {
        nextLeftBrightLed(); // in HAL.h
    }

    static void onRightToLeftBrightNextImpl(GarlandStatePtr statePtr) {
        resetLeds(); // in HAL.h
        setStateLeftToRight(statePtr);
    }

    void setStateRightToLeftBright(GarlandStatePtr statePtr) {
        defaultEventHandlersImpl(statePtr);
        statePtr->tickFunc = onRightToLeftBrightTickImpl;
        statePtr->nextFunc = onRightToLeftBrightNextImpl;
    }

Данное состояние будет следовать после `RightToLeftState`:

*/StatePatternC/Scale/src/RightToLeftState.c*

    :::cpp
    #include "RightToLeftState.h"
    #include "RightToLeftBrightState.h"
    #include "HAL.h"

    static void onRightToLeftTickImpl(GarlandStatePtr statePtr) {
        nextLeftLed(); // in HAL.h
    }

    static void onRightToLeftNextImpl(GarlandStatePtr statePtr) {
        resetLeds(); // in HAL.h
        setStateRightToLeftBright(statePtr);
    }

    void setStateRightToLeft(GarlandStatePtr statePtr) {
        defaultEventHandlersImpl(statePtr);
        statePtr->tickFunc = onRightToLeftTickImpl;
        statePtr->nextFunc = onRightToLeftNextImpl;
    }

Всё ! Очень просто добавлять новые состояния - насколько хватит фантазии. Все алгоритмы инкапсулированы каждый в своём модуле и никак не могут нарушить работу друг друга.

###Прелесть Отладки

Чуточку расширим структуру `GarlandState` - добавим поле `name`, в котором будет храниться название текущего состояния в виде строки:

*/StatePatternC/Debug/src/GarlandState.h*

    :::cpp
    #ifndef __GARLAND_STATE_H
    #define __GARLAND_STATE_H

    /* Неполный тип GarlandState для компиляции Events typedefs */

    typedef struct GarlandState* GarlandStatePtr;

    /* Events typedefs */

    typedef void (*EventTickFunc)(GarlandStatePtr);
    typedef void (*EventNextFunc)(GarlandStatePtr);

    struct GarlandState {
        EventTickFunc tickFunc;
        EventNextFunc nextFunc;
        const char* name;
    };

    /* Обработчики событий по умолчанию */

    void defaultEventHandlersImpl(GarlandStatePtr);

    #endif

*/StatePatternC/Debug/src/RightToLeftState.с*

    :::cpp
    #include "RightToLeftState.h"
    #include "RightToLeftBrightState.h"
    #include "HAL.h"

    static void onRightToLeftTickImpl(GarlandStatePtr statePtr) {
        nextLeftLed(); // in HAL.h
    }

    static void onRightToLeftNextImpl(GarlandStatePtr statePtr) {
        resetLeds(); // in HAL.h
        setStateRightToLeftBright(statePtr);
    }

    void setStateRightToLeft(GarlandStatePtr statePtr) {
        defaultEventHandlersImpl(statePtr);
        statePtr->tickFunc = onRightToLeftTickImpl;
        statePtr->nextFunc = onRightToLeftNextImpl;
        statePtr->name = "RightToLeftState";
    }

Теперь можно расширить функциональность обработки событий по умолчанию:

*/StatePatternC/Debug/src/GarlandState.с*

    :::cpp
    #include "GarlandState.h"
    #include "HAL.h"

    static void defaultTick(GarlandStatePtr statePtr) {
        /* Обработка события Tick по умолчанию */
        signalError("Tick", statePtr->name);
    }

    static void defaultNext(GarlandStatePtr statePtr) {
        /* Обработка события Next по умолчанию */
        signalError("Next", statePtr->name);
    }

    void defaultEventHandlersImpl(GarlandStatePtr statePtr) {
        statePtr->tickFunc = defaultTick;
        statePtr->nextFunc = defaultNext;
    }

После добавления ошибок на этапе выполнения можно наблюдать следующую картинку (`signalError` реализована в модуле HAL - выводит диагностические сообщения в *UART*. Эмуляция в  *Proteus VSM* ):

![UML]({attach}StatePatternDebug.png){:style="width:100%; border:1px solid #ddd;"}

###Вариации шаблона State

В рассмотренном нами примере переключением состояния занимаются сами *состояния*. Экземпляр состояния хранится в *контексте* (переменная `_garlandState`). Что можно переделать:

- Можно делегировать обязанность переключать состояние контексту. Для этого интерфейс модуля `GarlandContext` необходимо расширить функцией `changeState`, которая позволит переключать текущее состояние.

- Сделать состояния *ленивыми*. В таком случае в `GarlandContext` вместо переменной `_garlandState`, представляющей экземпляр текущего состояния, можно обойтись соответствующим указателем `GarlandStatePtr`. Экземпляры самих состояний логично хранить в самих модулях, реализующих эти состояния (простите за каламбур, возможно проще будет взглянуть на исходный код).

*/StatePatternC/Stateless/src/RightToLeftBrightState.c*

    :::cpp
    #include "RightToLeftBrightState.h"
    #include "LeftToRightState.h"
    #include "GarlandContext.h"

    #include "HAL.h"

    static void onRightToLeftBrightTickImpl(GarlandStatePtr statePtr) {
        nextLeftBrightLed(); // in HAL.h
    }

    static void onRightToLeftBrightNextImpl(GarlandStatePtr statePtr) {
        resetLeds(); // in HAL.h
        changeState(getStateLeftToRight());
    }

    GarlandStatePtr getStateRightToLeftBright() {
        static struct GarlandState garlandState;
        static bit initialized = 0;
        if (!initialized) {
            defaultEventHandlersImpl(&garlandState);
            garlandState.tickFunc = onRightToLeftBrightTickImpl;
            garlandState.nextFunc = onRightToLeftBrightNextImpl;
            garlandState.name = "RightToLeftBrightState";

            initialized = 1;
        }
        return &garlandState;
    }

*/StatePatternC/Stateless/src/GarlandContext.c*

    :::cpp
    #include "GarlandContext.h"
    #include "RightToLeftState.h"
    #include <stdio.h> // NULL

    static GarlandStatePtr _garlandStatePtr = NULL;

    void garlandTick() {
        if (!_garlandStatePtr) {

            /* Начальное состояние справа налево */

            _garlandStatePtr = getStateRightToLeft();
        }
        _garlandStatePtr->tickFunc(_garlandStatePtr);
    }

    void garlandNext() {
        if (!_garlandStatePtr) {

            /* Начальное состояние справа налево */

            _garlandStatePtr = getStateRightToLeft();
        }
        _garlandStatePtr->nextFunc(_garlandStatePtr);
    }

    /* Обратный вызов для смены состояния */

    void changeState(GarlandStatePtr newStatePtr) {
        _garlandStatePtr = newStatePtr;
    }

Примечательно, что такой приём даёт возможность объявить тип `GarlandStatePtr` как указатель на экземпляр - константу `GarlandState`, ведь в нашем случае объект пула (состояние) инициализируется только один раз и нелогично, чтобы он изменялся в процессе выполнения. Подход с использованием указателя на контанту придаст надёжности разрабатываемой системе - ведь теперь, например, при попытке в теле функции `onRightToLeftBrightTickImpl` и ей подобных изменить аргумент `statePtr` компилятор вежливо напомнит, что нельзя трогать объект - константу. В *С-указателях* `сonst` слева от звёздочки задаёт постоянство значения, на которое он указывает:

*/StatePatternC/Stateless/src/GarlandState.h*

    :::cpp
    #ifndef __GARLAND_STATE_H
    #define __GARLAND_STATE_H

    /* Неполный тип GarlandState для компиляции Events typedefs */

    typedef struct GarlandState const* GarlandStatePtr;

    /* Events typedefs */

    typedef void (*EventTickFunc)(GarlandStatePtr);
    typedef void (*EventNextFunc)(GarlandStatePtr);

    struct GarlandState {
        EventTickFunc tickFunc;
        EventNextFunc nextFunc;
        const char* name;
    };

    /* Обработчики событий по умолчанию */

    void defaultEventHandlersImpl(struct GarlandState*);

    #endif

*/StatePatternC/Stateless/src/GarlandState.c*

    :::cpp
    #include "GarlandState.h"
    #include "HAL.h"

    static void defaultTick(GarlandStatePtr statePtr) {
        /* Обработка события Tick по умолчанию */
        signalError("Tick", statePtr->name);
    }

    static void defaultNext(GarlandStatePtr statePtr) {
        /* Обработка события Next по умолчанию */
        signalError("Next", statePtr->name);
    }

    void defaultEventHandlersImpl(struct GarlandState* statePtr) {
        statePtr->tickFunc = defaultTick;
        statePtr->nextFunc = defaultNext;
    }

###Итого

Паттерн **State** локализует зависящее от состояния поведение и делит его на части, соответствующие состояниям. Всё поведение, ассоциированное с конкретным состоянием **изолировано** в отдельном модуле. Такой подход даёт целый рад преимуществ: *расширяемость* - легко добавлять новые состояния; *инкапсуляция* - каждое состояние изолировано в отдельном модуле; *отладка* - удобно отлавливать ошибки в процессе выполнения; *надёжность* / *читабельность* - уменьшение количества операций условных переходов `switch` / `case` или `if` / `else`.

###Принцип открытости / закрытости

Единственная константа в программировании - **ИЗМЕНЕНИЯ**. Каким образом можно разрабатывать программы, устойчивые к изменениям ? В 1988 году *Бертран Мейер* ответил на этот вопрос, предложив принцип [открытости / закрытости](http://ru.wikipedia.org/wiki/%D0%9F%D1%80%D0%B8%D0%BD%D1%86%D0%B8%D0%BF_%D0%BE%D1%82%D0%BA%D1%80%D1%8B%D1%82%D0%BE%D1%81%D1%82%D0%B8/%D0%B7%D0%B0%D0%BA%D1%80%D1%8B%D1%82%D0%BE%D1%81%D1%82%D0%B8){:rel="nofollow"}: «программные сущности (классы, модули, функции и т. п.) должны быть открыты для расширения, но закрыты для изменения». В нашем случае добавление в систему нового состояния (алгоритма переключения гирлянд) требует минимум изменений в системе, т.е. использование паттерна *State* (как в принципе и большинство других, описываемых *GoF*) - это шаг навстречу к соблюдению принципа *открытости / закрытости*.

Исходники [тут]({attach}StatePatternC.zip).

###Мозговой штурм

- Э. Гамма, Р. Хелм, Р. Джонсон, Дж. Влиссидес, "Приемы объектно-ориентированного проектирования. Паттерны проектирования == Design Patterns: Elements of Reusable Object-Oriented Software" — СПб: «Питер», 2007. — С. 366. — ISBN 978-5-469-01136-1 (также ISBN 5-272-00355-1)

- Джошуа Кериевски, "Рефакторинг с использованием шаблонов (паттернов проектирования) == Refactoring to Patterns (Addison-Wesley Signature Series)" — М.: «Вильямс», 2006. — С. 400. — ISBN 0-321-21335-1

- Э. Фримен, Э. Фримен, К. Сьерра, Б. Бейтс, "Паттерны проектирования" — ISBN 978-5-459-00435-9; 2011 г.

- Роберт К. Мартин, Джеймс В. Ньюкирк, Роберт С. Косс, "Быстрая разработка программ. Принципы, примеры, практика" — ISBN 5-8459-0558-3, 0-13-597444-5; 2004 г.

- Adam Petersen, "[Patterns in C, part 2: STATE](http://www.adampetersen.se/Patterns%20in%20C%202,%20STATE.pdf){:rel="nofollow"}", C Vu 17.2
