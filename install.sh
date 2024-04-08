timedatectl set-ntp true
loadkeys trq
pacman -S --noconfirm reflector grub gptfdisk glibc

echo -n "**** Setting up mirrors ****"
reflector -a 48 -c "TR" -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist

echo -n "**** Formatting the disk ****"
sgdisk -Z /dev/sda
sgdisk -a 2048 -o /dev/sda

sgdisk -n 1::+512M --typecode=1:ef00 --change-name=1:"BOOT" /dev/sda
sgdisk -n 2::+4G --typecode=2:8200 --change-name=2:"SWAP" /dev/sda
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:"SYSTEM" /dev/sda

echo -n "**** Create filesystems ****"
mkfs.vfat -F32 -n "BOOT" /dev/sda1
mkswap -L SWAP /dev/sda2
mkfs.ext4 -L SYSTEM /dev/sda3

echo -n "**** Mount filesystems ****"
mount /dev/sda3 /mnt
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi
swapon /dev/sda2

echo -n "**** Installing base system ****"
pacstrap /mnt base networkmanager linux linux-firmware efibootmgr networkmanager vim amd-ucode base-devel sof-firmware
genfstab /mnt > /mnt/etc/fstab

echo -ne "----------------------------------------------------
                            Configuring
          ----------------------------------------------------"

arch-chroot /mnt
ln -sf /usr/share/zoneinfo/Europe/Istanbul /etc/localtime
hwclock --systohc
sed -i '#tr_TR.UTF-8 UTF-8/tr_TR.UTF-8 UTF-8' /etc/locale.gen
locale-gen
echo 'LANG=EN' > /etc/locale.conf
echo 'KEYMAP=trq' > /etc/vconsole.conf
echo 'Archer' > /etc/hostname
passwd
useradd -m -G wheel -s /bin/bash ulsaa
passwd ulsaa
sed -i '# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL' /etc/sudoers

systemctl enable NetworkManager
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg