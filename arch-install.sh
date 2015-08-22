#!/bin/bash

echo "[INFO] checking internet connection ..."
ping -c3 www.google.com
if [ $? -ne 0 ]; then
    echo "[ERROR] no Internet connection, exiting ..."
    exit 1
fi

echo "----------------------------"
echo " This script will install Arch Linux with following configuration."
echo ""
echo " / is BTRFS and you can have mountpoints as subvolumes under it."
echo " All other basic mountpoints that are not subvolumes are on their own partition."
echo ""
echo " --> Boots to KDE desktop with a user that has sudo rights."
echo "----------------------------"

read -p "Are you ready to continue ? [PRESS ENTER]" x

lsblk
echo "Partitioning the disk is the first thing to do."
echo "Decide which mountpoints get their own partition."
read -p "Do you want partition the disk ? [yes/no] " partition
if [ "$partition" = "yes" ]; then
    read -p "Give the __device__ to partition: " partition
    cfdisk $partition
fi

lsblk
echo "#### SWAP partition ####"
read -p "Give full path to SWAP partition: " swap_part
mkswap $swap_part
swapon $swap_part

echo "#### ROOT partition (btrfs) ####"
read -p "Give full path to ROOT partition: " root_part
mkfs.btrfs -f -L rootfs $root_part

mkdir /mnt/btrfs-root
mount $root_part /mnt/btrfs-root

mkdir /mnt/btrfs-root/__current
mkdir /mnt/btrfs-root/__snapshot

btrfs subvolume create /mnt/btrfs-root/__current/ROOT
mkdir /mnt/btrfs-current
mount -o subvol=__current/ROOT $root_part /mnt/btrfs-current

echo "#### BTRFS subvolumes ####"
echo "Give a list of mountpoints that will be btrfs subvolumes under ROOT."
echo "Giving an empty value means:"
echo "  --> All mountpoints can be on their separate partition"
echo "  --> or just under /"
read -p "Give subvolume list: " subvolumes

if [ -n "$subvolumes" ]; then

    for mountpoint in $subvolumes; do
        echo "[INFO] SUBVOLUM-ING: __${mountpoint}__"
        btrfs subvolume create /mnt/btrfs-root/__current/$mountpoint
        mkdir /mnt/btrfs-current/$mountpoint
        mount -o subvol=__current/$mountpoint $root_part /mnt/btrfs-current/$mountpoint
        sleep 2
    done
fi

echo "Following mountpoints will be handled next."
echo "boot home var $subvolumes" | tr " " "\n" | sort | uniq -u
mountpoint_is_partition=$(echo "boot home var $subvolumes" | tr " " "\n" | sort | uniq -u)

for mountpoint in $mountpoint_is_partition; do

    read -p "Will mountpoint __${mountpoint}__ be on a separate partition ? [yes/no]: " partition

    if [ "$partition" = "yes" ]; then
        lsblk
        read -p "Give full path to __${mountpoint}__ partition: " partition
        read -p "Give filesystem type to format __${mountpoint}__ partition: " fstype
        mkfs.${fstype} $partition
        mkdir /mnt/btrfs-current/$mountpoint
        mount $partition /mnt/btrfs-current/$mountpoint
        sleep 2
    fi
done

#### install base system
pacstrap -i /mnt/btrfs-current base btrfs-progs grub sudo sed

#### setup fstab
root_part_uuid=$(ls -l /dev/disk/by-uuid | grep $(basename $root_part) | awk '{print $9}')
genfstab -U -p /mnt/btrfs-current > /mnt/btrfs-current/etc/fstab
echo "tmpfs    /tmp        tmpfs    nodev,nosuid        0 0"  >> /mnt/btrfs-current/etc/fstab
echo "tmpfs    /dev/shm    tmpfs    nodev,nosuid,noexec 0 0"  >> /mnt/btrfs-current/etc/fstab

#### set locale
arch-chroot /mnt/btrfs-current sed -i "s|#en_US.UTF-8 UTF-8|en_US.UTF-8 UTF-8|g" /etc/locale.gen
arch-chroot /mnt/btrfs-current locale-gen
arch-chroot /mnt/btrfs-current echo "LANG=en_US.UTF-8" > /etc/locale.conf

#### set keyboard
arch-chroot /mnt/btrfs-current echo "KEYMAP=fi"             > /etc/vconsole.conf
arch-chroot /mnt/btrfs-current echo "FONT=Lat2-Terminus16" >> /etc/vconsole.conf

#### set timezone
arch-chroot /mnt/btrfs-current ln -s /usr/share/zoneinfo/Europe/Helsinki /etc/localtime

#### set system clock
arch-chroot /mnt/btrfs-current hwclock --systohc --utc

#### hostname
read -p "Give a hostname: " hostname
arch-chroot /mnt/btrfs-current echo "$hostname" > /etc/hostname

#### sudo permissions
arch-chroot /mnt/btrfs-current sed -i "s|# %wheel.*|%wheel ALL=(ALL) ALL|g" /etc/sudoers

#### root password
echo "Give a root password."
arch-chroot /mnt/btrfs-current passwd

#### create new user
read -p "Give a username: " username
arch-chroot /mnt/btrfs-current useradd --create-home --groups wheel,users,uucp -s /bin/bash $username
arch-chroot /mnt/btrfs-current chfn $username
echo "Give $username a password."
arch-chroot /mnt/btrfs-current passwd $username

#### btrfs hook to initramfs
arch-chroot /mnt/btrfs-current sed -i "s|MODULES=\"\"|MODULES=\"crc32c\"|g" /etc/mkinitcpio.conf
arch-chroot /mnt/btrfs-current sed -i "s| fsck\"| fsck btrfs\"|g"           /etc/mkinitcpio.conf
arch-chroot /mnt/btrfs-current mkinitcpio -p linux

#### install grub
lsblk
read -p "Give full path to BOOT __device__: " boot_dev
arch-chroot /mnt/btrfs-current grub-install --target=i386-pc --recheck --debug $boot_dev
arch-chroot /mnt/btrfs-current sed -i "s|^GRUB_CMDLINE_LINUX=.*$|GRUB_CMDLINE_LINUX=\"init=/lib/systemd/systemd ipv6.disable=1\"|" /etc/default/grub
arch-chroot /mnt/btrfs-current sed -i "s|^GRUB_GFXMODE=.*|GRUB_GFXMODE=1024x768x32,auto|g"                                         /etc/default/grub
arch-chroot /mnt/btrfs-current grub-mkconfig -o /boot/grub/grub.cfg

#### networking
echo "[INFO] setup dhcp networking ..."
ip link
read -p "Give network interface for system-networkd (dhcpcd): " interface
arch-chroot /mnt/btrfs-current systemctl enable dhcpcd@${interface}.service

cat << EOF > /mnt/btrfs-current/etc/systemd/network/wired.network
[Match]
Name=$interface

[Network]
DHCP=ipv4
EOF
echo ""
echo ""
echo "ARCH WIKI: systemd-networkd can replace dhcpcd@${interface}.service ..."
echo ""
echo ""
sleep 5

#### install rest of the packages
arch-chroot /mnt/btrfs-current pacman -S base-devel abs htop bash-completion vim terminus-font git cronie yakuake xorg-server xorg-drivers xorg-apps dri2proto plasma sddm kdeadmin kdebase kdegraphics kdemultimedia kdesdk kdeutils
arch-chroot /mnt/btrfs-current systemctl enable sddm

read -p "Is this Arch Linux installation done inside Virtualbox ? [yes/no]: " virtualbox
if [ "$virtualbox" = "yes" ]; then
    arch-chroot /mnt/btrfs-current pacman -S virtualbox-guest-utils
    arch-chroot /mnt/btrfs-current systemctl enable vboxservice.service
    arch-chroot /mnt/btrfs-current gpasswd -a $username vboxsf
fi

umount -R /mnt/btrfs-current
umount -R /mnt/btrfs-root
reboot
