title: NGSPICE.js - неинвертирующий усилитель на ОУ
category: Embedded 
tags: gEDA, ngspice, ОУ

[Продолжаем]({filename}../2016-10-28-ngspice-introduction/2016-10-28-ngspice-introduction.md) осваивать NGSPICE вообще и [ОУ]({filename}../2016-11-18-op-amp-basics/2016-11-18-op-amp-basics.md) в частности.

В неинвертирующем усилителе входной сигнал подаётся на неинвертирующий вход ОУ, а ООС заведена с выхода на инвертирующий вход. Отличительными особенностями данного усилителя являются:

  - [входное сопротивление]({filename}../2016-11-04-input-output-impedance/2016-11-04-input-output-impedance.md) у идеального ОУ стремиться к бесконечности

  - фаза сигнала на входе и на выходе совпадает

  - коэффициент усиления по напряжению ```1+Rf/Rg```, как не сложно догадаться он **не может быть меньше 1** - усилитель с коэффициентом 1 иногда называют буфером


В следующих схемах использовалась SPICE модель операционного усилителя [LT1007]({attach}LT1007CS.txt).

[схема неинвертирующего усилителя]({attach}non-inverting.sch) | [netlist]({attach}non-inverting.net) | [ngspice.js](https://ngspice.js.org/?gist=afbeb59caf6deff2cfead830a50cfb59)

![screenshot]({attach}show-img-non-inverting.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source non-inverting.net
    ngspice 2 -> dc vin -10m 10m 20u
    ngspice 3 -> plot v(out) ylimit -10 10

Коэффициент усиления схемы ```1+365000/365 = 1001```, т.е. при 10 мВ на входе на выходе будет 10.01 В. Для красоты картинки результат округлён до 10 с помощью ```ylimit```.

![screenshot]({attach}non-inverting-canvas.png){:style="width:100%; border:1px solid #ddd;"}

Классическая схема включения ОУ подразумевает биполярный источник питания, в предыдущем примере это ± 15В. Если в документации к ОУ не упомянуто обратное, то однополярное питание зачастую также возможно, однако потребуются дополнительные телодвижения - например подача напряжения смещения, гальваническая развязка и понимание зачем это надо. Идея такая же  как и в [транзисторных]({filename}../2016-11-07-bipolar-common-emitter/2016-11-07-bipolar-common-emitter.md) схемах усилителей:

[неинвертирующий усилитель с однополярным питанием]({attach}non-inverting-single.sch) | [netlist]({attach}non-inverting-single.net) | [ngspice.js](https://ngspice.js.org/?gist=d07144c7716c6e14452bb449f8a4d129)

![screenshot]({attach}show-img-non-inverting-single.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source non-inverting-single.net
    ngspice 2 -> tran 1u 0.5m
    ngspice 3 -> plot v(out) v(in)

Обратная связь обеспечивает коэффициент усиления ```1+100/50 = 3``` для высокочастотных сигналов и равный **единице** для постоянной составляющей - в противном случае ОУ будет усиливать собственное напряжения смещения. Также несложно убедиться фаза входного и выходного сигнала совпадает. Напряжение смещение обычно задают равным половине напряжения питания.  

![screenshot]({attach}non-inverting-single-canvas.png){:style="width:100%; border:1px solid #ddd;"}

Далее инвертирующий усилитель на ОУ.