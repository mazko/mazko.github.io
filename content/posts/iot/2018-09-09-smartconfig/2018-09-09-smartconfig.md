title:  Как работает «Smart Config»
category: IoT
tags: Wi-Fi

Обычно процедура подключения устройства (например телефона) к Wi-Fi выглядит следующим образом: телефон выполняет поиск сетей Wi-Fi, предоставляет пользователю список доступных, пользователь выбирает сеть, вводит пароль. Если же говорить об устройствах IoT, трудность заключается в том, что многие из них не имеют дисплея и клавиатуры, а зачастую у них вообще нет никакого пользовательского интерфейса. Таким устройствам нужны другие способы получения имени сети и пароля от пользователя.

Режим точки доступа (Access Point, AP) — наиболее изученный сегодня способ подключения устройств, не имеющих пользовательского интерфейса. После того как пользователь подключит свой смартфон к AP неинициализированного устройства, он открывает веб-браузер смартфона и входит на веб-сайт устройства, используя заданный локальный URL или IP-адрес. На встроенном веб-сайте пользователь выбирает имя Wi-Fi сети и пароль. Устройство сохраняет сетевые реквизиты в энергонезависимой памяти, а затем переходит из режима AP в режим станции, чтобы подключиться к домашней сети с использованием сохраненных сетевых реквизитов. Недостаток режима AP заключается в том, что при подключении к конфигурационной сети AP неинициализированного устройства телефон отключается от домашней сети. Это может вызвать перерывы в передаче данных и привести к появлению сообщений об ошибках. Также не все производители телефонов предоставляют API для программного переключения Wi-Fi сетей, пользователь вынужден это делать вручную.

Технология «Smart Config» лишена данных недостатков. Она предполагает использование ПК, телефона или планшета в качестве интерфейса пользователя, который позволяет ввести информацию о сети с помощью дисплея и клавиатуры ПК, телефона или планшета с последующей передачей введённой информации IoT-устройствам. Из известных реализаций на текущий момент стоит упомянуть CC3200 SmartConfig и ESP-Touch.

##КАК РАБОТАЕТ

Итак у нас есть два устройства — одно (телефон) уже подключено к Wi-Fi сети, и другое (IoT), которое нужно подключить к Wi-Fi сети. IoT устройство непрерывно сканирует Wi-Fi эфир. Для эксперимента понадобится два  Wi-Fi адаптера, можно даже на одном компьютере:

    :::bash
    ~$ iwconfig 2> /dev/null

Вывод:

    wlo1      IEEE 802.11  ESSID:"Dumer"  
              Mode:Managed  Frequency:2.447 GHz  Access Point: XX:XX:XX:XX:XX:XX   
              Bit Rate=121.5 Mb/s   Tx-Power=15 dBm   
              Retry short limit:7   RTS thr:off   Fragment thr:off
              Power Management:off
              Link Quality=61/70  Signal level=-49 dBm  
              Rx invalid nwid:0  Rx invalid crypt:0  Rx invalid frag:0
              Tx excessive retries:27  Invalid misc:3493   Missed beacon:0

    wlxbcf68565bc38  IEEE 802.11  ESSID:off/any  
              Mode:Managed  Access Point: Not-Associated   Tx-Power=20 dBm   
              Retry short  long limit:2   RTS thr:off   Fragment thr:off
              Power Management:off

Адаптер wlo1 подключён к сети Dumer, wlxbcf68565bc38 будет сканировать эфир. Как известно сетка частот Wi-Fi состоит из [14 каналов]({filename}../2016-07-17-gnuplot-wifi/2016-07-17-gnuplot-wifi.md), для простоты будем слушать только тот (8), к которому подключён wlo1.

    :::bash
    ~$ iwlist wlo1 channel

Вывод:

    wlo1      14 channels in total; available frequencies :
              Channel 01 : 2.412 GHz
              Channel 02 : 2.417 GHz
              Channel 03 : 2.422 GHz
              Channel 04 : 2.427 GHz
              Channel 05 : 2.432 GHz
              Channel 06 : 2.437 GHz
              Channel 07 : 2.442 GHz
              Channel 08 : 2.447 GHz
              Channel 09 : 2.452 GHz
              Channel 10 : 2.457 GHz
              Channel 11 : 2.462 GHz
              Channel 12 : 2.467 GHz
              Channel 13 : 2.472 GHz
              Channel 14 : 2.484 GHz
              Current Frequency=2.447 GHz (Channel 8)

Переведём адаптер в режим сканирования:

    :::bash
    ~$ ifconfig wlxbcf68565bc38 down
    ~$ iwconfig wlxbcf68565bc38 mode monitor
    ~$ ifconfig wlxbcf68565bc38 up
    ~$ iwconfig wlxbcf68565bc38 channel 8
    ~$ iwlist wlxbcf68565bc38 channel

Примерно так выглядит эфир Wi-Fi в WireShark:

![screenshot]({attach}wirshark.png){:style="width:100%; border:1px solid #ddd;"}

MAC адреса и кое-какая другая информация в Wi-Fi фреймах идёт в открытом виде без шифрования. Полезные данные внутри Wi-Fi фрейма зашифрованы, но мы видим их длину. Если предположить, что шифрование изменяет длину передаваемых данных на какую-то константу, почему бы не попробовать передавать данные меняя длину пакета по принципу один пакет == один байт. Для передачи 42 байт нужно отправить 42 пакета где длина каждого пакета зависит от значения передаваемого байта. Содержимое пакета нас не интересует т.к. расшифровать его могут только участники Wi-Fi сети, подключённые к роутеру. Все скрипты проверялись на **python3**:

*transmitter.py*

    :::python
    #!/usr/bin/python3

    import socket
    import binascii

    MCAST_GRP = '234.42.42.42'
    MCAST_PORT = 7001

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
    sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 2)

    def crc8(data):
      return binascii.crc32(data) & 0xFF

    def transmit_one_byte(b):
      assert(1 <= b)
      assert(b <= 548) # 576(MTU) - 20(IP) - 8(UDP)
      data = bytes(b)
      sock.sendto(data, (MCAST_GRP, MCAST_PORT))

    preamble = [515, 514, 513, 512]
    payload  = b'hello world!'

    while True:
      for c in preamble:
        transmit_one_byte(c)
      transmit_one_byte(len(payload))
      transmit_one_byte(crc8(payload))
      for c in payload:
        transmit_one_byte(c)

В текущем примере данные передаются на мультикаст адрес 234.xx.xx.xx по [UDP]({filename}../contiki/2017-10-03-udp/2017-10-03-udp.md). Вначале идёт фиксированная посылка синхронизации preamble. Содержимое preamble также известно приёмнику, сравнивая принятые пакеты с preamble он может высчитать константу, добавляемую при шифровании. Затем передаём общую длину полезных данных, их контрольную сумму и сами данные.

*receiver.py*

    :::python
    #!/usr/bin/python3

    import sys
    import binascii

    preamble = [515, 514, 513, 512]

    def crc8(data):
      return binascii.crc32(data) & 0xFF

    def decode(data, crc):
      try:
        data = bytes(data)
        if crc == crc8(data):
          print(data)
      except:
        pass

    def parse(data):
      for idx, b in enumerate(data):
        if idx >= len(preamble):
          diff = set(k-i for i, k in zip(preamble, data[idx-len(preamble):idx]))
          if len(diff) == 1 and len(data) > idx + 1:
            c = diff.pop()
            l = data[idx] - c
            payload = [d-c for d in data[idx+1:idx+2+l]]
            decode(payload[1:], payload[0])

    received = []

    for line in sys.stdin:
      line = line.strip()
      if len(received) > 42:
        received.pop(0)
      if line.isdigit():
        received.append(int(line))
        parse(received)

У Wireshark есть консольный аналог tshark. Заодно отфильтруем точно не нужные пакеты, оставив только data:

    :::bash
    ~$ tshark -i wlxbcf68565bc38 -I -T fields -e data.len subtype data | \
       python3 receiver.py

В зависимости от зашумлённости эфира часть передаваемых пакетов теряется и это неизбежно. Для увеличения надёжности можно добавить Код Хемминга, но это уже удел производителя чипов и SDK со «Smart Config» на борту.

Ключевые преимущества «Smart Config» — простота использования и возможность беспрепятственной интеграции в телефонное приложение устройства. Кроме того, если несколько устройств Wi-Fi одновременно находятся в режиме «Smart Config», одно телефонное приложение может обеспечить подключение их всех одновременно.

Основной недостаток этой технологии заключается в том, что телефон должен подключаться к сети, используя ту полосу частот и ту скорость передачи данных, которые поддерживаются неподключенным устройством. Что если неподключенное устройство поддерживает диапазон 2,4 ГГц, а телефон использует для связи с двухдиапазонной сетью диапазон 5 ГГц ?

[Исходники]({attach}smartconfig.zip).