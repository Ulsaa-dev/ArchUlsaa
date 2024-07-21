timedatectl set-ntp true
loadkeys trq
pacman -S --noconfirm reflector grub gptfdisk glibc curl

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

echo -n "**** Setting up mirrors ****"
pacman -S --noconfirm archlinux-keyring #update keyrings to latest to prevent packages failing to install
pacman -S --noconfirm --needed pacman-contrib terminus-font
setfont ter-v22b

echo -n "**** Setting up parallel downloads ****"
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -S --noconfirm --needed reflector rsync grub
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
reflector --verbose --protocol https --score 35 --sort rate --country FR,PT,RO,GB --ipv4 --save /etc/pacman.d/mirrorlist


echo -n "**** Installing base system ****"
pacstrap /mnt base networkmanager linux linux-lts linux-firmware efibootmgr networkmanager vim base-devel sof-firmware
genfstab -L /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

echo -ne "----------------------------------------------------
                            Configuring
          ----------------------------------------------------"

echo -n "**** Setting up timezone ****"
ln -sf /usr/share/zoneinfo/Europe/Istanbul /etc/localtime
sed -i 's/^#tr_TR.UTF-8 UTF-8/tr_TR.UTF-8 UTF-8' /etc/locale.gen
locale-gen
timedatectl set-timezone Europe/Istanbul
timedatectl set-ntp 1
hwclock --systohc
echo 'LANG=EN' > /etc/locale.conf
echo 'KEYMAP=trq' > /etc/vconsole.conf
echo 'Archer' > /etc/hostname
passwd

echo -n "**** Adding user ****"
useradd -m -G wheel -s /bin/bash ulsaa
passwd ulsaa

echo -n "**** Setting up no password sudo rights ****"
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

echo -n "**** Installing microcode for AMD ****"
pacman -S amd-ucode --noconfirm

echo -n "**** Enabling NetworkManager ****"
systemctl enable NetworkManager

echo -n "**** Installing GRUB ****"
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg