#!/bin/bash
# Author: PortWINE-Linux.ru
. "$(dirname $(readlink -f "$0"))/runlib"

try_remove_file "${PORT_WINE_TMP_PATH}/update_notifier"
try_remove_file "${PORT_WINE_TMP_PATH}/init_run_suc"

try_remove_file "${PORT_WINE_PATH}/data/port_on"
try_remove_file "${PORT_WINE_PATH}/data/dxvk.conf"
try_remove_file "${PORT_WINE_PATH}/settings.desktop"
try_remove_file "${PORT_WINE_PATH}/debug.desktop"
try_remove_file "${PORT_WINE_PATH}/restart.desktop"

try_remove_dir "${PORT_WINE_PATH}/data/pfx/dosdevices"
try_remove_dir "${PORT_WINE_PATH}/Settings"
try_remove_dir "${PORT_SCRIPTS_PATH}/vars"

create_new_dir "/home/${USER}/.local/share/applications"

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
cp -f "${PORT_WINE_PATH}/${name_desktop}.desktop" /home/${USER}/.local/share/applications/

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

for name_desktop in "reset"
do
	echo ""[Desktop Entry]"
	"Name=${name_desktop}"
	"Exec=env "${PORT_SCRIPTS_PATH}/${name_desktop}""
	"Type=Application"
	"Categories=Game"
	"StartupNotify=true"
	"Path="${PORT_SCRIPTS_PATH}/""
	"Icon="${PORT_WINE_PATH}/data/img/s.png""" > "${PORT_WINE_PATH}/${name_desktop}.desktop"
	chmod u+x "${PORT_WINE_PATH}/${name_desktop}.desktop"
done
chmod u+x "${PORT_SCRIPTS_PATH}/"*

if [ "${s_install}" = "1" ]; then
	echo "Installation completed successfully."
else
	`zenity --info --title "${inst_set_top}" --text "${inst_succ}" --no-wrap ` > /dev/null 2>&1  
	xdg-open "http://portwine-linux.ru/portwine-faq/" > /dev/null 2>&1 & exit 0
fi  

unset INSTALLING_PORT