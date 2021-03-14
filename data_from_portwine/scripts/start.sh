#!/bin/bash
# Author: PortWINE-Linux.ru
if [ -f "$1" ]; then
    export portwine_exe="$(readlink -f "$1")"
fi
. "$(dirname $(readlink -f "$0"))/runlib"
PW_SCRIPTS_UPDATE
########################################################################
PORTWINE_LAUNCH ()
{
KILL_PORTWINE
START_PORTWINE
PORTWINE_MSI=`basename "${portwine_exe}" | grep .msi`
PORTWINE_BAT=`basename "${portwine_exe}" | grep .bat`
if [ ! -z "${PW_VIRTUAL_DESKTOP}" ] && [ "${PW_VIRTUAL_DESKTOP}" == "1" ] ; then
    pw_screen_resolution=`xrandr --current | grep "*" | awk '{print $1;}' | head -1`
    PW_RUN explorer "/desktop=portwine,${pw_screen_resolution}" "$portwine_exe"
elif [ ! -z "${PORTWINE_MSI}" ]; then   
    echo "PORTWINE_MSI=${PORTWINE_MSI}"
    PW_RUN msiexec /i "$portwine_exe"
elif [ ! -z "${PORTWINE_BAT}" ]; then   
    echo "PORTWINE_BAT=${PORTWINE_BAT}"
    PW_RUN explorer "$portwine_exe" 
elif [ ! -z "${portwine_exe}" ]; then
    PW_RUN "$portwine_exe"
elif [ -z "${gamestart}" ]; then  
    PW_RUN explorer
else
    PW_RUN "${gamestart}"
fi
}
########################################################################
PORTWINE_CREATE_SHORTCUT ()
{
if [ ! -z "${portwine_exe}" ]; then
    PORTPROTON_EXE="${portwine_exe}"
else
    PORTPROTON_EXE=$(zenity --file-selection --file-filter=""*.exe" "*.bat"" \
    --title="${sc_path}" --filename="${PORT_WINE_PATH}/data/pfx/drive_c/")
    if [ $? -eq 1 ];then exit 1; fi
fi
PORTPROTON_NAME="$(basename "${PORTPROTON_EXE}" | sed s/".exe"/""/gi )"
PORTPROTON_PATH="$( cd "$( dirname "${PORTPROTON_EXE}" )" >/dev/null 2>&1 && pwd )" 
if [ -x "`which wrestool 2>/dev/null`" ]; then
    wrestool -x --output="${PORTPROTON_PATH}/" -t14 "${PORTPROTON_EXE}"
    cp "$(ls -S -1 "${PORTPROTON_EXE}"*".ico"  | head -n 1)" "${PORTPROTON_EXE}.ico"
    cp -f "${PORTPROTON_EXE}.ico" "${PORT_WINE_PATH}/data/img/${PORTPROTON_NAME}.ico"
    rm -f "${PORTPROTON_PATH}/"*.ico
fi
if [ $? -eq 1 ] ; then exit 1 ; fi
export PW_VULKAN_TO_DB=`cat "${PORT_WINE_TMP_PATH}/pw_vulkan"`
if [ ! -z "${PORTWINE_DB}" ]; then
    PORTWINE_DB_FILE=`grep -il "${PORTWINE_DB}" "${PORT_SCRIPTS_PATH}/portwine_db"/* | sed s/".exe"/""/gi`
    if [ ! -z "${PORTWINE_DB_FILE}" ] && [ -z "${PW_VULKAN_USE}" ]; then
        echo "export PW_VULKAN_USE=${PW_VULKAN_TO_DB}" >> "${PORTWINE_DB_FILE}"
    elif [ -z "${PORTWINE_DB_FILE}" ]; then
        echo "#!/bin/bash
#Author: "${USER}"
#"${PORTWINE_DB}.exe" 
#Rating=1-5
################################################
export PW_VULKAN_USE=${PW_VULKAN_TO_DB}" > "${PORT_SCRIPTS_PATH}/portwine_db/$PORTWINE_DB"
    fi
    cat "${PORT_SCRIPTS_PATH}/portwine_db/default" | grep "##" >> "${PORT_SCRIPTS_PATH}/portwine_db/$PORTWINE_DB"
fi
name_desktop="${PORTPROTON_NAME}" 
echo "[Desktop Entry]" > "${PORT_WINE_PATH}/${name_desktop}.desktop"
echo "Name=${PORTPROTON_NAME}" >> "${PORT_WINE_PATH}/${name_desktop}.desktop" 
echo "Exec=env PW_GUI_DISABLED_CS=1 "\"${PORT_SCRIPTS_PATH}/start.sh\" \"${PORTPROTON_EXE}\" "" \
>> "${PORT_WINE_PATH}/${name_desktop}.desktop"
echo "Type=Application" >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
echo "Categories=Game" >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
echo "StartupNotify=true" >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
echo "Path="${PORT_SCRIPTS_PATH}/"" >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
echo "Icon="${PORT_WINE_PATH}/data/img/${PORTPROTON_NAME}.ico"" >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
chmod u+x "${PORT_WINE_PATH}/${name_desktop}.desktop"
`zenity --question --title "${inst_set}." --text "${ss_done}" --no-wrap ` > /dev/null 2>&1  
if [ $? -eq "0" ]; then
	cp -f "${PORT_WINE_PATH}/${name_desktop}.desktop" /home/${USER}/.local/share/applications/ 
fi
xdg-open "${PORT_WINE_PATH}" 2>1 >/dev/null &
}
########################################################################
PORTWINE_DEBUG ()
{
KILL_PORTWINE
export PW_LOG=1
export PW_WINEDBG_DISABLE=0
export PW_XTERM="${WINELIB}/amd64/usr/bin/xterm -l -lf ${PORT_WINE_PATH}/${portname}.log.wine -geometry 159x37 -e"
START_PORTWINE
echo "${port_deb1}" > "${PORT_WINE_PATH}/${portname}.log"
echo "${port_deb2}" >> "${PORT_WINE_PATH}/${portname}.log"
echo "--------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
echo "GLIBC version:" >> "${PORT_WINE_PATH}/${portname}.log"
echo "echo $(ldd --version)" | grep ldd >> "${PORT_WINE_PATH}/${portname}.log"
echo "--------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
echo "PortWINE version:" >> "${PORT_WINE_PATH}/${portname}.log"
read install_ver < "${PORT_WINE_TMP_PATH}/${portname}_ver"
echo "${portname}-${install_ver}" >> "${PORT_WINE_PATH}/${portname}.log"
echo "-------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
echo "var_pw_vulkan = ${var_pw_vulkan}" >> "${PORT_WINE_PATH}/${portname}.log"
echo "------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
echo "Date and time of start debug for ${portname}" >> "${PORT_WINE_PATH}/${portname}.log"
date >> "${PORT_WINE_PATH}/${portname}.log"
echo "-----------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
echo "The installation path of the ${portname}:" >> "${PORT_WINE_PATH}/${portname}.log"
echo "$PORT_WINE_PATH" >> "${PORT_WINE_PATH}/${portname}.log"
echo "----------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
echo "Operating system" >> "${PORT_WINE_PATH}/${portname}.log"
lsb_release -d | sed s/Description/ОС/g >> "${PORT_WINE_PATH}/${portname}.log"
echo "--------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
echo "Desktop Environment" >> "${PORT_WINE_PATH}/${portname}.log"
echo "$DESKTOP_SESSION" >> "${PORT_WINE_PATH}/${portname}.log"
echo "${XDG_CURRENT_DESKTOP}" >> "${PORT_WINE_PATH}/${portname}.log"
echo "--------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
echo "Kernel" >> "${PORT_WINE_PATH}/${portname}.log"
uname -r >> "${PORT_WINE_PATH}/${portname}.log"
echo "-------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
echo "CPU" >> "${PORT_WINE_PATH}/${portname}.log"
cat /proc/cpuinfo | grep "model name" >> "${PORT_WINE_PATH}/${portname}.log"
echo "------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
echo "RAM" >> "${PORT_WINE_PATH}/${portname}.log"
free -m >> "${PORT_WINE_PATH}/${portname}.log"
echo "-----------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
echo "Graphic cards and drivers" >> "${PORT_WINE_PATH}/${portname}.log"
"${WINELIB}/amd64/usr/bin/glxinfo" -B >> "${PORT_WINE_PATH}/${portname}.log"
echo "----------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
echo "Vulkan info device name:" >> "${PORT_WINE_PATH}/${portname}.log"
"${WINELIB}/amd64/usr/bin/vulkaninfo" | grep deviceName >> "${PORT_WINE_PATH}/${portname}.log"
"${WINELIB}/amd64/usr/bin/vkcube" --c 50 
if [ $? -eq 0 ]; then 
	echo "Vulkan cube test passed successfully" >> "${PORT_WINE_PATH}/${portname}.log"
else
	echo "Vkcube test completed with error" >> "${PORT_WINE_PATH}/${portname}.log"
fi
echo "---------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
if [ ! -x "`which gamemoderun 2>/dev/null`" ]
then
	echo "!!!gamemod not found!!!"  >> "${PORT_WINE_PATH}/${portname}.log"
fi
echo "--------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
echo "Version WINE in the Port" >> "${PORT_WINE_PATH}/${portname}.log"
"$WINELOADER" --version 2>&1 | tee -a "${PORT_WINE_PATH}/${portname}.log"
echo "-------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
echo "log WINE:" >> "${PORT_WINE_PATH}/${portname}.log"

export DXVK_HUD="full"
export PW_XTERM="${WINELIB}/amd64/usr/bin/xterm -l -lf ${PORT_WINE_PATH}/${portname}.log.wine -geometry 159x37 -e"

try_remove_file "${PORT_WINE_PATH}/${portname}.log.wine"
if [ ! -z "${portwine_exe}" ]; then
    export PATH_TO_GAME="$( cd "$( dirname "${portwine_exe}" )" >/dev/null 2>&1 && pwd )"
    cd "$PATH_TO_GAME"
    if [ ! -z ${optirun_on} ]; then
        $PW_XTERM "${WINELOADER}" ${optirun_on} "$portwine_exe" ${LAUNCH_PARAMETERS} 2>&1 &
    else
        $PW_XTERM "${WINELOADER}" "$portwine_exe" ${LAUNCH_PARAMETERS} 2>&1 &
    fi
elif [ -z "${gamestart}" ]; then 
    if [ ! -z $optirun_on ]; then
        $PW_XTERM "${WINELOADER}" ${optirun_on} explorer 2>&1 &
    else
        $PW_XTERM "${WINELOADER}" explorer 2>&1 &
    fi
else
    export PATH_TO_GAME="$( cd "$( dirname "${gamestart}" )" >/dev/null 2>&1 && pwd )"
    cd "$PATH_TO_GAME" 
    if [ ! -z $optirun_on ]; then
        ${optirun_on} $PW_XTERM "${PW_RUNTIME}" "${WINELOADER}" "${gamestart}" ${LAUNCH_PARAMETERS} 2>&1 &
    else
        $PW_XTERM "${PW_RUNTIME}" "${WINELOADER}" "${gamestart}" ${LAUNCH_PARAMETERS} 2>&1 &
    fi
fi

zenity --info --title "DEBUG" --text "${port_debug}" --no-wrap && "${WINESERVER}" -k
STOP_PORTWINE | sszen
cat "${PORT_WINE_PATH}/${portname}.log.wine" >> "${PORT_WINE_PATH}/${portname}.log"
try_remove_file "${PORT_WINE_PATH}/${portname}.log.wine"
deb_text=$(cat "${PORT_WINE_PATH}/${portname}.log"  | awk '! a[$0]++') 
echo "$deb_text" > "${PORT_WINE_PATH}/${portname}.log"
echo "$deb_text" | zenity --text-info --editable --width=800 --height=600 --title="${portname}.log"
}
########################################################################
PW_WINECFG ()
{
START_PORTWINE
PW_RUN winecfg
} 
########################################################################
PW_WINEFILE ()
{
START_PORTWINE
PW_RUN "explorer" 
}
########################################################################
PW_WINECMD ()
{
export PW_USE_TERMINAL=1
START_PORTWINE
PW_RUN "cmd"
}
########################################################################
PW_WINEREG ()
{
START_PORTWINE
PW_RUN "regedit"
}
########################################################################
PW_WINETRICKS ()
{
UPDATE_WINETRICKS
export PW_USE_TERMINAL=1
START_PORTWINE
$PW_TERM "${PW_RUNTIME}" "${PORT_WINE_TMP_PATH}/winetricks" -q --force
}
########################################################################
if [ ! -z "${portwine_exe}" ]; then
    if [ -z "${PW_GUI_DISABLED_CS}" ] || [ "${PW_GUI_DISABLED_CS}" = 0 ] ; then
        if [ ! -z "${PORTWINE_DB_FILE}" ] && [ ! -z "${PW_VULKAN_USE}" ]; then
            if [ -z "${PW_COMMENT_DB}" ] ; then
                PW_COMMENT_DB="PortWINE database file for "\"${PORTWINE_DB}"\" was found."
            fi
            OUTPUT_START=$("${pw_yad}" --text-align=center --text "$PW_COMMENT_DB" --wrap-width=150 --borders=15 --form --center  \
            --title "$portname"  --image "$PW_GUI_ICON_PATH/port_proton.png" --separator=";" \
            --button='CREATE  SHORTCUT'!!"111":100 \
            --button='DEBUG'!!'проверка подсказки1':102 \
            --button='LAUNCH'!!'проверка подсказки3':106 )
            PW_YAD_SET="$?"
        else
            OUTPUT_START=$("${pw_yad}" --wrap-width=250 --borders=15 --form --center  \
            --title "$portname"  --image "$PW_GUI_ICON_PATH/port_proton.png" --separator=";" \
            --field="WINE:CB" "DXVK ${PW_WINE_VER_DXVK}"!"VKD3D ${PW_WINE_VER_VKD3D}"!"OPENGL ${PW_WINE_VER_DXVK}" \
            --button='CREATE  SHORTCUT'!!"111":100 \
            --button='DEBUG'!!'проверка подсказки1':102 \
            --button='LAUNCH'!!'проверка подсказки3':106 )
            PW_YAD_SET="$?"
        fi
    elif [ ! -z "${PORTWINE_DB_FILE}" ]; then
        PORTWINE_LAUNCH
    else
        OUTPUT_START=$("${pw_yad}" --wrap-width=250 --borders=15 --form --center  \
        --title "$portname"  --image "$PW_GUI_ICON_PATH/port_proton.png" --separator=";" \
        --field="WINE:CB" "DXVK ${PW_WINE_VER_DXVK}"!"VKD3D ${PW_WINE_VER_VKD3D}"!"OPENGL ${PW_WINE_VER_DXVK}" \
        --button='CREATE  SHORTCUT'!!"111":100 \
        --button='DEBUG'!!'проверка подсказки1':102 \
        --button='LAUNCH'!!'проверка подсказки3':106 )
        PW_YAD_SET="$?"
    fi
else
    OUTPUT_START=$("${pw_yad}" --wrap-width=250 --borders=15 --form --center  \
    --title "$portname"  --image "$PW_GUI_ICON_PATH/port_proton.png" --separator=";" \
    --field="WINE:CB" "DXVK ${PW_WINE_VER_DXVK}"!"VKD3D ${PW_WINE_VER_VKD3D}"!"OPENGL ${PW_WINE_VER_DXVK}" \
    --button='CREATE  SHORTCUT'!!"111":100 \
    --button='DEBUG'!!'проверка подсказки1':102 \
    --button='LAUNCH'!!'проверка подсказки3':106 \
    --button='WINECFG'!!"Run winecfg for $portname":108 \
    --button='WINEFILE'!!'проверка подсказки1':110 \
    --button='WINECMD'!!'проверка подсказки2':112 \
    --button='WINEREG'!!'проверка подсказки3':114 \
    --button='WINETRICKS'!!'проверка подсказки4 - бла бла бла бла бла ла ла ла =)':116 )
    PW_YAD_SET="$?"
fi
export VULKAN_MOD=$(echo $OUTPUT_START | awk 'BEGIN {FS=";" } { print $1 }')
if [ "${VULKAN_MOD}" = "DXVK ${PW_WINE_VER_DXVK}" ]; then
    echo "dxvk" > "${PORT_WINE_TMP_PATH}/pw_vulkan"
elif [ "${VULKAN_MOD}" = "VKD3D ${PW_WINE_VER_VKD3D}" ]; then
    echo "vkd3d" > "${PORT_WINE_TMP_PATH}/pw_vulkan"
else   
    echo "0" > "${PORT_WINE_TMP_PATH}/pw_vulkan"
fi
case "$PW_YAD_SET" in
    100) PORTWINE_CREATE_SHORTCUT ;;
    102) PORTWINE_DEBUG ;;
    106) PORTWINE_LAUNCH ;;
    108) PW_WINECFG ;;
    110) PW_WINEFILE ;;
    112) PW_WINECMD ;;
    114) PW_WINEREG ;;
    116) PW_WINETRICKS ;;
esac
########################################################################
STOP_PORTWINE
