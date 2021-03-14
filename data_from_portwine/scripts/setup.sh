#!/bin/bash
# Author: PortWINE-Linux.ru
. "$(dirname $(readlink -f "$0"))/runlib"

try_remove_file "${PORT_WINE_TMP_PATH}/update_notifier"
try_remove_file "${PORT_WINE_TMP_PATH}/init_run_suc"

try_remove_file "${PORT_WINE_PATH}/data/port_on" 
try_remove_file "${PORT_WINE_PATH}/data/dxvk.conf" 
try_remove_file "${PORT_WINE_PATH}/Create_shortcut_PP.desktop"
try_remove_file "${PORT_WINE_PATH}/Proton.desktop"
try_remove_file "${PORT_WINE_PATH}/settings.desktop"
try_remove_file "${PORT_WINE_PATH}/settings.desktop"
try_remove_file "${PORT_WINE_PATH}/debug.desktop"
try_remove_file "${PORT_WINE_PATH}/restart.desktop"

try_remove_dir "${PORT_WINE_PATH}/data/pfx/dosdevices" 
try_remove_dir "${PORT_WINE_PATH}/Settings"

create_new_dir "/home/${USER}/.local/share/applications"

if ! [ "${portname}" = "PortProton" ]; then
	name_desktop="${gamename}" 
	echo "[Desktop Entry]"	 				  > "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Name=${name_desktop}" 				 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Exec=env "${PORT_SCRIPTS_PATH}/start.sh""	 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Type=Application" 				 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Categories=Game"	    				 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "StartupNotify=true" 	    			 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Path="${PORT_SCRIPTS_PATH}/""		 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Icon="${PORT_WINE_PATH}/data/img/w.png""   	 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	chmod u+x "${PORT_WINE_PATH}/${name_desktop}.desktop"
	cp -f "${PORT_WINE_PATH}/${name_desktop}.desktop" /home/${USER}/.local/share/applications/ 
else
	name_desktop="PortProton" 
	echo "[Desktop Entry]"	 				  > "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Name=${name_desktop}" 				 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Exec=env "${PORT_SCRIPTS_PATH}/start.sh %U""	 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Type=Application" 				 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Categories=Game"	    				 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "StartupNotify=true" 	    			 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "MimeType=application/x-ms-dos-executable;application/x-wine-extension-msp;application/x-msi;application/x-msdos-program"  >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Path="${PORT_SCRIPTS_PATH}/""		 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	echo "Icon="${PORT_WINE_PATH}/data/img/w.png""   	 >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
	chmod u+x "${PORT_WINE_PATH}/${name_desktop}.desktop"
	cp -f "${PORT_WINE_PATH}/${name_desktop}.desktop" /home/${USER}/.local/share/applications/
fi

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

try_force_link_dir "${PORT_WINE_PATH}/data/pfx/drive_c/" "${PORT_WINE_PATH}/drive_c"
if [ -d "${PORT_WINE_PATH}/data/pfx/drive_c/users/Public" ] && [ ! -L "${PORT_WINE_PATH}/data/pfx/drive_c/users/Public" ]; then
	cp -fr "${PORT_WINE_PATH}/data/pfx/drive_c/users/Public"/* "${PORT_WINE_PATH}/data/pfx/drive_c/users/steamuser/"
	rm -fr "${PORT_WINE_PATH}/data/pfx/drive_c/users/Public"
elif [ -L "${PORT_WINE_PATH}/data/pfx/drive_c/users/Public" ]; then
	rm -fr "${PORT_WINE_PATH}/data/pfx/drive_c/users/Public"
fi
ln -s "${PORT_WINE_PATH}/data/pfx/drive_c/users/steamuser" "${PORT_WINE_PATH}/data/pfx/drive_c/users/Public"

if [ ! -d "${PORT_WINE_PATH}/data/pfx/drive_c/users/${USER}" ]; then
	ln -s "${PORT_WINE_PATH}/data/pfx/drive_c/users/steamuser" "${PORT_WINE_PATH}/data/pfx/drive_c/users/${USER}"
fi

if [ -e "${PORT_WINE_PATH}/data/pfx/system.reg" ] || [ -e "${PORT_WINE_PATH}/data/pfx/user.reg" ] || [ -e "${PORT_WINE_PATH}/data/pfx/userdef.reg" ]; then
	sed -i "s/xuser/${USER}/g" "${PORT_WINE_PATH}/data/pfx/"*.reg
	sed -i "s/vagrant/${USER}/g" "${PORT_WINE_PATH}/data/pfx/"*.reg
fi

if [ "${s_install}" = "1" ]; then
	echo "Installation completed successfully."
else
	`zenity --info --title "${inst_set_top}" --text "${inst_succ}" --no-wrap ` > /dev/null 2>&1  
	xdg-open "http://portwine-linux.ru/portwine-faq/" > /dev/null 2>&1 & exit 0
fi  
