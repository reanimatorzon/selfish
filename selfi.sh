#!/bin/bash

### folder structure ###
mkdir -p $HOME/selfish
mkdir -p $HOME/selfish/downloads
mkdir -p $HOME/selfish/soft
mkdir -p $HOME/selfish/bin
###

### one-liners ###
silent() { "$@" > /dev/null 2>&1; }
missing() { if silent command -v $1; then false; else true; fi }
download() { wget $1 -O $HOME/selfish/downloads/$2; }
install_deb() { sudo apt-get -qq install -yf $HOME/selfish/downloads/$1; }
deb() { if missing $1; then download $2 $1.deb && install_deb $1.deb; fi }
targz() { if missing $1; then download $2 $1.tar.gz && tar xzf $HOME/selfish/downloads/$1.tar.gz -C $HOME/selfish/soft && ln -sf $( find $HOME/selfish/soft -name $1 ) $HOME/selfish/bin/$1; fi }
script() { if missing $1; then curl -s $2 | bash -s -- "${@:3}"; fi }
installer() { if missing $1; then download $2 $1.run && chmod +x $HOME/selfish/downloads/$1.run && sudo $HOME/selfish/downloads/$1.run; fi }
###

### make me sudo ###
if ! sudo -v; then
    echo "LOG: ROOT pwd required in order to grant 'sudo'."
    su -c "echo '$USER ALL=NOPASSWD: ALL' > /etc/sudoers.d/$USER"
fi
###

### update PATH ###
if ! grep "$HOME/selfish/bin" <<< $PATH > /dev/null; then
    sudo tee $HOME/.bash_profile > /dev/null <<< 'PATH="$HOME/selfish/bin:$PATH"'
    source $HOME/.bash_profile
fi
###

### apt ###
### sources ###
sudo tee /etc/apt/sources.list > /dev/null <<EOF
deb http://deb.debian.org/debian/ bullseye main contrib non-free
deb-src http://deb.debian.org/debian/ bullseye main non-free
deb http://security.debian.org/debian-security bullseye-security main contrib non-free
deb-src http://security.debian.org/debian-security bullseye-security main contrib non-free
EOF
### packages ###
sudo apt-get -qq update -y >/dev/null && sudo apt-get -qq upgrade -y >/dev/null
sudo apt-get -qq install -yf \
    nano curl zip terminator numlockx \
    git containerd \
    gcc make linux-headers-$( uname -r ) \
    build-essential linux-source bc kmod cpio flex libncurses5-dev libelf-dev libssl-dev
###

### other repos apps ###
deb google-chrome "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
#
silent source $HOME/.sdkman/bin/sdkman-init.sh
script sdk "https://get.sdkman.io"
#
script n "https://git.io/n-install" -y && source $HOME/.bashrc
#
installer nvidia-settings "https://ru.download.nvidia.com/XFree86/Linux-x86_64/460.39/NVIDIA-Linux-x86_64-460.39.run"
#
targz jetbrains-toolbox "https://download.jetbrains.com/toolbox/jetbrains-toolbox-1.20.7940.tar.gz"
###

### sdkman, jdk, sdks ###
sdki() { sdk install "$@" | grep -v -e 'is already installed' -e ''; }
sdki java 11.0.10-zulu
sdki gradle
###

### k3s ###
if missing k3s; then
    sudo curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable-agent" sh -
fi
###

### gnome settings ###
gshortcuts=()
shortcut() {
    gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom-$1/" name "$1"
    gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom-$1/" binding "$2"
    gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom-$1/" command "$3"
    gshortcuts+=("'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom-$1/'")
}
shortcut terminator '<Super>R' terminator
# ...
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "[$( IFS=$','; echo "${gshortcuts[@]}"; IFS=$' '; )]"
#
if [ $( gsettings get "org.gnome.desktop.interface" gtk-theme ) != "'Adwaita-dark'" ]; then
    gsettings set "org.gnome.desktop.interface" gtk-theme 'Adwaita-dark'
    gsettings set "org.gnome.desktop.interface" icon-theme 'Adwaita-dark'
    gsettings set "org.gnome.desktop.interface" cursor-theme 'Adwaita-dark'
    gsettings set "org.gnome.desktop.wm.preferences" theme 'Adwaita-dark'
    killall -3 gnome-shell
fi
###

### git ###
git config --global user.name "Vasiliy Bolgar"
git config --global user.email reanimatorzon@users.noreply.github.com
###

### ensure num lock on ###
# https://wiki.archlinux.org/index.php/Activating_numlock_on_bootup#GDM
echo 'if [ -x /usr/bin/numlockx ]; then /usr/bin/numlockx on; fi' > $HOME/.xprofile
###
