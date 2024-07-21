echo -n "**** Installing paru ****"

git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si --noconfirm

echo -n "**** Installing nvidia drivers ****"
sudo pacman -S nvidia-lts nvidia-utils nvidia-settings linux-lts-headers
sudo pacman -Sy lib32-nvidia-utils

sudo sed -n "GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/&quiet splash nvidia-drm.modeset=1/" /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

sudo sed -n "MODULES.*/MODULES=(nvidia nvidia_uvm nvidia_modeset nvidia_drm)" /etc/mkinitcpio.conf
sudo mkinitcpio -P

mkdir Repos
mkdir WgetCurl
cd WgetCurl
wget https://raw.githubusercontent.com/korvahannu/arch-nvidia-drivers-installation-guide/main/nvidia.hook

sed -n "Target=nvidia/Target=nvidia-lts" nvidia.hook
sudo mv ./nvidia.hook /etc/pacman.d/hooks/

nvidia-xconfig