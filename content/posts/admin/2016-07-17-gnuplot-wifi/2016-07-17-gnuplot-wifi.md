title: Ищем свободные Wi-Fi каналы с помощью GnuPlot
category: Admin
tags: GnuPlot

В эпоху интернета беспроводные Wi-Fi маршрутизаторы уже давно стали незаменимой частью нашего бытия. Wi-Fi сети работают в диапазоне 2,4 GHz либо 5 GHz и могут взаимно мешать работе друг друга например в ситуации, когда у вашего соседа тоже стоит роутер и работает на такой же частоте что и ваш. Для таких случаев в настройках роутера предусмотрена сетка каналов 1-13 (2.412GHz-2.472GHz). Соседей много, всем нужен хороший интернет. В данном материале мы научимся рисовать вот такую красивую картинку без стороннего ПО, т.е. исключительно средствами Linux и программы для построения графиков [gnuplot](http://www.gnuplot.info/){:rel="nofollow"}.

##TL;DR

![screenshot]({attach}shot.png){:style="width:100%; border:1px solid #ddd;"}


    :::bash
    ~$ sudo iwlist wlo1 scanning | python3 -c '

    import re,sys

    def tokenize(code):
        token_specification = [
            ("CELL",  r"^\s+Cell \d+"),
            ("FREQ",  r"^\s+Frequency:(\d+(\.\d*)?)"),
            ("CHNL",  r"^\s+Channel:(\d+)"),
            ("ESSID", r"^\s+ESSID:\"([-_ A-Za-z0-9]*)\""),
            ("LEVEL", r"\s+Signal level=(-\d+)"),
        ]
        tok_regex = "|".join("(?P<%s>%s)" % pair for pair in token_specification)

        for mo in re.finditer(tok_regex, code, re.M):
            typ = mo.lastgroup
            if typ == "CELL":
                if "res" in vars() and res:
                    yield res
                res = {}
            else:
                grs = [v for v in mo.groups() if v not in [mo.group(typ), None]]
                assert len(grs), "Forgot capture value for %s ?" % typ
                res[typ] = grs[0]
        if res:
            yield res

    data = list(tokenize(sys.stdin.read()))

    print(
    """
    # legend
    set key top left outside horizontal
    set xlabel "Channel"
    set ylabel "Strength (dbm)"
    # x axis step
    set xtics 1
    # show horizontal grid lines 
    set grid ytics
    set xrange [-2:16]
    set yrange [%(bottom)d - 0.05:%(top)d]
    set term png truecolor size 1280,720
    plot for [IDX=0:%(total)d-1] "-" \
        using 2:(%(bottom)d):(4):(2*abs(%(bottom)d - $1)) \
        title columnheader(1) with ellipses \
        fill transparent solid 0.5 
    """ 
    % {
        "total": len(data), 
        "top": max([int(tok["LEVEL"]) for tok in data]) + 1, 
        "bottom": min([int(tok["LEVEL"]) for tok in data]) - 5, 
    })

    for tok in data:
        print("\"%s\"" % (tok["ESSID"] or "<HIDDEN>"))
        print(tok["LEVEL"], tok["CHNL"])
        print("e")
        assert set(("FREQ","CHNL","ESSID", "LEVEL")) <= set(tok)
    ' | gnuplot > out.png

Часто полезно видеть график в реальном времени ```while sleep 10; do sudo iwlist wlo1 scanning | python3 wifi.plot.py | gnuplot > out.png; done``` и какой нибудь периодический просмотрщик изображений типа ```feh  --reload 1 out.png```

##GNUPLOT

В gnuplot можно рисовать графики как с помощью функций так и по заданным точкам. Нас интересует последний вариант:

    :::bash
    ~$ gnuplot --version
    gnuplot 4.6 patchlevel 6
    ~$ echo '
    plot for [IDX=0:1] "-" using 1:2 title columnheader(1) with lines
    hello
    1 1
    3 3
    e
    world
    1 3
    3 1
    e
    ' | gnuplot -p

![screenshot]({attach}hello.png){:style="width:100%; border:1px solid #ddd;"}

    :::bash
    ~$ echo '
    set term png truecolor size 1280,480
    set xrange [0:6]
    plot for [IDX=0:3] "-" using 2:1 title columnheader(1) with points pointsize 3
    "Anna"
    -93 1
    e
    "Erika"
    -73 1
    e
    "Alina"
    -84 1
    e
    "Nast"
    -93 5
    e
    ' | gnuplot > wifi.points.png

![screenshot]({attach}wifi.points.png){:style="width:100%; border:1px solid #ddd;"}

    :::bash
    ~$ echo '
    set term png truecolor size 1280,480
    set xlabel "Channel"
    set ylabel "Strength (dbm)"
    set xrange [0:6]
    set yrange [-110:-60]
    set grid ytics
    plot for [IDX=0:3] "-" using 2:1:(2):(abs($1/3)) title columnheader(1) with ellipses
    "Anna"
    -93 1
    e
    "Erika"
    -73 1
    e
    "Alina"
    -84 1
    e
    "Nast"
    -93 5
    e
    ' | gnuplot > wifi.ellipses.png

![screenshot]({attach}wifi.ellipses.png){:style="width:100%; border:1px solid #ddd;"}

Мы ввели зависимость высоты эллипса от уровня сигнала. Осталось правильно её пересчитать, закрасить полупрозрачностью и опустить вниз на половину. Также gnuplot не обрабатывает точки, находящиеся за предалами xrange, yrange - поэтому к yrange для страховки прибавлено ~0.05.