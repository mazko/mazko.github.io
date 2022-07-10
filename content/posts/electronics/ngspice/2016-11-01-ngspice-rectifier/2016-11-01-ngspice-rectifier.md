title: NGSPICE.js - выпрямитель переменного тока на диодах
category: Electronics
tags: gEDA, ngspice

[Продолжаем]({filename}../2016-10-28-ngspice-introduction/2016-10-28-ngspice-introduction.md) осваивать NGSPICE и конкретное применение [полупроводниковых диодов]({filename}../2016-10-31-ngspice-diode/2016-10-31-ngspice-diode.md) в частности.

Выпрямитель электрического тока - преобразователь электрической энергии предназначенный для преобразования входного электрического тока переменного направления в ток постоянного направления. Выпрямители используются в большинстве современных электроприборах - от зарядки для мобильного телефона до телевизоров и ноутбуков. В следующих схемах для симуляции использовалась SPICE модель диода 1n4007.

<!-- 
<a href="{attach}1n4007.txt"></a>
-->

    :::bash
    ~$ wget -nc http://www.vishay.com/docs/88000/1n4007.txt

[схема однополупериодного выпрямителя]({attach}half-wave.sch) | [netlist]({attach}half-wave.net) | [ngspice.js](https://ngspice.js.org/?gist=fd2a88aab52c56f971179c9a1bd9a502)

![screenshot]({attach}show-img-half-wave.png){:style="width:100%; border:1px solid #ddd;"}

У однополупериодных выпрямителей используется только одна полуволна постоянного тока на выходе при каждом полном цикле переменного тока на входе.

![screenshot]({attach}half-wave-canvas.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source half-wave.net
    ngspice 2 -> tran 0.5m 150m
    ngspice 3 -> alter r1 1
    ngspice 4 -> tran 0.5m 150m
    ngspice 5 -> plot tran1.v(n1) tran2.v(n1)

Куда более эффективными являются двухполупериодные выпрямители. 

[схема диодный мост]({attach}bridge.sch) | [netlist]({attach}bridge.net) | [ngspice.js](https://ngspice.js.org/?gist=2cf3ee433d7f6ab178d903d7f1c8ecef)

![screenshot]({attach}show-img-bridge.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source bridge.net
    ngspice 2 -> tran 0.5m 150m
    ngspice 3 -> alter r1 1
    ngspice 4 -> tran 0.5m 150m
    ngspice 5 -> plot tran1.v(n3) tran2.v(n3)

Диодный мост использует оба полупериода входного сигнала и поэтому имеем меньшую пульсацию напряжения на выходе и это есть очень хорошо:

![screenshot]({attach}bridge-canvas.png){:style="width:100%; border:1px solid #ddd;"}

Ещё одной интересной схемой выпрямителя является умножитель напряжения:

[схема умножитель напряжения]({attach}mul.sch) | [netlist]({attach}mul.net) | [ngspice.js](https://ngspice.js.org/?gist=b390ade98165e3b89c957c865dff87d2)

![screenshot]({attach}show-img-mul.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source mul.net
    ngspice 2 -> tran 1m 500m
    ngspice 3 -> plot n2 n4

Входное напряжение после каждой пары диодов умножается на ~2x (часть напряжения теряется на диодах). Величина выходного напряжения, достигнутая с помощью данной схемы, может быть весьма велика - например у люстры Чижевского это десятки тысяч вольт.

![screenshot]({attach}mul-canvas.png){:style="width:100%; border:1px solid #ddd;"}

[Далее]({filename}../2016-11-02-bipolar-transistor/2016-11-02-bipolar-transistor.md) биполярный транзистор.