title: Софтверная WI-FI точка доступа в Linux
category: Embedded
tags: MK802,кросскомпиляция,hostapd,udhcpd


Для разогрева предлагаю провести маленький эксперимент - на одной машине генерить случайные данные ```/dev/urandom```, а на другой принимать  и сливать в ```/dev/null```, тем самым замерять скорость:

	:::bash
	# sudo apt-get install sshpass pv
	~$ cat /dev/urandom | pv | sshpass -p "YOUR_SSH_PASS" \
	ssh root@torrents.local "cat > /dev/null"
	9,7GB 13:32:04 [ 376kB/s] [                    <=>    ]

Напрашиваются сл. выводы:

- WI-FI отработал стабильно > 10 ч. - на больше у автора терпения не хватило :)

- С такой скоростью далеко не уедешь :(

Предлагаю убрать посредника в виде роутера и попробовать передавать данные напрямую, переведя WI-FI модуль [MK802]({filename}2014-01-25-torrent-client-with-mini-pc-mk802.md) в режим точки доступа:

	:::bash
	~$ ssh root@torrents.local lsmod
	Module                  Size  Used by
	mali_drm                2600  0 
	drm                   209376  1 mali_drm
	mali                  110904  0 
	ump                    52145  1 mali
	8192cu                454729  0

	~$ ssh root@torrents.local lsusb | grep WLAN 
	Bus 004 Device 002: ID 0bda:8176 ... RTL8188CUS 802.11n WLAN Adapter

	~$ ssh root@torrents.local iwconfig wlan0 | grep ESSID
	wlan0 IEEE 802.11bg ESSID:"some.essid" Nickname:"<WIFI@REALTEK>"

Итого внутри MK802 впаян USB модуль RTL8188CUS от Realtek, iwconfig считает что он может работать в скоростных режимах 802.11bg, хотя производитель с этим [не согласен](http://www.realtek.com.tw/products/productsView.aspx?Langid=1&PFid=48&Level=5&Conn=4&ProdID=274){:rel="nofollow"} (802.11b/g/n). Это хитрый чип, поставляется со своим [софтом](http://www.realtek.com.tw/downloads/downloadsView.aspx?Langid=1&PFid=48&Level=5&Conn=4&ProdID=274&DownTypeID=3&GetDown=false&Downloads=true#2292){:rel="nofollow"}, т.е. в репозиториях Debian его не найти. Благо кросскомпильнуть исходники под ARM совсем несложно. Итак у нас есть RTL8188C_8192C_USB*.zip, скачанный с оф. сайта Realtek:

	:::bash
	# sudo su
	# cd allwinter
	# mount -o loop debfs_armhf.img debfs_armhf
	# mount -t devpts devpts debfs_armhf/dev/pts
	# mount -t proc proc debfs_armhf/proc
	# chroot debfs_armhf/
	# apt-get purge wpa_supplicant
	# sync
	# <ctrl-d>
	# umount debfs_armhf/proc debfs_armhf/dev/pts

	~$ unzip RTL8188C_8192C_USB_linux_v4.0.2_9000.20130911.zip
	~$ RTLSRC=RTL8188C_8192C_USB_linux_v4.0.2_9000.20130911

	# look at ${RTLSRC}/document/Wireless_tools_porting_guide.pdf

	~$ tar xvfz ${RTLSRC}/wpa_supplicant_hostapd/\
	wpa_supplicant_hostapd-0.8_rtw_r7475.20130812.tar.gz

	~$ make -C wpa_supplicant_hostapd-0.8_rtw_r7475.20130812/hostapd/\
	 CC=arm-linux-gnueabihf-gcc install DESTDIR=../../debfs_armhf

	~$ make -C wpa_supplicant_hostapd-0.8_rtw_r7475.20130812/wpa_supplicant/\
	 CC=arm-linux-gnueabihf-gcc install DESTDIR=../../debfs_armhf

Теперь настройка демонов точки доступа hostapd + udhcpd для раздачи IP адресов:

	:::bash
	~$ mount -t devpts devpts debfs_armhf/dev/pts
	~$ mount -t proc proc debfs_armhf/proc
	~$ chroot debfs_armhf/
	~$ apt-get install udhcpd
	~$ sed -ie 's/\(DHCPD_ENABLED="no"\)/#\1/' /etc/default/udhcpd
	~$ /etc/init.d/udhcpd stop
	~$ cp /etc/udhcpd.conf /etc/udhcpd.conf.bak
	~$ sed -ie 's/\(interface\s\+\)eth0/\1wlan0/' /etc/udhcpd.conf

	# http://wireless.kernel.org/en/users/Documentation/hostapd

	~$ cat <<EOT > /etc/hostapd.conf
	interface=wlan0
	ssid=MK802
	channel=8
	wpa=2
	wpa_passphrase=YOUR_PASSWORD
	wpa_key_mgmt=WPA-PSK
	wpa_pairwise=CCMP
	hw_mode=g
	EOT
	~$ sed -ie '/auto wlan0/d' /etc/network/interfaces
	~$ cat <<EOT > /home/.scripts/net-monitor.sh
	#!/bin/bash
	source /etc/profile
	set +e
	cd "\`dirname "\${0}"\`"

	ifconfig wlan0 192.168.0.1

	/etc/init.d/udhcpd start
	hostapd /etc/hostapd.conf 2>&1 &
	HOSTAPD_PID=\$!

	echo "\`date\`: HOSTAPD_PID: \$HOSTAPD_PID"

	ELAPSED=0
	while sleep 1; do ps -p \$HOSTAPD_PID > /dev/null && \
	test \$((ELAPSED++)) -lt 100 || break; done

	echo "\`date\`: ARP scaning"

	while sleep 1; do ps -p \$HOSTAPD_PID > /dev/null && \
	arp | grep -q "wlan0" || break; done

	kill 2>&1 \$HOSTAPD_PID
	/etc/init.d/udhcpd stop
	wait \$HOSTAPD_PID

	ifconfig wlan0 0.0.0.0
	echo "\`date\`: Network monitor started"
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
	~$ sync
	<ctrl-d>
	~$ umount debfs_armhf/proc debfs_armhf/dev/pts
	~$ cd debfs_armhf/ && tar -cvz * -f ../mk802rootfs.tgz && cd ..
	~$ cd sunxi-bsp/
	~$ scripts/sunxi-media-create.sh /dev/mmcblk0 \
	output/mk802-1gb_hwpack.tar.xz ../mk802rootfs.tgz
	~$ sync

При загрузке системы стартует точка доступа, затем, если нет активности на линии, WI-FI переключается в обычный режим. Собственно результат наших трудов:

	:::bash
	~$ cat /dev/urandom | pv | sshpass -p "YOUR_SSH_PASS" \
	ssh root@torrents.local "cat > /dev/null"
	13GB 1:15:53 [3,05MB/s] [                <=> ]

Это когда WI-FI модуль в режиме *g*, а если верить производителю RTL8188CUS способен работать в режиме *n*. Для самых отважных предлагаю попробовать добавить строчку *ieee80211n=1* в ```/etc/hostapd.conf```:

	:::bash
	~$ cat /dev/urandom | pv | sshpass -p "YOUR_SSH_PASS" \
	ssh root@torrents.local "cat > /dev/null"
	15GB 1:18:28 [   5MB/s] [                <=> ]

	~$ ssh root@torrents.local
	~$ ps aux | grep sshd:
	~$ top -p sshd_PID
	# %CPU ~ 80%

Чистым результат назвать нельзя, т.к наверняка присутствуют какие-то издержки из-за ssh, а так есть ещё над чем экспериментировать ;-)
