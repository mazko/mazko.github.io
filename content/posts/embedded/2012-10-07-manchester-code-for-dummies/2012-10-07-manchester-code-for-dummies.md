title: Манчестерский код для чайников
category: Embedded
tags: TDD, Манчестерский код, gtest, gmock


*Манчестерский Код* - это самосинхронизирующийся двоичный код без постоянной составляющей, в котором значение каждого передаваемого бита определяется направлением смены логического уровня в середине обусловленного заранее временного интервала. Поскольку логических уровней у самой маленькой единицы информации (бит) на данный момент известно всего два (1 и 0),  вариантов тут немного: либо смена 1 => 0 либо 0 => 1. Согласно общепринятым стандартам для *Манчестерского кода* переход от нуля к единице считается 1, а если наоборот, то 0. На самом деле последнее утверждение - это просто формальность - вопрос в том, с какой стороны посмотреть ;-) Главное, чтобы и приёмник и передатчик смотрели на жизнь одинаково.

![Код Манчестер]({attach}man_diagram.png){:style="width:100%; border:1px solid #ddd;"}

Введите число и нажмите "**Encode Manchester!**":

<script type="text/javascript" src="{attach}manchester.js"> </script>

<p>
<input maxlength="25" size="10" id="manchester_query" value="0x623" style="text-align: right; padding:.3em;" type="text"/>
<button type="button" style="padding:.2em;" onclick="manchester_encode_and_print();"><noscript><span style="color:red;">Включите JavaScript ! </span></noscript>Encode Manchester!</button>
</p>
<p id="manchester_result">
</p>

Теперь давайте внимательно посмотрим на картинку и попробуем проанализировать и перечислить основные преимущества и недостатки преобразования данных в *Манчестерский Код*:

- Pазмер данных увеличивается вдвое - это негативно сказывается на скорости передачи

- Kоличество логических нулей всегда равно количеству логических единиц, соответственно у такого сигнала не будет постоянной составляющей - это крайне важно для электрических цепей и радиоволн

- Комбинация логических уровней 11 однозначно говорит о последнем принятом 0, а комбинация 00, соответственно, говорит о 1. Таким образом после одной из них приёмник синхронизируется

- Не может идти последовательно более двух одинаковых логических уровней, т.е. комбинация типа 111 или 000 невозможна

- В начале данных и в конце не может быть двух одинаковых логических уровней - только 10 или 01

###Сначала пишем тест

О пользе тестов можно почитать [тут](https://ru.wikipedia.org/wiki/%D0%9C%D0%BE%D0%B4%D1%83%D0%BB%D1%8C%D0%BD%D0%BE%D0%B5_%D1%82%D0%B5%D1%81%D1%82%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5){:rel="nofollow"}. В контексте решения текущей задачи будет использоваться техника **Mock**-объектов, поэтому используемую ранее в примерах среду тестирования **CppUnit** проще заменить связкой **gtes**t([Google Test](http://code.google.com/p/googletest-translations/w/list){:rel="nofollow"}) + **gmock**([Google Mocking Framework](http://code.google.com/p/googletest-translations/w/list){:rel="nofollow"}). Они поставляются в исходниках, поэтому единственное требование к системе - совместимый **C** / **C++** компилятор, например **gcc g++** для **Linux** или **Visual Studio C++** для **Windows**.

Так же как и в случае с **CppUnit**, прежде всего необходимо реализовать простое консольное приложение, которое будет собираться вместе с тестами и запускать их:

*/manchester/tests/gtest/main.cpp*

	:::cpp
	#include "gtest/gtest.h"

	int main(int argc, char* argv[]) {
	    testing::InitGoogleTest(&argc, argv);
	    return RUN_ALL_TESTS();
	}

Теперь сами тесты. Более простой задачей является преобразование данных в *Манчестерский Код* (**encode**), поэтому с неё, пожалуй, и начнём:

*/manchester/tests/gtest/src/manchester/Man_Encode.cpp*

	:::cpp
	#include <gtest/gtest.h>
	#include <gmock/gmock.h>

	extern "C"
	{
	    #include "../../../../manchester/src/tx/Man_Encode.c"
	}

	class IManEncode {
	    public:
	        virtual void Man_Encode_One() = 0;
	        virtual void Man_Encode_Zero() = 0;
	};

	/* Mock implementation */

	ACTION_P2(Act_Inc_1, T, V) {
	    ON_CALL(*T, Man_Encode_One())
	        .WillByDefault(Act_Inc_1(T, testing::ByRef(++V)));
	}

	ACTION_P2(Act_Inc_0, T, V) {
	    ON_CALL(*T, Man_Encode_Zero())
	        .WillByDefault(Act_Inc_0(T, testing::ByRef(++V)));
	}

	class ManEncodeMock : public IManEncode {
	    public:
	        MOCK_METHOD0(Man_Encode_One,void());
	        MOCK_METHOD0(Man_Encode_Zero,void());

	        ManEncodeMock() {
	            _total_1 = _total_0 = 0;
	            ON_CALL(*this, Man_Encode_One())
	                .WillByDefault(Act_Inc_1(this, testing::ByRef(_total_1)));
	            ON_CALL(*this, Man_Encode_Zero())
	                .WillByDefault(Act_Inc_0(this, testing::ByRef(_total_0)));
	        }

	        void Expect_Total_1_And_0_Eq(int total) {
	            EXPECT_EQ(_total_1, total);
	            EXPECT_EQ(_total_0, total);
	        }

	    private:
	        int _total_1, _total_0;
	};

	/* Fixture class for each test */

	class ManEncodeTest_F : public testing::Test {
	    public:
	        static ManEncodeMock* getMock() {
	            return _ManEncodePtr;
	        }

	    protected:
	        virtual void SetUp() {
	            _ManEncodePtr = &_ManEncode;
	        }

	    private:
	        ManEncodeMock _ManEncode;
	        static ManEncodeMock* _ManEncodePtr;    
	};

	ManEncodeMock* ManEncodeTest_F::_ManEncodePtr;

	/* Man_Encode externs (events) */

	void On_Man_Encode_One() {
	    ManEncodeTest_F::getMock()->Man_Encode_One();
	}

	void On_Man_Encode_Zero() {
	    ManEncodeTest_F::getMock()->Man_Encode_Zero();
	}

	/* 0 => 1010101010101010(manchester) */

	TEST_F(ManEncodeTest_F, Send_0) {
	    testing::InSequence s;
	    for (int i = 0; i < 8; i++) {
	        EXPECT_CALL(*getMock(), Man_Encode_One()); // MSB
	        EXPECT_CALL(*getMock(), Man_Encode_Zero());
	    }

	    Man_Encode(0);

	    getMock()->Expect_Total_1_And_0_Eq(8);
	}

	/* 255(dec) => 11111111(bin) => 0101010101010101(manchester) */

	TEST_F(ManEncodeTest_F, Send_255) {
	    testing::InSequence s;
	    for (int i = 0; i < 8; i++) {
	        EXPECT_CALL(*getMock(), Man_Encode_Zero()); // MSB
	        EXPECT_CALL(*getMock(), Man_Encode_One());
	    }

	    Man_Encode(255);

	    getMock()->Expect_Total_1_And_0_Eq(8);
	}

	/* 170(dec) => 10101010(bin) => 0110011001100110(manchester) */

	TEST_F(ManEncodeTest_F, Send_170) {
	    testing::InSequence s;
	    EXPECT_CALL(*getMock(), Man_Encode_Zero()); // MSB
	    for (int i = 0; i < 3; i++) {
	        EXPECT_CALL(*getMock(), Man_Encode_One()).Times(2);
	        EXPECT_CALL(*getMock(), Man_Encode_Zero()).Times(2);
	    }
	    EXPECT_CALL(*getMock(), Man_Encode_One()).Times(2);
	    EXPECT_CALL(*getMock(), Man_Encode_Zero());

	    Man_Encode(170);

	    getMock()->Expect_Total_1_And_0_Eq(8);
	}

	/* 85(dec) => 01010101(bin) => 1001100110011001(manchester) */

	TEST_F(ManEncodeTest_F, Send_85) {
	    testing::InSequence s;
	    EXPECT_CALL(*getMock(), Man_Encode_One()); // MSB
	    for (int i = 0; i < 3; i++) {
	        EXPECT_CALL(*getMock(), Man_Encode_Zero()).Times(2);
	        EXPECT_CALL(*getMock(), Man_Encode_One()).Times(2);
	    }
	    EXPECT_CALL(*getMock(), Man_Encode_Zero()).Times(2);
	    EXPECT_CALL(*getMock(), Man_Encode_One());

	    Man_Encode(85);

	    getMock()->Expect_Total_1_And_0_Eq(8);
	}

	/* 84(dec) => 01010100(bin) => 1001100110011010(manchester) */

	TEST_F(ManEncodeTest_F, Send_84) {
	    testing::InSequence s;
	    EXPECT_CALL(*getMock(), Man_Encode_One()); // MSB
	    for (int i = 0; i < 3; i++) {
	        EXPECT_CALL(*getMock(), Man_Encode_Zero()).Times(2);
	        EXPECT_CALL(*getMock(), Man_Encode_One()).Times(2);
	    }
	    EXPECT_CALL(*getMock(), Man_Encode_Zero());
	    EXPECT_CALL(*getMock(), Man_Encode_One());
	    EXPECT_CALL(*getMock(), Man_Encode_Zero());

	    Man_Encode(84);

	    getMock()->Expect_Total_1_And_0_Eq(8);
	}

Все тесты помещены в макрос `TEST_F()`. В начале теста с помощью `EXPECT_CALL()` необходимо установить ожидаемое поведение. В процессе преобразования *0 => 1010101010101010* и при условии, что старший бит идёт первым (*MSB*), ожидается последовательный вызов методов `On_Man_Encode_One()`  и `On_Man_Encode_Zero()` и так восемь раз. После того, как ожидаемое поведение описано, необходимо вызвать проверяемый метод `Man_Encode()`. Если реальное поведение отличается от ожидаемого, в процессе выполнения тестов будет сообщено об ошибке. В конце каждого теста также выполняется проверка условия, что количество нулей равно количеству единиц.

Преобразовать данные в *Манчестерский Код* очень легко:

*/manchester/src/tx/Man_Encode.c*

	:::cpp
	#include "Man_Encode.h"

	/********************************************************************
	 *      Function Name:  Man_Encode                                  *
	 *      Return Value:   no                                          *
	 *      Parameters:     character to transmit                       *
	 *      Description:    Convert char to Manchester Code (2 chars)   *
	 *                      MSB is first to convert                     *
	 ********************************************************************/

	void Man_Encode(register char character) {
	    register unsigned char bitcount = 8;

	    while (bitcount--) {
	        if (character & 0x80) {
	            On_Man_Encode_Zero();
	            On_Man_Encode_One();

	        } else {
	            On_Man_Encode_One();
	            On_Man_Encode_Zero();
	        }
	        character <<= 1;
	    }
	}

Реализация обратной задачи - декодирования данных из *Манчестерского Кода* в оригинальный несколько сложнее. Перед началом передачи данных необходимо синхронизироваться с приёмником сиигнала. В реализации тестов нас особо не интересует как именно приёмник синхронизируется и в какой последовательности будут вызваны(если вообще будут) `On_Man_Decode_Add_1()` и `On_Man_Decode_Add_0()` - для этой цели обозначим предварительные ожидания как `testing::AtMost(1)`. После синхронизации процесс декодирования можно точно спрогнозировать и описать соответствующие ожидания с помощью `EXPECT_CALL()`. Также как и в предыдущем случае в конце каждого теста проверяется отсутствие постоянной составляющей (количество нулей и единиц должно совпадать).

*/manchester/tests/gtest/src/manchester/Man_Decode.cpp*

	:::cpp
	#include <gtest/gtest.h>
	#include <gmock/gmock.h>

	extern "C"
	{
	    #include "../../../../manchester/src/rx/Man_Decode.c"
	}

	class IManDecode {
	    public:
	        virtual void Man_Dec_Add_1() = 0;
	        virtual void Man_Dec_Add_0() = 0;
	};

	/* Mock implementation */

	class ManDecodeMock : public IManDecode {
	    public:
	        MOCK_METHOD0(Man_Dec_Add_1,void());
	        MOCK_METHOD0(Man_Dec_Add_0,void());
	};

	/* Fixture class for each test */

	class ManDecodeTest_F : public testing::Test {
	    public:
	        static ManDecodeMock* getMock() {
	            return _ManDecodePtr;
	        }

	    protected:
	        virtual void SetUp() {
	            _total_1 = _total_0 = 0;
	            _ManDecodePtr = &_ManDecode;
	        }

	        void Expect_Total_1_And_0_Eq(int total) {
	            EXPECT_EQ(_total_1, total);
	            EXPECT_EQ(_total_0, total);
	        }

	        void Perform_Stable_Zero(unsigned char periods) {
	            _total_0 += periods;
	            Man_Decode_Stable_Zero(periods);
	        }

	        void Perform_Stable_One(unsigned char periods) {
	            _total_1 += periods;
	            Man_Decode_Stable_One(periods);
	        }

	    private:
	        ManDecodeMock _ManDecode;
	        static ManDecodeMock* _ManDecodePtr;
	        int _total_1, _total_0;
	};

	ManDecodeMock* ManDecodeTest_F::_ManDecodePtr;

	/* Man_Decode externs (events) */

	void On_Man_Decode_Add_1() {
	    ManDecodeTest_F::getMock()->Man_Dec_Add_1();
	}

	void On_Man_Decode_Add_0() {
	    ManDecodeTest_F::getMock()->Man_Dec_Add_0();
	}

	/* Helpers for TEST_F */

	#define EXPECT_MAN_SYNCH(x,y)                               \
	    EXPECT_CALL(*getMock(), Man_Dec_Add_##x())              \
	        .Times(testing::AtMost(1)); /* Clay? */             \
	    EXPECT_CALL(*getMock(), Man_Dec_Add_##y())              \
	        .Times(testing::AtMost(1)); /* Clay? */             \
	    EXPECT_CALL(*getMock(), Man_Dec_Add_##x()); /* Sync  */ \
	    EXPECT_CALL(*getMock(), Man_Dec_Add_##y())  /* Sync  */ \

	#define PERFORM_MAN_SYNCH(x,y)                               \
	    Perform_Stable_##x(1);  /* Clay balance (1 - 1 = 0) */   \
	    Perform_Stable_##y(2);  /* Sync balance (2 - 2 = 0) */   \
	    Perform_Stable_##x(2);  /* Sync */                       \
	    Perform_Stable_##y(1)   /* Clay */                       \

	/* 1010101010101010(manchester) => 0 */

	TEST_F(ManDecodeTest_F, Decode_0) {
	    testing::InSequence s;
	    EXPECT_MAN_SYNCH(1,0);
	    EXPECT_CALL(*getMock(), Man_Dec_Add_0()).Times(8);

	    PERFORM_MAN_SYNCH(One, Zero);
	    for (int i = 0; i < 8; i++) {
	        Perform_Stable_One(1);
	        Perform_Stable_Zero(1);
	    }

	    Expect_Total_1_And_0_Eq(11); // Sync(3) + Byte(8)
	}

	/* 0101010101010101(manchester) => 11111111(bin) => 255(dec) */

	TEST_F(ManDecodeTest_F, Decode_255) {
	    testing::InSequence s;
	    EXPECT_MAN_SYNCH(0,1);
	    EXPECT_CALL(*getMock(), Man_Dec_Add_1()).Times(8);

	    PERFORM_MAN_SYNCH(Zero, One);
	    for (int i = 0; i < 8; i++) {
	        Perform_Stable_Zero(1);
	        Perform_Stable_One(1);
	    }

	    Expect_Total_1_And_0_Eq(11); // Sync(3) + Byte(8)
	}

	/* 0110011001100110(manchester) => 10101010(bin) => 170(dec) */

	TEST_F(ManDecodeTest_F, Decode_170) {
	    testing::InSequence s;
	    EXPECT_MAN_SYNCH(0,1);
	    for (int i = 0; i < 4; i++) {
	        EXPECT_CALL(*getMock(), Man_Dec_Add_1());
	        EXPECT_CALL(*getMock(), Man_Dec_Add_0());
	    }

	    PERFORM_MAN_SYNCH(Zero, One);
	    Perform_Stable_Zero(1);
	    for (int i = 0; i < 3; i++) {
	        Perform_Stable_One(2);
	        Perform_Stable_Zero(2);
	    }
	    Perform_Stable_One(2);
	    Perform_Stable_Zero(1);

	    Expect_Total_1_And_0_Eq(11); // Sync(3) + Byte(8)
	}

	/* 1001100110011001(manchester) => 01010101(bin) => 85(dec) */

	TEST_F(ManDecodeTest_F, Decode_85) {
	    testing::InSequence s;
	    EXPECT_MAN_SYNCH(1,0);
	    for (int i = 0; i < 4; i++) {
	        EXPECT_CALL(*getMock(), Man_Dec_Add_0());
	        EXPECT_CALL(*getMock(), Man_Dec_Add_1());
	    }

	    PERFORM_MAN_SYNCH(One, Zero);
	    Perform_Stable_One(1);
	    for (int i = 0; i < 3; i++) {
	        Perform_Stable_Zero(2);
	        Perform_Stable_One(2);
	    }
	    Perform_Stable_Zero(2);
	    Perform_Stable_One(1);

	    Expect_Total_1_And_0_Eq(11); // Sync(3) + Byte(8)
	}

	/* 1001100110011010(manchester) => 84(dec) => 01010100(bin) */

	TEST_F(ManDecodeTest_F, Decode_84) {
	    testing::InSequence s;
	    EXPECT_MAN_SYNCH(1,0);
	    for (int i = 0; i < 3; i++) {
	        EXPECT_CALL(*getMock(), Man_Dec_Add_0());
	        EXPECT_CALL(*getMock(), Man_Dec_Add_1());
	    }
	    EXPECT_CALL(*getMock(), Man_Dec_Add_0()).Times(2);

	    PERFORM_MAN_SYNCH(One, Zero);
	    Perform_Stable_One(1);
	    for (int i = 0; i < 3; i++) {
	        Perform_Stable_Zero(2);
	        Perform_Stable_One(2);
	    }
	    Perform_Stable_Zero(1);
	    Perform_Stable_One(1);
	    Perform_Stable_Zero(1);

	    Expect_Total_1_And_0_Eq(11); // Sync(3) + Byte(8)
	}

Предположительная реализация процесса декодирования *Манчестерского кода*:

*/manchester/src/rx/Man_Decode.c*

	:::cpp
	#include "Man_Decode.h"

	static bool ds_LB;

	/********************************************************************
	 *      Function Name:  Man_Decode_Stable_Zero                      *
	 *      Return Value:   no                                          *
	 *      Parameters:     Stable digital input periods. Ideal 1 or 2  *
	 *      Description:    Convert signal from Manchester Code.        *
	 *                      Fire according On_Man_Decode_Add_1()        *
	 *                      callback event.                             *
	 ********************************************************************/

	void Man_Decode_Stable_Zero(register unsigned char periods) {
	    if ( periods ) {
	        if ( !--periods ) {
	            if ( ds_LB ) {
	                On_Man_Decode_Add_1();
	                ds_LB = 1;
	            }
	        } else if ( !--periods ) {
	            On_Man_Decode_Add_1();
	            ds_LB = 1;
	        }
	    }
	}

	/********************************************************************
	 *      Function Name:  Man_Decode_Stable_One                       *
	 *      Return Value:   no                                          *
	 *      Parameters:     Stable digital input periods. Ideal 1 or 2  *
	 *      Description:    Convert signal from Manchester Code.        *
	 *                      Fire according On_Man_Decode_Add_0()        *
	 *                      callback event.                             *
	 ********************************************************************/

	void Man_Decode_Stable_One(register unsigned char periods) {
	    if ( periods ) {
	        if ( !--periods ) {
	            if ( !ds_LB ) {
	                On_Man_Decode_Add_0();
	                ds_LB = 0;
	            }
	        } else if ( !--periods ) {
	            On_Man_Decode_Add_0();
	            ds_LB = 0;
	        }
	    }
	}

###Сборка и запуск тестов

Если Вы работаете в связке **Windows** + **Visual Studio**, необходимо выполнить следующее:

	:::bat
	@set GTEST_HOME=gtest-1.6.0 
	@set GMOCK_HOME=gmock-1.6.0 
	 
	cl /EHsc /I%GTEST_HOME% /I%GTEST_HOME%/include -I%GMOCK_HOME% ^
	-I%GMOCK_HOME%/include main.cpp src/manchester/Man_Encode.cpp ^
	src/manchester/Man_Decode.cpp %GTEST_HOME%/src/gtest-all.cc ^
	%GMOCK_HOME%/src/gmock-all.cc 
	 
	main.exe

![Windows Скриншот]({attach}win-gtest-gmock-run.png){:style="width:100%; border:1px solid grey;"}

При использовании **Linux** + **gcc g++**:

	:::bash
	GTEST_HOME=gtest-1.6.0
	GMOCK_HOME=gmock-1.6.0

	g++ -g -I$GTEST_HOME -I$GTEST_HOME/include -I$GMOCK_HOME \
	-I$GMOCK_HOME/include -pthread main.cpp src/manchester/Man_Encode.cpp \
	src/manchester/Man_Decode.cpp $GTEST_HOME/src/gtest-all.cc \
	$GMOCK_HOME/src/gmock-all.cc

	./a.out

![Linux Скриншот]({attach}suse_tests_run.png){:style="width:100%; border:1px solid grey;"}

Тестов много не бывает. Например, было бы неплохо добавить проверку для последовательности из двух байт и более, или проверку условия отсутствия невозможных для Манчестерского Кода комбинаций - например 111 или 000. Чем больше терпения и выдержки на этом этапе разработки - тем крепче будет сон после её сдачи в эксплуатацию.

###Практика

Тесты это хорошо, но пока что всё это больше похоже на теорию - а теория без практики, как известно, скучна. Поэтому, если Вы дочитали до этого момента, милости прошу посетить [следующий]({filename}../2012-10-07-manchester-code-real-world-example/2012-10-07-manchester-code-real-world-example.md) пост, в котором в качестве приёмника и передатчика используются два микроконтроллера, а сам процесс эмулируется в виртуальной среде, которая умеет моделировать поведение электрических цепей.

Исходники к текущему посту на [GitHub](https://github.com/mazko/Manchester-Code){:rel="nofollow"}.

