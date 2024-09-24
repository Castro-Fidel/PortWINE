#!/usr/bin/env bash
# Author: linux-gaming.ru
# shellcheck disable=SC2317
export INSTALLING_PORT=1
# shellcheck source=./start.sh
source "$(dirname "$(readlink -f "$0")")/start.sh"

if check_flatpak
then PW_EXEC="flatpak run ru.linux_gaming.PortProton"
else PW_EXEC="env \"${PORT_SCRIPTS_PATH}/start.sh\" %F"
fi

cat << EOF > "${PORT_WINE_PATH}/PortProton.desktop"
[Desktop Entry]
Name=PortProton
Version=${install_ver}
Exec=$PW_EXEC
Type=Application
Terminal=False
Categories=Game
StartupNotify=true
MimeType=application/x-ms-dos-executable;application/x-wine-extension-msp;application/x-msi;application/x-msdos-program;text/win-bat;
Path=${PORT_SCRIPTS_PATH}
Icon=${PORT_WINE_PATH}/data/img/w.png
EOF
chmod u+x "${PORT_WINE_PATH}/PortProton.desktop"

if [[ ! -f /usr/bin/portproton ]] \
&& ! check_flatpak
then
	cp -f "${PORT_WINE_PATH}/PortProton.desktop" "${HOME}/.local/share/applications/"
fi

if grep "SteamOS" "/etc/os-release" &>/dev/null \
|| check_flatpak
then
	cp -f "${PORT_WINE_PATH}/PortProton.desktop" "$(xdg-user-dir DESKTOP)"
fi

if ! check_flatpak ; then
	update-desktop-database -q "${HOME}/.local/share/applications"
	xdg-mime default PortProton.desktop "application/x-ms-dos-executable;application/x-wine-extension-msp;application/x-msi;application/x-msdos-program;text/win-bat;"
fi

if [[ -f /usr/bin/portproton ]] \
&& [[ -f "${HOME}/.local/share/applications/PortProton.desktop" ]]
then
	try_remove_file "${HOME}/.local/share/applications/PortProton.desktop"
fi

if check_flatpak \
&& [[ ! -f /usr/bin/portproton ]] \
&& [[ -f "${HOME}/.local/share/applications/PortProton.desktop" ]] ; then
	PORT_WINE_OLD_PATH="$(grep "Exec=" "${HOME}/.local/share/applications/PortProton.desktop" | awk -F'env ' '{print $2}' | awk -F'/data/scripts/' '{print $1}')"
	if [[ -d "$PORT_WINE_OLD_PATH" ]] \
	&& yad_question "${translations[PortProton installed by script has been detected. Do you want to transfer all the data from it to the new flatpak version of PortProton?]}"
	then
		pw_start_progress_bar_block "${translations[Please wait...]}"

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
		yad_info "${translations[PortProton has been moved to flatpak. You can now remove the old directory:]} ${PORT_WINE_OLD_PATH}"
	fi
fi

unset INSTALLING_PORT

echo "Restarting PP after installing..."
export SKIP_CHECK_UPDATES=1
/usr/bin/env bash -c "${PORT_WINE_PATH}/data/scripts/start.sh" $@ &
exit 0
