#!/bin/sh

VMS="vm1 vm2"
if [ -n "$*" ] ; then
    VMS=$*
fi

### install packages
rpm -q epel-release-6-8 || rpm -ivh http://mirror.nl.leaseweb.net/epel/6/i386/epel-release-6-8.noarch.rpm
rpm -q lxc || yum install -y lxc lxc-libs lxc-templates bridge-utils libcgroup

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
service cgconfig status || service cgconfig start
service cgred status || service cgred start
chkconfig --level 345 cgconfig on
chkconfig --level 345 cgred on

## host config
cat <<EOF > /home/vagrant/.ssh/config
Host $VMS
   StrictHostKeyChecking no
   UserKnownHostsFile /dev/null
   IdentityFile /vagrant/.vagrant/machines/default/virtualbox/private_key
EOF

chown -R vagrant:vagrant /home/vagrant/.ssh/config
chmod -R 600 /home/vagrant/.ssh/config

cat <<EOF > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
EOF

## containers
for vm in $VMS
do
    ### destroy lxc
    lxc-info -n $vm &> /dev/null && lxc-destroy -n $vm -f
    
    ### create lxc
    cat <<EOF > lxc-$vm.conf
lxc.network.type = veth
lxc.network.link = virbr0
lxc.network.flags = up
lxc.network.veth.pair = veth-$vm
EOF
    lxc-create -t centos -n $vm -f lxc-$vm.conf

    ### override lxc container with vagrant
    ROOTFS=/var/lib/lxc/$vm/rootfs
    chroot $ROOTFS groupadd -g 1001 vagrant
    chroot $ROOTFS useradd --create-home -s /bin/bash -u 1001 -g vagrant vagrant
    mkdir -p $ROOTFS/etc/sudoers.d/
    cp /etc/sudoers.d/vagrant $ROOTFS/etc/sudoers.d/vagrant
    cp -r /home/vagrant $ROOTFS/home
    chown -R vagrant:vagrant $ROOTFS/home/vagrant
    cp /etc/sudoers $ROOTFS/etc/sudoers

    ### start lxc
    lxc-start -d -n $vm
    sleep 10

    echo `lxc-info -n $vm -i -H` $vm >> /etc/hosts
done


## hints
echo "You can login to $VMS with ssh"
for vm in $VMS
do
    echo "You can login to $vm (with root/`cat /var/lib/lxc/$vm/tmp_root_pass`)"
    echo "sudo lxc-console -n $vm"
done
