#!/bin/bash

loadkeys fi

echo "[INFO] checking internet connection ..."
ping -c3 www.google.com
if [ $? -ne 0 ]; then
    echo "[ERROR] no Internet connection, exiting ..."
    exit 1
fi

echo "----------------------------"
echo " This script will install Arch Linux with following configuration."
echo ""
echo " / can be BTRFS and you can have mountpoints as subvolumes under it."
echo " All other basic mountpoints that are not subvolumes are on their own partition."
echo " OR"
echo " / can be EXT4 (with encryption optionally)."
echo ""
echo " --> Boots to KDE desktop with a user that has sudo rights."
echo "----------------------------"

read -p "Are you ready to continue ? [PRESS ENTER]" x

lsblk
echo ""
echo ""
echo "Partitioning the disk is the first thing to do."
echo "Set partitioning style to 'msdos' in MBR for this script to work. "
echo ""
echo "We will run 'parted' in interactive mode. Give following commands."
echo "mklabel msdos"
echo "quit"
echo ""
echo "Decide which mountpoints get their own partition."
echo "**** at least 'swap' and '/' need their own partitions ***"
read -p "Do you want partition the disk ? [yes/no] " partition
if [ "$partition" = "yes" ]; then
    read -p "Give the __device__ to partition: " partition
    parted $partition
    cfdisk $partition
fi

lsblk
echo "#### ROOT partition ####"
read -p "Give full path to ROOT partition: " root_part
read -p "Give FS type for ROOT partition (ext4 or btrfs): " root_fstype
read -p "Do you want to encrypt the ROOT partition? [yes/no]: " root_crypt

if [ "$root_crypt" = "yes" -a "$root_fstype" = "btrfs" ]; then
    echo "[ERROR] you can't use encryption with BTRFS, exiting"
    exit 1
fi

if [ "$root_crypt" = "yes" ]; then
    cryptsetup -y -v luksFormat $root_part
    cryptsetup open $root_part cryptroot
fi

if [ "$root_fstype" = "btrfs" ]; then
    root_mountpoint="/mnt/btrfs-current"

    mkfs.btrfs -f -L rootfs $root_part

    mkdir /mnt/btrfs-root
    mount $root_part /mnt/btrfs-root

    mkdir /mnt/btrfs-root/__current
    mkdir /mnt/btrfs-root/__snapshot

    btrfs subvolume create /mnt/btrfs-root/__current/ROOT
    mkdir $root_mountpoint
    mount -o subvol=__current/ROOT $root_part $root_mountpoint

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
            mkdir $root_mountpoint/$mountpoint
            mount -o subvol=__current/$mountpoint $root_part $root_mountpoint/$mountpoint
            sleep 2
        done
    fi

elif [ "$root_fstype" = "ext4" ]; then
    root_mountpoint="/mnt/ext4_root"

    if [ "$root_crypt" = "yes" ]; then
        mkfs.ext4 -L rootfs /dev/mapper/cryptroot
    else
        mkfs.ext4 -L rootfs $root_part
    fi

    mkdir $root_mountpoint

    if [ "$root_crypt" = "yes" ]; then
        mount /dev/mapper/cryptroot $root_mountpoint
    else
        mount $root_part $root_mountpoint
    fi

    if [ "$root_crypt" = "yes" ]; then
        echo "unmount $root_mountpoint"
        umount $root_mountpoint

        echo "cryptsetup close cryptroot"
        cryptsetup close cryptroot

        echo "cryptsetup open $root_part cryptroot"
        cryptsetup open $root_part cryptroot

        echo "mount /dev/mapper/cryptroot $root_mountpoint"
        mount /dev/mapper/cryptroot $root_mountpoint
    fi
else
    echo "You chose something else than 'ext4' or 'btrfs', exiting ..."
    exit 1
fi

if [ "$root_crypt" = "yes" ]; then
    list_of_mountpoints="boot"
elif [ "$root_fstype" = "btrfs" ]; then
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
        mkdir $root_mountpoint/$mountpoint
        mount $partition $root_mountpoint/$mountpoint
        sleep 2
    fi
done

echo "#### SWAP partition ####"
read -p "Give full path to SWAP partition: " swap_part
mkswap $swap_part
swapon $swap_part

#### install base system
pacstrap -i $root_mountpoint base btrfs-progs grub sudo sed

#### setup fstab
root_part_uuid=$(ls -l /dev/disk/by-uuid | grep $(basename $root_part) | awk '{print $9}')
genfstab -U -p $root_mountpoint > $root_mountpoint/etc/fstab
echo "tmpfs    /tmp        tmpfs    nodev,nosuid        0 0"  >> $root_mountpoint/etc/fstab
echo "tmpfs    /dev/shm    tmpfs    nodev,nosuid,noexec 0 0"  >> $root_mountpoint/etc/fstab

#### install grub
lsblk
read -p "Give full path to BOOT __device__: " boot_dev
arch-chroot $root_mountpoint grub-install --target=i386-pc --recheck --debug $boot_dev
if [ "$root_fstype" = "btrfs" ]; then
    arch-chroot $root_mountpoint sed -i "s|^GRUB_CMDLINE_LINUX=.*$|GRUB_CMDLINE_LINUX=\"init=/lib/systemd/systemd ipv6.disable=1\"|" /etc/default/grub
else
    arch-chroot $root_mountpoint sed -i "s|^GRUB_CMDLINE_LINUX=.*$|GRUB_CMDLINE_LINUX=\"ipv6.disable=1\"|" /etc/default/grub
fi
arch-chroot $root_mountpoint sed -i "s|^GRUB_GFXMODE=.*|GRUB_GFXMODE=1024x768x32,auto|g"                                         /etc/default/grub
arch-chroot $root_mountpoint grub-mkconfig -o /boot/grub/grub.cfg

#### set locale
arch-chroot $root_mountpoint sed -i "s|#en_US.UTF-8 UTF-8|en_US.UTF-8 UTF-8|g" /etc/locale.gen
arch-chroot $root_mountpoint locale-gen
arch-chroot $root_mountpoint echo "LANG=en_US.UTF-8" > /etc/locale.conf

#### set keyboard
arch-chroot $root_mountpoint echo "KEYMAP=fi"             > /etc/vconsole.conf
arch-chroot $root_mountpoint echo "FONT=Lat2-Terminus16" >> /etc/vconsole.conf

#### set timezone
arch-chroot $root_mountpoint ln -s /usr/share/zoneinfo/Europe/Helsinki /etc/localtime

#### set system clock
arch-chroot $root_mountpoint hwclock --systohc --utc

#### hostname
read -p "Give a hostname: " hostname
arch-chroot $root_mountpoint echo "$hostname" > /etc/hostname

#### sudo permissions
arch-chroot $root_mountpoint sed -i "s|# %wheel.*|%wheel ALL=(ALL) ALL|g" /etc/sudoers

#### root password
echo "Give a root password."
arch-chroot $root_mountpoint passwd

#### create new user
read -p "Give a username: " username
arch-chroot $root_mountpoint useradd --create-home --groups wheel,users,uucp -s /bin/bash $username
arch-chroot $root_mountpoint chfn $username
echo "Give $username a password."
arch-chroot $root_mountpoint passwd $username

#### networking
echo "[INFO] setup dhcp networking ..."
ip link
read -p "Give network interface for system-networkd (dhcpcd): " interface
arch-chroot $root_mountpoint systemctl enable dhcpcd@${interface}.service

cat << EOF > $root_mountpoint/etc/systemd/network/wired.network
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
arch-chroot $root_mountpoint pacman -S base-devel abs htop bash-completion vim terminus-font git cronie yakuake xorg-server xorg-drivers xorg-apps dri2proto plasma sddm kdeadmin kdebase kdegraphics kdemultimedia kdesdk kdeutils
arch-chroot $root_mountpoint systemctl enable sddm

read -p "Is this Arch Linux installation done inside Virtualbox ? [yes/no]: " virtualbox
if [ "$virtualbox" = "yes" ]; then
    arch-chroot $root_mountpoint pacman -S virtualbox-guest-utils
    arch-chroot $root_mountpoint systemctl enable vboxservice.service
    arch-chroot $root_mountpoint gpasswd -a $username vboxsf
fi

if [ "$root_fstype" = "btrfs" ]; then
    #### btrfs hook to initramfs
    arch-chroot $root_mountpoint sed -i "s|MODULES=\"\"|MODULES=\"crc32c\"|g" /etc/mkinitcpio.conf
    arch-chroot $root_mountpoint sed -i "s| fsck\"| fsck btrfs\"|g"           /etc/mkinitcpio.conf
fi

if [ "$root_crypt" = "yes" ]; then
    echo "[INFO] add 'encrypt' to HOOKS in /etc/mkinitcpio.conf"
    arch-chroot $root_mountpoint
fi

arch-chroot $root_mountpoint mkinitcpio -p linux

umount -R $root_mountpoint
if [ "$root_fstype" = "btrfs" ]; then
    umount -R /mnt/btrfs-root
fi
reboot
