title: NGSPICE.js - усилительный каскад с общим коллектором
category: Embedded 
tags: gEDA, ngspice

[Продолжаем]({filename}../2016-10-28-ngspice-introduction/2016-10-28-ngspice-introduction.md) осваивать NGSPICE.

При схеме включения [биполярного транзистора]({filename}../2016-11-02-bipolar-transistor/2016-11-02-bipolar-transistor.md) с общим коллектором (ОК) каскад усиливает только ток тогда как коэффициент передачи по напряжению близок к единице (теоретически немного меньше). Поскольку напряжение на выходе повторяет напряжение на входе то схему включения с ОК часто называют *эмиттерным повторителем*. Основные отличия от каскада с [ОЭ]({filename}../2016-11-07-bipolar-common-emitter/2016-11-07-bipolar-common-emitter.md):

  - 100% отрицательная обратная связь по напряжению  позволяет значительно уменьшить нелинейные искажения

  - большое [входное]({filename}../2016-11-04-input-output-impedance/2016-11-04-input-output-impedance.md) и малое выходное сопротивление

  - коэффициент передачи по напряжению близок к единице

  - фазы входного и выходного сигнала совпадают

В следующих схемах для симуляции использовалась SPICE модель популярного n-p-n транзистора [2N2222]({attach}2N2222.LIB)

[простейший каскад с ОК]({attach}simple.sch) | [netlist]({attach}simple.net) | [ngspice.js](https://ngspice.js.org/?gist=5ce99532a7aa87358fcdfc949e821a94)

![screenshot]({attach}show-img-simple.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source simple.net
    ngspice 2 -> set temp=0
    ngspice 3 -> dc vin 0 11 0.1
    ngspice 4 -> set temp=50
    ngspice 5 -> dc vin 0 11 0.1
    ngspice 6 -> alter r 1k
    ngspice 7 -> dc vin 0 11 0.1
    ngspice 8 -> plot dc1.v(out) dc2.v(out) dc3.v(out)
    ngspice 9 -> alter vin 1
    ngspice 10 -> op
    ngspice 11 -> show q1
    ngspice 12 -> alter vin 9
    ngspice 13 -> op
    ngspice 14 -> show q1 

Команда ```op``` по двум точкам активного (линейного) режима работы транзистора фиксирует следующие значения - ie:-0.000373456 | ib:2.29529e-06 и ie:-0.00828277 | ib:3.71691e-05

Усиление по напряжению каскада c ОК [≈ 1 ≈ 0 дБ](https://bc.js.org/) ```1000*(0.00828277-0.000373456)/(9-1) ≈ 0.9887```

Усиление по току [≈ 227](https://bc.js.org/) ```(0.00828277-0.000373456)/(3.71691*10^-05-2.29529*10^-06)``` [≈ 47 дБ](https://bc.js.org/) ```20*log(227)=20*l(227)/l(10)``` или исходя из [первого закона Кирхгофа]({filename}../2016-10-28-ngspice-introduction/2016-10-28-ngspice-introduction.md) ```Ie/Ib = (Ic + Ib)/Ib = β + 1```

[Входное]({filename}../2016-11-04-input-output-impedance/2016-11-04-input-output-impedance.md) сопротивление [≈ 230 кОм](https://bc.js.org/) ```(9-1)/(3.71691*10^-05-2.29529*10^-06)``` или упрощённо ```β*R = (227-1)*1000 ≈ 230 кОм```

Выходное сопротивление очевидно ≈ R ≈ 1 кОм (42 Ом)

![screenshot]({attach}simple-canvas.png){:style="width:100%; border:1px solid #ddd;"}

По аналогии с [ОЭ]({filename}../2016-11-07-bipolar-common-emitter/2016-11-07-bipolar-common-emitter.md) для того тобы усиливать переменный (синусоидальный) сигнал в схему обычно добавляют гальваническую развязку по входу и напряжение смещения.

Далее усилительный каскад с общей базой.