title: NGSPICE.js - двухтактные усилители мощности
category: Embedded 
tags: gEDA, ngspice, ОУ

[Продолжаем]({filename}../2016-10-28-ngspice-introduction/2016-10-28-ngspice-introduction.md) осваивать NGSPICE вообще и [ОУ]({filename}../2016-11-18-op-amp-basics/2016-11-18-op-amp-basics.md) в частности.

Из школьного курса по физике хорошо известна формула мощности ```P = U*I = U*U/R = I*I*R```, где последние две формулы элементарно выводятся из закона Ома, а R - не что иное, как сопротивление нагрузки. Таким образом, если взять усилитель по схеме с [ОЭ]({filename}../2016-11-07-bipolar-common-emitter/2016-11-07-bipolar-common-emitter.md) и пересчитать на меньшее выходное сопротивление, то мощность на выходе увеличится ? В теории да, однако на практике мы столкнёмся со следующими проблемами:

  - у любого электронного компонента есть предельно допустимая мощность, гарантируемая производителем - для 2N2222 это порядка 0.5 Вт, так что скорее всего нам понадобится более мощный транзистор

  - в режиме покоя (при отсутствии входного сигнала) в схеме с [ОЭ]({filename}../2016-11-07-bipolar-common-emitter/2016-11-07-bipolar-common-emitter.md) через нагрузку R протекает ток ```U/(2*R)```, поэтому чем меньше R тем больше бесполезная трата электроэнергии

Побороть эти недостатки призвана интересная схема, именуемая *двухтактным усилителем*. Рассмотрим более детально одну из её реализаций на комплементарной паре [биполярных]({filename}../2016-11-02-bipolar-transistor/2016-11-02-bipolar-transistor.md) транзисторов - тоесть транзисторов противоположной структуры (p-n-p и n-p-n), но с максимально близкими параметрами.

<!-- 
<a href="{attach}LT1007CS.txt"></a>
<a href="{attach}2N5686.LIB"></a>
<a href="{attach}2N5684.LIB"></a>
-->

В следующих схемах использовались SPICE модели операционного усилителя LT1007 и комплиментарной пары мощных транзисторов 2N5684 | 2N5686

    :::bash
    ~$ wget http://cds.linear.com/docs/en/software-and-simulation/LT1007CS.txt
    ~$ wget http://www.onsemi.com/pub/Collateral/2N5686.LIB
    ~$ wget http://www.onsemi.com/pub/Collateral/2N5684.LIB

[двухтактных усилитель на комплиментарной паре]({attach}push-pull.sch) | [netlist]({attach}push-pull.net) | [ngspice.js](https://ngspice.js.org/?gist=563e8f84d54d533ad33e0dd8d271145d)

![screenshot]({attach}show-img-push-pull.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source push-pull.net
    ngspice 2 -> tran 5u 2m
    ngspice 3 -> plot v(out) v(in)
    ngspice 4 -> fourier 3k v(out)

Схема состоит из двух транзисторов противоположной структуры, включённых по схеме с [ОК]({filename}../2016-11-09-bipolar-common-collector/2016-11-09-bipolar-common-collector.md). При положительной полуволне входного сигнала открывается один транзистор, при отрицательной другой. Таким образом мощность распределяется на оба транзистора поровну. Схема с ОК обладает высоким входным сопротивлением, низким выходным и коэффициентом усиления по напряжению порядка единицы.

![screenshot]({attach}push-pull-canvas.png){:style="width:100%; border:1px solid #ddd;"}

 Сильные искажения выходного сигнала на рисунке (fourier 35 %) объясняются тем, что биполярный транзистор открывается не сразу, а только после 0.6 Вольт. Чтобы понизить искажения транзисторы необходимо постоянно держать в приоткрытом состоянии, задав сопротивление Rb3:

    :::text
    ngspice 1 -> source push-pull.net
    ngspice 2 -> alter rb3 1k
    ngspice 3 -> tran 5u 2m
    ngspice 4 -> plot v(out)
    ngspice 5 -> fourier 3k v(out)
    ngspice 6 -> op
    ngspice 7 -> print i(v1)

Коэффициент нелинейных искажений (КНН) - в терминах ngspice Total Harmonic Distortion (THD) [снизился](https://ngspice.js.org/?gist=267e04b8fa5e4a66ea82ccae2caf9c83) до 0.0625869 %, в свою очередь по сравнению со схемой с [ОЭ]({filename}../2016-11-07-bipolar-common-emitter/2016-11-07-bipolar-common-emitter.md) КПД значительно повысился так как ток покоя данной схемы ```print i(v1)``` ≈ 95 мА, что на порядок меньше чем ```U/(2*R) = 30/16 ≈ 2 А```. Но можно лучше !

![screenshot]({attach}push-pull-canvas-bias.png){:style="width:100%; border:1px solid #ddd;"}

При однополярном питании на выходе усилителя ставят развязывающий конденсатор, причём учитывая небольшое выходное сопротивление каскада с [ОК]({filename}../2016-11-09-bipolar-common-collector/2016-11-09-bipolar-common-collector.md) для звуковых частот его ёмкость должна бить пару тысяч микрофарад - такой себе боченок внушительных размеров.

[двухтактных усилитель на ОУ с однополярным питанием]({attach}op-amp-push-pull.sch) | [netlist]({attach}op-amp-push-pull.net) | [ngspice.js](https://ngspice.js.org/?gist=2d0f909cb8624234a0126fa2f3b094dd)

![screenshot]({attach}show-img-op-amp-push-pull.png){:style="width:100%; border:1px solid #ddd;"}

    :::text
    ngspice 1 -> source op-amp-push-pull.net
    ngspice 2 -> tran 5u 2m
    ngspice 3 -> plot v(out)
    ngspice 4 -> fourier 3k v(out)
    ngspice 5 -> op
    ngspice 6 -> print i(v1)

Почему нет искажений в этой схеме ? Это магическое воздействие обратной связи - большой запас усиления вытягивает напряжение до необходимого уровня, заданного ООС, и тем самым убирает искажения. По замерам THD: 0.0387129 % тогда как ток, потребляемый при отсутствии входного сигнала, всего лишь 2.8 мА ! Очень красивое и практичное решение для портативных устройств, которые работают от батареек.

![screenshot]({attach}op-amp-push-pull-canvas.png){:style="width:100%; border:1px solid #ddd;"}

[Далее]({filename}../2016-11-30-op-amp-integrator-differentiator/2016-11-30-op-amp-integrator-differentiator.md) интегратор и дифференциатор на ОУ.