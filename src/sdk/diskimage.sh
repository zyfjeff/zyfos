#!/bin/bash
#qemu-img 创建一个大小为2M大小的镜像文件
qemu-img create c.img 2M
#对这个镜像文件进行分区
fdisk ./c.img  << EOF
x
c
4
h
16
s
63
r
n
p
1
1
4
a
1
w
EOF

fdisk -l -u ./c.img
#这里-o代表偏移量,意思就是从c.img的32256偏移处开始附加到回环设备上，
#为什么是32256呢 63*512 =32256,
losetup -o 32256 /dev/loop1 ./c.img

mke2fs /dev/loop1
mount  /dev/loop1 /mnt/
cp -R bootdisk/* /mnt/
umount /mnt/
grub --device-map=/dev/null << EOF
device (hd0) ./c.img
geometry (hd0) 4 16 63
root (hd0,0)
setup (hd0)
quit
EOF

losetup -d /dev/loop1
