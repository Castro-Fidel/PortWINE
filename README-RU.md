<div align="center">
  <img src="https://raw.githubusercontent.com/Castro-Fidel/PortProton_PKGBUILD/main/portproton.svg" width="64">
  <h1 align="center">PortProton</h1>
  <p align="center">Проект, призванный сделать запуск Windows-игр в Linux простым и удобным как для начинающих, так и для опытных пользователей.
Проект стремится сделать запуск игр (и другого программного обеспечения) максимально простым, но в то же время предоставляет гибкие настройки для опытных пользователей.</p>
</div>

# **Язык README**
**Русский** - [English](README.md)

## Внимание
**Официальный сайт проекта** с сентября 2022 года: https://linux-gaming.ru.  **Любой другой сайт - фальшивка!**

## Особенности

- Основан на версии WINE от Valve (Proton) и ее модификациях (Proton GE).
Включает набор скриптов, объединенных с самим wine-proton, контейнер Steam Runtime Sniper с добавлением портированных версий MANGOHUD (вывод полезной информации в окно игры: FPS, FrameTime, CPU, GPU и т.д.) и vkBasalt (улучшение графики в играх, очень хорош в связке с FSR, DLSS) + множество уже настроенных оптимизаций для максимальной производительности.

- Реализована автоматическая установка одним щелчком мыши (на вкладке АВТОУСТАНОВКА) популярных лаунчеров, таких как: WGC, Epic Games, Battle.net, Origin, EVE Online, RockStar, Ubisoft connect , League of Legends и многие другие.

- Для любителей консольных игр предлагается множество эмуляторов консолей (на вкладке ЭМУЛЯТОРЫ ): PPSSPP, Citra, Cemu, ePSXe, MAME и многие другие..

**ПОЖАЛУЙСТА, НЕ СООБЩАЙТЕ О НАЙДЕННЫХ ОШИБКАХ В WINEHQ ИЛИ ПРОГРАММНОМ ОБЕСПЕЧЕНИИ VALVE!**

## **Ссылка на исходный код версий wine используемых в PortProton:**

* WINE-PROTON: https://github.com/ValveSoftware/Proton

* WINE-PROTON-GE: https://github.com/GloriousEggroll/proton-ge-custom/

## Установка с помощью пакетов


* **Alt Linux**

`apt-get` :
```sh
su -

apt-get update && apt-get dist-upgrade -y

apt-get install portproton i586-{libvulkan1,libd3d,libGL,libgio,libnm,libnsl1,libnss,glibc-nss,glibc-pthread,libunwind,xorg-dri-swrast}

exit
```

`Вариант установки с помощью eepm`:
```sh
su -

epm full-upgrade

epm play portproton

exit
```

* **Ubuntu 20.04** (Kubuntu, Xubuntu, Lubuntu, и т.д.), **Linux Mint 20.x** :
[portproton_1.0-2_amd64.deb](https://github.com/Castro-Fidel/PortProton_dpkg/releases/download/portproton_1.0-2_amd64/portproton_1.0-2_amd64.deb)

* **Arch Linux** и производные (Manjaro, Garuda, и т.д.) :
[AUR](https://aur.archlinux.org/packages/portproton)

* **OpenSuse**:
[OBS](https://software.opensuse.org/download/package?package=portproton&project=home%3ABoria138%3APortProton)

* **ROSA Linux** устанавливается с помощью этой команды:

```sh
sudo urpmi portproton
```

* **Fedora 37+** and **Nobara**:

```sh
sudo dnf copr enable boria138/portproton

sudo dnf install portproton
```

## Универсальный (ручной) метод установки

**ВНИМАНИЕ** : при универсальном способе установки PortProton зависимости должны быть установлены вручную!

Нормальная установка:

```sh
wget -c "https://github.com/Castro-Fidel/PortWINE/raw/master/portwine_install_script/PortProton_1.0" && sh PortProton_1.0
```

Тихая установка (ENG):

```sh
wget -c "https://github.com/Castro-Fidel/PortWINE/raw/master/portwine_install_script/PortProton_1.0" && sh PortProton_1.0 -eng
```

Тихая установка (RUS):

```sh
wget -c "https://github.com/Castro-Fidel/PortWINE/raw/master/portwine_install_script/PortProton_1.0" && sh PortProton_1.0 -rus
```

## Зависимости

* **Пользователи карт NVIDIA**

Если у вас видеокарта от NVIDIA и установлен проприетарный драйвер, то необходимо проверить, установлена ли lib32-nvidia-utils (без нее ни одна 32-битная игра не будет работать)

* **Ubuntu / Linux Mint / Pop!_OS**

```sh
sudo dpkg --add-architecture i386

sudo add-apt-repository multiverse

sudo apt update

sudo apt upgrade

sudo apt install curl file libc6 libnss3 policykit-1 xz-utils zenity bubblewrap curl icoutils tar libvulkan1 libvulkan1:i386 wget zenity zstd cabextract xdg-utils openssl bc libgl1-mesa-glx libgl1-mesa-glx:i386
```

* **Arch Linux / Manjaro**

Сперва проверьте включён ли **multilib** репозиторий

```sh
/etc/pacman.conf
===================================
[multilib]
Include = /etc/pacman.d/mirrorlist
====================================
```

```sh
sudo pacman -Syu bash icoutils wget bubblewrap zstd cabextract bc tar openssl gamemode desktop-file-utils curl dbus freetype2 gdk-pixbuf2 ttf-font zenity gzip nss xorg-xrandr vulkan-driver vulkan-icd-loader lsof lib32-freetype2 lib32-libgl lib32-gcc-libs lib32-libx11 lib32-libxss lib32-alsa-plugins lib32-libgpg-error lib32-nss lib32-vulkan-driver lib32-vulkan-icd-loader lib32-gamemode lib32-openssl
```

Если у вас видеокарта от **NVIDIA**, обязательно проверьте, установлен ли пакет **lib32-nvidia-utils**.

```sh
sudo pacman -Syu lib32-nvidia-utils
```

* **Debian/Deepin**

```sh
sudo apt install software-properties-common -y

sudo apt-add-repository non-free

sudo dpkg --add-architecture i386

sudo apt update

sudo apt upgrade

sudo apt install bubblewrap curl gamemode icoutils tar wget zenity zstd libvulkan1 libvulkan1:i386 steam cabextract
```

* **openSUSE**

```sh
sudo zypper install curl icoutils wget zenity bubblewrap zstd cabextract tar steam zenity zenity-lang gamemoded libgamemode0 libgamemodeauto0
```

* **Fedora**

```sh
sudo dnf update

sudo dnf upgrade --refresh

sudo dnf install curl gamemode gamemode.i686 icoutils wget zenity bubblewrap zstd cabextract tar openssl mesa-dri-drivers.i686 mesa-vulkan-drivers mesa-vulkan-drivers.i686 vulkan-loader vulkan-loader.i686 nss.i686 alsa-lib.i686 mesa-libGL.i686 mesa-libEGL.i686 wmctrl ImageMagick
```

* **Alt Linux**

```sh
sudo apt-get update

sudo apt-get dist-upgrade -y

sudo apt-get install bubblewrap cabextract curl gamemode icoutils i586-libvulkan1 libvulkan1 steam vulkan-tools wget zenity zstd
```

* **ROSA DESKTOP FRESH R12**

```sh
sudo dnf update

sudo dnf upgrade --refresh

sudo dnf install sysvinit-tools curl libcurl4 icoutils wget zenity bubblewrap zstd cabextract tar libvulkan1 lib64vulkan1 vulkan.x86_64 vulkan.i686 vkd3d.x86_64 vkd3d.i686 coreutils file libc6 libnss3 xz bubblewrap xdg-utils openssl bc libgl1 lib64freetype2 libfreetype2 lib64txc-dxtn libtxc-dxtn lib64opencl1 libopencl1 libdrm2 libdrm2.i686 mesa.i686
```

* **RED OS**

```sh
sudo -E dnf install curl icoutils libcurl wget zenity bubblewrap zstd cabextract tar goverlay openssl steam
```

* **Solus 4.x**

```sh
sudo eopkg it curl file zenity bubblewrap curl icoutils tar wget zenity zstd cabextract xdg-utils openssl bc vulkan vulkan-32bit mesalib-32bit samba
```

## Контакты

<p>
    <a href="https://discord.gg/FTaheP99wE">
        <img src="https://img.shields.io/discord/378683352946835456?logo=discord"
            alt="chat on Discord"></a>
</p>
