#!/usr/bin/env bash
# Author: linux-gaming.ru
. "$(dirname $(readlink -f "$0"))/runlib"

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

if [ -z "${PW_AUTOPLAY}" ] ; then
	cp -f "${PORT_WINE_PATH}/${name_desktop}.desktop" ${HOME}/.local/share/applications/
fi

update-desktop-database -q "${HOME}/.local/share/applications"
xdg-mime default PortProton.desktop "application/x-ms-dos-executable;application/x-wine-extension-msp;application/x-msi;application/x-msdos-program"

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
		if [[ -f "${HOME}/.local/share/applications/PortProton.desktop" ]] ; then
			export PW_OLD_PATH=`cat "${HOME}/.local/share/applications/PortProton.desktop" | grep -w 'Path=' | sed -E 's/Path=//' | sed -E 's%\/PortProton\/data\/scripts\/%%g' `
			echo "PW_OLD_PATH=${PW_OLD_PATH}"
			try_remove_file "${HOME}/.local/share/applications/PortProton.desktop"
		fi
		if [[ ! -z "${PW_OLD_PATH}" ]]	; then 
			if [[ "${PW_OLD_PATH}"* == "${HOME}/PortWINE"* ]] & [[ -d "${HOME}/PortWINE" ]] ; then
				echo "Old path = ${HOME}/PortWINE"
				try_remove_dir "${XDG_DATA_HOME}/PortWINE"
				mv -f "${HOME}/PortWINE" "${XDG_DATA_HOME}"
			elif [[ "${PW_OLD_PATH}"* == "${PW_OLD_PATH}/PortWINE"* ]] & [[ -d "${PW_OLD_PATH}/PortWINE" ]] ; then
				try_remove_dir "${XDG_DATA_HOME}/PortWINE"
				ln -s "${PW_OLD_PATH}/PortWINE" "${XDG_DATA_HOME}/"
			elif [[ "${PW_OLD_PATH}"* == "${PW_OLD_PATH}/PortProton"* ]] & [[ -d "${PW_OLD_PATH}/PortProton" ]] ; then
				try_remove_dir "${XDG_DATA_HOME}/PortWINE"
				create_new_dir "${XDG_DATA_HOME}/PortWINE"
				ln -s "${PW_OLD_PATH}/PortProton" "${XDG_DATA_HOME}/PortWINE"
			fi
		fi
		ln -s "${XDG_DATA_HOME}/PortWINE" "${HOME}/"
		echo "Restarting PP after installing..."
		/usr/bin/env bash -c "${XDG_DATA_HOME}/PortWINE/PortProton/data/scripts/start.sh" $@ & 
		exit 0
	else
		echo "Installation completed successfully."
	fi
else
	`zenity --info --title "${inst_set_top}" --text "${inst_succ}" --no-wrap ` > /dev/null 2>&1
	xdg-open "https://linux-gaming.ru/portproton/" > /dev/null 2>&1 & exit 0
fi
unset INSTALLING_PORT