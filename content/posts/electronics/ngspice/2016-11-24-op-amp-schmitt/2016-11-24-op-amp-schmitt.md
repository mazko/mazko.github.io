title: NGSPICE.js - компаратор и триггер Шмитта на ОУ
category: Electronics
tags: gEDA, ngspice, ОУ

[Продолжаем]({filename}../2016-10-28-ngspice-introduction/2016-10-28-ngspice-introduction.md) осваивать NGSPICE вообще и [ОУ]({filename}../2016-11-18-op-amp-basics/2016-11-18-op-amp-basics.md) в частности.

Компаратор сравнивает два *аналоговых* сигнала и выдаёт двоичный результат в виде 0 или 1 на выходе. Простейшую схему компаратора на [ОУ]({filename}../2016-11-18-op-amp-basics/2016-11-18-op-amp-basics.md) мы уже построили ранее - на один из входов операционного усилителя подается известное опорное напряжение, на другой - сравниваемый аналоговый сигнал, например сигнал с датчика. Так как в схеме отсутствует обратная связь, то идеальный ОУ может быть только в режиме насыщения и соответственно либо с минимальным либо максимальным уровнем напряжения питания на выходе. В зависимости от того на какой из дифференциальных входов подаётся опорное напряжение компаратор может быть соответственно инвертирующим и неинвертирующим.

<!-- 
<a href="{attach}LT1007CS.txt"></a>
-->

В следующих схемах использовалась SPICE модель операционного усилителя LT1007:

    :::bash
    ~$ wget http://cds.linear.com/docs/en/software-and-simulation/LT1007CS.txt

[неинвертирующий компаратор с однополярным питанием]({attach}comparator-single.sch) | [netlist]({attach}comparator-single.net) | [ngspice.js](https://ngspice.js.org/?gist=d120122d336d4f1856b1582c12a9a205)

![screenshot]({attach}show-img-comparator-single.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source comparator-single.net
    ngspice 2 -> tran 10u 4m
    ngspice 3 -> plot v(out) v(in)

Опорное напряжение задано делителем Rf1/Rf2 и очевидно равно 5В. При этом на вход поступает сигнал сложной формы. Компаратор отработал логически правильно сработав четырежды т.к. входное напряжение четырежды перевалило отметку 5В, однако на практике зачастую требуется иное поведение если предположить что провал напряжения посредине это была помеха. Для борьбы с этим неприятным явлением в компаратор с помощью ПОС добавляют *гистерезис* и называется такое решение [триггером Шмитта](http://www.pcbheaven.com/wikipages/The_Schmitt_Trigger/){:rel="nofollow"}.

![screenshot]({attach}comparator-single-canvas.png){:style="width:100%; border:1px solid #ddd;"}

Как видно на следующей схеме, триггер Шмитта очень похож на обычный компаратор за исключением положительной обратной связи через резистор **Rf**. Гистерезис добавляет задержку выключения компаратора и тем самым обеспечивается более высокая помехоустойчивость схемы. 

[инвертирующий триггер Шмитта с однополярным питанием]({attach}shmitt-trigger-single.sch) | [netlist]({attach}shmitt-trigger-single.net) | [ngspice.js](https://ngspice.js.org/?gist=22dbe97a1a4b121e6678a1b27ceffc12)

![screenshot]({attach}show-img-shmitt-trigger-single.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source shmitt-trigger-single.net
    ngspice 2 -> tran 10u 4m
    ngspice 3 -> plot v(out) v(in)

Приблизительный [расчёт](https://bc.js.org/) напряжений срабатывания с гистерезисом:

  - верхний порог ```V1*Rf2/(Rf2+Rx) = 15*15000/(15000+29876) ≈ 5 В```, где ```Rx = (Rf1*Rf)/(Rf1+Rf) = 47000*82000/(47000+82000) ≈ 29876 Ом```

  - нижний порог ```V1*Rx/(Rf1+Rx) = 15*12680/(47000+12680) ≈ 3.2 В```, где ```Rx = (Rf2*Rf)/(Rf2+Rf) = 15000*82000/(15000+82000) ≈ 12680 Ом```

Ну а фактически на картинке верхний порог срабатывания получился чуть меньше 5 Вольт, тогда как нижний чуть больше 3 Вольт.

![screenshot]({attach}shmitt-trigger-single-canvas.png){:style="width:100%; border:1px solid #ddd;"}

[Далее]({filename}../2016-11-28-push-pull-output/2016-11-28-push-pull-output.md) немного о выходных каскадах усилителей.