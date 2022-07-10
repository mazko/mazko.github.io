title: NGSPICE.js - усилительный каскад с общей базой
category: Electronics
tags: gEDA, ngspice

[Продолжаем]({filename}../2016-10-28-ngspice-introduction/2016-10-28-ngspice-introduction.md) осваивать NGSPICE.

При схеме включения [биполярного транзистора]({filename}../2016-11-02-bipolar-transistor/2016-11-02-bipolar-transistor.md) с общей базой (ОБ) каскад усиливает только напряжение тогда как коэффициент передачи по току близок к единице (по факту немного меньше). Входной сигнал подаётся на эмиттер, а выходной снимается с коллектора. Основные отличия от каскада с [ОЭ]({filename}../2016-11-07-bipolar-common-emitter/2016-11-07-bipolar-common-emitter.md):

  - малое [входное]({filename}../2016-11-04-input-output-impedance/2016-11-04-input-output-impedance.md) и большое выходное сопротивление

  - коэффициент передачи по току близок к единице

  - фазы входного и выходного сигнала совпадают

  - отсутствует «паразитная» отрицательная обратная связь на высоких частотах с выхода на вход через ёмкость между базой и коллектором (ёмкость [Миллера]({filename}../2016-11-11-cascode-amplifier/2016-11-11-cascode-amplifier.md)), поэтому схема с общей базой наиболее часто используется для построения высокочастотных усилителей

<!-- 
<a href="{attach}2N2222.LIB"></a>
-->

В следующих схемах для симуляции использовалась SPICE модель популярного n-p-n транзистора 2N2222:

    :::bash
    ~$ wget -nc http://www.centralsemi.com/docs/csm/2N2222.LIB

[простейший каскад с ОБ]({attach}simple.sch) | [netlist]({attach}simple.net) | [ngspice.js](https://ngspice.js.org/?gist=44fd7de297163ea25acb498aecc87003)

![screenshot]({attach}show-img-simple.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source simple.net
    ngspice 2 -> dc i1 0 2.5m 5u
    ngspice 3 -> plot -i(v1)
    ngspice 4 -> alter i1 0.1m
    ngspice 5 -> op
    ngspice 6 -> show q1
    ngspice 7 -> alter i1 2m
    ngspice 8 -> op
    ngspice 9 -> show q1 

Команда ```op``` по двум точкам фиксирует следующие значения - ie:-0.000100001 | ic:9.90469e-05 | vbe:0.633027 и ie:-0.00200004 | ic:0.00198885 | vbe:0.712851

Усиление по току каскада c ОБ [≈ 1 ≈ 0 дБ](https://bc.js.org/) ```(0.00198885-9.90469*10^-05)/(0.00200004-0.000100001) ≈ 0.995```

Усиление по напряжению [≈ 111](https://bc.js.org/) ```4700*(0.00198885-9.90469*10^-05)/(0.712851-0.633027)``` [≈ 40.9 дБ](https://bc.js.org/) ```20*log(111)=20*l(111)/l(10)```

[Входное]({filename}../2016-11-04-input-output-impedance/2016-11-04-input-output-impedance.md) сопротивление [≈ 42 Ом](https://bc.js.org/) ```(0.712851-0.633027)/(0.00200004-0.000100001)```

Выходное сопротивление очевидно ≈ Rc ≈ 4.7

![screenshot]({attach}simple-canvas.png){:style="width:100%; border:1px solid #ddd;"}

По аналогии с [ОЭ]({filename}../2016-11-07-bipolar-common-emitter/2016-11-07-bipolar-common-emitter.md) для того тобы усиливать переменный (синусоидальный) сигнал в схему обычно добавляют гальваническую развязку по входу и напряжение смещения.

[Далее]({filename}../2016-11-11-cascode-amplifier/2016-11-11-cascode-amplifier.md) каскодный усилитель.