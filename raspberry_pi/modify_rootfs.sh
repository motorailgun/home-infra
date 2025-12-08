#!/bin/bash
set -xe

# THIS SCRIPT MUST BE RUN AS ROOT

# Modify raspi's rootfs so that first-stage boot can mount nfs rootfs and do switch_root
# Requires: 
#   - qemu-user-static
#   - losetup

# Raspberry Pi OS image file
# This script does NOT automatically download the image
RPI_IMAGE="2025-11-24-raspios-trixie-arm64-lite.img"
WORK_DIR=$(mktemp -d)

LOOP_DEV=$(losetup --show -fP "$RPI_IMAGE")

mount -o ro "${LOOP_DEV}p2" /mnt
mount -o ro "${LOOP_DEV}p1" /mnt/boot/firmware

rsync -aAXH /mnt/* $WORK_DIR/

cp $(which qemu-aarch64-static) $WORK_DIR/usr/bin/

chroot $WORK_DIR /usr/bin/qemu-aarch64-static /bin/bash <<'EOF'
    set -xe
    apt install -y nfs-common
EOF

rm $WORK_DIR/sbin/init
cp init.sh $WORK_DIR/sbin/init
chmod 777 $WORK_DIR/sbin/init

mkdir -p $WORK_DIR/etc/systemd/system.conf.d
echo -e "[Manager]\nRuntimeWatchdogSec=10\n" > $WORK_DIR/etc/systemd/system.conf.d/watchdog.conf
chmod -R 755 $WORK_DIR/etc/systemd/system.conf.d

echo "options bcm2835_wdt heartbeat=15 nowayout=0" > $WORK_DIR/etc/modprobe.d/bcm2835-wdt.conf

umount -R /mnt
losetup -d "$LOOP_DEV"
mv "$WORK_DIR" raspberry_pi_rootfs_modified
