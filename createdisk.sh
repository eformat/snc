#!/bin/bash

set -x

if [[ $# -ne 1 ]]; then
   echo "You need to provide the running cluster directory to copy kubeconfig"
   exit 1
fi

tarballDirectory="crc_libvirt_$(date "+%d%m%Y")"
mkdir $tarballDirectory

random_string=$(sudo virsh list --all | grep -oP '(?<=test1-).*(?=-master-0)')

# Shutdown the instance
sudo virsh shutdown test1-${random_string}-master-0

hostInfo=$(sudo virsh net-dumpxml test1-${random_string} | grep test1-${random_string}-master-0 | sed "s/^[ \t]*//")
masterMac=$(sudo virsh dumpxml test1-${random_string}-master-0 | grep "mac address" | sed "s/^[ \t]*//")

sed "s|ReplaceMeWithCorrectHost|$hostInfo|g" crc_libvirt.template > $tarballDirectory/crc_libvirt.sh
sed "s|ReplaceMeWithCorrectMac|$masterMac|g" crc_libvirt.template > $tarballDirectory/crc_libvirt.sh

chmod +x $tarballDirectory/crc_libvirt.sh

# Create the disk images
sudo cp /var/lib/libvirt/images/test1-${random_string}-master-0 $tarballDirectory
sudo cp /var/lib/libvirt/images/test1-${random_string}-base $tarballDirectory

sudo chown $USER:$USER -R $tarballDirectory
cp $tarballDirectory/test1-${random_string}-base $tarballDirectory/crc
qemu-img rebase -b $tarballDirectory/crc $tarballDirectory/test1-${random_string}-master-0
qemu-img commit $tarballDirectory/test1-${random_string}-master-0

rm -fr $tarballDirectory/test1-${random_string}-master-0 $tarballDirectory/test1-${random_string}-base

# Copy the kubeconfig and kubeadm password file
cp $1/auth/kube* $tarballDirectory/

# Copy the master public key
cp $USER/.ssh/id_rsa $tarballDirectory/master_privatekey
