#!/usr/bin/env bash
# Author: linux-gaming.ru
. "$(dirname $(readlink -f "$0"))/start.sh"

if check_flatpak
then PW_EXEC="flatpak run ru.linux_gaming.PortProton"
else PW_EXEC="env ${PORT_SCRIPTS_PATH}/start.sh %F"
fi

echo "[Desktop Entry]"	 					  		 > "${PORT_WINE_PATH}/PortProton.desktop"
echo "Name=PortProton" 				 				 >> "${PORT_WINE_PATH}/PortProton.desktop"
echo "Version=${install_ver}"						 >> "${PORT_WINE_PATH}/PortProton.desktop"
echo "Exec=$PW_EXEC"	 							 >> "${PORT_WINE_PATH}/PortProton.desktop"
echo "Type=Application" 						 	 >> "${PORT_WINE_PATH}/PortProton.desktop"
echo "Terminal=False" 						 		 >> "${PORT_WINE_PATH}/PortProton.desktop"
echo "Categories=Game"	    				 		 >> "${PORT_WINE_PATH}/PortProton.desktop"
echo "StartupNotify=true" 	    			 		 >> "${PORT_WINE_PATH}/PortProton.desktop"
echo "MimeType=application/x-ms-dos-executable;application/x-wine-extension-msp;application/x-msi;application/x-msdos-program" >> "${PORT_WINE_PATH}/PortProton.desktop"
echo "Path="${PORT_SCRIPTS_PATH}/""			 		 >> "${PORT_WINE_PATH}/PortProton.desktop"
echo "Icon="${PORT_WINE_PATH}/data/img/w.png""   	 >> "${PORT_WINE_PATH}/PortProton.desktop"
chmod u+x "${PORT_WINE_PATH}/PortProton.desktop"

if [[ ! -f /usr/bin/portproton ]] && ! check_flatpak ; then
	cp -f "${PORT_WINE_PATH}/PortProton.desktop" ${HOME}/.local/share/applications/
fi

if grep "SteamOS" "/etc/os-release" &>/dev/null \
|| check_flatpak
then
	cp -f "${PORT_WINE_PATH}/PortProton.desktop" "$(xdg-user-dir DESKTOP)"
fi

if ! check_flatpak ; then
	update-desktop-database -q "${HOME}/.local/share/applications"
	xdg-mime default PortProton.desktop "application/x-ms-dos-executable;application/x-wine-extension-msp;application/x-msi;application/x-msdos-program"
fi

if [[ -f "${HOME}/.local/share/applications/PortProton.desktop" ]] && [[ -f /usr/bin/portproton ]] ; then
	try_remove_file "${HOME}/.local/share/applications/PortProton.desktop"
fi

unset INSTALLING_PORT

echo "Restarting PP after installing..."
export SKIP_CHECK_UPDATES=1
/usr/bin/env bash -c "${PORT_WINE_PATH}/data/scripts/start.sh" $@ &
exit 0
