title: NGSPICE.js - колебательный контур
category: Electronics
tags: gEDA, ngspice

[Продолжаем]({filename}../2016-10-28-ngspice-introduction/2016-10-28-ngspice-introduction.md) осваивать NGSPICE.

Колебательный контур (КК) - электрическая цепь, содержащая катушку индуктивности, конденсатор и источник электрической энергии. Если частота источника энергии совпадает с собственной частотой контура происходит замечательное явление, которое в физике называют резонансом. Резонансная частота контура определяется так называемой формулой Томсона: ```f = 1/(2π√LC)```. При последовательном соединении элементов цепи происходит резонанс напряжений, при параллельном - резонанс токов.

[схема последовательного КК]({attach}serial.sch) | [netlist]({attach}serial.net) | [ngspice.js](https://ngspice.js.org/?gist=5e3f4a6715af6a2a93ffb06da9f3d023)

![screenshot]({attach}show-img-serial.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source serial.net
    ngspice 2 -> ac lin 1000 3780Hz 3800Hz
    ngspice 3 -> alter r1 2m
    ngspice 4 -> ac lin 1000 3780Hz 3800Hz
    ngspice 5 -> plot ac1.i(v1) ac2.i(v1)

При резонансе напряжений электрический импеданс КК стремится к величине активного сопротивления R1. Добротность КК определяется величиной сопротивления R1 - чем оно меньше тем выше добротность и тем уже полоса пропускания. По формуле частота резонанса [равна](https://bc.js.org/) ```1/(2*3.14*sqrt(42*10^-6*42*10^-6)) = 3791.3 ``` Гц.

![screenshot]({attach}serial-canvas.png){:style="width:100%; border:1px solid #ddd;"}

В следующей схеме для исследования работы параллельного КК источник переменного напряжения заменён на источник переменного тока:

[схема параллельного КК]({attach}parallel.sch) | [netlist]({attach}parallel.net) | [ngspice.js](https://ngspice.js.org/?gist=21c6cf0b8c1274661bf845c5313b6408)

![screenshot]({attach}show-img-parallel.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source parallel.net
    ngspice 2 -> ac lin 1000 3780Hz 3800Hz
    ngspice 3 -> alter r1 2k
    ngspice 4 -> ac lin 1000 3780Hz 3800Hz
    ngspice 5 -> plot ac1.v(n1) ac2.v(n1)

При резонансе токов импеданс КК также стремится к величине R1, при этом полоса пропускания уменьшается при увеличении R1. 

![screenshot]({attach}parallel-canvas.png){:style="width:100%; border:1px solid #ddd;"}

Далее [полупроводники]({filename}../2016-10-31-ngspice-diode/2016-10-31-ngspice-diode.md).