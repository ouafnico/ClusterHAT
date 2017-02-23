#!/bin/bash
#
# ClusterHAT image generation
# based on 8086 Consultancy original script
# Nicolas Repentin <nicolas@shivaserv.fr>
#
# Version 1.0 / 02/23/2017
#

# VARIABLES


# STARTING HERE

if [ ! $1 ]; then
	echo -e "\033[0;31mMissing arguments :) \033[0m"
	echo
	echo "Usage:"
	echo "./create-zero.sh <path to raspbian image> <slot number of Pi Zero>"
	echo
	echo "Example for P2:"
	echo "./create-zero.sh raspbian.img 2"
	exit
fi

if [ ! -d ~/build ]; then
	mkdir ~/build
fi
if [ ! -d ~/mnt ]; then
	mkdir ~/mnt
fi

if [ ! -d ~/sources ]; then
	mkdir ~/sources
fi

cp $1 ~/build/ClusterHAT-zero-p$2.img
if [ $? -eq 0 ]; then
	echo -e "\033[0;31mError during image copy.\033[0m"
fi

MAC="10+$2"
LOOP=`losetup -f`
losetup $LOOP ~/build/ClusterHAT-zero-p$2.img
sleep 5
kpartx -av $LOOP
sleep 5
mount `echo $LOOP|sed s#dev#dev/mapper#`p2 ~/mnt
mount `echo $LOOP|sed s#dev#dev/mapper#`p1 ~/mnt/boot
echo -n "dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait g_cdc.host_addr=00:22:82:ff:fe:$MAC g_cdc.dev_addr=00:22:82:ff:ff:$MAC console=ttyGS0 modules-load=dwc2,g_cdc" > ~/mnt/boot/cmdline.txt
cp sources/interfaces.p ~/mnt/etc/network/interfaces 
cp sources/issue.p ~/mnt/etc/issue
sed -i "s#^127.0.1.1.*#127.0.1.1\tp$2#g" ~/mnt/etc/hosts
sed -i "s/^#dtoverlay=dwc2$/dtoverlay=dwc2/" ~/mnt/boot/config.txt
echo "P$2" > ~/mnt/etc/hostname

umount mnt/boot
umount mnt
kpartx -dv $LOOP
losetup -d $LOOP
