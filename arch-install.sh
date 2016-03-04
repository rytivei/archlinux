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
echo "**** at least 'swap' and '/' need their own partitions ***"
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

echo "#### ROOT partition ####"
read -p "Give full path to ROOT partition: " root_part
read -p "Give FS type for ROOT partition (ext4 or btrfs): " rootfs_type

if [ "$rootfs_type" = "btrfs" ]; then
    mounted_root_path="/mnt/btrfs-current"

    mkfs.btrfs -f -L rootfs $root_part

    mkdir /mnt/btrfs-root
    mount $root_part /mnt/btrfs-root

    mkdir /mnt/btrfs-root/__current
    mkdir /mnt/btrfs-root/__snapshot

    btrfs subvolume create /mnt/btrfs-root/__current/ROOT
    mkdir $mounted_root_path
    mount -o subvol=__current/ROOT $root_part $mounted_root_path

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
            mkdir $mounted_root_path/$mountpoint
            mount -o subvol=__current/$mountpoint $root_part $mounted_root_path/$mountpoint
            sleep 2
        done
    fi

elif [ "$rootfs_type" = "ext4" ]; then

    mounted_root_path="/mnt/ext4_root"

    mkfs.ext4 -L rootfs $root_part
    mkdir $mounted_root_path
    mount $root_part $mounted_root_path
else
    echo "You chose something else than 'ext4' or 'btrfs', exiting ..."
    exit 1
fi

if [ "$rootfs_type" = "btrfs" ]; then
    list_of_mountpoints="boot home $subvolumes"
else
    list_of_mountpoints="boot home"
fi
mountpoint_is_partition=$(echo "$list_of_mountpoints" | tr " " "\n" | sort | uniq -u)

echo "Following mountpoints will be handled next."
echo "$mountpoint_is_partition"

for mountpoint in $mountpoint_is_partition; do

    read -p "Will mountpoint __${mountpoint}__ be on a separate partition ? [yes/no]: " partition

    if [ "$partition" = "yes" ]; then
        lsblk
        read -p "Give full path to __${mountpoint}__ partition: " partition
        read -p "Give filesystem type to format __${mountpoint}__ partition: " fstype
        mkfs.${fstype} $partition
        mkdir $mounted_root_path/$mountpoint
        mount $partition $mounted_root_path/$mountpoint
        sleep 2
    fi
done

#### install base system
pacstrap -i $mounted_root_path base btrfs-progs grub sudo sed

#### setup fstab
root_part_uuid=$(ls -l /dev/disk/by-uuid | grep $(basename $root_part) | awk '{print $9}')
genfstab -U -p $mounted_root_path > $mounted_root_path/etc/fstab
echo "tmpfs    /tmp        tmpfs    nodev,nosuid        0 0"  >> $mounted_root_path/etc/fstab
echo "tmpfs    /dev/shm    tmpfs    nodev,nosuid,noexec 0 0"  >> $mounted_root_path/etc/fstab

#### set locale
arch-chroot $mounted_root_path sed -i "s|#en_US.UTF-8 UTF-8|en_US.UTF-8 UTF-8|g" /etc/locale.gen
arch-chroot $mounted_root_path locale-gen
arch-chroot $mounted_root_path echo "LANG=en_US.UTF-8" > /etc/locale.conf

#### set keyboard
arch-chroot $mounted_root_path echo "KEYMAP=fi"             > /etc/vconsole.conf
arch-chroot $mounted_root_path echo "FONT=Lat2-Terminus16" >> /etc/vconsole.conf

#### set timezone
arch-chroot $mounted_root_path ln -s /usr/share/zoneinfo/Europe/Helsinki /etc/localtime

#### set system clock
arch-chroot $mounted_root_path hwclock --systohc --utc

#### hostname
read -p "Give a hostname: " hostname
arch-chroot $mounted_root_path echo "$hostname" > /etc/hostname

#### sudo permissions
arch-chroot $mounted_root_path sed -i "s|# %wheel.*|%wheel ALL=(ALL) ALL|g" /etc/sudoers

#### root password
echo "Give a root password."
arch-chroot $mounted_root_path passwd

#### create new user
read -p "Give a username: " username
arch-chroot $mounted_root_path useradd --create-home --groups wheel,users,uucp -s /bin/bash $username
arch-chroot $mounted_root_path chfn $username
echo "Give $username a password."
arch-chroot $mounted_root_path passwd $username

if [ "$rootfs_type" = "btrfs" ]; then
    #### btrfs hook to initramfs
    arch-chroot $mounted_root_path sed -i "s|MODULES=\"\"|MODULES=\"crc32c\"|g" /etc/mkinitcpio.conf
    arch-chroot $mounted_root_path sed -i "s| fsck\"| fsck btrfs\"|g"           /etc/mkinitcpio.conf
    arch-chroot $mounted_root_path mkinitcpio -p linux
fi

#### install grub
lsblk
read -p "Give full path to BOOT __device__: " boot_dev
arch-chroot $mounted_root_path grub-install --target=i386-pc --recheck --debug $boot_dev
if [ "$rootfs_type" = "btrfs" ]; then
    arch-chroot $mounted_root_path sed -i "s|^GRUB_CMDLINE_LINUX=.*$|GRUB_CMDLINE_LINUX=\"init=/lib/systemd/systemd ipv6.disable=1\"|" /etc/default/grub
else
    arch-chroot $mounted_root_path sed -i "s|^GRUB_CMDLINE_LINUX=.*$|GRUB_CMDLINE_LINUX=\"ipv6.disable=1\"|" /etc/default/grub
fi
arch-chroot $mounted_root_path sed -i "s|^GRUB_GFXMODE=.*|GRUB_GFXMODE=1024x768x32,auto|g"                                         /etc/default/grub
arch-chroot $mounted_root_path grub-mkconfig -o /boot/grub/grub.cfg

#### networking
echo "[INFO] setup dhcp networking ..."
ip link
read -p "Give network interface for system-networkd (dhcpcd): " interface
arch-chroot $mounted_root_path systemctl enable dhcpcd@${interface}.service

cat << EOF > $mounted_root_path/etc/systemd/network/wired.network
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
arch-chroot $mounted_root_path pacman -S base-devel abs htop bash-completion vim terminus-font git cronie yakuake xorg-server xorg-drivers xorg-apps dri2proto plasma sddm kdeadmin kdebase kdegraphics kdemultimedia kdesdk kdeutils
arch-chroot $mounted_root_path systemctl enable sddm

read -p "Is this Arch Linux installation done inside Virtualbox ? [yes/no]: " virtualbox
if [ "$virtualbox" = "yes" ]; then
    arch-chroot $mounted_root_path pacman -S virtualbox-guest-utils
    arch-chroot $mounted_root_path systemctl enable vboxservice.service
    arch-chroot $mounted_root_path gpasswd -a $username vboxsf
fi

umount -R $mounted_root_path
if [ "$rootfs_type" = "btrfs" ]; then
    umount -R /mnt/btrfs-root
fi
reboot
