title: NGSPICE.js - инвертирующий усилитель на ОУ
category: Embedded 
tags: gEDA, ngspice, ОУ

[Продолжаем]({filename}../2016-10-28-ngspice-introduction/2016-10-28-ngspice-introduction.md) осваивать NGSPICE вообще и [ОУ]({filename}../2016-11-18-op-amp-basics/2016-11-18-op-amp-basics.md) в частности.

В инвертирующем усилителе входной сигнал подаётся на инвертирующий вход ОУ, туда же заведена ООС, при этом неинвертирующий вход заземлён. Отличительными особенностями данной схемы для идеального ОУ являются:

  - [входное сопротивление]({filename}../2016-11-04-input-output-impedance/2016-11-04-input-output-impedance.md) эквивалентно величине резистора Rg

  - фаза сигнала на выходе сдвинута на 180° по отношению к входному

  - коэффициент усиления по напряжению ```-Rf/Rg```, т.е. может быть < 1 и соответственно диапазон шире чем у [неинвертирующего]({filename}../2016-11-21-op-amp-non-inverting/2016-11-21-op-amp-non-inverting.md)

  - В предположении, что разность напряжений между входами ОУ равна нулю, цепь обратной связи должна работать так, чтобы поддерживать потенциал инвертирующего входа также равным нулю. Этот потенциал иногда называют **виртуальной землёй** 


<!-- 
<a href="{attach}LT1007CS.txt"></a>
-->

В следующих схемах использовалась SPICE модель операционного усилителя LT1007:

    :::bash
    ~$ wget http://cds.linear.com/docs/en/software-and-simulation/LT1007CS.txt

[схема инвертирующего усилителя]({attach}inverting.sch) | [netlist]({attach}inverting.net) | [ngspice.js](https://ngspice.js.org/?gist=2b635c0b8bae28e0ab4152cde6eb475d)

![screenshot]({attach}show-img-inverting.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source inverting.net
    ngspice 2 -> dc vin -10m 10m 20u
    ngspice 3 -> plot v(out) ylimit -10 10

Коэффициент усиления схемы ```365000/365 = 1000```, т.е. при 10 мВ на входе на выходе будет 10 В.

![screenshot]({attach}inverting-canvas.png){:style="width:100%; border:1px solid #ddd;"}

При однополярном питании необходимо подать стабильное напряжение смещения - в простейшем случае это конденсатор C2, наличие которого повышает устойчивость системы от самовозбуждения при просадках напряжения в неидеальном источнике питания.

[инвертирующий усилитель с однополярным питанием]({attach}inverting-single.sch) | [netlist]({attach}inverting-single.net) | [ngspice.js](https://ngspice.js.org/?gist=fb963c63f640a5012853ae869a6ee912)

![screenshot]({attach}show-img-inverting-single.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source inverting-single.net
    ngspice 2 -> tran 1u 0.5m
    ngspice 3 -> plot v(out) v(in) v(vgnd)

Обратная связь обеспечивает коэффициент усиления ```100k/50k = 2```, напряжение смещение как обычно половина напряжения питания. В активном режиме напряжение в точке виртуальной земли равно напряжению смещения независимо от уровня входного сигнала. Фазы входного и выходного сигнала сдвинуты на 180°.

![screenshot]({attach}inverting-single-canvas.png){:style="width:100%; border:1px solid #ddd;"}

 Коэффициент нелинейных искажений для ОУ усилителей очень [низкий](https://ngspice.js.org/?gist=ba2f8531a36037d47487ce7074520f84) THD: 5.6773e-05 %, что является следствием сильной ООС.

    :::text
    ngspice 4 -> fourier 10k v(out)

[Далее]({filename}../2016-11-23-op-amp-summing/2016-11-23-op-amp-summing.md) сумматоры напряжений на ОУ.