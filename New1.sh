#!/bin/bash

# Configuration Variables
DRIVE="/dev/nvme0n1" # Update to your target drive (e.g., /dev/sda)
HOSTNAME="arch-proton"
USERNAME="user"
TIMEZONE="UTC"

echo "--- Partitioning Drive ---"
sgdisk -Z $DRIVE
sgdisk -n 1:0:+1G -t 1:ef00 $DRIVE
sgdisk -n 2:0:0 -t 2:8e00 $DRIVE

echo "--- Setting up Encryption ---"
# You will be prompted to create your disk encryption password here
cryptsetup luksFormat "${DRIVE}p2"
cryptsetup open "${DRIVE}p2" cryptlvm

echo "--- Setting up LVM ---"
pvcreate /dev/mapper/cryptlvm
vgcreate vg0 /dev/mapper/cryptlvm
lvcreate -L 8G vg0 -n swap
lvcreate -l 100%FREE vg0 -n root

echo "--- Formatting Filesystems ---"
mkfs.fat -F32 "${DRIVE}p1"
mkfs.ext4 /dev/vg0/root
mkswap /dev/vg0/swap

echo "--- Mounting Filesystems ---"
mount /dev/vg0/root /mnt
mount --mkdir "${DRIVE}p1" /mnt/boot
swapon /dev/vg0/swap

echo "--- Installing Base, XFCE, Pipewire & Fonts ---"
pacstrap -K /mnt base base-devel linux linux-headers linux-firmware lvm2 vim \
intel-ucode networkmanager network-manager-applet dialog ntfs-3g \
wireless_tools wpa_supplicant mtools dosfstools git bluez bluez-utils \
cups alsa-utils xdg-utils openssh xf86-video-intel xorg \
pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings xfce4 xfce4-goodies \
gvfs dbus blueman firefox xarchiver xz unrar unzip p7zip \
ttf-dejavu ttf-liberation noto-fonts ttf-roboto

echo "--- Generating fstab ---"
genfstab -U /mnt >> /mnt/etc/fstab

echo "--- Configuring System (Chroot) ---"
arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "$HOSTNAME" > /etc/hostname

# Update Initramfs Hooks for Encryption and LVM
sed -i 's/HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf kms keyboard keymap block encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -p linux

# Bootloader Setup with Encryption and Microcode support
pacman -S --noconfirm grub efibootmgr
UUID=\$(blkid -s UUID -o value ${DRIVE}p2)
# Added cryptdevice and root parameters to GRUB
sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\"|GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=\$UUID:cryptlvm root=/dev/vg0/root |" /etc/default/grub

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

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

EOF

echo "Installation Complete! Reboot and enjoy your encrypted XFCE system."
