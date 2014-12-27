title: Бесплатное определение координат по GSM сотам
category: Python
tags: GSM, Google Maps, Bluetooth, socat


Сколько раз доводилось слышать, что криминальные элементы или правоохранительные органы могут определить местоположение телефона по его номеру. Это правда :) Изначально GSM стандарты не разрабатывались для этих целей, поэтому, безусловно, *точность* полученных координат конечно же уступает всем известным GPS / ГЛОНАСС. В густонаселенных местах, где плотность базовых станций (такие закрытые будки с антеннами) большая точность повышается, а в сельской местности, на трассе соответственно уменьшается. Не особо углубляясь в теорию предлагаю посмотреть как в любое время можно определить местоположение ручками с помощью обычных AT-команд.

Итак, у каждого GSM модуля, зарегистрированного в сети мобильного оператора, всегда можно вполне легально запросить следующие параметры: 

- [MCC - Mobile Country Code](http://ru.wikipedia.org/wiki/Mobile_Country_Code){:rel="nofollow"}
- [MNC - Mobile Network Code](http://ru.wikipedia.org/wiki/Mobile_Network_Code){:rel="nofollow"}
- [LAC - Location Area Code](http://ru.wikipedia.org/wiki/Cell_Global_Identity){:rel="nofollow"}
- [CID - Cell ID](http://ru.wikipedia.org/wiki/Cell_Global_Identity){:rel="nofollow"}

Для экспериментов можно задействовать любой мобильный телефон (либо GSM модуль типа sim900, если Вы дружите с паяльником), который имеет возможность подключения к ПК. Поскольку особого желания возиться с проводами нету, самый простой способ соединить телефон и компьютер - использовать Bluetooth. Посмотрим какие устройства доступны для подключения:

    :::bash
    ~$ hcitool scan
    Scanning ...
    	00:11:22:33:44:55	Nokia 6300

Имея MAC адрес устройства, можем посмотреть список сервисов (вывод команды показан не весь):

    :::bash
    ~$ sdptool browse 00:11:22:33:44:55
    Browsing 00:11:22:33:44:55 ...
    ......
    Service Name: COM 1
    Service RecHandle: 0x10002
    Service Class ID List:
      "Serial Port" (0x1101)
    Protocol Descriptor List:
      "L2CAP" (0x0100)
      "RFCOMM" (0x0003)
        Channel: 3
    Language Base Attr List:
      code_ISO639: 0x656e
      encoding:    0x6a
      base_offset: 0x100
    ......

Цепляемся к ```Channel: 3```:

    :::bash
    ~$ rfcomm connect 0 00:11:22:33:44:55 3
    Connected /dev/rfcomm0 to 00:11:22:33:44:55 on channel 3
    Press CTRL-C for hangup

Теперь мы можем подключиться к последовательному порту ```/dev/rfcomm0```:

    :::bash
    # cu -l /dev/rfcomm0
    # screen /dev/rfcomm0
    # minicom
    ~$ putty -serial /dev/rfcomm0

После запуска ```Putty``` открывается окошко, в котором можно писать AT-команды:

    :::bash
    # ATE1
    AT
    OK

Отлично. Нас интересуют две AT-команды: ```AT+COPS``` и ```AT+CREG```, которые имеют настраиваемый формат ответа - задаём тот, который устроит:

    :::bash
    AT+COPS=0,2
    OK
    AT+CREG=2
    OK

Всё готово - запрашиваем MCC, MNC, LAC, CID:

    :::bash
    AT+COPS?
    +COPS: 0,2,"25501",0

    OK
    AT+CREG?
    +CREG: 2,1,"8174","EA45"

    OK

В сети [полно](http://lbs.ultrastar.ru/){:rel="nofollow"} онлайн сервисов, которые позволяют преобразовать MCC=255, MNC=01, LAC=8174, CID=EA45 в координаты Latitude, Longitude, но, как всегда, Гуголь знает всё:

*pygsm.py*

    :::python
    #!/usr/bin/python

    MMAP_URL = 'http://www.google.com/glm/mmap'
    GOOGLE_MAPS_URL  = 'http://maps.google.com'

    import shlex
    import csv
    import urllib2
    import serial # pip install pyserial
    import time

    def fetch_cell_from_serial(comm='/dev/rfcomm0'):

        # open serial and setup GSM module

        ser = serial.Serial(comm)
        ser.write('AT+COPS=0,2\r')
        ser.write('AT+CREG=2\r')

        # Get MCC and MNC

        ser.write('AT+COPS?\r')
        time.sleep(1)
        out = ser.read(ser.inWaiting())
        # out >>> 'AT+COPS?\r\r\n+COPS: 0,2,"25501",0\r\n\r\nOK\r\n'

        tmp = shlex.split(out) 
        # tmp >>> ['AT+COPS?', '+COPS:', '0,2,25501,0', 'OK']
        tmp = tmp[tmp.index('+COPS:') + 1] # '0,2,25501,0'
        tmp = csv.reader([tmp])
        tmp = [row for row in tmp][-1] # ['0', '2', '25501', '0']
        mcc_mnc_dec = int(tmp[-2], 16) # 152833

        # Get LAC and CID

        ser.write('AT+CREG?\r')
        time.sleep(1)
        out = ser.read(ser.inWaiting())
        # out >>> 'AT+CREG?\r\r\n+CREG: 2,1,"8174","EA45"\r\n\r\nOK\r\n'

        tmp = shlex.split(out)
        # tmp >>> ['AT+CREG?', '+CREG:', '2,1,8174,EA45', 'OK']
        tmp = tmp[tmp.index('+CREG:') + 1] # '2,1,8174,E76A'
        tmp = csv.reader([tmp])
        tmp = [row for row in tmp][-1] # ['2', '1', '8174', 'E76A']

        lac_dec = int(tmp[-2], 16) # 33140
        cid_dec = int(tmp[-1], 16) # 59242

        return cid_dec, lac_dec, mcc_mnc_dec

    def get_location_by_cell(cid_dec, lac_dec, mcc_mnc_dec):

        # Use Google to get coordinates

        a = '000E00000000000000000000000000001B0000000000000000000000030000'
        h1, h2 = divmod(mcc_mnc_dec, 100) # 152833 >>> (1528, 33)
        b = hex(cid_dec)[2:].zfill(8) + hex(lac_dec)[2:].zfill(8)
        # b >>> '0000e76a00008174'
        c = hex(h1)[2:].zfill(8) + hex(h2)[2:].zfill(8)
        # c >>> '000005f800000021'

        data = (a + b + c + 'FFFFFFFF00000000').decode('hex')
        response = urllib2.urlopen(MMAP_URL, data)
        res_hex = response.read().encode('hex')
        # res_hex >>> '000e1b0000000002e5bfbd020f49a50000097b0000004b0000'

        latitude = float(int(res_hex[14:22], 16)) / 1000000 # 48.611261
        longitude = float(int(res_hex[22:30], 16)) / 1000000 # 34.556325

        return latitude, longitude

    def format_googlemaps_link(latitude, longitude):
        return '%s?q=%f,%f' % (GOOGLE_MAPS_URL, latitude, longitude)


    if __name__ == '__main__':
        cid_dec, lac_dec, mcc_mnc_dec = fetch_cell_from_serial()
        lat, lon = get_location_by_cell(cid_dec, lac_dec, mcc_mnc_dec)
        print format_googlemaps_link(lat, lon)

Скрипт написан на питоне и использует ```pyserial``` для коммуникации с последовательным портом.

    :::bash
    ~$ python pygsm.py 
    http://maps.google.com?q=48.611261,34.556325

###ПОЛЕЗНЫЕ ТРЮКИ

Данные обмена можно снифить:

    :::bash
    #apt-get install socat
    ~$ socat -d -v -x \
    PTY,link=/dev/ttyNONGREEDY,raw,perm=777,echo=0 \
    /dev/rfcomm0,raw
    #echo -e 'AT\r' > /dev/ttyNONGREEDY
    > 2014/01/11 11:34:08.565031  length=4 from=0 to=3
     41 54 0d 0a                                      AT..
    --
    < 2014/01/11 11:34:08.743405  length=6 from=0 to=5
     0d 0a                                            ..
     4f 4b 0d 0a                                      OK..
    --

Порой для корректной работы необходимо задать источнику скорость:

    :::bash
    ~$ socat -d -v -x \
    PTY,link=/dev/ttyNONGREEDY,raw,perm=777 \
    /dev/ttyUSB0,raw,b115200 

Если нужно пробрасить последовательный порт по сети от одного компа к другому:

    :::bash
    ~$ wget -O tcp_serial_redirect.py \
    http://sourceforge.net/p/pyserial/code/HEAD/tree/trunk/\
    pyserial/examples/tcp_serial_redirect.py?format=raw
    ~$ python tcp_serial_redirect.py -b 115200 -p /dev/rfcomm0 --spy
    #ifconfig | grep -o 'inet addr:[^ ]*'
    #inet addr:192.168.1.246

    # на другом компе
    ~$ socat PTY,link=/dev/rfcomm0,perm=777 TCP:192.168.1.246:7777 

Эмулировать устройство можно так:

    :::bash
    ~$ socat -d -v -x \
    PTY,link=/dev/rfcomm0,raw,perm=777,echo=0 \
    PTY,link=/dev/ttyNONGREEDY,raw,perm=777,echo=0
    # echo -e 'AT\r' > /dev/rfcomm0
    > 2014/01/11 12:31:37.585420  length=4 from=0 to=3
     41 54 0d 0a                                      AT..
    --
    < 2014/01/11 12:31:37.586518  length=7 from=0 to=6
     41 54 0d 0a                                      AT..
     4f 4b 0a                                         OK.
    -- 

    ~$ cat /dev/ttyNONGREEDY | while read val; \
    do echo $val && \
    echo $val > /dev/ttyNONGREEDY && \
    echo 'OK' > /dev/ttyNONGREEDY; \
    done
    AT

P.S. Совсем необязательно иметь ПК чтобы получить MCC, MNC, LAC, CID с телефона - просто так удобнее для текущей задачи. Большинство производителей предоставляют API для доступа к подобного рода данным из приложений, запускаемых в их телефонах. В этом случае можно (и даже нужно) обойтись без AT команд. Вот например API для мидлетов [Nokia](http://developer.nokia.com/Community/Wiki/CS000947_-_Getting_Cell_ID_in_Java_ME){:rel="nofollow"} и т.д.
