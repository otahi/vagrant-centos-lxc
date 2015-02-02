#!/bin/sh

### install packages
rpm -ivh http://mirror.nl.leaseweb.net/epel/6/i386/epel-release-6-8.noarch.rpm
yum install -y lxc lxc-libs lxc-templates bridge-utils libcgroup

### virbr0
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-virbr0
DEVICE=virbr0
BOOTPROTO="dhcp"
TYPE=Bridge
ONBOOT=yes
EOF

grep -q virbr0 /etc/sysconfig/network-scripts/ifcfg-eth0 || \
    echo "BRIDGE=virbr0" >> /etc/sysconfig/network-scripts/ifcfg-eth0
service network reload

### lxc
service cgconfig start
service cgred start
chkconfig --level 345 cgconfig on
chkconfig --level 345 cgred on

### lxc vms
lxc-create -t centos -n vm1 -f share/lxc-vm1.conf
lxc-start -d -n vm2
sleep 10

lxc-create -t centos -n vm2 -f share/lxc-vm2.conf
lxc-start -d -n vm1


### hints
echo "##HINTS##"
echo "You can login to vm1 (with root/`cat /var/lib/lxc/vm1/tmp_root_pass`)"
echo "% sudo lxc-console -n vm1"
echo "You can login to vm2 (with root/`cat /var/lib/lxc/vm2/tmp_root_pass`)"
echo "% sudo lxc-console -n vm2"

