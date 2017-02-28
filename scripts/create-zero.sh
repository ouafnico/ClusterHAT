#!/bin/bash
#
# ClusterHAT image generation
# based on 8086 Consultancy original script
# Nicolas Repentin <nicolas@shivaserv.fr>
#
# Version 1.0 / 02/23/2017
#

# VARIABLES


# FUNCTIONS

init_script(){
        echo -e "\033[0;33m##### IMAGE GENERATION FOR Pi Zeroes ##### \033[0m\n"
	if [ ! -d ~/build ]; then
	        mkdir ~/build
	fi
	if [ ! -d ~/mnt ]; then
	        mkdir ~/mnt
	fi
}

main(){
	init_script
	echo -e "\033[0;33mCopying image [...] \033[0m"
	cp $1 ~/build/ClusterHAT-zero-p$2.img	
	if [ $? -ne 0 ]; then
	        echo -e "\033[0;31mError during image copy.\033[0m"
		exit
	else
		echo -e "\033[0;32mCopying image [DONE] \033[0m"
	fi
	LOOP=`losetup -f`
	echo -e "\033[0;33mMounting image [...] \033[0m"
	losetup $LOOP ~/build/ClusterHAT-zero-p$2.img 
	sleep 2
	if [ $? -ne 0 ]; then
		echo -e "\033[0;31mMounting image [FAIL]\033[0m"
		exit
	else
		echo -e "\033[0;32mMounting image [DONE] \033[0m"
	fi
	echo -e "\033[0;33mEnabling partitions on image [...] \033[0m"
	kpartx -av $LOOP
	sleep 2
        if [ $? -ne 0 ]; then
                echo -e "\033[0;31mEnabling partitions on image [FAIL]\033[0m"
                exit
        else
                echo -e "\033[0;32mEnabling partitions on image [DONE] \033[0m"
        fi
	echo -e "\033[0;33mMounting partitions [...] \033[0m"
	mount `echo $LOOP|sed s#dev#dev/mapper#`p2 ~/mnt && mount `echo $LOOP|sed s#dev#dev/mapper#`p1 ~/mnt/boot
	if [ $? -ne 0 ]; then
                echo -e "\033[0;31mMounting partitions [FAIL]\033[0m"
                exit
        else
                echo -e "\033[0;32mMounting partitions [DONE] \033[0m"
        fi
	MAC=`expr 10 + $2`
	echo -n "dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait g_cdc.host_addr=00:22:82:ff:fe:$MAC g_cdc.dev_addr=00:22:82:ff:ff:$MAC console=ttyGS0 modules-load=dwc2,g_cdc" > ~/mnt/boot/cmdline.txt && \
	sed -i "s#^127.0.1.1.*#127.0.1.1\tp$2#g" ~/mnt/etc/hosts && \
	echo "dtoverlay=dwc2" >> ~/mnt/boot/config.txt && \
	echo "P$2" > ~/mnt/etc/hostname && \
	cp sources/interfaces.p ~/mnt/etc/network/interfaces && \
	echo -e "\nauto usb0:0\niface usb0:0 inet static\naddress 10.0.0.$MAC\nnetmask 255.255.255.0" >> ~/mnt/etc/network/interfaces
	echo -e "\033[0;33mConfiguring image [...] \033[0m"
	if [ $? -ne 0 ]; then
                echo -e "\033[0;31mConfiguring image [FAIL]\033[0m"
                exit
        else
                echo -e "\033[0;32mConfiguring image [DONE] \033[0m"
        fi
	echo -e "\033[0;33mUnmounting image [...] \033[0m"
	sync
	umount ~/mnt/boot && umount ~/mnt && kpartx -dv $LOOP && losetup -d $LOOP
	if [ $? -ne 0 ]; then
                echo -e "\033[0;31mUnmounting image [FAIL]\033[0m"
                exit
        else
                echo -e "\033[0;32mUnmounting image [DONE] \033[0m"
        fi
}

# STARTING HERE

if [ ! $1 ] || [ ! $2 ]; then
	echo -e "\033[0;31mMissing arguments :) \033[0m"
	echo
	echo "Usage:"
	echo "./create-zero.sh <path to controller image> <number of slot>"
	echo
	echo "Example:"
	echo "./create-zero.sh ClusterHAT-controller.img 2"
	exit
else
	main $1 $2
fi
