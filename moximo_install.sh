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
BOOTFS="/home/ichavero/sotolitoLabs/moximo-images/fs/moximo-bootfs.tar.gz"
ROOTFS="/home/ichavero/sotolitoLabs/moximo-images/fs/moximo-rootfs.tar.gz"
VARFS="/home/ichavero/sotolitoLabs/moximo-images/fs/moximo-varfs.tar.gz"
IMAGE="../fedora-images/Fedora-Server-armhfp-24-1.2-sda.raw.xz"

if [ "${SD}" == "" ]; then
    echo "Missing SD parameter"
    exit 0;
fi

if [ "${HD}" == "" ]; then
    echo "Missing Hard Drive parameter"
    exit 0;
fi


echo "Writing image to SD: ${SD}"
#fedora-arm-image-installer -y --image=${IMAGE} --target=Cubietruck --media=${SD}

echo "Creating HD partitions"
sfdisk $HD < $HD_GEOMETRY
mkswap "${HD}1"
mkfs.ext4 -F -F "${HD}2"
mkfs.xfs -f "${HD}3"

# make temp mount points
mkdir /tmp/{moximo_sd_boot,moximo_root,moximo_var}
echo "mount ${SD}p1 /tmp/moximo_sd_boot"
mount "${SD}p1" /tmp/moximo_sd_boot &> /dev/null
tar --strip-components=1 -xf ${BOOTFS} -C /tmp/moximo_sd_boot
#sed -i 's/\sroot=.*\s/ root=\/dev\/sda2 /' /tmp/moximo_sd_boot/extlinux/extlinux.conf

echo "Extracting root filesystem ${HD}2: $ROOTFS"
mount "${HD}2" /tmp/moximo_root
tar -xf ${ROOTFS} -C /tmp/moximo_root

echo "Extracting var filesystem ${HD}3: $VARFS"
mount "${HD}3" /tmp/moximo_var
tar --strip-components=1 -xf ${VARFS} -C /tmp/moximo_var

#echo "DEBUG exiting before unmounting"
#exit


echo "Unmounting filesystems"
umount /tmp/moximo_sd_boot
umount /tmp/moximo_root
umount /tmp/moximo_var

echo "Cleaning up"
rm -r /tmp/{moximo_sd_boot,moximo_root,moximo_var} &> /dev/null

echo "Done, enjoy your new sexy moximo appliance"
