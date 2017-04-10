title:  Введение в симуляцию электрических схем с помощью NGSPICE.js
category: Electronics
tags: gEDA, ngspice

SPICE (**S**imulation **P**rogram with **I**ntegrated **C**ircuit **E**mphasis) - алгоритм моделирования процессов, протекающих в электрических схемах, разработанный в конце 70-х годов в университете Беркли (Калифорния). NGSPICE является расширением оригинального Spice3f5 с открытым кодом.

Наиболее часто используются 5 видов анализа электронных схем:

  -  OP: Замер значений напряжения/тока при устойчивом состоянии системы. Например замер потребляемой мощности системы при отсутствии входного сигнала

  -  DC: анализ по постоянному току посредством изменения параметров источников постоянного напряжения и/или тока. Пример - снятие вольт-амперной характеристики диода

  -  AC: анализ по переменному току посредством изменения частоты. Пример - анализ частотной характеристики RC фильтра

  -  Transient: Анализ поведения системы во времени. Например подбор параметров схемы генератора электрических колебаний

  -  Fourier: Разложение функции в ряд Фурье. Позволяет качественно оценить нелинейные искажения сигнала

Начнём с проверки законов Кирхгофа с помощью простого OP анализа.

![screenshot]({attach}ui.gif){:style="width:100%; border:1px solid #ddd;"}

На вход ngspice приходит схема в формате [netlist](https://ru.wikipedia.org/wiki/%D0%A1%D0%BF%D0%B8%D1%81%D0%BE%D0%BA_%D1%81%D0%BE%D0%B5%D0%B4%D0%B8%D0%BD%D0%B5%D0%BD%D0%B8%D0%B9){:rel="nofollow"}. В данном материале для редактирования электрических схем используется [gschem](http://wiki.geda-project.org/geda:ngspice_and_gschem){:rel="nofollow"} + gnetlist.

    :::bash
    ~$ gnetlist -g spice-sdb -o kirghof.net kirghof.sch

[comment]: <> (byzanz-record -c --x=74 --y=26 --delay 5 -d 123 ui.flv)
[comment]: <> (ffmpeg -i ui.flv -pix_fmt rgb24 -r 10 -vf crop=in_w:in_h-2:0:2 "frames/frame-%05d.png")
[comment]: <> (convert -monitor -limit memory 1024MiB -limit map 2048MiB -layers removeDups -layers Optimize -delay 10 -loop 0 "frames/*.png" ui.gif)

[схема]({attach}kirghof.sch) | [netlist]({attach}kirghof.net) | [ngspice.js](https://ngspice.js.org/?gist=f416efb827fa91fd7badacc588c55bd8)

![screenshot]({attach}show-img-kirghof.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source kirghof.net
    ngspice 2 -> op
    ngspice 3 -> show v1 v2 v3
    ngspice 4 -> print i(v1) i(v2) i(v3)

Результат: i(v1) = -2.54545 | i(v2) = -1.18182 | i(v3) = -3.72727

**Первый закон Кирхгофа**: *алгебраическая сумма токов, сходящихся в любом узле, равна нулю* ( ```-2.54545 -1.18182 = -3.72727``` )

**Второй закон Кирхгофа**: *алгебраическая сумма падений напряжений на отдельных участках замкнутого контура, произвольно выделенного в сложной разветвленной цепи, равна алгебраической сумме ЭДС в этом контуре* ( ```2.54545*10 - 1.18182*30 = 40-50``` )

[Далее]({filename}../2016-10-29-ngspice-rc/2016-10-29-ngspice-rc.md) RC - цепочка.