#!/bin/bash

[ $(id -u) = 0 ] && echo "This script must not be run as root." && exit 1

# get name of multi OS device (should be /dev/sdb)
DEV=$(lsblk --nodeps -o name,serial | grep S597NE0MB01465B | awk '{print $1'})
# echo "Multi OS device is /dev/${DEV}."

# find and mount all partitions except active OS, EFI and swap
MNTD=$(findmnt -Dn -T / | awk '{print $1}' | sed 's/\/dev\///')
MOUNT_LIST=$(blkid | grep -Ev "swap|EFI BOOT" | cut -f1 -d':' | grep $DEV | grep -v $MNTD)
while read DISK
do
    udisksctl mount -b $DISK > /dev/null 2>&1
done <<< "$MOUNT_LIST"

# get device names and numbers
DEVICE_LIST=$(lsblk -nlo name,label /dev/${DEV} | tail +4)

# Find kernels and Nvidia drivers
echo "Searching mounted devices for kernels and Nvidia drivers..."
echo
KERNELS=$(sudo find /media/pete/*/boot /media/pete/*/EFI /boot -type f -name vmlinuz* -o -name kernel-* | grep -Ev 'ignore|rescue|grub')
NVIDIA=$(sudo find /media/pete/*/usr/lib /media/pete/*/usr/lib64 /usr/lib -name "libcuda.so.*" 2>/dev/null | grep -Ev 'so.1|flatpak|i386' | sed "s/x86_64-linux-gnu/Mint/" | awk -F "/" -v OFS='\t' '{print $4,$NF}' | sed "s/libcuda.so.//" | sort -u)

# try this:
# grep "X Driver" /media/pete/*/var/log/Xorg.0.log | sed "s/^.*X Driver  //" | sed "s/ .*$//"

# probe each kernel file
KERNEL_VERSIONS=$(
while read OS
    do
        echo $OS | sed 's/^\/boot/\/dummy1\/dummy2\/Mint/' | awk -F "/" '{printf "%s\t", $4}'
        sudo file -bL $OS | grep -oP 'version\s+\K[^ ]+'        # returns only the string after "version " until the following space
    #   file -bL $OS | grep -Eo 'version\ [^ ]+'                # returns the full string matched including "version "
    #   https://stackoverflow.com/questions/55027495/grep-match-next-word-after-pattern-until-first-space
    done <<< "$KERNELS"
)

# unmount
while read DISK
do
    udisksctl unmount -b $DISK > /dev/null 2>&1
done <<< "$MOUNT_LIST"

# Put it all together.  sed command explained here: https://stackoverflow.com/questions/38714435/add-an-extra-column-after-grep-content
DEV_OS_KRNL=$(
    while read DEVICE OS_NAME
    do
        echo "$KERNEL_VERSIONS" | sed -n "/$OS_NAME/ s/^/$DEVICE\t/p"
    done <<< "$DEVICE_LIST"
)

FINAL=$(
    while read OS_NAME NV_VERSION
    do
        echo "$DEV_OS_KRNL" | sed -n "/$OS_NAME/ s/$/\t$NV_VERSION/p"
    done <<< "$NVIDIA"
)

echo "$FINAL" | awk -F "\t" '{printf "%s\t%-12s%-24s%s\n", $1,$2,$3,$4}' | sort -V
echo

DEVICES=$(expr $(wc -l <<< "$MOUNT_LIST") + 1)
KERNELS=$(wc -l <<< "$KERNELS")
RED='\033[0;31m'
NC='\033[0m'

[ $DEVICES == $KERNELS ] && echo "Found $DEVICES devices and kernels." || printf "${RED}***${NC} Found $DEVICES devices and $KERNELS kernels. ${RED}***${NC}\n"

exit 0

