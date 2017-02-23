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
        echo -e "\033[0;33m##### IMAGE GENERATION FOR Pi Controller ##### \033[0m\n"
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
	cp $1 ~/build/ClusterHAT-controller.img
	if [ $? -ne 0 ]; then
	        echo -e "\033[0;31mError during image copy.\033[0m"
		exit
	else
		echo -e "\033[0;32mCopying image [DONE] \033[0m"
	fi
	LOOP=`losetup -f`
	echo -e "\033[0;33mMounting image [...] \033[0m"
	losetup $LOOP ~/build/ClusterHAT-controller.img
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
	echo -e "\033[0;33mUpdating and installing packages [...] \033[0m"
	chroot ~/mnt apt-get update && chroot ~/mnt apt-get dist-upgrade -qy && chroot ~/mnt apt-get remove dhcpcd5 -qy && chroot ~/mnt apt-get install bridge-utils wiringpi screen minicom vim htop -qy 
        if [ $? -ne 0 ]; then
                echo -e "\033[0;31mUpdating and installing packages [FAIL]\033[0m"
                exit
        else
                echo -e "\033[0;32mUpdating and installing packages [DONE] \033[0m"
        fi
	echo -e "\033[0;33mConfiguring image [...] \033[0m"
	chroot ~/mnt systemctl set-default multi-user.target && chroot ~/mnt ln -fs /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@ttyGS0.service && sed -i "s#^127.0.1.1.*#127.0.1.1\tcontroller#g" ~/mnt/etc/hosts && echo "controller" > ~/mnt/etc/hostname && echo -e "\nauto br0\niface br0 inet dhcp\nbridge_ports eth0\nbridge_stp off\nbridge_waitport 0\nbridge_fd 0" >> ~/mnt/etc/network/interfaces && echo -e "\nauto ethpi1\nallow-hotplug ethpi1\niface ethpi1 inet manual\npre-up brctl addif br0 ethpi1\nup ifconfig ethpi1 up" >> ~/mnt/etc/network/interfaces && echo -e "\nauto ethpi2\nallow-hotplug ethpi2\niface ethpi2 inet manual\npre-up brctl addif br0 ethpi2\nup ifconfig ethpi2 up" >> ~/mnt/etc/network/interfaces && echo -e "\nauto ethpi3\nallow-hotplug ethpi3\niface ethpi3 inet manual\npre-up brctl addif br0 ethpi3\nup ifconfig ethpi3 up" >> ~/mnt/etc/network/interfaces && echo -e "\nauto ethpi4\nallow-hotplug ethpi4\niface ethpi4 inet manual\npre-up brctl addif br0 ethpi4\nup ifconfig ethpi4 up" >> ~/mnt/etc/network/interfaces && cp clusterhat /sbin/clusterhat && chmod a+x /sbin/clusterhat && chroot ~/mnt rm -f mnt/etc/ssh/*key* && chroot ~/mnt apt-get -qy autoremove --purge && chroot ~/mnt apt-get clean
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

if [ ! $1 ]; then
	echo -e "\033[0;31mMissing arguments :) \033[0m"
	echo
	echo "Usage:"
	echo "./create-controller.sh <path to raspbian image>"
	echo
	echo "Example:"
	echo "./create-zero.sh raspbian.img"
	exit
else
	main $1 $2
fi
