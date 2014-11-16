#!/bin/bash
#name of the windows guest VM as configured on VBox
#
# Before running this script change the user,password and vmguestname below
#
#
apt-get update && apt-get upgrade
apt-get install openssh-server openssh-client

apt-get install python-sqlalchemy python-bson python-dpkt python-jinja2 python-magic python-pymongo  python-libvirt python-bottle python-pefile python-chardet
apt-get install python-pip python-dev libxml2-dev libxslt-dev

pip install  django cybox
pip install MAEC

apt-get install ssdeep libfuzzy-dev
apt-get   install git
git clone https://github.com/kbandla/pydeep.git
cd ~
cd pydeep
python setup.py install

apt-get install libtool automake
cd ~
git clone https://github.com/plusvic/yara.git
cd yara
chmod a+x build.sh
./build.sh
make install
cd yara-python
python setup.py install
apt-get install tcpdump
cd ~
setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump
#phpvbox
apt-get update && apt-get upgrade
apt-get install build-essential dkms unzip -y

echo "deb http://download.virtualbox.org/virtualbox/debian trusty contrib" >> /etc/apt/sources.list
cd ~
wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | sudo apt-key add -
apt-get update && apt-get install VirtualBox-4.3 -y
usermod -aG vboxusers $USER

/etc/init.d/vboxdrv  setup
wget http://download.virtualbox.org/virtualbox/4.3.12/Oracle_VM_VirtualBox_Extension_Pack-4.3.12-93733.vbox-extpack
VBoxManage extpack install Oracle_VM_VirtualBox_Extension_Pack-4.3.12-93733.vbox-extpack

#Lamp
apt-get install lamp
apt-get install php-soap
/etc/init.d/apache2 restart
cd ~
wget http://sourceforge.net/projects/phpvirtualbox/files/phpvirtualbox-4.3-1.zip
unzip phpvirtualbox-4.3-1.zip
mv phpvirtualbox-4.3-1 /var/www/html/phpvirtualbox
cp /var/www/html/phpvirtualbox/config.php-example /var/www/html/phpvirtualbox/config.php
sed  -i 's/^\(var $username =\).*/\1"$USER"/' /var/www/html/phpvirtualbox/config.php
sed -i 's/^\(var $password =\).*/\1"$PASSWORD"/' /var/www/html/phpvirtualbox/config.php
touch /etc/default/virtualbox
echo "VBOXWEB_USER=$USER" >> /etc/default/virtualbox
/etc/init.d/vboxweb-service start
apt-get install mongodb
cd ~
git clone https://github.com/volatilityfoundation/volatility.git
cd  volatility
python setup.py install

#cuckoo
adduser cuckoo
usermod -aG vboxusers cuckoo
cd /opt
git clone https://github.com/cuckoobox/cuckoo.git
chown -R root:root cuckoo
sed -i 's/^\(memory_dump = \).*/\1on/' /opt/cuckoo/conf/cuckoo.conf
sed -i 's/^\(ip=\).*/\1192.168.56.1/' /opt/cuckoo/conf/cuckoo.conf
sed -i 's/^\(label = \).*/\1$VMGUESTNAME/' /opt/cuckoo/conf/virtualbox.conf
sed -i 's/^\(ip = \).*/\1192.168.56.101/' /opt/cuckoo/conf/virtualbox.conf

sed -i 's/^\(delete_memdump = \).*/\1yes/' /opt/cuckoo/conf/memory.conf
sed -i 's/^\(enabled =\).*/\1yes/'/opt/cuckoo/conf/processing.conf
sed -i 's/^\(key =\).*/\12176bdb26b4f5da89301a66611aa140385f8e2a9c62845c71f26637fc48022cd/'/opt/cuckoo/conf/processing.conf

sed -i 's/^\(enabled =\).*/\1yes/'/opt/cuckoo/conf/reporting.conf

apt-get install iptables-persistent

iptables -A FORWARD -o eth0 -i vboxnet0 -s 192.168.56.0/24 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A POSTROUTING -t nat -j MASQUERADE
iptables -P FORWARD DROP

sh -c "iptables-save > /etc/iptables/rules.v4"
sysctl -w net.ipv4.ipforward=1
python /opt/cuckoo/cuckoo.py

python /opt/cuckoo/utils/web.py
