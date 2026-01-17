#!/bin/bash

DRIVE="/dev/nvme0n1"
HOSTNAME="arch-proton"
USERNAME="user"

echo "DRIVE \$DRIVE HOSTNAME \$HOSTNAME USERNAME \$USERNAME"

read -n 3 -s -r -p "Press any key to continue..." key
clear

echo "--- Installing XFCE, Pipewire & Fonts ---"
pacman --noconfirm networkmanager network-manager-applet dialog ntfs-3g wireless_tools wpa_supplicant mtools dosfstools git bluez bluez-utils cups alsa-utils xdg-utils openssh xf86-video-intel xorg pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings xfce4 xfce4-goodies gvfs dbus blueman firefox xarchiver xz unrar unzip p7zip ttf-dejavu ttf-liberation noto-fonts ttf-roboto

clear
read -n 3 -s -r -p "Press any key to continue..." key
clear

ln -sf /usr/share/zoneinfo/asia/baghdad /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "$HOSTNAME" > /etc/hostname

clear
read -n 3 -s -r -p "Press any key to continue..." key
clear


# Update Initramfs Hooks for Encryption and LVM
echo "Update Initramfs Hooks for Encryption and LVM"
read -n 3 -s -r -p "Press any key to continue..." key

sed -i 's/HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf kms keyboard keymap block encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf

clear
read -n 3 -s -r -p "Press any key to continue..." key
clear


mkinitcpio -p linux

read -n 3 -s -r -p "Press any key to continue..." key
clear

# Bootloader Setup with Encryption and Microcode support
pacman -S --noconfirm grub efibootmgr
UUID=\$(blkid -s UUID -o value ${DRIVE}p2)
# Added cryptdevice and root parameters to GRUB
sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\"|GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=\$UUID:cryptlvm root=/dev/vg0/root |" /etc/default/grub

clear
read -n 3 -s -r -p "Press any key to continue..." key
clear

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

clear
read -n 3 -s -r -p "Press any key to continue..." key
clear

# Enable Services
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups
systemctl enable lightdm
systemctl enable sshd

# User Setup
echo "--- Setting Root Password ---"
passwd
useradd -m -G wheel $USERNAME
echo "--- Setting Password for $USERNAME ---"
passwd $USERNAME
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

echo "Installation Complete! Reboot and enjoy your encrypted XFCE system."
