#!/usr/bin/env zsh

echo "Arch Installer\n"

function base_install() {
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
    pacstrap /mnt base base-devel linux linux-firmware zsh gvim grub efibootmgr networkmanager sudo git openssh xorg-server xorg-xinit

    # Generate the filesystem tables using UUID's.
    genfstab -U /mnt >> /mnt/etc/fstab

    # Clone the arch installer into the new system.
    # Then execute the post-install configuration.
    git clone https://github.com/ashleighwilson/arch-installer /mnt/root/arch-installer
    chmod +x /mnt/root/arch-installer/arch-install.zsh
    arch-chroot /mnt /root/arch-installer/arch-install.zsh config
    umount -R /mnt
}

function base_configuration() {
    echo -n "Setting timezone.. "
    ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
    echo "done."

    echo -n "Setting hardware clock.. "
    hwclock --systohc
    echo "done."

    echo -n "Configuring /etc/locale.gen.. "
    sed -i "/en_GB.UTF-8 UTF-8/s/^#//g" /etc/locale.gen
    locale-gen
    echo "done."

    echo -n " - Configuring /etc/sudoers.. "
    sed -i "/\%wheel ALL=(ALL) ALL/s/^# //g" /etc/sudoers
    echo "done."

    echo -n "Configuring /etc/ssh/sshd_config.. "
    sed -i '/PermitRootLogin no/^#//g' /etc/ssh/sshd_config
    systemctl enable sshd
    echo "done."

    echo -n " - Creating /etc/locale.conf.. "
    echo "LANG=en_GB.UTF-8" > /etc/locale.conf
    echo "done."

    echo -n " - Creating /etc/vconsole.conf.. "
    echo "KEYMAP=qwerty/uk" > /etc/vconsole.conf
    echo "done."

    echo -n " - Updating hostname.. "
    echo "archlinux" > /etc/hostname
    echo "127.0.0.1 localhost ::1\nlocalhost 127.0.1.1 archlinux.local archlinux" > /etc/hosts
    echo "done."

    echo -n " - Updating root password.. "
    passwd

    echo -n " - Installing and configuring GRUB to /boot.. "
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
    echo "done."
    exit
}

# Change PermitRootLogin in sshd_config

case "$1" in
    install)
        base_install
        ;;
    config)
        base_configuration
        ;;
    *)
        echo "No argument give. Please use either 'install' or 'config'."
        ;;
esac
