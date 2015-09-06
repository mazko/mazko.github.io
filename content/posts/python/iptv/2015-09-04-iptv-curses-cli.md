title: Суровый IPTV клиент для крепких духом
category: Python
tags: MK802, adb, iptv, chroot, hls

В плохую погоду спутниковое ТВ не всегда надёжно показывает, посему неплохо обзавестись запасным вариантом, особенно если есть хороший инет. Некоторые современные телевизоры уже поддерживают технологию [Smart TV](https://ru.wikipedia.org/wiki/Smart_TV){:rel="nofollow"} но увы не все. Вместе с тем лицезреть потоковое вещание можно и на другий девайсах помимо ТВ - планшетах, ПК и т.д. где есть экран и возможнось подключения к интернету. В итоге вооружившись приставкой [MK802]({filename}../../embedded/elinux/MK802/2014-01-25-torrent-client-with-mini-pc-mk802.md), на которой стоит родной Android:

    :::bash
    ~$ adb shell getprop ro.build.version.release
       4.0.4
    ~$ adb shell getprop ro.build.version.sdk
       15
    ~$ adb shell cat /proc/cpuinfo
       Processor   : ARMv7 Processor rev 2 (v7l)
       BogoMIPS    : 59.63
       Features    : swp half thumb fastmult vfp edsp neon vfpv3 
       CPU implementer : 0x41
       CPU architecture: 7
       CPU variant : 0x3
       CPU part    : 0xc08
       CPU revision    : 2
       Hardware    : sun4i
       Revision    : 0000
       Serial      : 07c142e6535648488077714916236792
    ~$ adb shell cat /proc/meminfo
       MemTotal:         833516 kB
       MemFree:          418632 kB
       ...

И имея представление на что можно рассчитывать по скорости WIFI *MK802* в локалке :

    :::bash
    ~$ adb shell nc -lp 7777 > /dev/null
    ~$ ADB_IP=`adb shell busybox ifconfig wlan0 | \
       grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1`
    ~$ cat /dev/urandom | pv | nc $ADB_IP 7777
       26,3MB 0:02:07 [ 243kB/s] [                         <=>                        ]

И кстати в данном случае скорость прямо скажем слабенькая, похоже соседи опять чего-то намутили с *WIFI* частотами :( Но не всё так плохо - мы тут не первые, есть поле для экспериментов с каналами *WIFI* на своём роутере, а на Android довольно много штуковин наподобие *com.farproc.wifi.analyzer*, хватает такого добра и под *Linux*:

    :::bash
    ~$ sudo add-apt-repository ppa:wseverin/ppa
    ~$ sudo apt-get update
    ~$ sudo apt-get install linssid

![LinSSID]({attach}wifi-channels.png){:style="width:100%; border:1px solid #ddd;"}

Итак android от [производителя](https://ru.wikipedia.org/wiki/Android_Mini_PC_MK802){:rel="nofollow"} поддерживает аппаратное декодирование видео потока, поэтому даже несмотря на слабенькие показатели CPU и ОЗУ можно побороться за HD качество 1080x720. 

Попытка номер раз - [BubbleUPnP UPnP/DLNA](https://play.google.com/store/apps/details?id=com.bubblesoft.android.bubbleupnp&hl=ru){:rel="nofollow"} рендерер + [MX Player](https://play.google.com/store/apps/details?id=com.mxtech.videoplayer.ad&hl=ru){:rel="nofollow"} + [MX Player кодек (ARMv7 NEON)](https://play.google.com/store/apps/details?id=com.mxtech.ffmpeg.v7_neon&hl=ru){:rel="nofollow"} на стороне *MK802* ну и контроллер (control point) типа [gupnp-av-cp](https://wiki.gnome.org/Projects/GUPnP){:rel="nofollow"} на стороне ПК. Работает нестабильно причём намертво подвисают что *BubbleUPnP* что *MX Player* и вернуть девайс к жизни можно только присоединив мышку/adb kill/передёрнув питание. Вобщем приятного мало :(

Попытка номер два - свести всё управление *MX Player* к суровым *adb* командам, сам *adb* научить работать без *USB* шнура по *WIFI*, *BubbleUPnP* с вещами на выход, а [Zeroconf](https://ru.wikipedia.org/wiki/Zeroconf){:rel="nofollow"} заменить чем попадётся под руку хоть бы и простым перебором IP-адресов в локалке: 

*player.sh*

    :::bash
    #!/bin/bash

    # chmod +x player.sh && sudo ln -s "`pwd`/player.sh" /usr/local/bin/play-to-tv

    set -e
    EXEC_TIMEOUT=15

    # zeroconf replacement
    timeout $EXEC_TIMEOUT adb shell true > /dev/null 2>&1 || {
      BASE_IP=`hostname -I | sed 's/\.[0-9 \t]*$//'`
      IPLIST=`for i in {1..254}; do ( \
        ping $BASE_IP.$i -c 1 -w $EXEC_TIMEOUT  >/dev/null && echo "$BASE_IP.$i" &); done`
      for ip in $IPLIST
      do
        adb kill-server > /dev/null 2>&1
        echo "adb connecting $ip"
        timeout $EXEC_TIMEOUT adb connect $ip > /dev/null 2>&1 || continue
        sleep 1
        timeout $EXEC_TIMEOUT adb shell true > /dev/null 2>&1 && break || continue
      done
    }

    # MX Player Free + Neon Codecs (adb shell cat /proc/cpuinfo | grep neon) + 
    # org.adblockplus.android + 
    # com.ttxapps.wifiadb +
    # com.farproc.wifi.analyzer to select best channel
    case "$1" in
      "-p")
        # pause
        timeout $EXEC_TIMEOUT adb shell input keyevent 62
        ;;
      "-f")
        # seek forward 
        timeout $EXEC_TIMEOUT adb shell input keyevent 22
        ;;
      "-b")
        # seek backward
        timeout $EXEC_TIMEOUT adb shell input keyevent 21
        ;;
      "-c")
        # copy title, url to clipboard
        echo -ne "#EXTINF:0,$2\n$3" | xclip -selection clipboard 2>&1
        ;;
      *)
        # stop
        timeout $EXEC_TIMEOUT adb shell "am force-stop com.mxtech.videoplayer.ad"
        # $# variable will tell you the number of input arguments the script was passed
        if [ $# -ne 0 ]
          then
            # play url $@
            timeout $EXEC_TIMEOUT adb shell \
              "am start -W -a action.intent.action.VIEW \
              -n com.mxtech.videoplayer.ad/.ActivityScreen -d '$@'"
        fi
        ;;
    esac

Установка в систему и пример использования:

    :::bash
    ~$ chmod +x player.sh && sudo ln -s "`pwd`/player.sh" /usr/local/bin/play-to-tv
    ~$ play-to-tv http://www.lanet.tv/playlist.m3u
       adb connecting 192.168.0.1
       adb connecting 192.168.0.102
       adb connecting 192.168.0.100
       adb connecting 192.168.0.101
       Starting: Intent { act=action.intent.action.VIEW \
                          dat=http://www.lanet.tv/playlist.m3u \
                          cmp=com.mxtech.videoplayer.ad/.ActivityScreen }
       Status: ok
       Activity: com.mxtech.videoplayer.ad/.ActivityScreen
       ThisTime: 1400
       TotalTime: 1400
       Complete
    ~$ play-to-tv # stop

Можно проигрывать *youtube*, локальные файлы отдавать по *http* и т.п.:

    :::bash
    ~$ youtube-dl -f "[width <= 720]" -g https://www.youtube.com/watch?v=Wj4wEBt0mHI | \
       xargs play-to-tv
    ~$ busybox httpd -f -p 8910 & # serve current directory with movie.avi over http
    ~$ play-to-tv "http://`hostname -I | sed 's/^[ \t]*//;s/[ \t]*$//'`:8910/movie.avi"

Качество видео в примере с *youtube* ограниченно преднамеренно, т.к. MK802 с большим разрешением не тянет, но об этом в самом конце.

#IPTV клиент на Python

Имея на руках плейлисты нехватает простого приложения для проверки ссылок/навигации/управления:

![iptv-cli]({attach}iptv-cli.png){:style="width:100%; border:1px solid #ddd;"}

Клавиши управления:

- **ENTER**: проиграть
- **p**: пауза
- **пробел**: стоп
- **c**: скопировать в формате *m3u*
- **f**: перемотка вперёд
- **b**: перемотка взад
- **ESC**/**q**/**Q**: выход

*iptv-cli.py*

    :::python
    #!/usr/bin/env python                                                      

    # chmod +x iptv-cli.py && sudo ln -s "`pwd`/iptv-cli.py" /usr/local/bin/iptv-cli

    import curses
    import sys
    import os
    from threading import Lock

    import m3u
    from validator import Validator


    # https://gist.github.com/bellbind/3058567
    # http://stackoverflow.com/questions/14200721/how-to-create-a-menu-and-submenus-in-python-curses

    class Menu(object):
        def __init__(self, items, screen):
            self.__screen = screen
            self.__rows = len(items)
            self.__cols = max(len(l['title']) for l in items)
            self.__top = 0
            self.__left = 0

            # logcal window for line texts
            self.__pad = curses.newpad(self.__rows + 1, self.__cols)
            self.__pad.keypad(1)  # accept arrow keys
            curses.init_pair(1, curses.COLOR_GREEN, curses.COLOR_BLACK)
            curses.init_pair(2, curses.COLOR_RED, curses.COLOR_BLACK)

            self.__position = 0
            self.__items = items
            self.__good_items = set()
            self.__bad_items = set()
            self.__render_lock = Lock()

        def navigate(self, n):
            self.__position += n
            if self.__position < 0:
                self.__position = 0
            elif self.__position >= len(self.__items):
                self.__position = len(self.__items) - 1

        def render(self, data=False):
            if data:
                with self.__render_lock:
                    self.__pad.clear()
                    for index, item in enumerate(self.__items):
                        mode = curses.A_REVERSE if index == self.__position else curses.A_LOW
                        if index in self.__bad_items:
                            mode |= curses.color_pair(2)
                        elif index in self.__good_items:
                            mode |= curses.color_pair(1)
                        self.__pad.addstr(index, 0, item['title'], mode)
            size = self.__screen.getmaxyx()  # current screen size
            self.__pad.refresh(self.__top, self.__left, 0, 0, size[0] - 1, size[1] - 2)

        def show(self):
            self.render(True)

            validator = Validator(on_ok=lambda u, i: self.__good_items.add(i),
                                  on_fail=lambda u, i, e: self.__bad_items.add(i),
                                  on_finish=lambda: self.render(True))
            validator.scan([item['model'] for item in self.__items], threads=16)

            while True:

                key = self.__pad.getch()

                if key in [curses.KEY_ENTER, ord('\n')]:
                    menu_item = self.__items[self.__position]
                    if int(menu_item['play-func'](menu_item['model'])) == 0:
                        self.__good_items.add(self.__position)
                    else:
                        self.__bad_items.add(self.__position)
                    self.render(True)

                elif key in [27, ord('q'), ord('Q')]:
                    break

                elif key == ord(' '):
                    self.__items[self.__position]['stop-func']()

                elif key == ord('c'):
                    menu_item = self.__items[self.__position]
                    menu_item['copy-func'](menu_item['model'], menu_item['title'].split(None, 1)[1])

                elif key == ord('p'):
                    self.__items[self.__position]['pause-func']()

                elif key == ord('f'):
                    self.__items[self.__position]['seek-forward-func']()

                elif key == ord('b'):
                    self.__items[self.__position]['seek-backward-func']()

                elif key == curses.KEY_UP:
                    self.navigate(-1)
                    self.__top = max(self.__top - 1, 0)
                    self.render(True)

                elif key == curses.KEY_DOWN:
                    self.navigate(1)
                    size = self.__screen.getmaxyx()
                    self.__top = min(self.__top + 1, self.__rows - size[0])
                    self.render(True)

                elif key == curses.KEY_LEFT:
                    self.__left = max(self.__left - 1, 0)
                    self.render()

                elif key == curses.KEY_RIGHT:
                    size = self.__screen.getmaxyx()
                    self.__left = min(self.__left + 1, self.__cols - size[1] + 1)
                    self.render()


    class MyApp(object):
        def __init__(self, screen):
            pwd = os.path.dirname(os.path.realpath(__file__)) + os.path.sep
            m3u_items = m3u.parse(sys.argv[1] if len(sys.argv) > 1 else pwd + 'iptv.m3u')
            menu_items = map(lambda (i, x): {
                'title': '%3d. %s' % (i + 1, '? Unknown ?' if x.title is None else x.title.strip()),
                'model': x.path,
                'play-func': lambda uri: os.system(pwd + 'player.sh ' + uri + ' > /dev/null 2>&1'),
                'stop-func': lambda: os.system(pwd + 'player.sh > /dev/null 2>&1'),
                'copy-func': lambda uri, title: os.system(pwd + "player.sh -c '%s' '%s' > /dev/null 2>&1"
                                                          % (title, uri,)),
                'pause-func': lambda: os.system(pwd + 'player.sh -p > /dev/null 2>&1'),
                'seek-forward-func': lambda: os.system(pwd + 'player.sh -f > /dev/null 2>&1'),
                'seek-backward-func': lambda: os.system(pwd + 'player.sh -b > /dev/null 2>&1'),
            }, enumerate(m3u_items))
            try:
                curses.curs_set(0)  # hide cursor
                menu = Menu(tuple(menu_items), screen)
                menu.show()
            finally:
                curses.curs_set(1)


    if __name__ == '__main__':
        import locale

        locale.setlocale(locale.LC_ALL, '')
        try:
            os.environ['ESCDELAY']
        except KeyError:
            os.environ['ESCDELAY'] = '25'
        curses.wrapper(MyApp)

*m3u.py*

    :::python
    #!/usr/bin/env python 

    # more info on the M3U file format available here:
    # https://en.wikipedia.org/wiki/M3U

    import urllib2
    import codecs
    from contextlib import closing


    class Track:
        def __init__(self, length, title, path):
            self.length = length
            self.title = title
            self.path = path


    def parse(uri):
        with closing(urllib2.urlopen(uri)
                     if urllib2.splittype(uri)[0]
                     else codecs.open(uri, 'r')) as inf:
            # initialize playlist variables before reading file
            playlist = []
            song = Track(None, None, None)

            for line_no, line in enumerate(inf):
                try:
                    line = line.strip(codecs.BOM_UTF8).strip()
                    if line.startswith('#EXTINF:'):
                        # pull length and title from #EXTINF line
                        length, title = line.split('#EXTINF:')[1].split(',', 1)
                        song = Track(length, title, None)
                    elif line.startswith('#'):
                        # comment, #EXTM3U
                        pass
                    elif len(line) != 0:
                        # pull song path from all other, non-blank lines
                        song.path = line
                        playlist.append(song)

                        # reset the song variable so it doesn't use the same EXTINF more than once
                        song = Track(None, None, None)
                except Exception, ex:
                    raise Exception("Can't parse line %d: %s" % (line_no, line), ex)

        return playlist


    if __name__ == '__main__':
        m3ufile = 'http://dom-ntv.ru/playlist/Playlist-m3u-IPTV-dom-ntv.m3u'
        playlist = parse(m3ufile)
        for item in playlist:
            print (item.title, item.length, item.path)

*validator.py*

    :::python
    #!/usr/bin/env python  

    from threading import Thread
    import urllib2
    import codecs
    from contextlib import closing


    class Validator:
        def __init__(self, on_fail=None, on_ok=None, on_finish=None):
            for func in [on_fail, on_ok, on_finish]:
                if func is not None and not callable(func):
                    raise
            self.__on_fail = on_fail
            self.__on_ok = on_ok
            self.__on_finish = on_finish
            self.__async_scan_thread = None

        def scan(self, *args, **kwargs):
            if self.__async_scan_thread and self.__async_scan_thread.is_alive():
                raise
            self.__async_scan_thread = Thread(target=self.__scan_worker, args=args, kwargs=kwargs)
            self.__async_scan_thread.daemon = True
            self.__async_scan_thread.start()
            return self

        def __scan_worker(self, candidates, threads=2, timeout=11):
            iterable = iter(enumerate(candidates))
            workers = []
            for _ in range(threads):
                thread = Thread(target=self.__worker, args=(iterable, timeout))
                workers.append(thread)
                thread.daemon = True
                thread.start()
            for thread in workers:
                thread.join()
            if self.__on_finish:
                self.__on_finish()

        def __worker(self, iterable, timeout):
            while True:
                pair = next(iterable, None)
                if pair is None:
                    break
                index, uri = pair
                try:
                    with closing(urllib2.urlopen(uri, timeout=timeout)
                                 if urllib2.splittype(uri)[0]
                                 else codecs.open(uri, 'r')):
                        if self.__on_ok:
                            self.__on_ok(uri, index)
                except Exception, e:
                    if self.__on_fail:
                        self.__on_fail(uri, index, e)

        def join_all(self, timeout=None):
            self.__async_scan_thread.join(timeout)
            return self


    if __name__ == '__main__':
        urls = (
            'http://vm-edge-nolanet.la.net.ua/tv/9053.m3u8',
            'http://vm-edge-nolanet.la.net.ua/tv/9014.m3u8',
            'http://vm-edge-nolanet.la.net.ua/tv/9018.m3u8',
            'http://vm-edge-nolanet.la.net.ua/tv/9035.m3u8',
            'http://vm-edge-nolanet.la.net.ua/tv/9050.m3u8',
            'http://vm-edge-nolanet.la.net.ua/tv/9060.m3u8',
            'http://vm-edge-nolanet.la.net.ua/tv/1001.m3u8',
            'cool.mp3',
            'validator.pyc',
        )

        from threading import Lock

        print_lock = Lock()


        def pr(x, y, z):
            with print_lock:
                print x, y, z


        Validator(
            on_ok=lambda url, index: pr('Success: ', url, index),
            on_fail=lambda url, index, err: pr('Fail: ', url, index),
            on_finish=lambda: pr('finished !', '!', '!')
        ).scan(urls, threads=4).join_all().scan(urls, threads=16).join_all()

#Транскодирование

HD видео с *youtube* на *MK802* тормозит и вот почему:

    :::bash
    ~$ youtube_url=`youtube-dl -f best -g https://www.youtube.com/watch?v=Wj4wEBt0mHI`
    ~$ play-to-tv "$youtube_url" && avprobe "$youtube_url"
    ~$ watch adb shell dumpsys cpuinfo
       Load: 3.26 / 2.5 / 2.34
       CPU usage from 15467ms to 2888ms ago:
         92% 7254/com.mxtech.videoplayer.ad: 86% user + 5.8% kernel / faults: 42 minor
         3.9% 87/surfaceflinger: 2.6% user + 1.3% kernel
         1.1% 7031/mediaserver: 0.3% user + 0.7% kernel
         0.4% 156/system_server: 0.2% user + 0.2% kernel / faults: 83 minor
         0.3% 7128/kworker/0:0: 0% user + 0.3% kernel
         0.2% 6894/kworker/u:2: 0% user + 0.2% kernel
         0.2% 7185/kworker/u:3: 0% user + 0.2% kernel
         0% 38/nfmtd: 0% user + 0% kernel
         0% 58/hdmi proc: 0% user + 0% kernel
         0% 224/com.android.systemui: 0% user + 0% kernel / faults: 2 minor
         0% 554/adbd: 0% user + 0% kernel / faults: 42 minor
       100% TOTAL: 91% user + 6.5% kernel + 2.3% softirq

И тем не менее потрудившись всё же можно из этой малютки выжать 1280x720, если ведео поток нарезать сегментами [hls](https://en.wikipedia.org/wiki/HTTP_Live_Streaming){:rel="nofollow"}. Справится с подобной задачей помогут [vlc](https://wiki.videolan.org/Documentation:Streaming_HowTo/Streaming_for_the_iPhone/){:rel="nofollow"} и [FFmpeg/Libav](https://www.ffmpeg.org/){:rel="nofollow"}. *FFmpeg* имеет смысл собрать из [исходников](https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu){:rel="nofollow"} на чистой файловой системе:

    :::bash
    ~$ sudo apt-get install schroot debootstrap
    ~$ mkdir -p ~/chroots/transcoding
       # ls /usr/share/debootstrap/scripts/
    ~$ sudo debootstrap vivid ~/chroots/transcoding
    ~$ cp /etc/schroot/schroot.conf /etc/schroot/schroot.conf.old
    ~$ conf=`cat <<EOF
    [vivid-transcoding]
    description=Video transcoding toolchain
    aliases=transcoding
    type=directory
    directory=$HOME/chroots/transcoding
    users=$USER
    EOF`
    ~$ sudo sh -c "echo '$conf' >> /etc/schroot/schroot.conf"
    ~$ schroot -c transcoding # schroot -a
    ~$ sudo apt-get install software-properties-common command-not-found man-db
    ~$ sudo add-apt-repository 'deb http://archive.canonical.com/ubuntu vivid partner'
    ~$ sudo add-apt-repository 'deb http://no.archive.ubuntu.com/ubuntu/ vivid universe'
    ~$ sudo add-apt-repository 'deb http://no.archive.ubuntu.com/ubuntu/ vivid multiverse'
    ~$ sudo apt-get update && sudo apt-get install python-pip wget busybox libssl-dev 
    ~$ bash # load command-not-found index
    ~$ sudo pip install youtube_dl

В [инструкции](https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu){:rel="nofollow"} по сборке *FFmpeg* почему-то забыли поддержку *https*, поэтому добавить *--enable-openssl* и заодно убрать [*--prefix=*, *--bindir=*]:

    :::bash
    ~$ ffmpeg -version
       ffmpeg version N-74774-g5d12d7d Copyright (c) 2000-2015 the FFmpeg developers
       built with gcc 4.9.2 (Ubuntu 4.9.2-10ubuntu13)
       configuration: --pkg-config-flags=--static --extra-cflags=-I/home/oleg/ffmpeg_build/include \
       --extra-ldflags=-L/home/oleg/ffmpeg_build/lib --enable-gpl --enable-libass \
       --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame --enable-libopus \
       --enable-libtheora --enable-libvorbis --enable-libvpx --enable-libx264 \
       --enable-libx265 --enable-nonfree --enable-openssl
       libavutil      54. 31.100 / 54. 31.100
       libavcodec     56. 59.100 / 56. 59.100
       libavformat    56. 40.101 / 56. 40.101
       libavdevice    56.  4.100 / 56.  4.100
       libavfilter     5. 40.101 /  5. 40.101
       libswscale      3.  1.101 /  3.  1.101
       libswresample   1.  2.101 /  1.  2.101
       libpostproc    53.  3.100 / 53.  3.100
    ~$ mkdir -p /tmp/hls-$$/ && busybox httpd -f -p 8910 -h /tmp/hls-$$/ &
    ~$ youtube='https://www.youtube.com/watch?v=Wj4wEBt0mHI'
    ~$ rm -rf /tmp/hls-$$/* && ffmpeg -i `youtube-dl -f best -g $youtube` \
    -codec copy -hls_time 11 -hls_list_size 333  -hls_flags delete_segments \
    -threads 16 -bsf:v h264_mp4toannexb /tmp/hls-$$/live.m3u8
    
Пробуем снова - картинка хорошая, тормозов нет:

    :::bash
    ~$ play-to-tv "http://`hostname -I | sed 's/^[ \t]*//;s/[ \t]*$//'`:8910/live.m3u8"
    ~$ watch adb shell dumpsys cpuinfo
       Load: 2.5 / 2.34 / 2.27
       CPU usage from 12991ms to 7273ms ago with 99% awake:
         10% 7031/mediaserver: 0% user + 10% kernel
         5.7% 3/ksoftirqd/0: 0% user + 5.7% kernel
         1.3% 156/system_server: 0.5% user + 0.8% kernel / faults: 20 minor
         1% 224/com.android.systemui: 1% user + 0% kernel / faults: 3 minor
         0.8% 87/surfaceflinger: 0.5% user + 0.3% kernel
         0.3% 7368/com.mxtech.videoplayer.ad: 0.3% user + 0% kernel / faults: 1 minor
         0.1% 7339/kworker/0:0: 0% user + 0.1% kernel
       34% TOTAL: 8.5% user + 25% kernel + 0.1% irq + 0.3% softirq

Притом что это по-прежнему HD, всё по честному :):

    :::bash
    ~$ avprobe "http://`hostname -I | sed 's/^[ \t]*//;s/[ \t]*$//'`:8910/live.m3u8"
       avprobe version 9.18-6:9.18-0ubuntu0.14.04.1+fdkaac, Copyright (c) 2007-2014 
       built on Apr 10 2015 23:18:58 with gcc 4.8 (Ubuntu 4.8.2-19ubuntu1)
       [hls,applehttp @ 0xebd200] Estimating duration from bitrate, this may be inaccurate
       Input #0, hls,applehttp, from 'http://192.168.0.102:8910/live.m3u8':
       Duration: N/A, start: 23.600000, bitrate: N/A
        Stream #0.0: Video: h264 (High), yuv420p, 1280x720 [PAR 1:1 DAR 16:9], \
        25 fps, 25 tbr, 90k tbn, 50 tbc
        Stream #0.1: Audio: aac, 44100 Hz, stereo, fltp
       [h264 @ 0xefb540] Ignoring NAL unit 9 during extradata parsing
       # avprobe output

Исходники [тут]({attach}iptv-cli.zip).
