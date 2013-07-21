#!/bin/sh

### install packages
yum -y --nogpgcheck localinstall share/RPMS/centos64/x86_64/lxc-0.9.0-1.el6.x86_64.rpm \
    share/RPMS/centos64/x86_64/lxc-libs-0.9.0-1.el6.x86_64.rpm
yum install -y libcgroup

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
mkdir -p /cgroup
grep -q lxc /etc/fstab  || echo "lxc /cgroup cgroup defaults 0 0" >> /etc/fstab
mount /cgroup
service cgconfig restart && chkconfig cgconfig on

### lxc centos
curl -O -L https://gist.github.com/hagix9/3514296/raw/7f6bb4e291fad1dad59a49a5c02f78642bb99a45/lxc-centos
cp lxc-centos /usr/share/lxc/templates/
chmod +x /usr/share/lxc/templates/lxc-centos
sed -i 's/curl -f/curl -Lf/g' /usr/share/lxc/templates/lxc-centos

### lxc vms
lxc-create -t centos -n vm1 -f share/lxc-vm1.conf
lxc-start -d -n vm2
sleep 10

lxc-create -t centos -n vm2 -f share/lxc-vm2.conf
lxc-start -d -n vm1


### hints
echo "##HINTS##"
echo "You can login to vm1 (with root/password)"
echo "% sudo lxc-console -n vm1"
echo "You can login to vm2 (with root/password)"
echo "% sudo lxc-console -n vm2"

