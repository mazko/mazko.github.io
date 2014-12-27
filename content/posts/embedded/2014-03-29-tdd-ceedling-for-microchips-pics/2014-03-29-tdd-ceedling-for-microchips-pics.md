title: TDD на уровне микроконтроллеров - свежий взгляд
category: Embedded
tags: Микроконтроллер, TDD, CMock, Unity


Тема профессиональной разработки ПО для микроконтроллеров с использованием современных методик на протяжении многих веков занимает прогрессивные умы человечества - в том числе и на [текущем]({filename}../2012-09-29-xp-in-microcontrollers-life/2012-09-29-xp-in-microcontrollers-life.md) ресурсе. Собственно если вкратце, то было предложено максимально разделять исходный код на отдельные модули и тестировать их на ПК независимо от железа. У данного подхода есть недостатки:

- увеличивается объём кода за счёт дополнительных функций или ```#ifdef``` на стыке с периферией (всякие *UART*, *I2C*, порты ввода-вывода и т.д.). Например логику по установке битов портов можно завернуть в функцию ```set_flag()``` и при написании тестов задействовать соотв. ей *mock* - однако это увеличит общий объём кода

- на уровне периферии код часто так и остаётся недопокрытым тестами. К примеру периферийные модули имеют свойство по характерным событиям выбрасывать флаги, наполнять регистры данными - изобретать велосипеды и придумывать фейковые периферийные модули ? Как минимум нужно прекрасно пронимать как эта периферия работает, плюс асинхронность. Да ну нафиг...

- ну а о тестировании фич типа [MIPS16](http://www.microchip.com/stellent/groups/SiteComm_sg/documents/DeviceDoc/en557154.pdf){:rel="nofollow"} вообще и говорить не приходится

Итак далее будет рассмотрен пример с использованием микроконтроллеров *Microchip*, **эмулятора** и TDD фреймворка [Ceedling](http://throwtheswitch.org/){:rel="nofollow"}. Эмулятор микроконтроллера запускается на ПК и соответственно использует его вычислительные ресурсы, а *Ceedling* это не более чем средство автоматизации, написано на *Ruby* плюс всё что может понадобится для покрытия тестами кода на *C* (*Unity*, *CMock* и даже *CException*).

	:::bash
	#apt-get install ruby
	~$ gem install ceedling
	~$ ceedling new PIC_Demo
	~$ cd PIC_Demo/
	~$ ls
	build  project.yml  rakefile.rb  src  test  vendor

Ещё нам понадобится *C* компилятор для микроконтроллеров *PIC* и среда разработки *MPLAB*. Всё это можно бесплатно зугрузить с официального сайта *Microchip* и после установки этого добра должно получиться примерно следующее:

	:::bash
	~$ which xc16-gcc
	/opt/microchip/xc16/v1.21/bin/xc16-gcc
	~$ which mplab_ide 
	/usr/bin/mplab_ide

Никак не обойтись нам без *Hello World*:

*src/hello.c*

	:::cpp
	#include <stdio.h> /* Required for printf */
	int main (void)
	{
	    printf ("Hello, world!");
	    return 0;
	}

Компиляция + линковка:

	:::bash
	~$ xc16-gcc -omf=elf -mcpu=24EP64MC206 src/hello.c \
	-o build/hello.elf -Wl,-Tp24EP64MC206.gld
	~$ file build/hello.elf
	build/hello.elf: ELF 32-bit LSB executable, \
	version 1 (SYSV), statically linked, not stripped

Эмуляция. Самый простой случай - использовать *sim30*, который поставляется вместе с *С* компилятором *xc16-gcc*:

	:::bash
	~$ echo "
	LD pic24epsuper
	LC build/hello.elf
	IO NULL /tmp/$$.txt
	RP
	E
	Q
	" | sim30
	~$ cat /tmp/$$.txt
	Hello, world!

Прелестно ! Важно отметить что при эмуляции в *sim30* есть ограничения и можно указывать только *семейства* чипов, а не какой-либо конкретно по отдельности:

	:::bash
	~$ echo DH | sim30 | grep LD 
	LD <devicename> -Load Device: \
	dspic30super dspic33epsuper pic24epsuper pic24fpsuper pic24super

Как результат в процессе эмуляции поддерживается не вся имеющаяся на борту микроконтроллера периферия и об этом мы ещё поговорим чуть позже, ну а сейчас самое время начать получать удовольствие от юнит тестов с использованием [Ceedling](http://throwtheswitch.org/){:rel="nofollow"}. В *Hello World* всего одна функция main. Не секрет, что в *C* программе функция с таким именем может быть только одна, а поскольку в *Ceedling* она уже явно имеется, для тестов *hello.c* тут нужны ```#ifdef``` - но это часный случай, исключение из правил так сказать и пугаться не стоит:

*src/hello.h*

	:::cpp
	#ifndef hello_H
	#define hello_H

	#ifdef TEST
	int test_main(void);
	#endif

	#endif // hello_H

*src/hello.c*

	:::cpp
	#include <stdio.h> /* Required for printf */
	#include "hello.h"
	#ifdef TEST
	int test_main(void)
	#else
	int main (void)
	#endif
	{
	    printf ("Hello, world!");
	    return 0;
	}

*test/test_main.c*

	:::cpp
	#include "unity.h"
	#include "hello.h"

	void setUp(void){
	}

	void tearDown(void){
	}

	void test_main_function_should_always_return_0(void){
	    TEST_ASSERT_EQUAL(0, test_main());
	}

По умолчанию *Ceedling* заточен под *gcc*, поэтому нужно допилить *project.yml*, указав компилятор, линковщик в секции ```:tools:```:

*project.yml*

	:::text
	:tools:
	  :test_compiler:
	    :executable: xc16-gcc
	    :arguments:
	      - -mcpu=24EP64MC206
	      - -x c
	      - -c
	      - "${1}"
	      - -o "${2}"
	      - -D$: COLLECTION_DEFINES_TEST_AND_VENDOR
	      - -I"$": COLLECTION_PATHS_TEST_SUPPORT_SOURCE_INCLUDE_VENDOR
	      - -Wall
	      - -Wextra
	      - -mlarge-code
	      - -mlarge-arrays
	      - -mlarge-data
	  :test_linker:
	    :executable: xc16-gcc
	    :arguments:
	      - -mcpu=24EP64MC206
	      - -omf=elf
	      - ${1}
	      - -o "./build/TestBuild.out"
	      - -Wl,-Tp24EP64MC206.gld

Запуск всех тестов выглядит так:

	:::bash
	# для просмотра всех возможностей Ceedling
	# rake -T
	~$ rake test:all
	# build/test/out/cmock.o: Link Error: \
	# Could not allocate section .bss, size = 32774 bytes, attributes = bss 
	# Link Error: Could not allocate data memory

Линковщик ругается - микроконтроллеру не хватает памяти для работы с *cmock*, поэтому уменьшим аппетиты этого замечательного инструмента в секции ```:defines:```:

*project.yml*

	:::text
	:commmon: &common_defines
	  - UNITY_INT_WIDTH=16
	  - CMOCK_MEM_INDEX_TYPE=uint16_t
	  - CMOCK_MEM_PTR_AS_INT=uint16_t
	  - CMOCK_MEM_ALIGN=1
	  - CMOCK_MEM_SIZE=4096

Пробуем:

	:::bash
	~$ rake test:all
	# ERROR: Test executable "test_main.out" failed.
	# > Produced no final test result counts in $stdout:
	# sh: 1: build/test/out/test_main.out: not found
	# > And exited with status: [127] (count of failed tests).
	# > This is often a symptom of a bad memory access in source or test code.

Тут *Ceedling* наивно пытается выполнить собранную программу *test_main.out*, но не знает как, зато мы знаем что это делается с помощью *sim30*:

*test/simulation/sim30_instruction.txt*

	:::text
	LD pic24epsuper
	LC ./build/TestBuild.out
	IO NULL ./test/simulation/out.txt
	RP
	E
	quit

*test/simulation/sim_test_fixture.rb*

	:::ruby
	OUT_FILE = "test/simulation/out.txt"
	File.delete OUT_FILE if File.exists? OUT_FILE
	pipe=IO.popen("sim30 ./test/simulation/sim30_instruction.txt")

	trap("INT") { Process.kill("KILL", pipe.pid); exit }

	Process.wait(pipe.pid)
	if File.exists? OUT_FILE
	    file_contents = File.read OUT_FILE
	    print file_contents
	else
	    print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n" \
	          "! Program was not simulated ? !\n" \
	          "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	end

Рассказать *Ceedling* в секции ```:tools:``` как всем этим управлять:

*project.yml* 

	:::text
	:test_fixture:
	  :executable: ruby
	  :name: "Microchip simulator test fixture"
	  :stderr_redirect: :win
	  :arguments:
	    - test/simulation/sim_test_fixture.rb

Запуск... Вуаля !

	:::bash
	~$ rake test:all
	# ----------------------
	# UNIT TEST OTHER OUTPUT
	# ----------------------
	# [test_main.c]
	#   - "Hello, world!"
	# -------------------------
	# OVERALL UNIT TEST SUMMARY
	# -------------------------
	# TESTED:  1
	# PASSED:  1
	# FAILED:  0
	# IGNORED: 0

Вот ! Теперь проект будет жить и развиваться вместе с тестами. Предлагаю помигать светодиодом и mockнуть результат сего действа:

*src/gpio_led.h*

	:::cpp
	#ifndef gpio_led_H
	#define gpio_led_H

	void gpio_led_init(void);
	void gpio_led_set(int brightness);
	void gpio_led_clear();

	#endif // gpio_H

*src/system.h*

	:::cpp
	#ifndef system_H
	#define system_H
	#include <stdbool.h>

	bool system_should_abort_app();

	#endif // system_H

*src/hello.c*

	:::cpp
	#include "hello.h"
	#include "system.h"
	#include "gpio_led.h"
	#ifdef TEST
	int test_main(void)
	#else
	int main (void)
	#endif
	{
	    gpio_led_init();
	    while(!system_should_abort_app()) {
	        gpio_led_set(11);
	        gpio_led_clear();
	    }
	    return 0;
	}

*test/test_main.c*

	:::cpp
	#include "unity.h"
	#include "hello.h"
	#include "mock_system.h"
	#include "mock_gpio_led.h"

	void setUp(void){
	    gpio_led_init_Expect();
	}

	void tearDown(void){
	}

	void test_main_function_without_loop(void){
	    system_should_abort_app_ExpectAndReturn(true);
	    TEST_ASSERT_EQUAL(0, test_main());
	}

	void test_main_function_loop_one_iteration(void){
	    system_should_abort_app_ExpectAndReturn(false);
	    gpio_led_set_Expect(11);
	    gpio_led_clear_Expect();
	    system_should_abort_app_ExpectAndReturn(true);
	    TEST_ASSERT_EQUAL(0, test_main());
	}

Пробуем:

	:::bash
	~$ rake test:all
	# -------------------------
	# OVERALL UNIT TEST SUMMARY
	# -------------------------
	# TESTED:  2
	# PASSED:  2
	# FAILED:  0
	# IGNORED: 0

Как несложно догадаться из *test/test_main.c* в пределах одного юнит теста *Ceedling* линкует все файлы, указанные в его ```#include```, причём если присутствует префикс ```mock```, вместо оригинальной *\*.c* имплементации *Ceedling* автоматически генерирует *mock* согласно интерфейсу, прописанному в соответствующем *\*.h*. 

Чуть ближе к железу на уровень портов ввода-вывода:

*src/gpio_led.c*

	:::cpp
	#include "gpio_led.h"
	#include <xc.h>

	void gpio_led_init() {
	    TRISAbits.TRISA0 = 0;
	}

	void gpio_led_set(int brightness) {
	    /* TODO: brightness :) */
	    LATAbits.LATA0 = 1;
	}

	void gpio_led_clear() {
	    LATAbits.LATA0 = 0;
	}

*test/test_gpio_led.c*

	:::cpp
	#include "unity.h"
	#include "gpio_led.h"
	#include <xc.h>
	#include <string.h>

	void setUp(void){
	    gpio_led_init();
	    LATABITS clean = {0};
	    memcpy((void*)&LATAbits, (void*)&clean, sizeof clean);
	}

	void tearDown(void){
	}

	void test_gpio_led_set(void){
	    TEST_ASSERT_EQUAL(0, LATAbits.LATA0);
	    gpio_led_set(11);
	    TEST_ASSERT_EQUAL(1, LATAbits.LATA0);
	}

	void test_gpio_led_clear(void){
	    test_gpio_led_set();
	    gpio_led_clear();
	    TEST_ASSERT_EQUAL(0, LATAbits.LATA0);
	}

Пробуем:

	:::bash
	~$ rake test:all
	# -------------------------
	# OVERALL UNIT TEST SUMMARY
	# -------------------------
	# TESTED:  4
	# PASSED:  4
	# FAILED:  0
	# IGNORED: 0

Очевидно, что такой *TDD* подход на порядок удобнее [предыдущих]({filename}../2012-09-29-xp-in-microcontrollers-life/2012-09-29-xp-in-microcontrollers-life.md). Тут очень многое зависит от возможностей эмулятора и иногда функционала *sim30* бывает недостаточно. Типичный пример - логика обработка прерываний:

*src/gpio_button.h*

	:::cpp
	#ifndef gpio_button_H
	#define gpio_button_H

	void gpio_button_init(void);

	#endif // gpio_H

*src/gpio_button.c*

	:::cpp
	#include "gpio_button.h"
	#include "gpio_led.h"
	#include <xc.h>

	void gpio_button_init() {
	    TRISFbits.TRISF0 = 1;
	    CNENFbits.CNIEF0 = 1;
	    IFS1bits.CNIF = 0;
	    IEC1bits.CNIE = 1;
	}

	void __attribute__((interrupt,auto_psv)) _CNInterrupt(void)
	{
	    IFS1bits.CNIF = 0;
	    gpio_led_set(42);
	}

*test/test_gpio_button.c*

	:::cpp
	#include "unity.h"
	#include "gpio_button.h"
	#include "mock_gpio_led.h"
	#include <xc.h>

	void setUp(void){
	    gpio_button_init();
	}

	void tearDown(void){
	}

	void test_gpio_button_interrupt(void){
	    gpio_led_set_Expect(42);
	    IFS1bits.CNIF = 1;
	    asm("NOP");
	}

Упс:

	:::bash
	~$ rake test:all
	# ------------------------
	# FAILED UNIT TEST SUMMARY
	# ------------------------
	# [test_gpio_button.c]
	# Test: test_gpio_button_interrupt
	# At line (13): "Function 'gpio_led_set' called less times than expected"

Похоже эмулятор *sim30* не обрабатывает прерывания. Альтернатива - использовать эмулятор *mdb* из среды разработки *MPLAB*. Текщий *MPLAB X IDE v2.05* написан на *Java* и поэтому эмулятор работает очень небыстро, ну маемо те шо маемо:

*test/simulation/mplab_sim_instructions.txt*

	:::text
	Device PIC24EP64MC206
	Hwtool SIM -p
	Program ./build/TestBuild.out
	Run
	Quit

*test/simulation/sim_test_fixture.rb*

	:::ruby
	OUT_FILE = "test/simulation/out.txt"
	File.delete OUT_FILE if File.exists? OUT_FILE

	pipe = IO.popen("/opt/microchip/mplabx/mplab_ide/bin/mdb.sh "   \
	                "./test/simulation/mplab_sim_instructions.txt " \
	                "> #{OUT_FILE}")

	trap("INT") { Process.kill("KILL", pipe.pid); exit }

	Process.wait(pipe.pid)
	if File.exists? OUT_FILE
	    file_contents = File.read OUT_FILE
	    print file_contents
	else
	    print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n" \
	          "! Program was not simulated ? !\n" \
	          "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	end

Финальный аккорд:

	:::bash
	~$ rake test:all
	# -------------------------
	# OVERALL UNIT TEST SUMMARY
	# -------------------------
	# TESTED:  5
	# PASSED:  5
	# FAILED:  0
	# IGNORED: 0

Исходники [тут]({attach}PIC_Demo.zip).
