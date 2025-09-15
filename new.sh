#!/bin/bash

# --- VARIABLES ---
# Set these variables to match your system
DISK="/dev/sda"
EFI_SIZE="600M"
BOOT_SIZE="2G"
SWAP_SIZE="32G"
ROOT_SIZE="100%FREE"
ENCRYPTED_DEVICE="cryptlvm"
ENCRYPTED_VG="vg0"

# Set hostname and user details
HN="arch-linux"
USER="archuser"
# You'll be prompted to enter passwords for the encrypted drive and the new user

# --- DISK PARTITIONING ---
echo "Partitioning disk ${DISK}..."
parted -s "${DISK}" mklabel gpt
parted -s "${DISK}" mkpart primary fat32 1MiB ${EFI_SIZE}
parted -s "${DISK}" set 1 esp on
parted -s "${DISK}" mkpart primary ext4 ${EFI_SIZE} ${BOOT_SIZE}
parted -s "${DISK}" mkpart primary ext4 ${BOOT_SIZE} 100%
parted -s "${DISK}" set 3 lvm on

# Wait for partitions to be created
sleep 2

# --- ENCRYPTION & LVM ---
echo "Setting up LVM on an encrypted partition..."
cryptsetup -v luksFormat "${DISK}3"
cryptsetup -v open "${DISK}3" "${ENCRYPTED_DEVICE}"

# Create LVM physical volume
pvcreate "/dev/mapper/${ENCRYPTED_DEVICE}"

# Create LVM volume group
vgcreate "${ENCRYPTED_VG}" "/dev/mapper/${ENCRYPTED_DEVICE}"

# Create LVM logical volumes
lvcreate -L "${SWAP_SIZE}" "${ENCRYPTED_VG}" -n swap
lvcreate -l "${ROOT_SIZE}" "${ENCRYPTED_VG}" -n root

# --- FORMATTING FILESYSTEMS ---
echo "Formatting filesystems..."
mkfs.fat -F32 "${DISK}1"
mkfs.ext4 "${DISK}2"
mkfs.ext4 "/dev/mapper/${ENCRYPTED_VG}-root"
mkswap "/dev/mapper/${ENCRYPTED_VG}-swap"

# --- MOUNTING ---
echo "Mounting filesystems..."
mount "/dev/mapper/${ENCRYPTED_VG}-root" /mnt
mkdir -p /mnt/boot
mount "${DISK}2" /mnt/boot
mkdir -p /mnt/boot/efi
mount "${DISK}1" /mnt/boot/efi
swapon "/dev/mapper/${ENCRYPTED_VG}-swap"

# --- PACSTRAP (Base System Installation) ---
echo "Installing base system..."
pacstrap /mnt base linux linux-firmware lvm2 grub efibootmgr networkmanager nano intel-ucode # Add amd-ucode for AMD systems

# --- GENERATE FSTAB ---
echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# --- CHROOT INTO NEW SYSTEM ---
echo "Entering chroot environment..."
arch-chroot /mnt /bin/bash <<EOF
# --- CHROOT SCRIPT ---
# Timezone setup
ln -sf /usr/share/zoneinfo/Asia/Baghdad /etc/localtime
hwclock --systohc

# Localization
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Network configuration
echo "${HN}" > /etc/hostname

# Host file
cat > /etc/hosts <<EOH
127.0.0.1  localhost
::1        localhost
127.0.1.1  ${HN}.localdomain ${HN}
EOH

# Initial ramdisk environment (mkinitcpio)
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block keyboard encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

# Root password
echo "Set the root password:"
passwd

# Grub configuration for encryption
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 cryptdevice=UUID='$(blkid -s UUID -o value "${DISK}3")':cryptlvm:allow-discards"/' /etc/default/grub

# Grub installation
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB

# Grub configuration file
grub-mkconfig -o /boot/grub/grub.cfg

# Enable network manager
systemctl enable NetworkManager

# Add a user
useradd -m -G wheel -s /bin/bash ${USER}
echo "Set password for user ${USER}:"
passwd ${USER}

# Sudo configuration (uncommenting the wheel group)
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "Installation complete. Type 'exit' to leave chroot, then reboot."
EOF

echo "Exiting chroot environment..."
echo "Installation script finished. Unmounting filesystems and rebooting in 5 seconds..."

# --- CLEAN UP ---
umount -R /mnt
swapoff -a
sleep 5
reboot
