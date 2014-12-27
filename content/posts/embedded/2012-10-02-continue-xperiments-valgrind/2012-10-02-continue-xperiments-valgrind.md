title: Продолжаем XPрименты - Valgrind
category: embedded
tags: TDD, Микроконтроллер, CppUnit, Valgrind


В предыдущем [посте]({filename}../2012-09-29-xp-in-microcontrollers-life/2012-09-29-xp-in-microcontrollers-life.md) было рассказано о пользе применения элементов **экстремального программирования** (*Extreme Programming* (*XP*)) в контексте разработки устройств на микроконтроллерах. Перед тем, как разворачивать приложение (прошивать микроконтроллер) в обязательном порядке на ПК запускаются тесты, представляющие собой обычный **исполняемый файл**, использующий тот же исходный код, что и конечный потребитель - микроконтроллер. Ключевое понятие сейчас для нас - **исполняемый файл**, фактически законченное консольное приложение. А значит можно задействовать дополнительные инструменты для проверки / анализа качества кода на этапе выполнения. Один из таких инструментов - [Valgring](http://valgrind.org/){:rel="nofollow"} обладает просто-таки потрясающими возможностями, в чём мы сейчас и постараемся убедиться.

**Valgrind** обновляется довольно часто, поэтому в репозиториях *Ubuntu* / *openSUSE* и т.д. может быть более *древняя* версия программы. В этой связи возможно проще работать с исходниками - процесс сборки / установки **Valgrind** стандартный как для **Unix** и состоит из трёх этапов: ./**configure**, **make**, **make install**:

    :::bash
    sudo zypper install make
    # cd '/home/embedded/Рабочий стол/vargrind/valgrind-3.7.0'
    ./configure
    make
    sudo make install

Вот что получится, если попросить **Valgrind** проверить нашу программу для расчёта расстояния между двумя GPS координатам:

![Первый запуск Скриншот]({attach}valgrind_demo.png){:style="width:100%; border:1px solid grey;"}

Основная утилита **Valgrind** - **memcheck**, она запускается по умолчанию. Для использования других утилит это необходимо явно указывать в параметрах командной строки, как продемонстрировано на вызове **exp-sgcheck** (ранее она называлась **exp-ptrcheck**). Как видно из рисунка, наш код ошибок при работе с памятью не имеет.

###Valgrind - memcheck

Теперь рассмотрим более интересный пример. Необходимо разработать метод, который принимает в качестве входного параметра **GPS** строку в формате **NMEA** и извлекает дату и время принятого пакета. Чтобы было проще сортировать полученные данные по дате, возможно, понадобится соответственно изменить её формат:

*gps_valgrind/src/gps/gps.c*

    :::cpp
    #include <string.h>
    #include <stdlib.h>

    typedef struct 
    {
        unsigned long Date, Time;
    } DateTimeGPS;

    /**************************************************************
     *      Function Name:  TryGetDateTimeRMCGPS                  *
     *      Return Value:   true if success, false if not         *
     *      Parameters:     NMEA RMC string,                      *
     *			DateTimeGPS structure, doSwap boolean *
     *      Description:    Find date and time in RMC string ang  *
     *			fill DateTimeGPS                      *
     **************************************************************/

    bool TryGetDateTimeRMCGPS(const char* rmc, 
                DateTimeGPS* datetime, bool doDateSwap) {
        const register char* s1 = strchr(rmc, ',');
            if (s1) {    
                datetime->Time = atol(s1 + 1);
                for (unsigned char c = 0; c < 8 && 
                    (s1 = strchr(s1 + 1, ',')); c++);
                if (s1) {
                    if(doDateSwap) {
                        char bufD[sizeof("130484")];
                        memcpy(bufD, s1 + 1, sizeof(bufD) - 1);
                        char swap;
                        swap = bufD[0]; 
                        bufD[0] = bufD[4]; 
                        bufD[4] = swap;
                        swap = bufD[1]; 
                        bufD[1] = bufD[5]; 
                        bufD[5] = swap;
                        datetime->Date = atol(bufD);
                    }
                    else datetime->Date = atol(s1 + 1);

                    return true;
                }
        }

        return false;
    }

*gps_valgrind/tests/cppunit/gps/GpsTest.h*

    :::cpp
    #ifndef __GPS_TEST_H
    #define __GPS_TEST_H

    #include <cppunit/extensions/HelperMacros.h>

    class GpsTest : public CppUnit::TestFixture {
        CPPUNIT_TEST_SUITE( GpsTest );
        CPPUNIT_TEST( test_empty_TryGetDateTimeRMCGPS );
        CPPUNIT_TEST( test_empty_swap_TryGetDateTimeRMCGPS );
        CPPUNIT_TEST( test_TryGetDateTimeRMCGPS );
        CPPUNIT_TEST( test_swap_TryGetDateTimeRMCGPS );
        CPPUNIT_TEST( test_params_immutable_TryGetDateTimeRMCGPS );
        CPPUNIT_TEST( test_params_immutable_swap_TryGetDateTimeRMCGPS );
        CPPUNIT_TEST_SUITE_END();
    public:
        void test_empty_TryGetDateTimeRMCGPS();
        void test_empty_swap_TryGetDateTimeRMCGPS();
        void test_TryGetDateTimeRMCGPS();
        void test_swap_TryGetDateTimeRMCGPS();
        void test_params_immutable_TryGetDateTimeRMCGPS();
        void test_params_immutable_swap_TryGetDateTimeRMCGPS();
    };

    #endif  // __GPS_TEST_H

*gps_valgrind/tests/cppunit/gps/GpsTest.cpp*

    :::cpp
    #include "GpsTest.h"

    extern "C"
    {
        #include "../../../src/gps/gps.c"
    }

    CPPUNIT_TEST_SUITE_REGISTRATION( GpsTest );

    #define VALID_TEST_RMC "$GPRMC,225446,A," \
        "4916.45,N,12311.12,W,000.5,054.7,191194,020.3,E*68"

    DateTimeGPS dt;

    void GpsTest::test_empty_TryGetDateTimeRMCGPS() {
        CPPUNIT_ASSERT(!TryGetDateTimeRMCGPS("", &dt, false));
        CPPUNIT_ASSERT(!TryGetDateTimeRMCGPS(
            "$GPRMC,,,,,,,,", &dt, false));
    }

    void GpsTest::test_empty_swap_TryGetDateTimeRMCGPS() {
        CPPUNIT_ASSERT(!TryGetDateTimeRMCGPS("", &dt, true));
        CPPUNIT_ASSERT(!TryGetDateTimeRMCGPS(
            "$GPRMC,,,,,,,,", &dt, true));
    }

    void GpsTest::test_TryGetDateTimeRMCGPS() {
        CPPUNIT_ASSERT(TryGetDateTimeRMCGPS(
            VALID_TEST_RMC, &dt, false));
        CPPUNIT_ASSERT_EQUAL( 191194ul, dt.Date );
        CPPUNIT_ASSERT_EQUAL( 225446ul, dt.Time );
    }

    void GpsTest::test_swap_TryGetDateTimeRMCGPS() {
        CPPUNIT_ASSERT(TryGetDateTimeRMCGPS(
            VALID_TEST_RMC, &dt, true));
        CPPUNIT_ASSERT_EQUAL( 941119ul, dt.Date );
        CPPUNIT_ASSERT_EQUAL( 225446ul, dt.Time );
    }

    void template_params_immutable_TryGetDateTimeRMCGPS(bool doSwap) {
        const char* rmc = "";
        dt.Date = 1;
        dt.Time = 2;
        TryGetDateTimeRMCGPS(rmc, &dt, doSwap);
        CPPUNIT_ASSERT( std::string("") == rmc );
        CPPUNIT_ASSERT_EQUAL( 1ul, dt.Date );
        CPPUNIT_ASSERT_EQUAL( 2ul, dt.Time );
        rmc = VALID_TEST_RMC;
        TryGetDateTimeRMCGPS(rmc, &dt, doSwap);
        CPPUNIT_ASSERT( std::string(VALID_TEST_RMC) == rmc );
    }

    void GpsTest::test_params_immutable_TryGetDateTimeRMCGPS() {
        template_params_immutable_TryGetDateTimeRMCGPS(false);
    }

    void GpsTest::test_params_immutable_swap_TryGetDateTimeRMCGPS() {
        template_params_immutable_TryGetDateTimeRMCGPS(true);
    }

Код успешно компилируется и проходит тесты. Но что по этому поводу думает **Valgrind** ?

![Memcheck]({attach}valgrind_memcheck_error.png){:style="width:100%; border:1px solid grey;"}

Строка должна всегда завершаться нулём, а в нашем случае последний символ bufD неопределён. Ниже представлен исправленный вариант.

*gps_valgrind/src/gps/gps.c*
    :::cpp
    #include <string.h>
    #include <stdlib.h>

    typedef struct 
    {
        unsigned long Date, Time;
    } DateTimeGPS;

    /**************************************************************
     *      Function Name:  TryGetDateTimeRMCGPS                  *
     *      Return Value:   true if success, false if not         *
     *      Parameters:     NMEA RMC string,                      *
     *			DateTimeGPS structure, doSwap boolean *
     *      Description:    Find date and time in RMC string ang  *
     *			fill DateTimeGPS                      *
     **************************************************************/

    bool TryGetDateTimeRMCGPS(const char* rmc, 
                DateTimeGPS* datetime, bool doDateSwap) {
        const register char* s1 = strchr(rmc, ',');
            if (s1) {    
                datetime->Time = atol(s1 + 1);
                for (unsigned char c = 0; c < 8 && 
                    (s1 = strchr(s1 + 1, ',')); c++);
                if (s1) {
                    if(doDateSwap) {
                        char bufD[sizeof("130484")];
                        memcpy(bufD, s1 + 1, sizeof(bufD) - 1);
                        char swap;
                        swap = bufD[0]; 
                        bufD[0] = bufD[4]; 
                        bufD[4] = swap;
                        swap = bufD[1]; 
                        bufD[1] = bufD[5]; 
                        bufD[5] = swap;
                        bufD[sizeof(bufD) - 1] = 0; // fixed
                        datetime->Date = atol(bufD);
                    }
                    else datetime->Date = atol(s1 + 1);

                    return true;
                }
        }

        return false;
    }

Существует одна категория ошибок, особенно актуальная при использовании чистого **С**, которую **memcheck** обнаружить пока не в состоянии - выход за границы массива, который расположен в стеке или является статическим (объявлен с помощью ключевого слова *static*).

###Valgrind - exp-sgcheck

Перед тем, как работать с **NMEA** пакетом, его необходимо получить. Вот очень простой код:

*gps_valgrind/src/gps/gpsUART.c*

    :::cpp
    #include "gps.h"

    /*************************************************************
     *      Each NMEA sting begins with '$' and ends             *
     *      with <CR> and can't be longer than 80                *
     *      characters of visible text                           *
     *************************************************************/

    static char buf[81];

    /*************************************************************
     *      Function Name:  getsGPS                              *
     *      Return Value:   bool                                 *
     *      Parameters:     no                                   *
     *      Description:    This routine read each char          *
     *                      while "\r\n" sequence not occur.     *
     *                      Return true if no overflow           *
     *************************************************************/

    static bool getsGPS(void) {
        register char pt = 0;

        do {
            char c;
            switch(c = Read_UART()) {
                case '\n':
                    if (pt) {
                        char* prev = &buf[pt - 1];
                        if(*prev == '\r') {
                            *prev = 0;
                            return true;
                        }
                    }
                default:
                    if (pt <= sizeof(buf)) buf[pt] = c;
            }
        }
        while (++pt <= sizeof(buf));

        /* Overflow. Force ensure buf last char is null terminated */
        
        buf[sizeof(buf) - 1] = 0;

        return false;
    }

*gps_valgrind/tests/cppunit/gps/GpsTestUART.h*

    :::cpp
    #ifndef __GPS_TEST_UART_H
    #define __GPS_TEST_UART_H

    #include <cppunit/extensions/HelperMacros.h>

    class GpsTestUART : public CppUnit::TestFixture {
        CPPUNIT_TEST_SUITE( GpsTestUART );
        CPPUNIT_TEST( test_getsGPS );
        CPPUNIT_TEST( test_rn_getsGPS );
        CPPUNIT_TEST( test_max_getsGPS );
        CPPUNIT_TEST( test_overflow_no_rn_empty_getsGPS );
        CPPUNIT_TEST( test_overflow_no_rn_dollar_getsGPS );
        CPPUNIT_TEST( test_overflow_no_rn_getsGPS );
        CPPUNIT_TEST_SUITE_END();
    public:
        void test_getsGPS();
        void test_rn_getsGPS();
        void test_max_getsGPS();
        void test_overflow_no_rn_empty_getsGPS();
        void test_overflow_no_rn_dollar_getsGPS();
        void test_overflow_no_rn_getsGPS();
    };

    #endif  // __GPS_TEST_UART_H

*gps_valgrind/tests/cppunit/gps/GpsTestUART.cpp*

    :::cpp
    #include "GpsTestUART.h"

    extern "C"
    {
        #include "fakeuart.c"
        #include "../../../src/gps/gpsUART.c"
    }

    CPPUNIT_TEST_SUITE_REGISTRATION( GpsTestUART );
    const int MAX_NMEA_LENGTH = 80;

    void GpsTestUART::test_rn_getsGPS() {
        FAKE_UART_FILL_BUFFER("\r\n");
        CPPUNIT_ASSERT(getsGPS());
        CPPUNIT_ASSERT(std::string("") == buf);
    }

    void GpsTestUART::test_getsGPS() {

        #define GPRMC_FAKE                                     \
                "$GPRMC,220516,A,5133.82,N,00042.24,W,173.8,"  \
                "231.8,130694,004.2,W*70"

        FAKE_UART_FILL_BUFFER(GPRMC_FAKE "\r\n");
        CPPUNIT_ASSERT(getsGPS());
        CPPUNIT_ASSERT(std::string(GPRMC_FAKE) == buf);

        #undef GPRMC_FAKE
    }

    void GpsTestUART::test_max_getsGPS() {

        #define GPRMC_FAKE                                     \
                "$GPRMC,145932.000,A,4836.5976,N,03433.7255,"  \
                "E,0.25,0.00,080711,xxxxxx,xxxxxx,A*68"

        CPPUNIT_ASSERT(
            std::string(GPRMC_FAKE).length() == MAX_NMEA_LENGTH);

        FAKE_UART_FILL_BUFFER(GPRMC_FAKE "\r\n");
        CPPUNIT_ASSERT(getsGPS());
        CPPUNIT_ASSERT(std::string(GPRMC_FAKE) == buf);

        #undef GPRMC_FAKE
    }

    void GpsTestUART::test_overflow_no_rn_empty_getsGPS() {
        FAKE_UART_FILL_BUFFER("");
        CPPUNIT_ASSERT(!getsGPS());
        CPPUNIT_ASSERT(std::string("") == buf);
    }

    void GpsTestUART::test_overflow_no_rn_dollar_getsGPS() {
        FAKE_UART_FILL_BUFFER("$");
        CPPUNIT_ASSERT(!getsGPS());
        CPPUNIT_ASSERT(std::string(
            &std::vector<char>(MAX_NMEA_LENGTH,'$')
                .front(), MAX_NMEA_LENGTH) == buf);
    }

    void GpsTestUART::test_overflow_no_rn_getsGPS() {

        #define GPRMC_OVERFLOW                                \
                "$GPRMC,145932.000,A,4836.5976,N,03433.7255," \
                "E,0.25,0.00,080711,xxxxxx,xxxxxx,A*68"

        CPPUNIT_ASSERT(
            std::string(GPRMC_OVERFLOW).length() == MAX_NMEA_LENGTH);

        FAKE_UART_FILL_BUFFER(GPRMC_OVERFLOW "\n\r");
        CPPUNIT_ASSERT(!getsGPS());
        CPPUNIT_ASSERT(std::string(GPRMC_OVERFLOW) == buf);

        #undef GPRMC_OVERFLOW
    }

*gps_valgrind/tests/cppunit/gps/fakeuart.c*

    :::cpp
    #define FAKE_UART_FILL_BUFFER(c)                \
            fakeuartbuf = c;                        \
            fakeuartbuf_s1 = 0

    static const char* fakeuartbuf;
    static unsigned int fakeuartbuf_s1;

    static char Read_UART() {
        if(!fakeuartbuf[fakeuartbuf_s1]) {
            fakeuartbuf_s1 = 0;
        }

        return fakeuartbuf[fakeuartbuf_s1++];
    }

Код успешно компилируется и проходит тесты и никаких вопросов у **memcheck** не вызывает. Запускаем **exp-sgcheck**:

![exp-sgcheck]({attach}valgrind_sgcheck_error.png){:style="width:100%; border:1px solid grey;"}

Программист допустил оплошность - при определённых обстоятельствах осуществляется выход за границы массива. Подобные ошибки трудно обнаружить, поскольку всё вроде как работает, но в самый неподходящий момент что-то сломается ;( Исправленный вариант выглядит так:

*gps_valgrind/src/gps/gpsUART.c*

    :::cpp
    #include "gps.h"

    /*************************************************************
     *      Each NMEA sting begins with '$' and ends             *
     *      with <CR> and can't be longer than 80                *
     *      characters of visible text                           *
     *************************************************************/

    static char buf[81];

    /*************************************************************
     *      Function Name:  getsGPS                              *
     *      Return Value:   bool                                 *
     *      Parameters:     no                                   *
     *      Description:    This routine read each char          *
     *                      while "\r\n" sequence not occur.     *
     *                      Return true if no overflow           *
     *************************************************************/

    static bool getsGPS(void) {
        register char pt = 0;

        do {
            char c;
            switch(c = Read_UART()) {
                case '\n':
                    if (pt) {
                        char* prev = &buf[pt - 1];
                        if(*prev == '\r') {
                            *prev = 0;
                            return true;
                        }
                    }
                default:
                    if (pt < sizeof(buf)) buf[pt] = c; // FIX <= !!!
            }
        }
        while (++pt <= sizeof(buf));

        /* Overflow. Force ensure buf last char is null terminated */
        
        buf[sizeof(buf) - 1] = 0;

        return false;
    }
    {% endhighlight %}

###Valgrind - suppressions

В процессе поиска ошибок **Valgrind** может также обнаруживать ошибки и в системных библиотеках, таких как GNU C или X11 к примеру. Поскольку подобный код мы не можем контролировать, было бы здорово иметь механизм подробного описания и подавления ошибок - это позволит сосредоточиться исключительно на ошибках разрабатываемого приложения. **Valgrind** не только умеет делать подобные вещи, но также поможет сгенерировать необходимый **suppression-синтаксис** с точным описанием ошибки при использовании специального параметра командной строки **--gen-suppressions=yes**.

    :::bash
    valgrind --tool=exp-sgcheck --gen-suppressions=all ./a.out
    #create ../test.supp
    valgrind --tool=exp-sgcheck --gen-suppressions=all \
    --suppressions=../test.supp ./a.out
    ==3540== exp-sgcheck, a stack and global array overrun detector
    ==3540== NOTE: This is an Experimental-Class Valgrind Tool
    ==3540== Copyright (C) 2003-2011, and GNU GPLd, by OpenWorks Ltd et al.
    ==3540== Using Valgrind-3.7.0 and LibVEX; rerun with -h for copyright info
    ==3540== Command: ./a.out
    ==3540== 
    ............

    OK (12)
    ==3540== 
    ==3540== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 7 from 7)

*gps_valgrind/tests/test.supp*

    :::bash
    # This file suppress UART getsGPS errors

    {
       UART getsGPS no_rn_test
       exp-sgcheck:SorG
       fun:getsGPS
       fun:_ZN11GpsTestUART27test_overflow_no_rn_getsGPSEv
    }

    {
       UART getsGPS no_rn_dollar_test
       exp-sgcheck:SorG
       fun:getsGPS
       fun:_ZN11GpsTestUART34test_overflow_no_rn_dollar_getsGPSEv
    }

    {
       UART getsGPS no_rn_empty_test
       exp-sgcheck:SorG
       fun:getsGPS
       fun:_ZN11GpsTestUART33test_overflow_no_rn_empty_getsGPSEv
    }

Исходники [тут]({attach}gps_valgrind.zip).
