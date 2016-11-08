#!/bin/bash

if [ ${UID} != 0 ]; then
    echo "This program should be run by root"
    exit 0
fi

SD=$1
HD=$2
HD_GEOMETRY="moximo_partitions.sfdisk"
#TODO fix this paths
# images are in /home/sotolitoLabs at sotolitolabs.com
ROOTFS="/home/ichavero/sotolitoLabs/moximo-images/fs/moximo-rootfs.tar.gz"
VARFS="/home/ichavero/sotolitoLabs/moximo-images/fs/moximo-varfs.tar.gz"

if [ ${SD} == "" ]; then
    echo "Missing SD parameter"
    exit 0;
fi

if [ ${HD} == "" ]; then
    echo "Missing Hard Drive parameter"
    exit 0;
fi

a
echo "Writing image to SD: ${SD}"
fedora-arm-image-installer -y --image=${IMAGE} --target=Cubietruck --media=${SD}

echo "Creating HD partitions"
sfdisk $HD < $HD_GEOMETRY
mkswap "${HD}1"
mkfs.ext4 -fy "${HD}2"
mkfs.xfs -fy "${HD}3"

# make temp mount points
mkdir /tmp/{moximo_sd_boot,moximo_root,moximo_var} &> /dev/null
mount "${SD}1" /tmp/moximo_sd_boot &> /dev/null
sed -i 's/\sroot=.*\s/ root=/dev/sda2 /' /tmp/moximo_sd_boot/extlinux/extlinux.conf

echo "Extracting root filesystem: $ROOTFS"
mount "${HD}2" /tmp/moximo_root
tar -xvf ${ROOTFS} -C /tmp/moximo_root

echo "Extracting var filesystem: $VARFS"
mount "${HD}2" /tmp/moximo_var
tar -xvf ${VARFS} -C /tmp/moximo_var

echo "DEBUG exiting before unmounting"
exit


echo "Unmounting filesystems"
umount /tmp/moximo_sd_boot
umount /tmp/moximo_root
umount /tmp/moximo_var

echo "Cleaning up"
rm -r /tmp/{moximo_sd_boot,moximo_root,moximo_var} &> /dev/null

echo "Done, enjoy your new sexy moximo appliance"
