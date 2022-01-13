#!/bin/bash
# Author: PortWINE-Linux.ru
. "$(dirname $(readlink -f "$0"))/runlib"

if [ -z "${PW_AUTOPLAY}" ] ; then
	create_new_dir "${HOME}/.local/share/applications"
	name_desktop="PortProton"
	echo "[Desktop Entry]"	 					  > "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Name=${name_desktop}" 				 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Exec=env "${PORT_SCRIPTS_PATH}/start.sh %F""	 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Type=Application" 					 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Terminal=False" 						 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Categories=Game"	    				 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "StartupNotify=true" 	    			 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "MimeType=application/x-ms-dos-executable;application/x-wine-extension-msp;application/x-msi;application/x-msdos-program"  >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Path="${PORT_SCRIPTS_PATH}/""			 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Icon="${PORT_WINE_PATH}/data/img/w.png""   	 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	chmod u+x "${PORT_WINE_PATH}/${name_desktop}.desktop"
	cp -f "${PORT_WINE_PATH}/${name_desktop}.desktop" ${HOME}/.local/share/applications/

	update-desktop-database -q "${HOME}/.local/share/applications"
	xdg-mime default PortProton.desktop "application/x-ms-dos-executable;application/x-wine-extension-msp;application/x-msi;application/x-msdos-program"
fi
name_desktop="readme"
echo "[Desktop Entry]"					 > "${PORT_WINE_PATH}/${name_desktop}.desktop"
echo "Name=${name_desktop}"				>> "${PORT_WINE_PATH}/${name_desktop}.desktop"
echo "Version=1.0"					>> "${PORT_WINE_PATH}/${name_desktop}.desktop"
echo "Type=Link"					>> "${PORT_WINE_PATH}/${name_desktop}.desktop"
echo "Icon="${PORT_WINE_PATH}/data/img/readme.png""	>> "${PORT_WINE_PATH}/${name_desktop}.desktop"
echo "URL=${urlg}" >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
chmod u+x "${PORT_WINE_PATH}/${name_desktop}.desktop"

if [ "${PW_SILENT_INSTALL}" = "1" ] ; then
	if [ "${PW_AUTOPLAY}" = "1" ] ; then
		unset INSTALLING_PORT
		sh "$HOME/PortWINE/PortProton/data/scripts/start.sh" $@ & exit 0
	else
		echo "Installation completed successfully."
	fi
else
	`zenity --info --title "${inst_set_top}" --text "${inst_succ}" --no-wrap ` > /dev/null 2>&1
	xdg-open "http://portwine-linux.ru/portwine-faq/" > /dev/null 2>&1 & exit 0
fi
unset INSTALLING_PORT