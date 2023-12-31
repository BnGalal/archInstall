#!/bin/bash

sudo pacman -S lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings xfce4 xfce4-goodies gvfs dbus bluez bluez-utils blueman
sudo systemctl enable lightdm
sudo systemctl enable bluetooth.service
sudo pacman -S firefox vlc xarchiver xz unrar unzip p7zip

# below line to use bluetooth after login 1st time
# sudo usermod -aG lp $(whoami)
# blueman-manager
