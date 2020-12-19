#!/usr/bin/env zsh

echo "Arch Installer\n"

loadkeys qwerty/uk

# Assuming for now that we are in EFI boot mode.
# Assuming for now that network connection exists.

echo -n "Setting system clock.. "
timedatectl set-ntp true
timedatectl status
echo "done."

# Assuming disk is /dev/sda for now.
# Apply default partition tables.
sfdisk /dev/sda < ./parallels-desktop.layout

# Format the partitions
mkfs.ext4 /dev/sda3 
mkswap /dev/sda2 
mkfs.vfat -F32 /dev/sda1 

# Mount the partitions
mount /dev/sda3 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
swapon /dev/sda2 

# Install software
pacstrap /mnt base base-devel linux linux-firmware zsh gvim grub efibootmgr networkmanager sudo git openssh xorg-server xinit

