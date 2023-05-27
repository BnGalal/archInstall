#!/bin/bash

ln -sf /usr/share/zoneinfo/Asia/Baghdad /etc/localtime
hwclock --systohc
sed -i '171s/.//' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

newhost=$(read -p "Please enter host name: " input; echo $input)
newuser=$(read -p "Please enter new user name: " input; echo $input)

echo "$newhost" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $newhost.localdomain $newhost" >> /etc/hosts
# echo root:x123 | chpasswd #change the root pwd

pacman -S xorg networkmanager network-manager-applet dialog ntfs-3g wireless_tools wpa_supplicant os-prober mtools dosfstools git base-devel linux-headers xf86-video-intel bluez bluez-utils cups alsa-utils pulseaudio pulseaudio-bluetooth grub efibootmgr xdg-utils openssh

# pacman -S --noconfirm xf86-video-amdgpu
# pacman -S --noconfirm nvidia nvidia-utils nvidia-settings
# grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB #change the directory to /boot/efi is you mounted the EFI partition at /boot/efi

grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups

useradd -mG wheel $newuser #add your username with wheel group

printf "\e[1;32mDone! root & user password + user ALL=(ALL) ALL EDITOR=nano visudo.\e[0m"
