#!/usr/bin/env bash
# Author: linux-gaming.ru
. "$(dirname $(readlink -f "$0"))/start.sh"

name_desktop="PortProton"
if check_flatpak ; then
	echo "[Desktop Entry]"	 					  		 > "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Name=${name_desktop}" 				 		 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Version=${install_ver}"						 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Exec=flatpak run ru.linux_gaming.PortProton"	 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Type=Application" 						 	 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Terminal=False" 						 		 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Categories=Game"	    				 		 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "StartupNotify=true" 	    			 		 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "MimeType=application/x-ms-dos-executable;application/x-wine-extension-msp;application/x-msi;application/x-msdos-program"  >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Path="${PORT_SCRIPTS_PATH}/""			 		 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Icon="${PORT_WINE_PATH}/data/img/w.png""   	 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	chmod u+x "${PORT_WINE_PATH}/${name_desktop}.desktop"
else
	echo "[Desktop Entry]"	 					  		 > "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Name=${name_desktop}" 				 		 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Version=${install_ver}"						 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Exec=env "${PORT_SCRIPTS_PATH}/start.sh %F""	 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Type=Application" 							 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Terminal=False" 								 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Categories=Game"	    						 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "StartupNotify=true" 	    					 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "MimeType=application/x-ms-dos-executable;application/x-wine-extension-msp;application/x-msi;application/x-msdos-program"  >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Path="${PORT_SCRIPTS_PATH}/""					 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Icon="${PORT_WINE_PATH}/data/img/w.png""   	 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	chmod u+x "${PORT_WINE_PATH}/${name_desktop}.desktop"
fi

if [[ ! -f /usr/bin/portproton ]] && ! check_flatpak ; then
	cp -f "${PORT_WINE_PATH}/${name_desktop}.desktop" ${HOME}/.local/share/applications/
fi

if grep "SteamOS" "/etc/os-release" &>/dev/null ; then
	cp -f "${PORT_WINE_PATH}/${name_desktop}.desktop" "$(xdg-user-dir DESKTOP)"
fi

update-desktop-database -q "${HOME}/.local/share/applications"

if ! check_flatpak ; then
	xdg-mime default PortProton.desktop "application/x-ms-dos-executable;application/x-wine-extension-msp;application/x-msi;application/x-msdos-program"
fi

name_desktop="readme"
echo "[Desktop Entry]"				 					> "${PORT_WINE_PATH}/${name_desktop}.desktop"
echo "Name=${name_desktop}"								>> "${PORT_WINE_PATH}/${name_desktop}.desktop"
echo "Version=${install_ver}"							>> "${PORT_WINE_PATH}/${name_desktop}.desktop"
echo "Type=Link"										>> "${PORT_WINE_PATH}/${name_desktop}.desktop"
echo "Icon="${PORT_WINE_PATH}/data/img/readme.png""		>> "${PORT_WINE_PATH}/${name_desktop}.desktop"
echo "URL=${urlg}" 										>> "${PORT_WINE_PATH}/${name_desktop}.desktop"
chmod u+x "${PORT_WINE_PATH}/${name_desktop}.desktop"

unset INSTALLING_PORT
if [[ "${PW_SILENT_INSTALL}" == 1 ]] ; then
	if [[ "${PW_AUTOPLAY}" == 1 ]] ; then
		if [[ -f "${HOME}/.local/share/applications/PortProton.desktop" ]] && [[ -f /usr/bin/portproton ]] ; then
			try_remove_file "${HOME}/.local/share/applications/PortProton.desktop"
		fi
		echo "Restarting PP after installing..."
		/usr/bin/env bash -c "${PORT_WINE_PATH}/data/scripts/start.sh" $@ &
		exit 0
	else
		echo "Installation completed successfully."
	fi
fi
