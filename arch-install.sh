#!/bin/bash

#### check internet connection
ping -c3 www.google.com
if [ $? -ne 0 ]; then
    echo "ERROR: No Internet connection"
    exit 1
fi

#### create filesystems
lsblk
read -p "Give full path to ROOT partition: " root_part
mkfs.btrfs -f -L rootfs $root_part

mkdir /mnt/btrfs-root
mount $root_part /mnt/btrfs-root

mkdir /mnt/btrfs-root/__current
mkdir /mnt/btrfs-root/__snapshot
btrfs subvolume create /mnt/btrfs-root/__current/ROOT
btrfs subvolume create /mnt/btrfs-root/__current/ROOT/etc
btrfs subvolume create /mnt/btrfs-root/__current/var

mkdir /mnt/btrfs-current
mount -o subvol=__current/ROOT     $root_part /mnt/btrfs-current

mkdir /mnt/btrfs-current/etc
mount -o subvol=__current/ROOT/etc $root_part /mnt/btrfs-current/etc

mkdir /mnt/btrfs-current/var
mount -o subvol=__current/var      $root_part /mnt/btrfs-current/var

mkdir /mnt/btrfs-current/var/lib
mount --bind /mnt/btrfs-root/__current/ROOT/var/lib /mnt/btrfs-current/var/lib

read -p "Give full path to BOOT partition: " boot_part
mkfs.ext2 $boot_part
mkdir /mnt/btrfs-current/boot
mount $boot_part /mnt/btrfs-current/boot

read -p "Give full path to HOME partition: " home_part
mkdir /mnt/btrfs-current/home
mount $home_part /mnt/btrfs-current/home

read -p "Give full path to SWAP partition: " swap_part
mkswap $swap_part
swapon $swap_part

#### install base system
pacstrap -i /mnt/btrfs-current base base-devel

#### setup fstab
root_part_uuid=$(ls -l /dev/disk/by-uuid | grep $(basename $root_part) | awk '{print $9}')
genfstab -U -p /mnt/btrfs-current > /mnt/btrfs-current/etc/fstab
echo "tmpfs                                     /tmp               tmpfs    nodev,nosuid        0 0"                         >> /mnt/btrfs-current/etc/fstab
echo "tmpfs                                     /dev/shm           tmpfs    nodev,nosuid,noexec 0 0"                         >> /mnt/btrfs-current/etc/fstab
echo "/run/btrfs-root/__current/ROOT/var/lib    /var/lib           none     bind                0 0"                         >> /mnt/btrfs-current/etc/fstab
echo "UUID=$root_part_uuid                      /run/btrfs-root    btrfs    rw,nodev,nosuid,noexec,relatime,space_cache 0 0" >> /mnt/btrfs-current/etc/fstab

#### configure system
arch-chroot /mnt/btrfs-current pacman -S btrfs-progs grub os-prober terminus-font intel-ucode yakuake sudo htop plasma sddm vim
arch-chroot /mnt/btrfs-current systemctl enable sddm
arch-chroot /mnt/btrfs-current sed -i "s|#en_US.UTF-8 UTF-8|en_US.UTF-8 UTF-8|g" /etc/locale.gen
arch-chroot /mnt/btrfs-current locale-gen
arch-chroot /mnt/btrfs-current echo "LANG=en_US.UTF-8"      > /etc/locale.conf
arch-chroot /mnt/btrfs-current echo "KEYMAP=fi"             > /etc/vconsole.conf
arch-chroot /mnt/btrfs-current echo "FONT=Lat2-Terminus16" >> /etc/vconsole.conf
arch-chroot /mnt/btrfs-current ln -s /usr/share/zoneinfo/Europe/Helsinki /etc/localtime
arch-chroot /mnt/btrfs-current hwclock --systohc --utc
read -p "Give a hostname: " hostname
arch-chroot /mnt/btrfs-current echo "$hostname" > /etc/hostname
ip link
read -p "Give network interface for DHCPCD: " interface
arch-chroot /mnt/btrfs-current systemctl enable dhcpcd@${interface}.service
arch-chroot /mnt/btrfs-current sed -i "s|MODULES=\"\"|MODULES=\"crc32c\"|g" /etc/mkinitcpio.conf
arch-chroot /mnt/btrfs-current sed -i "s| fsck\"| fsck btrfs\"|g"           /etc/mkinitcpio.conf
arch-chroot /mnt/btrfs-current mkinitcpio -p linux
read -p "Give full path to BOOT __device__: " boot_dev
arch-chroot /mnt/btrfs-current grub-install --target=i386-pc --recheck --debug $boot_dev
arch-chroot /mnt/btrfs-current sed -i "s|^GRUB_CMDLINE_LINUX=.*$|GRUB_CMDLINE_LINUX=\"init=/lib/systemd/systemd ipv6.disable=1\"|" /etc/default/grub
arch-chroot /mnt/btrfs-current grub-mkconfig -o /boot/grub/grub.cfg
arch-chroot /mnt/btrfs-current passwd
umount -R /mnt/btrfs-root
reboot
