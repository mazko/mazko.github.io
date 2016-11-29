title: NGSPICE.js - полупроводниковый диод
category: Embedded 
tags: gEDA, ngspice

[Продолжаем]({filename}../2016-10-28-ngspice-introduction/2016-10-28-ngspice-introduction.md) осваивать NGSPICE.

Полупроводниковый диод - самый простой полупроводниковый прибор, состоящий из одного PN перехода. Основная его функция - это проводить электрический ток в одном направлении, и не пропускать его в обратном. Свойства диодов наглядно показывает вольт-амперная характеристика (ВАХ) - зависимость тока через двухполюсник от напряжения на этом двухполюснике. Как мы сейчас убедимся ВАХ зависит от конкретной модели диода и температуры окружающей среды.

<!-- 
<a href="{attach}1n4007.txt"></a>
-->

Для симуляции диода в NGSPICE необходим найти (обычно на [сайте производителя](https://www.centralsemi.com/content/engineering/spicemodels/){:rel="nofollow"}) его SPICE модель - например 1n4007:

    :::bash
    ~$ wget -nc http://www.vishay.com/docs/88000/1n4007.txt

[схема прямого включения диода]({attach}diode-forward.sch) | [netlist]({attach}diode-forward.net) | [ngspice.js](https://ngspice.js.org/?gist=e93497542d39976cfcb6df1d193658c3)

![screenshot]({attach}show-img-diode-forward.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source diode-forward.net
    ngspice 2 -> set temp=0
    ngspice 3 -> dc i1 0 1 0.001
    ngspice 4 -> set temp=25
    ngspice 5 -> dc i1 0 1 0.001
    ngspice 6 -> set temp=50
    ngspice 7 -> dc i1 0 1 0.001
    ngspice 8 -> plot dc1.v(n1) dc2.v(n1) dc3.v(n1)

Кремниевый диод открывается при напряжении ~0.6 В. Чем выше температура окружающей среды, тем этот порог открывания немного меньше.

![screenshot]({attach}diode-forward-canvas.png){:style="width:100%; border:1px solid #ddd;"}

В учебниках по электронике дают обычно [перевёрнутый](https://ngspice.js.org/?gist=38b99db6363f932c6487c70c84502eb0) график ВАХ ```ngspice 8 -> plot "i-sweep" vs dc1.v(n1) "i-sweep" vs dc2.v(n1) "i-sweep" vs dc3.v(n1)```:

![screenshot]({attach}diode-forward-90-canvas.png){:style="width:100%; border:1px solid #ddd;"}

При [обратном напряжении](https://ngspice.js.org/?gist=31de19f98b10bfad7842b38ad3d99ce9) через диод протекают незначительные токи утечки и таким образом его активное сопротивление очень большое. Однако при высоком напряжении, которое может варьироваться в широких пределах в зависимости от конкретной модели диода, наступает пробой и ток через резко возрастает:

![screenshot]({attach}diode-backward-90-canvas.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source diode-forward.net
    ngspice 2 -> set temp=0
    ngspice 3 -> dc i1 -10m 0 10u
    ngspice 4 -> set temp=25
    ngspice 5 -> dc i1 -10m 0 10u
    ngspice 6 -> set temp=50
    ngspice 7 -> dc i1 -10m 0 10u
    ngspice 8 -> plot "i-sweep" vs dc1.v(n1) "i-sweep" vs dc2.v(n1) "i-sweep" vs dc3.v(n1)

Слишком большой ток вызовет необратимые изменения в кристалле диода, а вот для небольших токов явление пробоя оказывается весьма полезным. Существует целое подсемейство полупроводниковых диодов, называемых стабилитронами или диодами Зенера, для которых обратный режим работы является основным. В режиме пробоя напряжение на стабилитроне поддерживается с заданной точностью в широком диапазоне обратных токов.

[Далее]({filename}../2016-11-01-ngspice-rectifier/2016-11-01-ngspice-rectifier.md) выпрямитель переменного тока на диодах. 