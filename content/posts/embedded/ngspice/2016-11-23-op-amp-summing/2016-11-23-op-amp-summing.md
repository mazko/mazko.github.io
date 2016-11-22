title: NGSPICE.js - сумматоры напряжений на ОУ
category: Embedded 
tags: gEDA, ngspice, ОУ

[Продолжаем]({filename}../2016-10-28-ngspice-introduction/2016-10-28-ngspice-introduction.md) осваивать NGSPICE вообще и [ОУ]({filename}../2016-11-18-op-amp-basics/2016-11-18-op-amp-basics.md) в частности.

Наличие виртуальной земли в [инвертирующем]({filename}../2016-11-22-op-amp-inverting/2016-11-22-op-amp-inverting.md) усилителе позволяет просто и элегантно решить задачу сложения напряжений входных сигналов от разных источников таким образом, чтобы они не оказывали взаимного влияния друг на друга. При этом для каждого из входных напряжений можно добавить свой коэффициент или как ещё говорят вес. Данная схема включения получила название *инвертирующий сумматор* и для идеального ОУ напряжение на выходе рассчитывается по простой формуле ```Vout = -Rf*((Vin1/Rf1)+(Vin2/Rf2)+...)``` в зависимости от количества суммируемых входов.

В следующих схемах использовалась SPICE модель операционного усилителя [LT1007]({attach}LT1007CS.txt).

[схема инвертирующего сумматора + тестовый сумматор без ОУ]({attach}inverting-summator.sch) | [netlist]({attach}inverting-summator.net) | [ngspice.js](https://ngspice.js.org/?gist=a4ad89b810370046865df1eb4beca38c)

![screenshot]({attach}show-img-inverting-summator.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source inverting-summator.net
    ngspice 2 -> dc vin1 -10 4 0.1
    ngspice 3 -> plot v(out) (-v(test))

При ```Vin1=-10``` алгебраическая сумма входных напряжений ```-10+3-5=-12``` или ```12``` с инверсией и т.д. Как видно на картинке если бы мы не использовали ОУ а использовали обычные резисторы Rx то результат трудно назвать суммированием напряжений.

![screenshot]({attach}inverting-summator-canvas.png){:style="width:100%; border:1px solid #ddd;"}

Так как в основе инвертирующего сумматора лежит инвертирующего усилитель то для однополярного питания в принципе всё так же. Классический случай применения следующей схемы - качественный микшер аудио сигналов от нескольких источников.

[инвертирующий сумматор с однополярным питанием]({attach}inverting-summator-single.sch) | [netlist]({attach}inverting-summator-single.net) | [ngspice.js](https://ngspice.js.org/?gist=240fbcd9cd54346102e19984c5d24eba)

![screenshot]({attach}show-img-inverting-summator-single.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source inverting-summator-single.net
    ngspice 2 -> tran 1u 0.5m
    ngspice 3 -> plot v(out) v(in1) v(in2) v(vgnd)

Коэффициент усиления подобран единице для красоты картинки - при желании его можно изменить.

![screenshot]({attach}inverting-summator-single-canvas.png){:style="width:100%; border:1px solid #ddd;"}

Далее триггер Шмидта на ОУ.