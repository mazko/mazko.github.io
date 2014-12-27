title: TDD в жизни микроконтроллеров
category: Embedded
tags: Микроконтроллер, TDD, GPS, CppUnit

> Тестирование традиционно проводится в качестве финального аккорда разработки проекта, после того, как «всё заработало, просто для уверенности». Экстремальное программирование (*Extreme Programming*{:style="color:darkred;"} (*XP*{:style="color:darkred;"})) революционизирует процесс тестирования, придавая ему равный (а то и больший) приоритет с программированием. Вообще, вы пишете тесты перед написанием программы, которая будет тестироваться, и эти тесты навсегда остаются с кодом. Тесты должны успешно проводиться каждый раз при интеграции и сборке проекта. У таких тестов есть два чрезвычайно важных преимущества.
>
> + Они позволяют ясно определить интерфейс класса. Я часто предлагал «вообразить идеальный класс для решения определённой задачи» в качестве инструмента для разработки системы. Стратегия XP идёт дальше - она описывает, как класс должен выглядеть в точности для потребителя его услуг и ясно определяет его поведение. Без двусмысленных определений. Вы можете написать целый роман или создать ворох диаграмм, объясняя, как выглядит и что делает класс, но ничто не сравнится с несколькими тестами. Первое - не более чем список пожеланий, а тесты - своего рода контракт, скреплённый компилятором и выполняющийся программой. Трудно представить себе более конкретное описание класса, чем его тесты.
>
> + Bторой важный эффект написания тестов появляется, потому что вам приходится запускать тесты каждый раз при построении вашей программы. Если взглянуть на эволюцию языков программирования с этой точки зрения, нетрудно увидеть, что все настоящие улучшения в технологии связаны с тестами. Язык ассемблера проверял только синтаксис, а в **С**{:style="color:darkred;"} были введены некоторые семантические ограничения, которые в конечном счёте помогли избежать некоторых частых ошибок. Языки ООП накладывают ещё более строгие семантические ограничения, которые, если разобраться, находятся в форме нескольких тестов. «Правильно ли используется этот тип данных ?» и «Правильно ли вызывается функция ?» - это тесты, проводимые компилятором во время выполнения.
>
> Так как вы понимаете, что ваши тесты удержат вас в рамках дозволенного и не дадут удалиться от нужной задачи (при этом по мере разработки вы всё время добавляете тесты), появляется уверенность в себе - вы можете спокойно делать огромные изменения в проекте, не беспокоясь о том, что проект может прийти в беспорядок. Это действительно замечательно.
>
>**Брюс Еккель** *Философия Java. Библиотека пркраммиста. 2001г.*

При чём тут **микроконтроллеры** ? Естественно, в контексте **С** не нужно понимать выражение интерфейс класса буквально. Это может быть просто набор методов в файле заголовка, которые не объявлены как **static**.  Программы для микроконтроллеров пишутся на **C / C++**, а **XP** - это методика разработки, которая не привязана к конкретному языку программирования. В идеале, конечно, для достижения максимального эффекта лучше производить тестирование на той же платформе, на которой предполагается разворачивать приложение. Но это необязательное условие - если исходный код программы для микроконтроллера содержит явную ошибку, она никуда не исчезнет и её можно выявить посредством тестирования в другом месте, на ПК к примеру. Запустить же среду тестирования непосредственно в микроконтроллере вследствие ограниченности ресурсов может оказаться очень сложной да и нецелесообразной задачей.

###Постановка задачи

Необходимо рассчитать расстояние между двумя координатами **GPS**. Используем формулу под названием **haversine**:

<script type="text/javascript" src="{attach}haversine.js"> </script>

<table cellpadding="0" cellspacing="0">
<tbody>
<tr>
<td valign="top"><b>Haversine formula:</b>&nbsp;</td>
<td class="formula">a = sin²(Δlat/2) + cos(lat<sub>1</sub>) * cos(lat<sub>2</sub>) * sin²(Δlong/2)<br> c = 2 * atan2(√<span class="radicand">a</span>, √<span class="radicand">(1−a)</span>)<br> d = R * c</td>
</tr>
</tbody>
</table>

где ***R*** - радиус Земли (т.е. R = 6371km), d - ***km***, углы измеряются в ***радианах***. Формула рассчитывает кратчайшее расстояние по прямой, т.е. сферическая составляющая не учитывается - при небольших расстояниях её влияние невелико.

Координаты *Latitude* и *Longitude* первой точки:

<p>
<input maxlength="10" size="10" id="haversine_lat1" value="48.6098" style="text-align: right; padding:.3em;" type="text"/>
<input maxlength="10" size="10" id="haversine_long1" value="34.5621" style="text-align: right; padding:.3em;" type="text"/>
</p>

Координаты *Latitude* и *Longitude* второй точки:

<p>
<input maxlength="10" size="10" id="haversine_lat2" value="-48.6098" style="text-align: right; padding:.3em;" type="text"/>
<input maxlength="10" size="10" id="haversine_long2" value="-34.5621" style="text-align: right; padding:.3em;" type="text"/>
<button style="padding:.2em;" type="button" onclick="haversine_math.print_haversine();"><noscript><span style="color:red;">Включите JavaScript ! </span></noscript>Рассчитать!</button>
</p>

<p id="haversine_result">
</p>

###Рабочее место

Нам точно понадобится **C / C++** компилятор, в качестве среды тестирования выбор пал на **CppUnit**, работать будем под 'чистой' **openSUSE** 11.4.

    :::bash
    sudo zypper install gcc-c++ libcppunit-devel

![Установка Скриншот]({attach}cppunit_install.png){:style="width:100%; border:1px solid grey;"}

**CppUnit** поставляется в виде библиотеки, поэтому сперва необходимо реализовать программу, которая будет вызывать тесты, а результат выводить, например, в консоль:

*gps_haversine/tests/cppunit/main.cpp*

    :::cpp
    #include <cppunit/CompilerOutputter.h>
    #include <cppunit/extensions/TestFactoryRegistry.h>
    #include <cppunit/ui/text/TextTestRunner.h>

    int RunTests(void) {
    	// Get the top level suite from the registry
    	CppUnit::Test *suite = 
    	    CppUnit::TestFactoryRegistry::getRegistry()
                    .makeTest();

    	// Adds the test to the list of test to run
    	// CppUnit::TextUi::TestRunner runner;
    	CppUnit::TextTestRunner runner;
    	runner.addTest( suite );

    	// Change the default outputter to a error outputter
    	runner.setOutputter( 
    	    new CppUnit::CompilerOutputter( &runner.result(), 
                    std::cerr ) );
    	// Run the tests.
    	bool wasSucessful = runner.run();

    	// Return error code 1 if the one of test failed.
    	return wasSucessful ? 0 : 1;
    }

    int main(void) {
    	return RunTests();
    }

После сборки и запуска результат должен быть таким:

    :::bash
    g++ -g -ldl main.cpp -lcppunit
    ./a.out

    OK (0)

Теперь можно писать тесты. Для начала объявим тело функции, которую предполагается реализовать  - это позволит успешно проходить компиляцию в тех местах, где она используется:

*gps_haversine/src/gps/gps.c*

    :::cpp
    /*********************************************************
     *      Function Name:  haversine_km                     *
     *      Return Value:   Double                           *
     *      Parameters:     Two coordinates                  *
     *      Description:    Calculate haversine distance for *
     *                      linear distance                  *
     *********************************************************/

    double haversine_km(double lat1, double long1, 
                        double lat2, double long2) {
        return -1;
    }

Тесты:

*gps_haversine/tests/cppunit/gps/GpsTest.h*

    :::cpp
    #ifndef __GPS_TEST_H
    #define __GPS_TEST_H

    #include <cppunit/extensions/HelperMacros.h>

    class GpsTest : public CppUnit::TestFixture {
        CPPUNIT_TEST_SUITE( GpsTest );
        CPPUNIT_TEST( test_haversine_km_params_immutable );
        CPPUNIT_TEST( test_haversine_km_zero );
        CPPUNIT_TEST( test_haversine_km_params_positive );
        CPPUNIT_TEST( test_haversine_km_params_negative );
        CPPUNIT_TEST( test_haversine_km_lat1_negative );
        CPPUNIT_TEST( test_haversine_km_lon1_negative );
        CPPUNIT_TEST( test_haversine_km_lat2_negative );
        CPPUNIT_TEST( test_haversine_km_lon2_negative );
        CPPUNIT_TEST_SUITE_END();
    public:
        void test_haversine_km_params_immutable();
        void test_haversine_km_zero();
        void test_haversine_km_params_positive();
        void test_haversine_km_params_negative();
        void test_haversine_km_lat1_negative();
        void test_haversine_km_lon1_negative();
        void test_haversine_km_lat2_negative();
        void test_haversine_km_lon2_negative();
    };

    #endif  // __GPS_TEST_H

*gps_haversine/tests/cppunit/gps/GpsTest.cpp*

    :::cpp
    #include "GpsTest.h"

    extern "C"
    {
        #include "../../../src/gps/gps.c"
    }

    // Registers the fixture into the 'registry'
    CPPUNIT_TEST_SUITE_REGISTRATION( GpsTest );

    /* Функция не должна изменять значение передаваемых параметров */

    void GpsTest::test_haversine_km_params_immutable() {
        double lat1 = 0.1, lon1 = 3.1, lat2 = -0.1, lon2 = -3.1;
        CPPUNIT_ASSERT_DOUBLES_EQUAL( 689.8, 
            haversine_km(lat1, lon1, lat2, lon2), 0.5 );
        CPPUNIT_ASSERT_EQUAL(0.1, lat1);
        CPPUNIT_ASSERT_EQUAL(3.1, lon1);
        CPPUNIT_ASSERT_EQUAL(-0.1, lat2);
        CPPUNIT_ASSERT_EQUAL(-3.1, lon2);
    }

    /* Расстояние между одинаковыми точками ноль */

    void GpsTest::test_haversine_km_zero() {
        CPPUNIT_ASSERT_DOUBLES_EQUAL( 0, 
            haversine_km(0, 0, 0, 0), 0 );
        CPPUNIT_ASSERT_DOUBLES_EQUAL( 0, 
            haversine_km(1.5, 10, 1.5, 10), 0 );
        CPPUNIT_ASSERT_DOUBLES_EQUAL( 0, 
            haversine_km(-10, 1.5, -10, 1.5), 0 );
        CPPUNIT_ASSERT_DOUBLES_EQUAL( 0, 
            haversine_km(-90, 180, -90, 180), 0 );
    }

    void GpsTest::test_haversine_km_params_positive() {
        CPPUNIT_ASSERT_DOUBLES_EQUAL( 122.4, 
            haversine_km(49, 33, 48.6092, 34.5622), 0.1 );
        CPPUNIT_ASSERT_DOUBLES_EQUAL( 11.12, 
            haversine_km(0.1, 0, 0, 0), 0.1 );
    }

    void GpsTest::test_haversine_km_params_negative() {
        CPPUNIT_ASSERT_DOUBLES_EQUAL( 122.4, 
            haversine_km(-48.6092, -34.5622, -49, -33), 0.1 );
        CPPUNIT_ASSERT_DOUBLES_EQUAL( 31.45, 
            haversine_km(-0.1, -0.2, -0.3, -0.4), 0.1 );
    }

    void GpsTest::test_haversine_km_lat1_negative() {
        CPPUNIT_ASSERT_DOUBLES_EQUAL( 10850, 
            haversine_km(-48.6092, 34.5622, 49, 33), 2.2 );
        CPPUNIT_ASSERT_DOUBLES_EQUAL( 11.12, 
            haversine_km(-0.1, 0, 0, 0), 0.1 );
    }

    void GpsTest::test_haversine_km_lon1_negative() {
        CPPUNIT_ASSERT_DOUBLES_EQUAL( 4778, 
            haversine_km(48.6092, -34.5622, 49, 33), 3.5 );
        CPPUNIT_ASSERT_DOUBLES_EQUAL( 15.73, 
            haversine_km(0.1, -0.1, 0, 0), 0.1 );
    }

    void GpsTest::test_haversine_km_lat2_negative() {
        CPPUNIT_ASSERT_DOUBLES_EQUAL( 12630, 
            haversine_km(48.6092, 34.5622, -49, -33), 4.5 );
        CPPUNIT_ASSERT_DOUBLES_EQUAL( 15.73, 
            haversine_km(0, 0, -0.1, 0.1), 0.1 );
    }

    void GpsTest::test_haversine_km_lon2_negative() {
        CPPUNIT_ASSERT_DOUBLES_EQUAL( 10850, 
            haversine_km(48.6092, 34.5622, -49, 33), 2.2 );
        CPPUNIT_ASSERT_DOUBLES_EQUAL( 11.12, 
            haversine_km(0, 0, 0, -0.1), 0.1 );
    }

Тесты должны быть максимально лаконичными - иначе придётся ломать голову, где же именно ошибка. Мы пока не реализовали **haversine_km**, поэтому результат будет такой:

    :::bash
    g++ -g -ldl main.cpp gps/GpsTest.cpp -lcppunit
    ./a.out

    .F.F.F.F.F.F.F.F

    GpsTest.cpp:15:Assertion
    Test name: GpsTest::test_haversine_km_params_immutable
    double equality assertion failed
    - Expected: 689.8
    - Actual  : -1
    - Delta   : 0.5

    GpsTest.cpp:25:Assertion
    Test name: GpsTest::test_haversine_km_zero
    double equality assertion failed
    - Expected: 0
    - Actual  : -1
    - Delta   : 0

    GpsTest.cpp:32:Assertion
    Test name: GpsTest::test_haversine_km_params_positive
    double equality assertion failed
    - Expected: 122.4
    - Actual  : -1
    - Delta   : 0.1

    GpsTest.cpp:37:Assertion
    Test name: GpsTest::test_haversine_km_params_negative
    double equality assertion failed
    - Expected: 122.4
    - Actual  : -1
    - Delta   : 0.1

    GpsTest.cpp:42:Assertion
    Test name: GpsTest::test_haversine_km_lat1_negative
    double equality assertion failed
    - Expected: 10850
    - Actual  : -1
    - Delta   : 2.2

    GpsTest.cpp:47:Assertion
    Test name: GpsTest::test_haversine_km_lon1_negative
    double equality assertion failed
    - Expected: 4778
    - Actual  : -1
    - Delta   : 3.5

    GpsTest.cpp:52:Assertion
    Test name: GpsTest::test_haversine_km_lat2_negative
    double equality assertion failed
    - Expected: 12630
    - Actual  : -1
    - Delta   : 4.5

    GpsTest.cpp:57:Assertion
    Test name: GpsTest::test_haversine_km_lon2_negative
    double equality assertion failed
    - Expected: 10850
    - Actual  : -1
    - Delta   : 2.2

    Failures !!!
    Run: 8   Failure total: 8   Failures: 8   Errors: 0

На самом деле это хорошо - если теперь реализовать необходимый функционал и после этого все тесты пройдут успешно, значит они имеют смысл. Теперь реализуем недостающее звено. Вот первый пример рассчёта, взятый с сайта [StackOverflow.com](http://stackoverflow.com/questions/6148814/distance-measurment-by-the-gps-coordinates "StackOverflow.com"){:rel="nofollow"}:

*gps_haversine/src/gps/gps.c*

    :::cpp
    #include <math.h>

    /*********************************************************
     *      Function Name:  haversine_km                     *
     *      Return Value:   Double                           *
     *      Parameters:     Two coordinates                  *
     *      Description:    Calculate haversine distance for *
     *                      linear distance                  *
     *********************************************************/

    #define d2r (M_PI / 180.0)

    double haversine_km(double lat1, double long1, 
                        double lat2, double long2)
    {
        double dlong = (long2 - long1) * d2r;
        double dlat = (lat2 - lat1) * d2r;
        double a = pow(sin(dlat/2.0), 2) + 
            cos(lat1*d2r) * cos(lat2*d2r) * pow(sin(dlong/2.0), 2);
        double c = 2 * atan2(sqrt(a), sqrt(1-a));
        double d = 6367 * c;

        return d;
    }

Результат выполнения:

    :::bash
    g++ -g -ldl main.cpp gps/GpsTest.cpp -lcppunit
    ./a.out

    ........

    OK (8)

Теперь вернёмся к микроконтроллерам. В представленном решении компилятор резервирует в стеке место под **девять** переменных типа **double**, это очень много. Поэтому код нужно оптимизировать, а существующие тесты помогут избежать ошибок. Вот что получилось:

*gps_haversine/src/gps/gps.c*

    :::cpp
    #include <math.h>

    /*********************************************************
     *      Function Name:  haversine_km                     *
     *      Return Value:   Double                           *
     *      Parameters:     Two coordinates                  *
     *      Description:    Calculate haversine distance for *
     *                      linear distance                  *
     *********************************************************/

    double haversine_km(double lat1, double long1, 
                        double lat2, double long2)
    {
        #define d2r (3.141592 / 180.0)
        #define sindif(v1, v2) sin(((v1 - v2) * d2r) / 2.0)

        double sdlong = sindif(long2, long1);
        double sdlat  = sindif(lat2, lat1);
        lat1 *= d2r;
        lat2 *= d2r;
        sdlong *= sdlong;
        sdlat  *= sdlat;
        double a = sdlat + cos(lat1) * cos(lat2) * sdlong;

        return 6367 * 2 * atan2(sqrt(a), sqrt(1 - a));
    }

Результат выполнения тестов аналогичен предыдущему, а исходники [тут]({attach}gps_haversine.zip).
