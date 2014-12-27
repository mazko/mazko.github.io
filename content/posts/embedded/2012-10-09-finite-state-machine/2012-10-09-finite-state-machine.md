title: Автомат с конечным числом состояний
category: Embedded
tags: Паттерн, Конечный Автомат, Идиома


Простым примером машины с конечным числом состояний (**FSM** - *Finite State Machine*) может быть Китайская гирлянда. Конструктивно она представляет из себя черную коробочку с кнопочкой, два провода для питания (220 В), остальные провода для разноцветных лампочек, которыми управляет готовая программа. Внутри коробочки находится *микроконтроллер* и сопутствующая обвязка. Мы не будем углубляться в детали схемотехники а сконцентрируемся на различных методиках решения подобных задач и их анализе т.е. на программировании с использованием чистого *ANSI C*.

Для экспериментов нам понадобиться какой-то тестовый макет, который можно запустить / эмулировать в виртуальной среде (выбор пал на *Proteus VSM*). Есть простенький микроконтроллер (PIC16F1823), который управляет лампочками (гирляндой) и может менять их яркость с помощью встроенного цифро-аналогового преобразователя ЦАП (в реальном устройстве для этого лучше использовать ШИМ, ЦАП лучше подходит для эмуляции в *Proteus VSM*). Быстро вникнуть в суть дела можно посмотрев следующее видео:

<video width="100%" controls>
  <source src="{attach}video.mp4" type="video/mp4">
Your browser does not support the video tag.
</video> 

Начнём с простого - напишем программу для гирлянды с *двумя* состояниями - в первом светодиоды поочерёдно вспыхивают слева направо, во втором справа налево. В системе два события - нажали кнопочку (NEXT) и внутреннее (недоступно пользователю гирлянды) событие от таймера (TICK). Событие NEXT изменяет состояние:

![Диаграмма состояний Скриншот]({attach}State_Diagram.png){:style="width:100%; border:1px solid #ddd;"}

###Операторы switch/case

Прибегнув к помощи условных операторов `if` / `else` или `switch` / `case` по-старинке задачу решили так:

*/FSM/Child/src/main.c*

	:::cpp
	#include "main.h"

	typedef enum {
	    LEFT_TO_RIGHT,
	    RIGHT_TO_LEFT
	} State;

	/* Global variable to hold current state */

	static State currentState = RIGHT_TO_LEFT;

	/* Event handlers implementations */

	static void onLeftToRightTickImpl() {
	    nextLeftLed(); // in main.h
	}

	static void onLeftToRightNextImpl() {
	    resetLeds(); // in main.h
	    currentState = RIGHT_TO_LEFT;
	}

	static void onRightToLeftTickImpl() {
	    nextRightLed(); // in main.h
	}

	static void onRightToLeftNextImpl() {
	    resetLeds(); // in main.h
	    currentState = LEFT_TO_RIGHT;
	}

	void main (void) {

	    initHardware(); // in main.h

	    for (;;) {

	        typedef enum {
	            NEXT,
	            TICK
	        } Event;

	        /* Событие по-умолчанию */

	        Event eventToFire = TICK;

	        /* Если нажали кнопку, событие NEXT */

	        for (unsigned int i = 5000; i; i--) {
	            if (isNextButtonPressed()) {
	                eventToFire = NEXT;
	                break; // Fire NEXT event
	            } 
	        }

	        switch (currentState) {
	            case LEFT_TO_RIGHT : 
	                switch (eventToFire) {
	                    case TICK:
	                        onLeftToRightTickImpl();
	                        break; // TICK
	                    case NEXT:
	                        onLeftToRightNextImpl();
	                        break; // NEXT
	                        
	                }
	                break; // LEFT_TO_RIGHT
	            case RIGHT_TO_LEFT : 
	                switch (eventToFire) {
	                    case TICK:
	                        onRightToLeftTickImpl();
	                        break; // TICK
	                    case NEXT:
	                        onRightToLeftNextImpl();
	                        break; // NEXT
	                        
	                }
	                break; // RIGHT_TO_LEFT
	        }
	    }
	}

Некоторые детали реализации вынесены в заголовочный файл **main.h**, который прилагается к исходникам. Для сборки использовался компилятор HI-TECH PICC:

	:::bash
    /usr/hitech/picc/9.83/bin/PICC --opt=all --chip=16F1823 --ASMLIST main.c

Что мы можем сказать об этом решении, кроме того, что там много одинаковых слов `switch` и `case` ?

- Представьте себе несколько страниц кода с монолитным оператором `switch` / `case`. Такой код сложно читать и сопровождать. В самих `switch` / `case` или `if` / `else` нет ничего плохого - в конце-концов это ключевые слова **С**. Но когда их очень много в одном месте, с этим нужно бороться.

- Hет удачного разделения между логикой обработки событий машиной с конечным числом состояний и реализацией соответствующих действий. В результате добавление нового состояния требует больших изменений в разных местах.

###Табличная альтернатива

Второй способ решения задачи состоит в использовании таблицы переходов:

*/FSM/Table/Simple/src/main.c*

	:::cpp
	#include "main.h"

	typedef enum {
	    LEFT_TO_RIGHT,
	    RIGHT_TO_LEFT
	} State;

	/* Global variable to hold current state */

	static State currentState = RIGHT_TO_LEFT;

	/* Event handlers implementations */

	static void onLeftToRightTickImpl() {
	    nextLeftLed(); // in main.h
	}

	static void onLeftToRightNextImpl() {
	    resetLeds(); // in main.h
	    currentState = RIGHT_TO_LEFT;
	}

	static void onRightToLeftTickImpl() {
	    nextRightLed(); // in main.h
	}

	static void onRightToLeftNextImpl() {
	    resetLeds(); // in main.h
	    currentState = LEFT_TO_RIGHT;
	}

	void main (void) {

	    initHardware(); // in main.h

	    typedef enum {
	        NEXT,
	        TICK
	    } Event;

	    typedef struct _Transition {
	        State state;
	        Event event;
	        void (*EventFunc)();
	    } Transition;

	    const Transition transitionTable[] = {
	        {LEFT_TO_RIGHT, TICK, onLeftToRightTickImpl},
	        {LEFT_TO_RIGHT, NEXT, onLeftToRightNextImpl},
	        {RIGHT_TO_LEFT, TICK, onRightToLeftTickImpl},
	        {RIGHT_TO_LEFT, NEXT, onRightToLeftNextImpl}
	    };

	    for (;;) {

	        /* Событие по-умолчанию */

	        Event eventToFire = TICK;

	        /* Если нажали кнопку, событие NEXT */

	        for (unsigned int i = 5000; i; i--) {
	            if (isNextButtonPressed()) {
	                eventToFire = NEXT;
	                break; // Fire NEXT event
	            } 
	        }

	        /* Обработка события */

	        int elementsCount = 
	            sizeof(transitionTable) / sizeof(transitionTable[0]);
	        while (elementsCount--) {
	            Transition transition = transitionTable[elementsCount];
	            if (transition.state == currentState && 
	                transition.event == eventToFire) {
	                transition.EventFunc();
	                break; // Функция EventFunc найдена и выполнена!
	            }
	        }
	    }
	}

Давайте сравним данное решение с предыдущим:

- Табличная реализация несколько медленнее - как минимум добавился цикл `while`. Для обхода элементов таблицы задействована идиома КОЛИЧЕСТВО ЭЛЕМЕНТОВ МАССИВА КАК РЕЗУЛЬТАТ ДЕЛЕНИЯ, которая уже подробно описывалась [ранее]({filename}../2012-10-08-ansi-c-idioms/2012-10-08-ansi-c-idioms.md).

- Bся логика переходов сконцентрирована в одной таблице. Всё видно, как на ладони. Теперь можно быстрее разобраться / вспомнить, как всё это работает.

- Добавление нового состояния не требует изменений логики обработки событий машиной с конечным числом состояний.  Давайте добавим ещё одно состояние - лампочки **плавно** меняют яркость:

*/FSM/Table/Scale/src/main.c*

	:::cpp
	#include "main.h"

	typedef enum {
	    LEFT_TO_RIGHT,
	    RIGHT_TO_LEFT,

	    /* Add brightness algoritms States */

	    RIGHT_LEFT_TO_BRIGHT
	} State;

	/* Global variable to hold current state */

	static State currentState = RIGHT_TO_LEFT;

	/* Event handlers implementations */

	static void onLeftToRightTickImpl() {
	    nextLeftLed(); // in main.h
	}

	static void onLeftToRightNextImpl() {
	    resetLeds(); // in main.h
	    currentState = RIGHT_TO_LEFT;
	}

	static void onRightToLeftTickImpl() {
	    nextRightLed(); // in main.h
	}

	/* LEFT_TO_RIGHT ==> RIGHT_LEFT_TO_BRIGHT */

	static void onRightToLeftNextImpl() {
	    resetLeds(); // in main.h
	    currentState = RIGHT_LEFT_TO_BRIGHT;
	}

	/* Add brightness handlers */

	static void onRightToLeftBrigtTickImpl() {
	    nextRightBrightLed(); // in main.h
	}

	static void onRightToLeftBrigtNextImpl() {
	    resetLeds(); // in main.h
	    currentState = LEFT_TO_RIGHT;
	}

	void main (void) {

	    initHardware(); // in main.h

	    typedef enum {
	        NEXT,
	        TICK
	    } Event;

	    typedef struct _Transition {
	        State state;
	        Event event;
	        void (*EventFunc)();
	    } Transition;

	    const Transition transitionTable[] = {
	        {LEFT_TO_RIGHT, TICK, onLeftToRightTickImpl},
	        {LEFT_TO_RIGHT, NEXT, onLeftToRightNextImpl},
	        {RIGHT_TO_LEFT, TICK, onRightToLeftTickImpl},
	        {RIGHT_TO_LEFT, NEXT, onRightToLeftNextImpl},

	        /* Add brightness algoritms transitions */

	        {RIGHT_LEFT_TO_BRIGHT, TICK, onRightToLeftBrigtTickImpl},
	        {RIGHT_LEFT_TO_BRIGHT, NEXT, onRightToLeftBrigtNextImpl}
	    };

	    for (;;) {

	        /* Событие по-умолчанию */

	        Event eventToFire = TICK;

	        /* Если нажали кнопку, событие NEXT */

	        for (unsigned int i = 5000; i; i--) {
	            if (isNextButtonPressed()) {
	                eventToFire = NEXT;
	                break; // Fire NEXT event
	            } 
	        }

	        /* Обработка события */

	        int elementsCount = 
	            sizeof(transitionTable) / sizeof(transitionTable[0]);
	        while (elementsCount--) {
	            Transition transition = transitionTable[elementsCount];
	            if (transition.state == currentState && 
	                transition.event == eventToFire) {
	                transition.EventFunc();
	                break; // Функция EventFunc найдена и выполнена!
	            }
	        }
	    }
	}

Несложно заметить, что код в суперцикле `for(;;)` остался без изменений, т.е. решение с использованием таблиц лучше расширяется.

###Паттерн Состояние (State)

Не поверите, но у табличного решения тоже есть альтернатива - *Паттерн Состояние*, но об этом чуть [позже]({filename}../2012-10-13-finite-state-machine-pattern-state/2012-10-13-finite-state-machine-pattern-state.md).

Исходники [тут]({attach}FSM.zip).
