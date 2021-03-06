#!/bin/bash

# Copyright 2017 SotolitoLabs
#
#
# Prepare Hard Drive
# ------------
# 
# This script extracts the filesystem from a running system SD,
# installs it on the Hard Drive and configures the OS for using
# the Hard Drive as root filesystem
#
# TODO: add arguments

RELEASE="f26"
DIST="sotolito-moximo-remix-$RELEASE-ct.tar"
ROOTFS="/mnt"
KERNEL_VERSION="4.11.8-300.fc26.armv7hl"
HD_GEOMETRY="moximo_partitions.sfdisk"
HD="/dev/sda"
HOSTNAME="moximo"

echo "Preparing SotolitoLabs HD distribution"

dnf install -y xfsprogs tar

echo "Creating HD partitions"
sfdisk ${HD} < ${HD_GEOMETRY}

echo "Format HD partitions"
mkswap ${HD}1
mkfs.xfs -f ${HD}2
mkfs.xfs -f ${HD}3


mount ${HD}3 ${ROOTFS}
tar --exclude=${ROOTFS} -c / > ${ROOTFS}/${DIST}
umount ${ROOTFS}
mount ${HD}2 ${ROOTFS}
mkdir ${ROOTFS}/var
mount ${HD}3 ${ROOTFS}/var
tar -xf ${ROOTFS}/var/${DIST} -C ${ROOTFS}

echo "Creating fstab"
mv $ROOTFS/etc/fstab $ROOTFS/etc/fstab.sdcard

cat > ${ROOTFS}/etc/fstab <<- EOM

${HD}2       /     xfs    defaults,noatime                0 0
${HD}3       /var  xfs    defaults                        0 2
/dev/mmcblk0p2  /boot ext4   defaults,noatime             0 0
${HD}1       swap  swap   defaults                        0 0

EOM

echo "Setting up root partition"

mv /boot/extlinux/extlinux.conf /boot/extlinux/extlinux.conf.sdcard

cat > /boot/extlinux/extlinux.conf <<- EOM

# extlinux.conf generated by SotolitoLabs
ui menu.c32
menu autoboot Welcome to Sotolito OS ${RELEASE} Automatic boot in # second{,s}. Press a key for options.
menu title Sotolito OS ${RELEASE} Boot Options.
menu hidden
timeout 20
totaltimeout 600
label SotolitoOS-${RELEASE} (${KERNEL_VERSION})
        kernel /vmlinuz-${KERNEL_VERSION}
        append ro root=${HD}2
        fdtdir /dtb-${KERNEL_VERSION}/
        initrd /initramfs-${KERNEL_VERSION}.img

EOM

echo "Unmounting partitions"

echo "Setting up hostname"
echo $HOSTNAME > /mnt/etc/hostname

echo "Configure SELinux"
touch /mnt/.autorelabel

umount /mnt/var
umount /mnt
echo "Done, restart your device and enjoy life"
