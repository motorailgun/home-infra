#!/bin/sh
set -xe

SERVER=172.17.1.2

MAC=$(cat /sys/class/net/eth0/address | tr ':' '-')

if  mount -t nfs -o vers=4 $SERVER:/srv/$MAC /mnt 2>/dev/null; then
    umount /mnt
else
    mount -t nfs -o vers=4 $SERVER:/srv/ /mnt

    cp -av /mnt/rpi-template /mnt/$MAC

    echo "proc                  /proc   proc    defaults        0 0" > /mnt/$MAC/etc/fstab
    echo "$SERVER:/srv/$MAC  /       nfs     rw,vers=4      0 0" >> /mnt/$MAC/etc/fstab

    umount /mnt
fi

mount -t nfs -o rw,vers=4 $SERVER:/srv/$MAC /mnt/

exec switch_root /mnt /sbin/init
