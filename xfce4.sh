#!/bin/bash

sudo pacman -S lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings xfce4 xfce4-goodies gvfs dbus
sudo systemctl enable lightdm
sudo pacman -S firefox kazam vlc
