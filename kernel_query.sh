#!/bin/bash

[ $(id -u) = 0 ] && echo "This script must not be run as root." && exit 1

echo "Kernel version query"
echo

MNTD=$(findmnt -Dn -T / | awk '{print $1}' | sed 's/\/dev\///')
# echo "Running OS is on /dev/${MNTD}."

DISK_LIST=$(blkid | cut -f1 -d':' | grep sdb | grep -Ev 'sdb1$|sdb2$' | grep -v ${MNTD})

while read DISK
do
    # echo $DISK
    udisksctl mount -b $DISK > /dev/null 2>&1
done <<< "$DISK_LIST"

# echo "Searching mounted devices for kernels..."

KERNELS=$(sudo find /media/pete/*/boot /media/pete/*/EFI /boot -type f -name vmlinuz* -o -name kernel-* | grep -Ev 'ignore|rescue')

while read OS
do
    echo $OS
    sudo file -bL $OS | grep -oP 'version\s+\K[^ ]+'        # returns only the string after "version " until the following space
#   file -bL $OS | grep -Eo 'version\ [^ ]+'                # returns the full string matched including "version "
#   https://stackoverflow.com/questions/55027495/grep-match-next-word-after-pattern-until-first-space
    echo
done <<< "$KERNELS"

# unmount
while read DISK
do
    # echo $DISK
    udisksctl unmount -b $DISK > /dev/null 2>&1
done <<< "$DISK_LIST"

echo Found $(expr $(wc -l <<< "$DISK_LIST") + 1) devices.
echo Found $(wc -l <<< "$KERNELS") kernels.

exit 0
