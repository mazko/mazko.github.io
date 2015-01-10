title: Автономный торрент-насос на MK802
category: Embedded
tags: MK802, SoC, Torrent, Avahi, Debian


Что такое торрент думаю знает каждый школьник :) Попался мне в руки одноплатный компьютер [MK802](http://ru.wikipedia.org/wiki/Android_Mini_PC_MK802){:rel="nofollow"}, который отличается очень маленькими габаритами. Под капотом сего девайса одна большая [SoC](http://ru.wikipedia.org/wiki/SoC){:rel="nofollow"} - микросхема, параметры впечатляют - ARM V7 Cortex A8 1 GHz, 1GB ОЗУ, графических процессор Mali-400 и ОС *Android* на борту. Самое замечательное что разработчики заложили возможность вместо *Android* запустить любой линукс - достаточно точно так же как например в [Raspberry Pi](http://ru.wikipedia.org/wiki/Raspberry_Pi){:rel="nofollow"} и ей подобных девайсах просто вставить созданную должным образом *micro-SD*-карту в соответствующий разъём (он там один такой) и включить. На *MK802* будем ставить *Debian* а работать в Ubuntu 12.04. Первым делом поставим в Ubuntu 12.04 необходимые для кросскомпиляции инструменты:

	:::bash
	# sudo su
	~$ apt-get install qemu-user-static binfmt-support \
	binutils-arm-linux-gnueabihf gcc-4.7-arm-linux-gnueabihf-base \
	g++-4.7-arm-linux-gnueabihf libusb-1.0-0 libusb-1.0-0-dev git \
	wget fakeroot kernel-package zlib1g-dev libncurses5-dev debootstrap

###ФАЙЛОВАЯ СИСТЕМА DEBIAN

Создааётся и монтируется виртуальный диск *debfs_armhf*:

	:::bash
	~$ mkdir allwinter
	~$ cd allwinter
	~$ mkdir debfs_armhf
	~$ dd if=/dev/zero of=debfs_armhf.img bs=1M count=1024
	~$ mkfs.ext4 -F debfs_armhf.img
	~$ mount -o loop debfs_armhf.img debfs_armhf

Туда скачивается минимальная файловая система:

	:::bash
	~$ export LC_ALL="POSIX"
	~$ export LANG="POSIX"
	~$ debootstrap --verbose --arch armhf --variant=minbase \
	--foreign stable debfs_armhf http://ftp.debian.org/debian

И наконец немного магии - в созданную файловую систему копируется arm-эмулятор *Qemu*. Этот финт ушами позволит запускать программы из файловой системы на *debfs_armhf*, используя при этом ресурсы Ubuntu 12.04 - подключение к интернету, ОЗУ и т.д.:

	:::bash
	~$ cp /usr/bin/qemu-arm-static debfs_armhf/usr/bin/
	~$ mkdir debfs_armhf/dev/pts
	~$ mount -t devpts devpts debfs_armhf/dev/pts
	~$ mount -t proc proc debfs_armhf/proc
	~$ chroot debfs_armhf/
	~$ debootstrap/debootstrap --second-stage

Для справки - настройки подключения к интернету находятся в файле *debfs_armhf/etc/resolv.conf*, если отмонтировать *debfs_armhf* и перенести на другой компьютер его нужно будет подкорректировать.

	:::bash
	~$ cat <<EOT > /etc/apt/sources.list
	deb http://ftp.debian.org/debian/ wheezy main contrib non-free
	deb-src http://ftp.debian.org/debian/ wheezy main contrib non-free
	EOT
	~$ apt-get update
	~$ apt-get install ntp udev netbase ifupdown iproute \
	openssh-server iputils-ping net-tools wget ntpdate less \
	console-tools module-init-tools apt-utils dialog locales \
	isc-dhcp-client wireless-tools wpasupplicant man-db

Пароль рута:

	:::bash
	~$ passwd nongreedy

Файловая система:

*/etc/fstab*

	:::highlight bash
	~$ cat <<EOT > /etc/fstab
	# /etc/fstab: static file system information.
	#
	# Use 'blkid' to print the universally unique identifier for a
	# device; this may be used with UUID= as a more robust way to name 
	# devices that works even if disks are added and removed. See fstab(5).
	#
	# <file system><mount point><type><options>                 <dump><pass>
	/dev/root       /            ext4  noatime,errors=remount-ro 0     1
	tmpfs           /tmp         tmpfs defaults                  0     0
	EOT

К сети MK802 будет подключаться по WI-FI, нужно задать параметры сети. В простейшем случае если точка доступа открытая и именуется скажем SSID_NONGREEDY:

	:::bash
	~$ cat <<EOT > /etc/network/interfaces
	auto lo
	iface lo inet loopback

	auto wlan0 
	iface wlan0 inet dhcp
	    wireless-essid SSID_NONGREEDY
	EOT

Ну а если под паролем, то как-то так: 

	:::bash
	~$ wpa_passphrase SSID_NONGREEDY password
	network={
		ssid="SSID_NONGREEDY"
		#psk="password"
		psk=30967eef..4436f865
	}

	~$ cat <<EOT > /etc/network/interfaces
	auto lo
	iface lo inet loopback

	auto wlan0 
	iface wlan0 inet dhcp
	    wireless-essid SSID_NONGREEDY
	    wpa-key-mgmt WPA-PSK
	    wpa-psk 30967eef..4436f865
	EOT

Выйти из *chroot* окружения можно ```ctrl-d```, перед этим не помешает убедиться что все файлы записались на диск командой ```sync```:

	:::bash
	~$ sync
	<ctrl-d>
	~$ umount debfs_armhf/proc debfs_armhf/dev/pts
	~$ cd debfs_armhf/ && tar -cvz * -f ../mk802rootfs.tgz && cd ..

Имеем файловую систему, запакованную в *mk802rootfs.tgz*. 

###СБОРКА ЯДРА LINUX И ЗАГРУЗЧИКА

Тут много способов прострелить себе ногу, поэтому все действия лучше свести к минимуму:

	:::bash
	# cd sunxi-bsp && git pull && git submodule update --init --recursive
	~$ git clone --recursive git://github.com/linux-sunxi/sunxi-bsp.git

Перед сборкой необходимо задать цель и не помешает переключиться на последний стабильный бранч ядра Linux:

	:::bash
	~$ cd sunxi-bsp/linux-sunxi/ && git checkout sunxi-3.4 && cd ..
	~$ ./configure | grep mk802
	Usage: ./configure <board>

	supported boards:
		* mk802 mk802-android
		* mk802ii mk802ii-android
		* mk802-1gb mk802-1gb-android
		* mk802_a10s mk802_a10s-android

	~$ ./configure mk802-1gb

Ещё ради интереса можно залезть в настройки модулей ядра:

	:::bash
	~$ make linux-config # делать не обязательно
	~$ make # или make EXTRAVERSION=-Nongreedy

Если ```make``` отработал без ошибок, приступаем к созданию SD-карты:

	:::bash
	~$ scripts/sunxi-media-create.sh /dev/mmcblk0 \
	output/mk802-1gb_hwpack.tar.xz ../mk802rootfs.tgz
	~$ sync

Вставляем SD-карту в MK802, включаем и скрещиваем пальцы :) Через минутку-другую устройство должно зарегистрироваться в WI-FI сети. Список можно просматривать так:

	:::bash
	~$ watch -n 0,1 arp-scan -l --interface=wlan0
	Interface: wlan0, datalink type: EN10MB (Ethernet)
	Starting arp-scan 1.8.1 with 256 hosts
	192.168.1.1	00:0e:2e:2a:df:90	Edimax Technology Co., Ltd.
	192.168.1.10	00:1e:58:b7:cc:ad	D-Link Corporation
	192.168.1.15	08:9e:01:20:e8:e6	(Unknown)
	192.168.1.122	e0:cb:4e:c1:30:77	ASUSTek COMPUTER INC.
	192.168.1.203	00:25:22:b9:40:21	ASRock Incorporation
	192.168.1.205	00:17:31:50:e2:32	ASUSTek COMPUTER INC.
	192.168.1.209	f8:1a:67:80:f0:dd	(Unknown)
	192.168.1.227	d8:d3:85:38:60:35	Hewlett Packard
	192.168.1.235	00:e0:4c:2c:0e:82	REALTEK SEMICONDUCTOR CORP.
	192.168.1.233	f0:7b:cb:0f:3e:e4	Hon Hai Precision Ind. Co.,Ltd. 
	192.168.1.228	1c:65:9d:f9:e2:06	Liteon Technology Corporation
	192.168.1.231	48:02:2a:66:74:3f	(Unknown)
	192.168.1.240	78:ab:bb:c5:9b:e5	(Unknown)
	192.168.1.241	bc:b1:f3:14:c5:68	(Unknown)
	192.168.1.245	bc:f6:85:65:bc:38	(Unknown)

	15 packets received by filter, 0 packets dropped by kernel
	Ending arp-scan 1.8.1: 256 hosts scanned in 1.367 seconds

48:02:2a:66:74:3f по идее наш, осталось проверить:

	:::bash
	~$ ssh root@192.168.1.231

Если с первого раза не получилось, не нужно отчаиваться - лог загрузки Linux *rootfs/var/log/dmesg* в любое время можно посмотреть вставив SD-карту в любой рабочий комп.

###ЧТО-ТО ТАМ БЫЛО ПРО ТОРРЕНТЫ

Вернёмся к файловой системе. Да, где-то это уже было...

	:::bash
	~$ mount -t devpts devpts debfs_armhf/dev/pts
	~$ mount -t proc proc debfs_armhf/proc
	~$ chroot debfs_armhf/
	~$ apt-get install avahi-daemon transmission-daemon
	~$ sed -i s/#host-name=foo/host-name=torrents/ \
	/etc/avahi/avahi-daemon.conf

Пакет *avahi-daemon* - реализация протокола [ZeroConf](https://wiki.debian.org/ZeroConf){:rel="nofollow"}. Установка в */etc/avahi/avahi-daemon.conf* параметра **host-name=torrents** позволит забыть об *IP* MK802 и обращаться в пределах одной подсети через локальный *dns*: ```ssh root@torrents.local```.

Ещё не помешает менеджер подключения к интернету - всё что прописано в */etc/network/interfaces* отработает только при запуске системы, а ведь соединение ещё может быть разорвано в любой момент + процесс *transmission-daemon* может иногда падать, по такому случаю предусмотрим простейший супервайзер:

	:::bash
	~$ mkdir /home/.scripts
	~$ cat <<EOT > /home/.scripts/net-monitor.sh
	#!/bin/bash
	set +e
	cd "\`dirname "\${0}"\`"
	while true ; do
	   if ifconfig wlan0 | grep -q "inet addr:" ; then
	      /etc/init.d/transmission-daemon status > /dev/null || \
	      /etc/init.d/transmission-daemon start
	      sleep 3
	   else
	      echo "\`date\`: Network connection down! Reconnection..."
	      killall -9 ifup > /dev/null 2>&1
	      ifup --force wlan0
	      sleep 33
	   fi
	done
	EOT
	~$ chmod +x /home/.scripts/net-monitor.sh
	# для теста убрать -i
	~$ sed -i -e \
	'$i \mv /home/.scripts/ilog /home/.scripts/ilog.last || true\n' \
	/etc/rc.local
	~$ sed -i -e \
	'$i \/home/.scripts/net-monitor.sh > /home/.scripts/ilog 2>&1 &\n' \
	/etc/rc.local

Предусмотрим на SD-карточке отдельный раздел */torrents*, на котором будет файлопомойка:

	:::bash
	~$ mkdir /torrents
	~$ chmod a+rw /torrents
	~$ echo "/dev/mmcblk0p3 /torrents ext4 defaults 0 0" \
	>> /etc/fstab

Пакет *transmission-daemon* представляет из себя торрент-клиент без пользовательского интерфейса (GUI), управляемый по HTTP. После выполнения сл. команды настройки сохраняться в */etc/transmission-daemon/settings.json*:

	:::bash
	# к сожалению при выполнении из-под chroot это работает через
	# раз, и то с кучей ошибок, но вроде настройки сохраняет
	# скорее всего глюк из-за старой версии qemu-arm-static -version
	# qemu-arm version 1.0.50 (Debian 1.0.50-2012.03-0ubuntu2.1)...
	~$ /etc/init.d/transmission-daemon stop
	~$ transmission-daemon --foreground --auth \
	--username your_username --password your_password \
	--download-dir /torrents --config-dir /etc/transmission-daemon/ \
	--allowed "127.0.0.*,192.168.1.*,192.168.0.*,10.0.0.*"
	~$ sed -ie 's/\("start-added-torrents\s*":\).*/\1 false,/' \
	/etc/transmission-daemon/settings.json
	~$ chmod a+rw /etc/transmission-daemon/settings.json

Записываем SD-карточку, не забывая добавить новый раздел */torrents*, оставив для файловой системы Debian ~1GB. Для этого придётся немножко ручками подпилитиь *sunxi-media-create.sh*:

	:::bash
	~$ sync
	<ctrl-d>
	~$ umount debfs_armhf/proc debfs_armhf/dev/pts
	~$ cd debfs_armhf/ && tar -cvz * -f ../mk802rootfs.tgz && cd ..
	~$ cd sunxi-bsp/
	# строка 82 scripts/sunxi-media-create.sh:
	#  x=$(expr $BOOT_SIZE \* 2048)
	#  sfdisk --in-order -L -uS "$dev" <<-EOT
	#  2048,$x,c
	#  ,,L
	#  EOT
	# => 
	#  x=$(expr $BOOT_SIZE \* 2048)
	#  sfdisk --in-order -L -uS "$dev" <<-EOT
	#  2048,$x,c
	#  ,$(expr 1024 \* 2048),
	#  ,,L
	#  EOT
	# строка 99 =>:
	#  title "Format Partition 3 to EXT4"
	#  mkfs.ext4  ${subdevice}3 ||
	#    die "${subdevice}3: failed to format partition"
	~$ scripts/sunxi-media-create.sh /dev/mmcblk0 \
	output/mk802-1gb_hwpack.tar.xz ../mk802rootfs.tgz
	~$ sync

Проверить, что торрент-демон запущен и функционирует должным образом можно из браузера [torrents.local:9091](http://torrents.local:9091/){:rel="nofollow"}. Для управления *transmission-daemon* написано много клиентов - богатый [выбор](http://www.transmissionbt.com/resources/){:rel="nofollow"}. Мне вот по душе пришелся [этот](https://github.com/fagga/transmission-remote-cli){:rel="nofollow"} - скромно и со вкусом. Забирать скачанные торренты можно по ssh: ```scp -r root@torrents.local:/torrents .``` или любым другим удобным способом, например:

	:::bash
	~$ ssh root@torrents.local
	~$ adduser torrents
	~$ usermod -a -G debian-transmission torrents
	~$ /etc/init.d/transmission-daemon stop
	~$ sed -ie 's/\("umask\s*":\).*/\1 2,/' \
	/etc/transmission-daemon/settings.json
	~$ /etc/init.d/transmission-daemon start
	<ctrl-d>
	~$ scp -r torrents@torrents.local:/torrents .

[Далее]({filename}2014-02-08-wifi-acces-point-for-linux-mk802.md) рассмотрим случай настройки WI-FI в режиме точки доступа.

P.S. ```chmod a+rw /torrents``` необходимо делать по ssh, видимо диск должен быть физически примонтирован. Если кто знает почему внизу можно оставлять комментарии :)
