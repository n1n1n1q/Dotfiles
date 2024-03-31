#!/bin/bash
if [ "$EUID" -eq 0 ]; then
    echo "Please run this script as a regular user, not as root."
    exit 1
fi

# update system
sudo pacman -Syu --noconfirm

# install yay
if ! command -v yay &> /dev/null; then
    echo "yay is not installed, installing yay"
    git clone https://aur.archlinux.org/yay.git $HOME/.local/yay
    cd $HOME/.local/yay
    makepkg -si
    echo "yay installed"
fi

nvidia_present=false
if lspci | grep -i nvidia &> /dev/null; then
    nvidia_present=true
fi

if [ "$nvidia_present" = true ]; then
    echo "NVIDIA GPU detected. Installing NVIDIA drivers."
    yay -S --noconfirm nvidia-dkms nvidia-settings nvidia-utils libva libva-nvidia-driver-git

    echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nvidia-nouveau.conf 
    echo "NVIDIA drivers installation complete."

    # Check if the Nvidia modules are already added in mkinitcpio.conf and add if not
    if grep -qE '^MODULES=.*nvidia. *nvidia_modeset.*nvidia_uvm.*nvidia_drm' /etc/mkinitcpio.conf; then
        echo "Nvidia modules already included in /etc/mkinitcpio.conf" 2>&1 | tee -a "$LOG"
    else
        sudo sed -Ei 's/^(MODULES=\([^\)]*)\)/\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf 2>&1 | tee -a "$LOG"
        echo "Nvidia modules added in /etc/mkinitcpio.conf"
    fi
    sudo mkinitcpio -P
    if [ -f "/etc/modprobe.d/blacklist.conf" ]; then
      echo "install nouveau /bin/true" | sudo tee -a "/etc/modprobe.d/blacklist.conf" 2>&1 
    else
      echo "install nouveau /bin/true" | sudo tee "/etc/modprobe.d/blacklist.conf" 2>&1
    fi
else
    echo "No NVIDIA GPU detected. No action taken."
fi

read -p "Do you want to install the rog packages? (y/n): " user_input

if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
    echo "Installing rog package..."
    yay -S --noconfirm asusctl supergfxd
    echo "ROG packages installation complete."
    printf " Activating ROG services...\n"
    sudo systemctl enable --now supergfxd 2>&1
else
    echo "User chose not to install 'rog' package. Exiting."
fi

echo "Install packages"
yay -S --noconfirm - < packages

chsh -s $(which zsh)

sudo systemctl enable --now bluetooth
sudo systemctl enable --now NetworkManager
sudo systemctl enable sddm

gsettings set org.gnome.desktop.interface gtk-theme Graphite-dark

cp .config $HOME/ -r
cp scripts $HOME/ -r
cp .zshrc $HOME/ -r
cp .vscode $HOME/ -r
sudo cp pacman.conf /etc/

echo "Manually add wrappedhp to PATH and wayland sessions if you have Nvidia card."
echo "You should reboot your system now"
esac
