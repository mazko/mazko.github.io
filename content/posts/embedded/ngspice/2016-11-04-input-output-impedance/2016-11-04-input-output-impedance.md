title: NGSPICE.js - согласование источника с нагрузкой
category: Embedded 
tags: gEDA, ngspice

[Продолжаем]({filename}../2016-10-28-ngspice-introduction/2016-10-28-ngspice-introduction.md) осваивать NGSPICE.

Согласование источника и нагрузки - это выбор соотношения сопротивления нагрузки и внутреннего сопротивления источника с целью достижения заданных свойств полученной системы. Наиболее часто используются следующие типы согласования:

 - Согласование по мощности - оптимальное (с минимальными потерями) согласование по мощности источника сигнала и нагрузки. При условии **Ri = Rn** коэффициент передачи по напряжению Ku равен ```Un/Vi(max) = I*Rn/(I*Ri+I*Rn) = Rn/(Ri+Rn) = 0.5```, коэффициент передачи тока Ki равен ```In/Ii(max) = (Vi/(Ri+Rn))/(Vi/Ri) = Ri/(Ri+Rn)```, коэффициент передачи по мощности Kp равен ```Kp = Pn/Pi(max) = Ku*Ki = Ri*Rн/(Ri + Rn)^2 = 0.25```

 - Согласование по напряжению - получение максимального коэффициента передачи напряжения в нагрузку. Это имеет место при выполнении условия **Rn >> Ri** (или Rn -> ∞). При этом Ku стремится к единице

 - Согласование по току заключается в получении максимального коэффициента передачи тока Ki в нагрузку. При выполнении условия **Ri >> Rn** (или Rn -> 0) Ki стремится к единице

[схема источника и нагрузки]({attach}io.sch) | [netlist]({attach}io.net) | [ngspice.js](https://ngspice.js.org/?gist=a6fae4b564d851c5f1759643dc279823)

![screenshot]({attach}show-img-io.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source io.net
    ngspice 2 -> alter ri 3k
    ngspice 3 -> dc rn 1 10k 10
    ngspice 4 -> plot v(n)^2/"res-sweep"

На картинке максимальная рассеиваемая мощность на нагрузке ```Pn = Un*In = Un^2/Rn``` наблюдается при **Rn = Ri**, пример [расчёта](https://bc.js.org/): ```Pmax = Un*In = Vi^2*Rn/(Rn+Ri)^2 = Vi^2/(4*Rn) = 42^2/(4*3000) = 0.147```:

![screenshot]({attach}io-canvas-u2.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source io.net
    ngspice 2 -> alter ri 5
    ngspice 3 -> dc rn 0 25 50m
    ngspice 4 -> plot 5*"res-sweep"/(5 + "res-sweep")^2 "res-sweep"/("res-sweep" + 5) 5/("res-sweep" + 5)

Коэффициент [передачи](https://ngspice.js.org/?gist=02707f2545ae01e6202d6ed48ff10493) по мощности Kp на максимуме равен 0.25 при **Rn = Ri** и **Ku = Ki = 0.5**:

![screenshot]({attach}io-canvas.png){:style="width:100%; border:1px solid #ddd;"}

Далее усилительный каскад с общим эмиттером.
