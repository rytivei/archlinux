#!/bin/bash

#### load finnish keymap
localectl list-keymaps | grep fi
loadkeys fi

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
mkdir /mnt/root
mount $root_part /mnt/root
cd /mnt/root
btrfs subvolume create vol-root
btrfs subvolume create vol-etc
btrfs subvolume create vol-var
cd /
umount /mnt/root
mount -o subvol=vol-root $root_part /mnt/root
mkdir /mnt/root/{etc,var}
mount -o subvol=vol-etc $root_part /mnt/root/etc
mount -o subvol=vol-var $root_part /mnt/root/var
read -p "Give full path to SWAP partition: " swap_part
mkswap $swap_part
swapon $swap_part
read -p "Give full path to BOOT partition: " boot_part
mkfs.ext2 $boot_part
mkdir /mnt/root/boot
mount $boot_part /mnt/root/boot
read -p "Give full path to HOME partition: " home_part
mkdir /mnt/root/home
mount $home_part /mnt/root/home

#### install base system
pacstrap /mnt/root base base-devel

#### setup fstab
genfstab -U -p /mnt/root > /mnt/root/etc/fstab
echo 'tmpfs /tmp tmpfs nodev,nosuid 0 0' >> /mnt/root/etc/fstab
echo 'tmpfs /dev/shm tmpfs nodev,nosuid,noexec 0 0' >> /mnt/root/etc/fstab

#### configure system
arch-chroot /mnt/root /bin/bash

sed -i 's|#en_US.UTF-8 UTF-8|en_US.UTF-8 UTF-8|g' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
export LANG=en_US.UTF-8

echo 'KEYMAP=fi' > /etc/vconsole.conf
echo 'FONT=Lat2-Terminus16' >> /etc/vconsole.conf
pacman -S terminus-font

ln -s /usr/share/zoneinfo/Europe/Helsinki /etc/localtime

hwclock --systohc --utc

read -p "Give a hostname: " hostname
echo "$hostname" > /etc/hostname
######################### nano /etc/hosts

ip link
read -p "Give network interface for DHCPCD: " interface
systemctl enable dhcpcd@${interface}.service

pacman -S btrfs-progs grub os-prober
read -p "Set bootable partition. Open cfdisk by pressing ENTER..." x
cfdisk
read -p "Give full path to BOOT __device__: " boot_dev
grub-install --target=i386-pc --recheck --debug $boot_dev

sed -i 's|MODULES=""|MODULES="crc32c"|g' /etc/mkinitcpio.conf
sed -i 's| fsck"| fsck btrfs"|g' /etc/mkinitcpio.conf
mkinitcpio -p linux

sed -i 's|^GRUB_CMDLINE_LINUX=.*$|GRUB_CMDLINE_LINUX="init=/lib/systemd/systemd rootflags=subvol=vol-root ipv6.disable=1"|' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

passwd
exit
umount -R /mnt/root
reboot
