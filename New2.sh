#!/bin/bash

# Configuration Variables
DRIVE="/dev/nvme0n1" # Update to your target drive (e.g., /dev/sda)
HOSTNAME="arch-proton"
USERNAME="user"
TIMEZONE="UTC"

#echo "--- Partitioning Drive ---"
#sgdisk -Z $DRIVE
#sgdisk -n 1:0:+1G -t 1:ef00 $DRIVE
#sgdisk -n 2:0:0 -t 2:8e00 $DRIVE

echo "--- Setting up Encryption ---"
# You will be prompted to create your disk encryption password here
#cryptsetup luksFormat "${DRIVE}p2"
#cryptsetup open "${DRIVE}p2" cryptlvm

echo "--- Setting up LVM ---"
#pvcreate /dev/mapper/cryptlvm
#vgcreate vg0 /dev/mapper/cryptlvm
#lvcreate -L 8G vg0 -n swap
#lvcreate -l 100%FREE vg0 -n root

echo "--- Formatting Filesystems ---"
#mkfs.fat -F32 "${DRIVE}p1"
#mkfs.ext4 /dev/vg0/root
#mkswap /dev/vg0/swap

echo "--- Mounting Filesystems ---"
#mount /dev/vg0/root /mnt
#mount --mkdir "${DRIVE}p1" /mnt/boot
#swapon /dev/vg0/swap

echo "--- Installing Base, XFCE, Pipewire & Fonts ---"
#pacstrap -K /mnt base base-devel linux linux-headers linux-firmware lvm2 vim nano intel-ucode

#pacstrap -K /mnt networkmanager network-manager-applet dialog ntfs-3g wireless_tools wpa_supplicant mtools dosfstools git bluez bluez-utils cups alsa-utils xdg-utils openssh xf86-video-intel xorg pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings xfce4 xfce4-goodies gvfs dbus blueman firefox xarchiver xz unrar unzip p7zip ttf-dejavu ttf-liberation noto-fonts ttf-roboto

echo "--- Generating fstab ---"
#genfstab -U /mnt >> /mnt/etc/fstab

echo "--- Configuring System (Chroot) ---"
#arch-chroot /mnt
