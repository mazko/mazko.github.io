title: Использование манчестерского кода на примере
category: embedded 
tags: Манчестерский код, UART, Микроконтроллер


В [предыдущем]({filename}../2012-10-07-manchester-code-for-dummies/2012-10-07-manchester-code-for-dummies.md) посте была подготовлена почва для работы с *Манчестерским кодом*. Теперь рассмотрим реальный пример с использованием микроконтроллеров **Microchip** - один будет кодировать и передавать данные, другой принимать, декодировать и выводить результат в **UART** - терминал. Поскольку это тестовый пример, то с выбором **C** - компилятора ничего выдумывать не будем и возьмём то, что по умолчанию даёт производитель - пробную версию **mplabc18** (*mplabc18_v3.40_windows_eval.exe*) на 60 дней, скачать можно с официального сайта с родной средой разработки **MPLAB_IDE** (*v8_70*).

Как и в прошлый раз начнём с простого - реализуем устройство, которое преобразовывает последовательность данных в *Манчестерский Код* и передаёт их. Прежде всего необходимо создать новый проект в **MPLAB**, мастер попросит указать модель микроконтроллера - тут каких-либо особых требований нет, поэтому можно выбрать самый простой, например **PIC18F1230**. В результате должно получиться что-то вроде этого:

    :::cpp
    #include <p18cxxx.h> 
    #include <timers.h> 
    #include "../../../../src/tx/Man_Encode.h" 
     
    void main(){ 
        unsigned short long i; 
     
        PORTBbits.RB0 = 0; 
        TRISB = 0; 
        OpenTimer0(TIMER_INT_ON & T0_8BIT & T0_SOURCE_INT & T0_PS_1_8); 
     
        for(;;) { 
     
            /* 'n' => 01101110b, MSB = 0 see tests => Man_Decode.cpp */ 
     
            On_Man_Encode_One();  // Clay balance (1 - 1 = 0) 
            On_Man_Encode_Zero(); // Sync balance (2 - 2 = 0) 
            On_Man_Encode_Zero();  
            On_Man_Encode_One();  // Sync 
            On_Man_Encode_One(); 
            On_Man_Encode_Zero(); // Clay 
     
            Man_Encode('n'); 
            Man_Encode('o'); 
            Man_Encode('n'); 
            Man_Encode('g'); 
            Man_Encode('r'); 
            Man_Encode('e'); 
            Man_Encode('e'); 
            Man_Encode('d'); 
            Man_Encode('y'); 
            Man_Encode('.'); 
            Man_Encode('r'); 
            Man_Encode('u'); 
            Man_Encode('\r'); 
            Man_Encode('\n'); 
     
            On_Man_Encode_Zero(); /* Tx off */ 
     
            for(i = 150000; i; i--); 
        } 
    } 
     
    void On_Man_Encode_One(){ 
        while(!INTCONbits.TMR0IF); 
        TMR0L -= 104; // 4Mhz/4/8/1200bp/s = 104 
        INTCONbits.TMR0IF = 0; 
        PORTBbits.RB0 = 1; 
    } 
     
    void On_Man_Encode_Zero(){ 
        while(!INTCONbits.TMR0IF); 
        TMR0L -= 104; // 4Mhz/4/8/1200bp/s = 104 
        INTCONbits.TMR0IF = 0; 
        PORTBbits.RB0 = 0; 
    }

![MPLab Скриншот]({attach}mplab_man_tx.png){:style="width:100%; border:1px solid grey;"}

Результатом сборки является файл с расширением **.hex**, в народе просто *хекс* - прошивка, которую необходимо записать в микроконтроллер с помощью специального оборудования (программатора). Поскольку последнего, наверно, у Вас нет, можно задействовать виртуальную среду, которая умеет эмулировать поведение электронных схем - **Proteus VSM** (v 7.9sp1). Как видно из рисунка на виртуальном осциллографе время логической 1 чуть больше 4 делений при шаге 0.2 мс. При скорости 1200 бит/с 1000 мс / 1200 = 0,83 мс это похоже на правду.

![Proteus Sim Скриншот]({attach}proteus_tx_simulation.png){:style="width:100%; border:1px solid grey;"}

Теперь реализуем приёмник, который будет анализировать состояние на входе (вывод **RB0**), декодировать сигнал из *Манчестерского Кода* в оригинальный и принимать решение о том, что передача полезных данных завершена. Самый простой способ отобразить данные при работе в **Proteus VSM** - использовать виртуальный **UART** - терминал.

    :::cpp
    #include <p18cxxx.h> 
    #include <timers.h> 
    #include <usart.h> 
    #include <stdio.h>  
    #include "../../../../src/rx/Man_Decode.h" 
     
    char rxbuf[1 + (4*sizeof(long))]; 
     
    void printrxbuf() { 
        char i = sizeof(rxbuf); 
        while(i--) 
            _usart_putc(rxbuf[i]); 
    } 
     
    char calcperiods() { 
        unsigned char time = TMR0L; 
        TMR0L = 0; 
     
        /* 8Mhz/4/32/1200(bp/s) = 52 */ 
     
        if (time < 52/2) return 0; 
        if (time < 3*(52 / 2)) return 1; 
     
        return 2; 
    } 
     
    void main(){ 
        OpenTimer0(TIMER_INT_OFF & T0_8BIT & T0_SOURCE_INT & T0_PS_1_32); 
        OpenUSART( USART_TX_INT_OFF & USART_RX_INT_OFF & 
            USART_ASYNCH_MODE & USART_EIGHT_BIT & 
            USART_CONT_RX & USART_BRGH_HIGH, 12  ); // 38400 b/s 
     
        for(;;) { 
            memset(rxbuf, 0, sizeof(rxbuf)); 
            for(;;) { 
                char ds_B; 
     
                if (rxbuf[1] == '\r' && rxbuf[0] == '\n') { 
                    printrxbuf(); 
                    break; 
                } 
     
                if ( PORTBbits.RB0 ) { 
                    if ( ds_B ) continue; 
                    ds_B = 1; 
                    Man_Decode_Stable_Zero(calcperiods()); 
                } else { 
                    if ( !ds_B ) continue; 
                    ds_B = 0; 
                    Man_Decode_Stable_One(calcperiods()); 
                } 
            } 
        } 
    } 
     
    void shiftrxbuf() { 
        *(( unsigned long* )&rxbuf[12]) <<= 1; 
        if (rxbuf[11] & 0x80) rxbuf[12] |= 1; 
        *(( unsigned long* )&rxbuf[8]) <<= 1; 
        if (rxbuf[7] & 0x80) rxbuf[8] |= 1; 
        *(( unsigned long* )&rxbuf[4]) <<= 1; 
        if (rxbuf[3] & 0x80) rxbuf[4] |= 1; 
        *(( unsigned long* )&rxbuf) <<= 1; 
    } 
     
    void On_Man_Decode_Add_0(){ 
        shiftrxbuf(); 
        rxbuf[0] &= 0xFE; 
    } 
     
    void On_Man_Decode_Add_1(){ 
        shiftrxbuf(); 
        rxbuf[0] |= 1; 
    }

![MPLab Скриншот]({attach}mplab_man_rx.png){:style="width:100%; border:1px solid grey;"}

Как видно из кода, признаком окончания передачи данных в данном примере является комбинация символов `'\r'` и `'\n'`. Это очень простое решение, при использовании в реальных условиях этот механизм нужно доработать - иначе иногда можно получать ложный сигнал о завершении передачи данных. Также стоит обратить внимание на буфер `rxbuf`, в который программа записывает декодированные данные с помощью метода `shiftrxbuf()`. Етот метод делает операцию побитового сдвига для всего буфера, как если бы это был простой (примитивный) тип данных типа `char`, `long` и т.д.  Если всё это теперь запустить в **Proteus VSM**, то результат будет примерно таким:

![Proteus Sim Скриншот]({attach}proteus_rx_simulation.png){:style="width:100%; border:1px solid grey;"}

Вроде всё, исходники на [GitHub](https://github.com/mazko/Manchester-Code){:rel="nofollow"}.
