#!/usr/bin/env bash
# Author: linux-gaming.ru
export INSTALLING_PORT=1
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

if check_flatpak \
&& [[ ! -f /usr/bin/portproton ]] \
&& [[ -f "${HOME}/.local/share/applications/PortProton.desktop" ]] ; then
	PORT_WINE_OLD_PATH="$(cat "${HOME}/.local/share/applications/PortProton.desktop" | grep "Exec=" | awk -F'env ' '{print $2}' | awk -F'/data/scripts/' '{print $1}')"
	if [[ -d "$PORT_WINE_OLD_PATH" ]] \
	&& yad_question "$FOUND_OLD_PP"
	then
		pw_start_progress_bar_block "$loc_gui_settings"

		try_remove_file "${HOME}/.local/share/applications/PortProton.desktop"
		try_remove_file "${PORT_WINE_OLD_PATH}"/PortProton.desktop
		try_remove_file "${PORT_WINE_OLD_PATH}"/readme.desktop

		try_remove_dir "${PORT_WINE_PATH}/data/dist"
		mv -f "${PORT_WINE_OLD_PATH}"/data/dist "${PORT_WINE_PATH}/data/"

		try_remove_dir "${PORT_WINE_PATH}/data/prefixes"
		mv -f "${PORT_WINE_OLD_PATH}"/data/prefixes "${PORT_WINE_PATH}/data/"

		try_remove_dir "${PORT_WINE_PATH}/data/tmp/mono"
		mv -f "${PORT_WINE_OLD_PATH}"/data/tmp/mono "${PORT_WINE_PATH}/data/tmp/"

		try_remove_dir "${PORT_WINE_PATH}/data/tmp/gecko"
		mv -f "${PORT_WINE_OLD_PATH}"/data/tmp/gecko "${PORT_WINE_PATH}/data/tmp/"

		cp -f "${PORT_WINE_OLD_PATH}"/data/img/*.png "${PORT_WINE_PATH}"/data/img/

		cp -f "${PORT_WINE_OLD_PATH}"/*.desktop "${PORT_WINE_PATH}"/

		sed -i "s|env \"${PORT_WINE_OLD_PATH}/data/scripts/start.sh\"|$PW_EXEC|g" "${PORT_WINE_PATH}"/*.desktop
		sed -i "s|${PORT_WINE_OLD_PATH}|${PORT_WINE_PATH}|g" "${PORT_WINE_PATH}"/*.desktop

		sed -i "s|env \"${PORT_WINE_OLD_PATH}/data/scripts/start.sh\"|$PW_EXEC|g" "${HOME}/.local/share/applications"/*.desktop
		sed -i "s|${PORT_WINE_OLD_PATH}|${PORT_WINE_PATH}|g" "${HOME}/.local/share/applications"/*.desktop

		sed -i "s|env \"${PORT_WINE_OLD_PATH}/data/scripts/start.sh\"|$PW_EXEC|g" "$(xdg-user-dir DESKTOP)"/*.desktop
		sed -i "s|${PORT_WINE_OLD_PATH}|${PORT_WINE_PATH}|g" "$(xdg-user-dir DESKTOP)"/*.desktop

		if [[ -d "${PORT_WINE_OLD_PATH}"/steam_scripts/ ]] ; then
			create_new_dir "${PORT_WINE_PATH}/steam_scripts/"
			cp -f "${PORT_WINE_OLD_PATH}"/steam_scripts/* "${PORT_WINE_PATH}"/steam_scripts/
			sed -i "s|\"${PORT_WINE_OLD_PATH}/data/scripts/start.sh\"|$PW_EXEC|g" "${PORT_WINE_PATH}"/steam_scripts/*

			for STUIDPATH in "${HOME}"/.local/share/Steam/userdata/*/ ; do
				SCPATH="${STUIDPATH}/config/shortcuts.vdf"
				if [[ -f "$SCPATH" ]]
				then sed -i "s|${PORT_WINE_OLD_PATH}|${PORT_WINE_PATH}|g" "$SCPATH"
				else break
				fi
			done
		fi
		pw_stop_progress_bar
		yad_info "${MOVED_OLD_PP} ${PORT_WINE_OLD_PATH}"
	fi
fi

unset INSTALLING_PORT

echo "Restarting PP after installing..."
export SKIP_CHECK_UPDATES=1
/usr/bin/env bash -c "${PORT_WINE_PATH}/data/scripts/start.sh" $@ &
exit 0
