title: NGSPICE.js - RC фильтр нижних частот
category: Electronics
tags: gEDA, ngspice

[Продолжаем]({filename}../2016-10-28-ngspice-introduction/2016-10-28-ngspice-introduction.md) осваивать NGSPICE.

Фильтр нижних частот (ФНЧ, low-pass filter) - электронный или любой другой фильтр, эффективно пропускающий частотный спектр сигнала ниже некоторой частоты (частоты среза) и подавляющий частоты сигнала выше этой частоты. ФВЧ - это соответственно high-pass filter.

RC-фильтры предстваляют собой цепочку, состоящую из резистора и конденсатора. В зависимости от их расположения фильтр пропускает или верхние или нижние частоты. Частота среза ```f = 1/(2πRC)```

[схема ФНЧ]({attach}rcSIN.sch) | [netlist]({attach}rcSIN.net) | [ngspice.js](https://ngspice.js.org/?gist=1bc9e1a86a0a9de1d2d14ad8c7ed381e)

![screenshot]({attach}show-img-sin.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source rcSIN.net
    ngspice 2 -> tran 0.05us 25us
    ngspice 3 -> plot n0 n1

Transient (tran) - анализ поведения системы во времени. В данном случае шаг 0.05, общее время 25.

![screenshot]({attach}sin-canvas.png){:style="width:100%; border:1px solid #ddd;"}

Амплитудно-частотная характеристика (АЧХ) - зависимость амплитуды выходного сигнала от частоты входного сигнала:

[схема ФНЧ]({attach}rcAC.sch) | [netlist]({attach}rcAC.net) | [ngspice.js](https://ngspice.js.org/?gist=5e8d12da0a8572c0100f671b8fdfe348)

![screenshot]({attach}show-img-ac.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source rcAC.net
    ngspice 2 -> ac lin 1000 0.1 250kHz
    ngspice 3 -> plot n0 n1

Частота среза по [формуле](https://bc.js.org/) ```1/(2*3.14*10000*10^-9) = 15923.57 Hz```

![screenshot]({attach}ac-canvas.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source rcAC.net
    ngspice 2 -> ac lin 1000 0.1 250kHz
    ngspice 3 -> plot n1 xlog

Для АЧХ [логарифмическая](https://ngspice.js.org/?gist=cb74cef950521d483073204ba92ce141) шкала как правило выглядит нагляднее:

![screenshot]({attach}ac-xlog-canvas.png){:style="width:100%; border:1px solid #ddd;"}

[Далее]({filename}../2016-10-30-ngspice-resonance/2016-10-30-ngspice-resonance.md) явление резонанса.