# PortProton

The **official website of the project** since September 2022: https://linux-gaming.ru. **Any other site is fake!**

PortProton is a project designed to make it easy and convenient to run Windows games on Linux for both beginners and advanced users.
The project strives to make launching games (and other software) as simple as possible, but at the same time provides flexible settings for advanced users.

Based on the version of WINE from Valve (Proton) and its modifications (Proton GE). Includes a set of scripts combined with wine-proton itself, a Steam Runtime Sniper container with the addition of ported versions of MANGOHUD (output useful information over the game window: FPS, FrameTime, CPU, GPU, etc) and vkBasalt (improvement of graphics in games, very good in in conjunction with FSR, DLSS) + many already configured optimizations for maximum performance.

Implemented one-click auto-installation (in the AUTOINSTALL tab ) of popular launchers such as: WGC, Epic Games, Battle.net, Origin, EVE Online, RockStar, Ubisoft connect , League of Legends and many others.
For fans of console games, there are many console emulators to choose from (in the EMULATORS tab ): PPSSPP, Citra, Cemu, ePSXe, MAME and many others.

PLEASE DO NOT REPORT BUGS ENCOUNTERED WITH THIS AT WINEHQ OR VALVE SOFTWARE!

Wine sources used in PortWINE:  
WINE-PROTON: https://github.com/ValveSoftware/Proton  
WINE-PROTON-GE: https://github.com/GloriousEggroll/proton-ge-custom/

## Installation using packages

* **Ubuntu 20.04** (Kubuntu, Xubuntu, Lubuntu, etc.), **Linux Mint 20.x** : [portproton_1.0-2_amd64.deb](https://github.com/Castro-Fidel/PortProton_dpkg/releases/download/portproton_1.0-2_amd64/portproton_1.0-2_amd64.deb)
* **Arch Linux** and derivatives (Manjaro, Garuda, etc.) : [portproton-1.0-8-x86_64.pkg.tar.zst](https://github.com/Castro-Fidel/PortProton_PKGBUILD/releases/download/portproton-1.0-8-x86_64/portproton-1.0-8-x86_64.pkg.tar.zst)
* **ROSA Linux** (package in the official repository) is installed with the command:  `sudo urpmi portproton`

## Universal (manual) installation

**ATTENTION** : with the universal method of installing PortProton, dependencies must be installed manually!

Normal installation:

`wget -c "https://github.com/Castro-Fidel/PortWINE/raw/master/portwine_install_script/PortProton_1.0" && sh PortProton_1.0`

Silent installation (ENG):

`wget -c "https://github.com/Castro-Fidel/PortWINE/raw/master/portwine_install_script/PortProton_1.0" && sh PortProton_1.0 -eng`

Silent installation (RUS):

`wget -c "https://github.com/Castro-Fidel/PortWINE/raw/master/portwine_install_script/PortProton_1.0" && sh PortProton_1.0 -rus`

## Dependencies

* **NVIDIA graphics card users**

If you have a video card from NVIDIA and a proprietary driver is installed, then you need to check if lib32-nvidia-utils is installed (no 32-bit game will work without it)

* **Ubuntu / Linux Mint / Pop!_OS**

`sudo dpkg --add-architecture i386`

`sudo add-apt-repository multiverse`

`sudo apt update && sudo apt upgrade`

`sudo apt install curl file libc6 libnss3 policykit-1 xz-utils zenity bubblewrap curl icoutils tar libvulkan1 libvulkan1:i386 wget zenity zstd cabextract xdg-utils openssl bc libgl1-mesa-glx libgl1-mesa-glx:i386`

* **Arch Linux / Manjaro**

`sudo pacman -Syu bash icoutils wget bubblewrap zstd cabextract bc tar openssl gamemode desktop-file-utils curl dbus freetype2 gdk-pixbuf2 ttf-font zenity lsb-release nss xorg-xrandr vulkan-driver vulkan-icd-loader lsof lib32-freetype2 lib32-libgl lib32-gcc-libs lib32-libx11 lib32-libxss lib32-alsa-plugins lib32-libgpg-error lib32-nss lib32-vulkan-driver lib32-vulkan-icd-loader lib32-gamemode lib32-openssl`

If you have a video card from **NVIDIA** , be sure to check if the **lib32-nvidia-utils** package is installed

`sudo pacman -Syu lib32-nvidia-utils`

* **Debian/Deepin**

`sudo apt install software-properties-common -y && sudo apt-add-repository non-free && sudo dpkg --add-architecture i386 && sudo apt update && sudo apt upgrade`

`sudo apt install bubblewrap curl gamemode icoutils tar wget zenity zstd libvulkan1 libvulkan1:i386 steam cabextract`

* **openSUSE**

`sudo zypper in curl icoutils wget zenity bubblewrap zstd cabextract tar steam zenity zenity-lang gamemoded libgamemode0 libgamemodeauto0`

* **Fedora**

Enable Non-free repository:

`sudo dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm`

Install the required dependencies:

`sudo dnf update && sudo dnf upgrade --refresh && sudo dnf install curl gamemode icoutils libcurl  wget zenity bubblewrap zstd cabextract tar goverlay openssl steam`

* **Alt Linux**

`sudo apt-get update && sudo apt-get dist-upgrade -y`

`sudo apt-get install bubblewrap cabextract curl gamemode icoutils i586-libvulkan1 libvulkan1 steam vulkan-tools wget zenity zstd`

* **ROSA DESKTOP FRESH R12**

`sudo dnf update && sudo dnf upgrade --refresh && sudo dnf install sysvinit-tools curl libcurl4 icoutils wget zenity bubblewrap zstd cabextract tar libvulkan1 lib64vulkan1 vulkan.x86_64 vulkan.i686 vkd3d.x86_64 vkd3d.i686 coreutils file libc6 libnss3 xz bubblewrap xdg-utils openssl bc libgl1 lib64freetype2 libfreetype2 lib64txc-dxtn libtxc-dxtn lib64opencl1 libopencl1 libdrm2 libdrm2.i686 mesa.i686`

* **Solus 4.x**

`sudo eopkg it curl file zenity bubblewrap curl icoutils tar wget zenity zstd cabextract xdg-utils openssl bc vulkan vulkan-32bit mesalib-32bit samba`

## Contacts

You can join our [Discord](https://discord.gg/FTaheP99wE) server.
