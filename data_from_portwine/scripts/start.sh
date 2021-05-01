#!/bin/bash
# Author: PortWINE-Linux.ru
export pw_full_command_line=("$0" $*)
if [ -f "$1" ]; then
    export portwine_exe="$(readlink -f "$1")"
fi
. "$(dirname $(readlink -f "$0"))/runlib"

PORTWINE_LAUNCH () {
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
    else 
        PW_RUN explorer
    fi
}
PORTWINE_CREATE_SHORTCUT () {
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
        icotool -x --output="${PORTPROTON_PATH}/" "${PORTPROTON_EXE}.ico"
        cp "$(ls -S -1 "${PORTPROTON_EXE}"*".png"  | head -n 1)" "${PORTPROTON_EXE}.png"
        cp -f "${PORTPROTON_EXE}.png" "${PORT_WINE_PATH}/data/img/${PORTPROTON_NAME}.png"
        rm -f "${PORTPROTON_PATH}/"*.ico
        rm -f "${PORTPROTON_PATH}/"*.png
    fi
    if [ ! -z "${PORTWINE_DB}" ]; then
        PORTWINE_DB_FILE=`grep -il "\#${PORTWINE_DB}.exe" "${PORT_SCRIPTS_PATH}/portwine_db"/*`
        if [ ! -z "${PORTWINE_DB_FILE}" ] && [ -z "`cat "${PORTWINE_DB_FILE}"  | grep "export PW_VULKAN_USE=" | grep -v "#"`" ] ; then
            echo "export PW_VULKAN_USE=${PW_VULKAN_USE}" >> "${PORTWINE_DB_FILE}"
        elif [ -z "${PORTWINE_DB_FILE}" ]; then
            echo "#!/bin/bash"  > "${PORT_SCRIPTS_PATH}/portwine_db/$PORTWINE_DB"
            echo "#Author: "${USER}"" >> "${PORT_SCRIPTS_PATH}/portwine_db/$PORTWINE_DB"
            echo "#"${PORTWINE_DB}.exe"" >> "${PORT_SCRIPTS_PATH}/portwine_db/$PORTWINE_DB"
            echo "#Rating=1-5" >> "${PORT_SCRIPTS_PATH}/portwine_db/$PORTWINE_DB"
            echo "########################################################" >> "${PORT_SCRIPTS_PATH}/portwine_db/$PORTWINE_DB"
            echo "export PW_VULKAN_USE=${PW_VULKAN_USE}" >> "${PORT_SCRIPTS_PATH}/portwine_db/$PORTWINE_DB"
            cat "${PORT_SCRIPTS_PATH}/portwine_db/default" | grep "##" >> "${PORT_SCRIPTS_PATH}/portwine_db/$PORTWINE_DB"
        fi
    fi
name_desktop="${PORTPROTON_NAME}" 
    echo "[Desktop Entry]" > "${PORT_WINE_PATH}/${name_desktop}.desktop"
    echo "Name=${PORTPROTON_NAME}" >> "${PORT_WINE_PATH}/${name_desktop}.desktop" 
    if [ -z "${PW_CHECK_AUTOINSTAL}" ]
    then echo "Exec=env PW_GUI_DISABLED_CS=1 "\"${PORT_SCRIPTS_PATH}/start.sh\" \"${PORTPROTON_EXE}\" "" \
    >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
    else echo "Exec=env "\"${PORT_SCRIPTS_PATH}/start.sh\" \"${PORTPROTON_EXE}\" "" \
    >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
    fi
    echo "Type=Application" >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
    echo "Categories=Game" >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
    echo "StartupNotify=true" >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
    echo "Path="${PORT_SCRIPTS_PATH}/"" >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
    echo "Icon="${PORT_WINE_PATH}/data/img/${PORTPROTON_NAME}.png"" >> "${PORT_WINE_PATH}/${name_desktop}.desktop"
    chmod u+x "${PORT_WINE_PATH}/${name_desktop}.desktop"
    `zenity --question --title "${inst_set}." --text "${ss_done}" --no-wrap ` &> /dev/null  
    if [ $? -eq "0" ]; then
        cp -f "${PORT_WINE_PATH}/${name_desktop}.desktop" /home/${USER}/.local/share/applications/ 
    fi
    xdg-open "${PORT_WINE_PATH}" 2>1 >/dev/null &
}
PORTWINE_DEBUG () {
    KILL_PORTWINE 
    export PW_LOG=1
    export PW_WINEDBG_DISABLE=0
    START_PORTWINE
    echo "${port_deb1}" > "${PORT_WINE_PATH}/${portname}.log"
    echo "${port_deb2}" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "-----------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "PortWINE version:" >> "${PORT_WINE_PATH}/${portname}.log"
    read install_ver < "${PORT_WINE_TMP_PATH}/${portname}_ver"
    echo "${portname}-${install_ver}" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "----------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    if [ ! -z "${portwine_exe}" ] ; then 
        echo "Debug for programm:" >> "${PORT_WINE_PATH}/${portname}.log"
        echo "${portwine_exe}" >> "${PORT_WINE_PATH}/${portname}.log"
        echo "---------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    echo "GLIBC version:" >> "${PORT_WINE_PATH}/${portname}.log"
    echo `ldd --version | grep -m1 ldd | awk '{print $NF}'` >> "${PORT_WINE_PATH}/${portname}.log"
    echo "--------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    if [ "${PW_VULKAN_USE}" = "0" ]; then echo "PW_VULKAN_USE=${PW_VULKAN_USE} - DX9-11 to OpenGL" >> "${PORT_WINE_PATH}/${portname}.log"
    elif [ "${PW_VULKAN_USE}" = "dxvk" ]; then  echo "PW_VULKAN_USE=${PW_VULKAN_USE}_v."${PW_DXVK_VER}"" >> "${PORT_WINE_PATH}/${portname}.log"
    else echo "PW_VULKAN_USE=${PW_VULKAN_USE}_v."${PW_VKD3D_VER}"" >> "${PORT_WINE_PATH}/${portname}.log"
    fi
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
    if [ ! -x "`which gamemoderun 2>/dev/null`" ]
    then
        echo "---------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
        echo "!!!gamemod not found!!!"  >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    echo "--------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Version WINE in the Port" >> "${PORT_WINE_PATH}/${portname}.log"
    "$WINELOADER" --version 2>&1 | tee -a "${PORT_WINE_PATH}/${portname}.log"
    echo "-------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "winetricks.log:" >> "${PORT_WINE_PATH}/${portname}.log"
    cat "${WINEPREFIX}/winetricks.log" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    if [ ! -z "${PORTWINE_DB_FILE}" ]; then
        echo "Use ${PORTWINE_DB_FILE} db file:" >> "${PORT_WINE_PATH}/${portname}.log"
        cat "${PORTWINE_DB_FILE}" | sed '/##/d' | awk '{print $1 " " $2}' >> "${PORT_WINE_PATH}/${portname}.log"
    else
        echo "Use ${PORT_SCRIPTS_PATH}/portwine_db/default db file:" >> "${PORT_WINE_PATH}/${portname}.log"
        cat "${PORT_SCRIPTS_PATH}/portwine_db/default" | sed '/##/d' | awk '{print $1 " " $2}' >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    echo "-----------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Log WINE:" >> "${PORT_WINE_PATH}/${portname}.log"

    export DXVK_HUD="full"
    
    PORTWINE_LAUNCH & 
    sleep 1 && zenity --info --title "DEBUG" --text "${port_debug}" --no-wrap &> /dev/null && KILL_PORTWINE
    deb_text=$(cat "${PORT_WINE_PATH}/${portname}.log"  | awk '! a[$0]++') 
    echo "$deb_text" > "${PORT_WINE_PATH}/${portname}.log"
    "$pw_yad" --title="${portname}.log" --borders=10 --no-buttons --text-align=center \
    --text-info --show-uri --wrap --center --width=1200 --height=550 \
    --filename="${PORT_WINE_PATH}/${portname}.log"
}
PW_WINECFG () {
    START_PORTWINE
    PW_RUN winecfg
} 
PW_WINEFILE () {
    START_PORTWINE
    PW_RUN "explorer" 
}
PW_WINECMD () {
    export PW_USE_TERMINAL=1
    START_PORTWINE
    PW_RUN "cmd"
}
PW_WINEREG () {
    START_PORTWINE
    PW_RUN "regedit"
}
PW_WINETRICKS () {
    UPDATE_WINETRICKS
    export PW_USE_TERMINAL=1
    START_PORTWINE
    $PW_TERM "${PW_RUNTIME}" "${PORT_WINE_TMP_PATH}/winetricks" -q --force
}
PW_EDIT_DB () {
    xdg-open "${PORTWINE_DB_FILE}"
}
PW_AUTO_INSTALL_FROM_DB () {
    . "$PORT_SCRIPTS_PATH/autoinstall"
    $PW_YAD_SET
}


if [ ! -z "${portwine_exe}" ]; then
    if [ -z "${PW_GUI_DISABLED_CS}" ] || [ "${PW_GUI_DISABLED_CS}" = 0 ] || [ -z "${PW_VULKAN_USE}" ]; then
        if [ ! -z "${PORTWINE_DB_FILE}" ] && [ ! -z "${PW_VULKAN_USE}" ]; then
            if [ -z "${PW_COMMENT_DB}" ] ; then
                PW_COMMENT_DB="PortWINE database file for "\"${PORTWINE_DB}"\" was found."
            fi
            OUTPUT_START=$("${pw_yad}" --text-align=center --text "$PW_COMMENT_DB" --wrap-width=150 --borders=15 --form --center  \
            --title "$portname"  --image "$PW_GUI_ICON_PATH/port_proton.png" --separator=";" \
            --window-icon="$PW_GUI_ICON_PATH/port_proton.png" \
            --button='EDIT  DB'!!"${loc_edit_db} ${PORTWINE_DB}":118 \
            --button='CREATE SHORTCUT'!!"${loc_creat_shortcut}":100 \
            --button='DEBUG'!!"${loc_debug}":102 \
            --button='LAUNCH'!!"${loc_launch}":106 )  
            PW_YAD_SET="$?"
        elif [ ! -z "${PORTWINE_DB_FILE}" ] && [ -z "${PW_VULKAN_USE}" ]; then
            if [ -z "${PW_COMMENT_DB}" ] ; then
                PW_COMMENT_DB="PortWINE database file for "\"${PORTWINE_DB}"\" was found."
            fi
            OUTPUT_START=$("${pw_yad}" --text-align=center --text "$PW_COMMENT_DB" --wrap-width=150 --borders=15 --form --center  \
            --title "$portname"  --image "$PW_GUI_ICON_PATH/port_proton.png" --separator=";" \
            --window-icon="$PW_GUI_ICON_PATH/port_proton.png" \
            --field="Run with :CB" "DXVK (DX 9-11 to Vulkan)"\!"VKD3D (DX 12 to Vulkan)"\!"OPENGL " \
            --button='EDIT  DB'!!"${loc_edit_db} ${PORTWINE_DB}":118 \
            --button='CREATE SHORTCUT'!!"${loc_creat_shortcut}":100 \
            --button='DEBUG'!!"${loc_debug}":102 \
            --button='LAUNCH'!!"${loc_launch}":106 )  
            PW_YAD_SET="$?"
            export VULKAN_MOD=`echo "$OUTPUT_START" | awk '{print $1}'`
        else
            OUTPUT_START=$("${pw_yad}" --wrap-width=250 --borders=15 --form --center  \
            --title "$portname"  --image "$PW_GUI_ICON_PATH/port_proton.png" --separator=";" \
            --window-icon="$PW_GUI_ICON_PATH/port_proton.png" \
            --field="Run with :CB" "DXVK (DX 9-11 to Vulkan)"\!"VKD3D (DX 12 to Vulkan)"\!"OPENGL " \
            --button='CREATE SHORTCUT'!!"${loc_creat_shortcut}":100 \
            --button='DEBUG'!!"${loc_debug}":102 \
            --button='LAUNCH'!!"${loc_launch}":106 )  
            PW_YAD_SET="$?"
            export VULKAN_MOD=`echo "$OUTPUT_START" | awk '{print $1}'`
        fi
    elif [ ! -z "${PORTWINE_DB_FILE}" ]; then
        PORTWINE_LAUNCH
    else
        OUTPUT_START=$("${pw_yad}" --wrap-width=250 --borders=15 --form --center  \
        --title "$portname"  --image "$PW_GUI_ICON_PATH/port_proton.png" --separator=";" \
        --window-icon="$PW_GUI_ICON_PATH/port_proton.png" \
        --field="Run with :CB" "DXVK (DX 9-11 to Vulkan)"\!"VKD3D (DX 12 to Vulkan)"\!"OPENGL " \
        --button='CREATE SHORTCUT'!!"${loc_creat_shortcut}":100 \
        --button='DEBUG'!!"${loc_debug}":102 \
        --button='LAUNCH'!!"${loc_launch}":106 )
        PW_YAD_SET="$?"
        export VULKAN_MOD=`echo "$OUTPUT_START" | awk '{print $1}'`
    fi
else
    button_click () {
        [ ! -z "$1" ] && echo "$1" > "${PORT_WINE_TMP_PATH}/tmp_yad_form"
        if [ ! -z `pidof -s yad` ] ; then
            kill -s SIGUSR1 `pgrep -a yad | grep "\-\-key=${KEY} \-\-notebook" | awk '{print $1}'`
        fi 
    } 
    export -f button_click

    open_changelog () {
        "${pw_yad}" --title="Changelog" --borders=10 --no-buttons --text-align=center \
        --text-info --show-uri --wrap --center --width=1200 --height=550 \
        --filename="${PORT_WINE_PATH}/data/changelog"
    }
    export -f open_changelog

    export KEY=$RANDOM
    "${pw_yad}" --plug=$KEY --tabnum=2 --form --columns=2  --scroll \
    --field="   Wargaming Game Center"!"$PW_GUI_ICON_PATH/wgc.png":"BTN" '@bash -c "button_click PW_WGC"' \
    --field="   Battle.net Launcher"!"$PW_GUI_ICON_PATH/battle_net.png":"BTN" '@bash -c "button_click PW_BATTLE_NET"' \
    --field="   Epic Games Launcher"!"$PW_GUI_ICON_PATH/epicgames.png":"BTN" '@bash -c "button_click PW_EPIC"' \
    --field="   GoG Galaxy Launcher"!"$PW_GUI_ICON_PATH/gog.png":"BTN" '@bash -c "button_click PW_GOG"' \
    --field="   EVE Online Launcher"!"$PW_GUI_ICON_PATH/eve.png":"BTN" '@bash -c "button_click PW_EVE"' \
    --field="   Origin Launcher"!"$PW_GUI_ICON_PATH/origin.png":"BTN" '@bash -c "button_click PW_ORIGIN"' & \

    "${pw_yad}" --plug=${KEY} --tabnum=1 --columns=3 --form --separator=";" \
    --image "$PW_GUI_ICON_PATH/port_proton.png" \
    --field=":CB" "  DXVK (DX 9-11 to Vulkan)"\!"VKD3D (DX 12 to Vulkan)"\!"OPENGL " \
    --field=":LBL" "" \
    --field='DEBUG'!!"${loc_debug}":"BTN" '@bash -c "button_click DEBUG"' \
    --field='WINECFG'!!"${loc_winecfg}":"BTN" '@bash -c "button_click WINECFG"' \
    --field="${portname}-${install_ver} (${scripts_install_ver})"!!"":"FBTN" '@bash -c "open_changelog"' \
    --field=":LBL" "" \
    --field='WINEFILE'!!"${loc_winefile}":"BTN" '@bash -c "button_click WINEFILE"' \
    --field='WINECMD'!!"${loc_winecmd}":"BTN" '@bash -c "button_click WINECMD"' \
    --field="F.A.Q."!!"":"FBTN" '@bash -c "xdg-open https://portwine-linux.ru/portwine-faq/ ; button_click"' \
    --field=":LBL" "" \
    --field='WINEREG'!!"${loc_winereg}":"BTN" '@bash -c "button_click WINEREG"' \
    --field='WINETRICKS'!!"${loc_winetricks}":"BTN" '@bash -c "button_click WINETRICKS"' &> "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" & \

    "${pw_yad}" --key=$KEY --notebook --borders=10 --width=1000 --height=168 --no-buttons --text-align=center \
    --window-icon="$PW_GUI_ICON_PATH/port_proton.png" --title "$portname" --separator=";" \
    --tab-pos=right --tab="PORT_PROTON" --tab="AUTOINSTALL" --center 

    if [ -f "${PORT_WINE_TMP_PATH}/tmp_yad_form" ] ; then
        export PW_YAD_SET=`cat "${PORT_WINE_TMP_PATH}/tmp_yad_form" | head -n 1 | awk '{print $1}'`
        try_remove_file "${PORT_WINE_TMP_PATH}/tmp_yad_form"
    fi
    if [ -f "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" ] ; then
        export VULKAN_MOD=`cat "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" | grep \;\; | awk '{print $1}'`
        try_remove_file "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan"
    fi
fi
if [ ! -z "${VULKAN_MOD}" ] ; then
    if [ "${VULKAN_MOD}" = "DXVK" ] ; then export PW_VULKAN_USE="dxvk"
    elif [ "${VULKAN_MOD}" = "VKD3D" ]; then export PW_VULKAN_USE="vkd3d" 
    elif [ "${VULKAN_MOD}" = "OPENGL" ]; then export PW_VULKAN_USE="0" 
    fi
fi
case "$PW_YAD_SET" in
    1|252) exit 0 ;;
    100) PORTWINE_CREATE_SHORTCUT ;;
    DEBUG|102) PORTWINE_DEBUG ;;
    106) PORTWINE_LAUNCH ;;
    WINECFG|108) PW_WINECFG ;;
    WINEFILE|110) PW_WINEFILE ;;
    WINECMD|112) PW_WINECMD ;;
    WINEREG|114) PW_WINEREG ;;
    WINETRICKS|116) PW_WINETRICKS ;;
    118) PW_EDIT_DB ;;
    *) PW_AUTO_INSTALL_FROM_DB ;;
esac
########################################################################
STOP_PORTWINE
