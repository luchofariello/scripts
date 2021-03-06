#!/bin/bash

# sudo apt-get install git && \
# 	wget https://github.com/ejtaal/scripts/raw/master/setup-new-system.sh && \
#		bash ./setup-new-system.sh

echo "Setting up your new system, just sit back and relax..."

cd
if [ ! -d scripts ]; then
	git clone https://github.com/ejtaal/scripts
fi

if [ -f ~/scripts/generic-linux-funcs.sh ]; then
	. ~/scripts/generic-linux-funcs.sh
fi

if [ -L ~/.bashrc ]; then
	echo "Bashrc seems already installed:"
	ls -l ~/.bashrc
else
	mv -v ~/.bashrc ~/.bashrc.bak
	ln -s ~/scripts/bashrc ~/.bashrc
	echo "New bashrc installed"
fi

source ~/.bashrc

PRIORITY_PKGS="openssh-server git screen htop"

# Duff packages: openvas-cli openvas-client openvas-manager openvas-server 

PKGS="
aircrack-ng apmd autofs automake bmon build-essential calibre
cherrytree cifs-utils cpulimit ddd dkms edb elinks ettercap-graphical
fatsort fbreader fdupes filezilla flashplugin-nonfree
gadmin-openvpn-client gdb gedit git git-gui
gitk gnome-system-monitor gparted htop httrack hostapd
iftop ike-qtgui ipcalc
ionice iotop iptraf-ng k4dirstat kate kde-spectacle
knockd konsole krusader lftp
libav-tools libcpan-checksums-perl libdigest-crc-perl libgeo-ip-perl
libimage-exiftool-perl libreoffice libsox-fmt-mp3 libstring-crc32-perl
libstring-crc-cksum-perl libtool links linux-headers-`uname -r` ltrace
lynx mc mosh mtr munin munin-node ncdu netcat 
nethogs nmap ntp-doc okular onboard
openssh-blacklist openssh-blacklist-extra openssh-server 
openvpn parcellite partimage
pv python3-notify2 python-notify2 qbittorrent screen smartmontools
smplayer sox sshfs sshpass ssldump sslscan strace supercat sysfsutils
system-config-lvm tidy timelimit uswsusp veil-evasion vim vinagre vlc
wine wireshark x11vnc xine-ui virtualenvwrapper
"

FOUND_PKGS=

if [ -x /usr/bin/yum ]; then
	yum makecache
	CHECK_CMD="yum -q -C list"
	CMD=yum
elif [ -x /usr/bin/apt-get ]; then
	CHECK_CMD="apt-cache show"
	#CMD="apt-get -mV --ignore-missing"
	CMD="apt "
fi

hm "*" "Finding packages to install..."
for i in $PKGS; do
	if $CHECK_CMD $i >/dev/null 2>&1; then
		hm '+' "Found: $i"
		FOUND_PKGS="$FOUND_PKGS $i"
	else
		hm "-" "Not found: $i"
	fi
done

hm '*' "Doing update & upgrade first"
sudo $CMD update && sudo $CMD upgrade

hm '*' "Installing priority packages first:" $PRIORITY_PKGS
sudo $CMD install $PRIORITY_PKGS

hm '*' "Now installing following useful packages:" $FOUND_PKGS
sudo $CMD install $FOUND_PKGS

if [ -f /etc/apt/sources.list ]; then
	. /etc/lsb-release
	#echo $DISTRIB_CODENAME
	hm '+' "=> Potentionally interesting deb repositories:
sudo add-apt-repository ppa:jaap.karssenberg/zim
deb http://download.virtualbox.org/virtualbox/debian $DISTRIB_CODENAME contrib
'wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -'
sudo apt-get update
sudo apt-get install virtualbox-5.0 zim

mplayer/vlc etc
sudo apt-add-repository ppa:strukturag/libde265
sudo add-apt-repository ppa:videolan/stable-daily
sudo add-apt-repository ppa:mc3man/mplayer-test
sudo add-apt-repository ppa:rvm/smplayer
sudo add-apt-repository ppa:mc3man/mpv-tests
sudo apt-get update
sudo apt-get install gstreamer0.10-libde265 gstreamer1.0-libde265 vlc vlc-plugin-libde265 mplayer mpv smplayer smtube smplayer-themes smplayer-skins youtube-dl
"

fi

modify_file /etc/network/interfaces \
"#iface eth0 inet static
#        address 192.168.0.0
#        netmask 255.255.255.0
#        gateway 192.168.0.1
#        dns-nameservers 194.168.4.100 194.168.8.100
#        dns-search ejtaal.net
"

hm '+' "=> SSD tweaks:
fstab:
	noatime,nodiratime,commit=60
	tmpfs  /tmp  tmpfs defaults,noatime,nodiratime,mode=1777,size=20%  0  0
sysctl.conf:
	vm.swappiness=1
rc.local:
	mkdir -p /tmp/taal/.cache
	chown -vR taal:taal /tmp/taal
sysfs.conf:
	block/sda/queue/scheduler = deadline
"

for i in "" ".bak"; do
	modify_file "/etc/resolv.conf${i}" \
"#     PLEASE DO NOT EDIT THIS FILE, if you don't mind. Really, it's not nice, fool! - Mr.T
nameserver 194.168.4.100
nameserver 194.168.8.100
search ejtaal.net
"
done

hm '+' "=> Tablet additions:
echo greeter-session=lightdm-gtk-greeter >> /etc/lightdm/lightdm.conf
echo keyboard=onboard >> /etc/lightdm/lightdm-gtk-greeter.conf"

hm '+' "=> Network issues
Modify sleep values in /etc/init/failsafe.conf"

hm '+' "=> Consider zRam: (apt install zram-config)"
