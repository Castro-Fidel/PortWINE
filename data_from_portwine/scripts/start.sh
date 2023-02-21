#!/usr/bin/env bash
# Author: linux-gaming.ru
# clear
export NO_AT_BRIDGE=1
export pw_full_command_line=("$0" $*)
if [ -f "$1" ]; then
    export portwine_exe="$(readlink -f "$1")"
fi
. "$(dirname $(readlink -f "$0"))/runlib"
kill_portwine
killall -9 yad_new 2>/dev/null
pw_stop_progress_bar

if [[ -f "/usr/bin/portproton" ]] && [[ -f "${HOME}/.local/share/applications/PortProton.desktop" ]] ; then
    /usr/bin/env bash "/usr/bin/portproton" "$@" & 
    exit 0
fi

if [[ "${XDG_SESSION_TYPE}" = "wayland" ]] && [[ ! -f "${PORT_WINE_TMP_PATH}/check_wayland" ]]; then
    zenity_info "$PW_WAYLAND_INFO"
    echo "1" > "${PORT_WINE_TMP_PATH}/check_wayland"
fi

if [[ -n $(basename "${portwine_exe}" | grep .ppack) ]] ; then
    export PW_ADD_TO_ARGS_IN_RUNTIME="--xterm"
    unset PW_SANDBOX_HOME_PATH
    pw_init_runtime
    export PW_PREFIX_NAME=$(basename "$1" | awk -F'.' '{print $1}')
    ${pw_runtime} env PATH="${PATH}" LD_LIBRARY_PATH="${PW_LD_LIBRARY_PATH}" unsquashfs -f -d "${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}" "$1" &
    sleep 10
    while true ; do
        if [[ -n $(pgrep -a xterm | grep ".ppack" | head -n 1 | awk '{print $1}') ]] ; then
            sleep 0.5
        else
            kill -TERM $(pgrep -a unsquashfs | grep ".ppack" | head -n 1 | awk '{print $1}')
            sleep 0.3
            if [[ -z "$(pgrep -a unsquashfs | grep ".ppack" | head -n 1 | awk '{print $1}')" ]]
            then break
            else sleep 0.3
            fi
        fi
    done
    if [[ -f "${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}/.create_shortcut" ]] ; then
        orig_IFS="$IFS"
        IFS=$'\n'
        for crfb in $(cat "${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}/.create_shortcut") ; do
            export portwine_exe="${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}/${crfb}"
            portwine_create_shortcut "${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}/${crfb}"
        done
        IFS="$orig_IFS"
    fi
    exit 0
fi

portwine_launch () {
    start_portwine
    PORTWINE_MSI=$(basename "${portwine_exe}" | grep .msi)
    PORTWINE_BAT=$(basename "${portwine_exe}" | grep .bat)
    if [[ -n "${PW_VIRTUAL_DESKTOP}" && "${PW_VIRTUAL_DESKTOP}" == "1" ]] ; then
        pw_screen_resolution=$(xrandr --current | grep "*" | awk '{print $1;}' | head -1)
        pw_run explorer "/desktop=PortProton,${pw_screen_resolution}" ${WINE_WIN_START} "$portwine_exe"
    elif [ -n "${PORTWINE_MSI}" ]; then
        pw_run msiexec /i "$portwine_exe"
    elif [[ -n "${PORTWINE_BAT}" || -n "${portwine_exe}" ]] ; then
        pw_run ${WINE_WIN_START} "$portwine_exe"
    else
        pw_run winefile
    fi
}

portwine_start_debug () {
    kill_portwine
    export PW_LOG=1
    export PW_WINEDBG_DISABLE=0
    echo "${port_deb1}" > "${PORT_WINE_PATH}/${portname}.log"
    echo "${port_deb2}" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "-------------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "PortWINE version:" >> "${PORT_WINE_PATH}/${portname}.log"
    read install_ver < "${PORT_WINE_TMP_PATH}/${portname}_ver"
    echo "${portname}-${install_ver}" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "------------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Scripts version:" >> "${PORT_WINE_PATH}/${portname}.log"
    cat "${PORT_WINE_TMP_PATH}/scripts_ver" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "-----------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    if [ "${PW_USE_RUNTIME}" = 0 ] ; then
        echo "RUNTIME is disabled" >> "${PORT_WINE_PATH}/${portname}.log"
    else
        echo "RUNTIME is enabled" >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    echo "----------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    if [ -n "${portwine_exe}" ] ; then
        echo "Debug for programm:" >> "${PORT_WINE_PATH}/${portname}.log"
        echo "${portwine_exe}" >> "${PORT_WINE_PATH}/${portname}.log"
        echo "---------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    echo "GLIBC version:" >> "${PORT_WINE_PATH}/${portname}.log"
    echo $(ldd --version | grep -m1 ldd | awk '{print $NF}') >> "${PORT_WINE_PATH}/${portname}.log"
    echo "--------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    if [[ "${PW_VULKAN_USE}" = "0" ]] ; then 
        echo "PW_VULKAN_USE=${PW_VULKAN_USE} - DX9-11 to ${loc_gui_open_gl}" >> "${PORT_WINE_PATH}/${portname}.log"
    elif [[ "${PW_VULKAN_USE}" = "3" ]] ; then 
        echo "PW_VULKAN_USE=${PW_VULKAN_USE} - native DX9 on MESA drivers" >> "${PORT_WINE_PATH}/${portname}.log"
    else 
        echo "PW_VULKAN_USE=${PW_VULKAN_USE}" >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    echo "--------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Version WINE in the Port:" >> "${PORT_WINE_PATH}/${portname}.log"
    print_var PW_WINE_USE >> "${PORT_WINE_PATH}/${portname}.log"
    [ -f "${WINEDIR}/version" ] && cat "${WINEDIR}/version" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Date and time of start debug for ${portname}:" >> "${PORT_WINE_PATH}/${portname}.log"
    date >> "${PORT_WINE_PATH}/${portname}.log"
    echo "-----------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "The installation path of the ${portname}:" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "$PORT_WINE_PATH" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "----------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Operating system" >> "${PORT_WINE_PATH}/${portname}.log"
    lsb_release -d | sed s/Description/ОС/g >> "${PORT_WINE_PATH}/${portname}.log"
    echo "--------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Desktop environment:" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Desktop session: ${DESKTOP_SESSION}" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Current desktop: ${XDG_CURRENT_DESKTOP}" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Session type: ${XDG_SESSION_TYPE}" >> "${PORT_WINE_PATH}/${portname}.log"
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
    echo "Graphic cards and drivers:" >> "${PORT_WINE_PATH}/${portname}.log"
    echo 'lspci -k | grep -EA3 VGA|3D|Display:' >> "${PORT_WINE_PATH}/${portname}.log"
    echo $(lspci -k | grep -EA3 'VGA|3D|Display') >> "${PORT_WINE_PATH}/${portname}.log"
    [[ `which glxinfo` ]] && glxinfo -B >> "${PORT_WINE_PATH}/${portname}.log"
    echo " " >> "${PORT_WINE_PATH}/${portname}.log"
    echo "inxi -G:" >> "${PORT_WINE_PATH}/${portname}.log"
    "${PW_WINELIB}/portable/bin/inxi" -G >> "${PORT_WINE_PATH}/${portname}.log"
    echo "----------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Vulkan info device name:" >> "${PORT_WINE_PATH}/${portname}.log"
    [[ `which vulkaninfo` ]] && vulkaninfo | grep deviceName >> "${PORT_WINE_PATH}/${portname}.log"
    "${PW_WINELIB}/portable/bin/vkcube" --c 50
    if [ $? -eq 0 ]; then
        echo "Vulkan cube test passed successfully" >> "${PORT_WINE_PATH}/${portname}.log"
    else
        echo "Vkcube test completed with error" >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    if [ ! -x "$(which gamemoderun 2>/dev/null)" ]
    then
        echo "---------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
        echo "!!!gamemod not found!!!"  >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    echo "-------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    if [[ "${PW_USE_D3D_EXTRAS}" != 1 ]]
    then echo "D3D_EXTRAS - disabled" >> "${PORT_WINE_PATH}/${portname}.log"
    else echo "D3D_EXTRAS - enabled" >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    echo "------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "winetricks.log:" >> "${PORT_WINE_PATH}/${portname}.log"
    cat "${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}/winetricks.log" | sed -e /"^d3dcomp*"/d -e /"^d3dx*"/d >> "${PORT_WINE_PATH}/${portname}.log"
    echo "-----------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    if [ -n "${PORTWINE_DB_FILE}" ]; then
        echo "Use ${PORTWINE_DB_FILE} db file:" >> "${PORT_WINE_PATH}/${portname}.log"
        cat "${PORTWINE_DB_FILE}" | sed '/##/d' >> "${PORT_WINE_PATH}/${portname}.log"
    else
        echo "Use ${PORT_SCRIPTS_PATH}/portwine_db/default db file:" >> "${PORT_WINE_PATH}/${portname}.log"
        cat "${PORT_SCRIPTS_PATH}/portwine_db/default" | sed '/##/d' >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    echo "----------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    if [ -f "${USER_CONF}" ]; then
        cat "${USER_CONF}" | sed '/bash/d' >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    echo "---------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"

    export DXVK_HUD="full"

    portwine_launch &
    sleep 3
    pw_stop_progress_bar_cover
    unset PW_TIMER
    while read -r line || [[ -n $(pgrep -a yad | grep "yad_new --text-info --tail --button="STOP":0 --title="DEBUG"" | awk '{print $1}') ]] ; do
            sleep 0.005
            if [[ -n "${line}" ]] && [[ -z "$(echo "${line}" | grep -i "gstreamer")" ]] \
                                    && [[ -z "$(echo "${line}" | grep -i "kerberos")" ]] \
                                    && [[ -z "$(echo "${line}" | grep -i "ntlm")" ]]
            then
                echo "# ${line}"
            fi
            if [[ "${PW_TIMER}" != 1 ]] ; then
                sleep 3
                PW_TIMER=1
            fi
    done < "${PORT_WINE_PATH}/${portname}.log" | "${pw_yad_new}" --text-info --tail --button="STOP":0 --title="DEBUG" \
    --skip-taskbar --center --width=800 --height=400 --text "${port_debug}" &&
    kill_portwine
#    sleep 1 && zenity --info --title "DEBUG" --text "${port_debug}" --no-wrap &> /dev/null && kill_portwine
    sed -i '/.fx$/d' "${PORT_WINE_PATH}/${portname}.log"
    sed -i '/GStreamer/d' "${PORT_WINE_PATH}/${portname}.log"
    sed -i '/kerberos/d' "${PORT_WINE_PATH}/${portname}.log"
    sed -i '/ntlm/d' "${PORT_WINE_PATH}/${portname}.log"
    sed -i '/HACK_does_openvr_work/d' "${PORT_WINE_PATH}/${portname}.log"
    sed -i '/Uploading is disabled/d' "${PORT_WINE_PATH}/${portname}.log"
    deb_text=$(cat "${PORT_WINE_PATH}/${portname}.log"  | awk '! a[$0]++') 
    echo "$deb_text" > "${PORT_WINE_PATH}/${portname}.log"
    "$pw_yad" --title="${portname}.log" --borders=7 --no-buttons --text-align=center \
    --text-info --show-uri --wrap --center --width=1200 --height=550  --uri-color=red \
    --filename="${PORT_WINE_PATH}/${portname}.log"
    stop_portwine
}

pw_winecfg () {
    start_portwine
    pw_run winecfg
}

pw_winefile () {
    start_portwine
    pw_run winefile
}

pw_winecmd () {
    export PW_USE_TERMINAL=1
    start_portwine
    cd "${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}/drive_c"
    ${pw_runtime} env LD_LIBRARY_PATH="${PW_LD_LIBRARY_PATH}" xterm -e "${WINELOADER}" cmd
    stop_portwine
}

pw_winereg () {
    start_portwine
    pw_run regedit
}

pw_prefix_manager () {
    update_winetricks
    start_portwine
    if [ ! -f "${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}/winetricks.log" ] ; then
        touch "${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}/winetricks.log"
    fi

    pw_start_progress_bar_block "Starting prefix manager..."
    "${PORT_WINE_TMP_PATH}/winetricks" dlls list | awk -F'(' '{print $1}' 1> "${PORT_WINE_TMP_PATH}/dll_list"
    "${PORT_WINE_TMP_PATH}/winetricks" fonts list | awk -F'(' '{print $1}' 1> "${PORT_WINE_TMP_PATH}/fonts_list"
    "${PORT_WINE_TMP_PATH}/winetricks" settings list | awk -F'(' '{print $1}' 1> "${PORT_WINE_TMP_PATH}/settings_list"
    pw_stop_progress_bar

    gui_prefix_manager () {
        pw_start_progress_bar_block "Starting prefix manager..."
        unset SET_FROM_PFX_MANAGER_TMP SET_FROM_PFX_MANAGER
        old_IFS=$IFS
        IFS=$'\n'
        try_remove_file  "${PORT_WINE_TMP_PATH}/dll_list_tmp"
        while read PW_BOOL_IN_DLL_LIST ; do
            if [[ -z $(echo "${PW_BOOL_IN_DLL_LIST}" | grep -E 'd3d|directx9|dont_use|dxvk|vkd3d|galliumnine|faudio1') ]] ; then
                if grep "^$(echo ${PW_BOOL_IN_DLL_LIST} | awk '{print $1}')$" "${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}/winetricks.log" ; then
                    echo -e "true\n$(echo ${PW_BOOL_IN_DLL_LIST} | awk '{print $1}')\n`echo ${PW_BOOL_IN_DLL_LIST} | awk '{ $1 = ""; print substr($0, 2) }'`" >> "${PORT_WINE_TMP_PATH}/dll_list_tmp"
                else
                    echo -e "false\n`echo "${PW_BOOL_IN_DLL_LIST}" | awk '{print $1}'`\n`echo ${PW_BOOL_IN_DLL_LIST} | awk '{ $1 = ""; print substr($0, 2) }'`" >> "${PORT_WINE_TMP_PATH}/dll_list_tmp"
                fi
            fi
        done < "${PORT_WINE_TMP_PATH}/dll_list"
        try_remove_file  "${PORT_WINE_TMP_PATH}/fonts_list_tmp"
        while read PW_BOOL_IN_FONTS_LIST ; do
            if [[ -z $(echo "${PW_BOOL_IN_FONTS_LIST}" | grep -E 'dont_use') ]] ; then
                if grep "^$(echo "${PW_BOOL_IN_FONTS_LIST}" | awk '{print $1}')$" "${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}/winetricks.log" ; then
                    echo -e "true\n$(echo "${PW_BOOL_IN_FONTS_LIST}" | awk '{print $1}')\n$(echo "${PW_BOOL_IN_FONTS_LIST}" | awk '{ $1 = ""; print substr($0, 2) }')" >> "${PORT_WINE_TMP_PATH}/fonts_list_tmp"
                else
                    echo -e "false\n$(echo "${PW_BOOL_IN_FONTS_LIST}" | awk '{print $1}')\n$(echo "${PW_BOOL_IN_FONTS_LIST}" | awk '{ $1 = ""; print substr($0, 2) }')" >> "${PORT_WINE_TMP_PATH}/fonts_list_tmp"
                fi
            fi
        done < "${PORT_WINE_TMP_PATH}/fonts_list"
        try_remove_file  "${PORT_WINE_TMP_PATH}/settings_list_tmp"
        while read PW_BOOL_IN_FONTS_LIST ; do
            if [[ -z $(echo "${PW_BOOL_IN_FONTS_LIST}" | grep -E 'vista|alldlls|autostart_|bad|good|win|videomemory|vd=|isolate_home') ]] ; then
                if grep "^$(echo "${PW_BOOL_IN_FONTS_LIST}" | awk '{print $1}')$" "${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}/winetricks.log" ; then
                    echo -e "true\n$(echo "${PW_BOOL_IN_FONTS_LIST}" | awk '{print $1}')\n$(echo "${PW_BOOL_IN_FONTS_LIST}" | awk '{ $1 = ""; print substr($0, 2) }')" >> "${PORT_WINE_TMP_PATH}/settings_list_tmp"
                else
                    echo -e "false\n$(echo "${PW_BOOL_IN_FONTS_LIST}" | awk '{print $1}')\n$(echo "${PW_BOOL_IN_FONTS_LIST}" | awk '{ $1 = ""; print substr($0, 2) }')" >> "${PORT_WINE_TMP_PATH}/settings_list_tmp"
                fi
            fi
        done < "${PORT_WINE_TMP_PATH}/settings_list"
        pw_stop_progress_bar

        KEY_EDIT_MANAGER_GUI=$RANDOM
        "${pw_yad_new}" --plug=$KEY_EDIT_MANAGER_GUI --tabnum=1 --list --checklist \
        --text="Select components to install in prefix: <b>\"${PW_PREFIX_NAME}\"</b>, using wine: <b>\"${PW_WINE_USE}\"</b>" \
        --column=set --column=dll --column=info < "${PORT_WINE_TMP_PATH}/dll_list_tmp" 1>> "${PORT_WINE_TMP_PATH}/to_winetricks" &

        "${pw_yad_new}" --plug=$KEY_EDIT_MANAGER_GUI --tabnum=2 --list --checklist \
        --text="Select fonts to install in prefix: <b>\"${PW_PREFIX_NAME}\"</b>, using wine: <b>\"${PW_WINE_USE}\"</b>" \
        --column=set --column=dll --column=info < "${PORT_WINE_TMP_PATH}/fonts_list_tmp" 1>> "${PORT_WINE_TMP_PATH}/to_winetricks" &

        "${pw_yad_new}" --plug=$KEY_EDIT_MANAGER_GUI --tabnum=3 --list --checklist \
        --text="Change config for prefix: <b>\"${PW_PREFIX_NAME}\"</b>" \
        --column=set --column=dll --column=info < "${PORT_WINE_TMP_PATH}/settings_list_tmp" 1>> "${PORT_WINE_TMP_PATH}/to_winetricks" &

        "${pw_yad_new}" --key=$KEY_EDIT_MANAGER_GUI --notebook --borders=5 --width=700 --height=600 --center \
        --window-icon="$PW_GUI_ICON_PATH/port_proton.png" --title "PREFIX MANAGER..." --tab-pos=bottom --tab="DLL" --tab="FONTS" --tab="SETTINGS"
        YAD_STATUS="$?"
        if [[ "$YAD_STATUS" == "1" || "$YAD_STATUS" == "252" ]] ; then
            stop_portwine
            exit 0
        fi 
        try_remove_file  "${PORT_WINE_TMP_PATH}/dll_list_tmp"
        try_remove_file  "${PORT_WINE_TMP_PATH}/fonts_list_tmp"
        try_remove_file  "${PORT_WINE_TMP_PATH}/settings_list_tmp"

        for STPFXMNG in $(cat "${PORT_WINE_TMP_PATH}/to_winetricks") ; do
            grep $(echo ${STPFXMNG} | awk -F'|' '{print $2}') "${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}/winetricks.log" &>/dev/null
            if [ "$?" == "1" ] ; then
                [[ -n "${STPFXMNG}" ]] && SET_FROM_PFX_MANAGER+="$(echo "${STPFXMNG}" | awk -F'|' '{print $2}') "
            fi
        done
        IFS=${old_IFS}
        try_remove_file  "${PORT_WINE_TMP_PATH}/to_winetricks"

        if [[ -n ${SET_FROM_PFX_MANAGER} ]] ; then
            export PW_ADD_TO_ARGS_IN_RUNTIME="--xterm"
            pw_init_runtime
            ${pw_runtime} env PATH="${PATH}" LD_LIBRARY_PATH="${PW_LD_LIBRARY_PATH}" "${PORT_WINE_TMP_PATH}/winetricks" -q -r -f ${SET_FROM_PFX_MANAGER}
            gui_prefix_manager
        else
            print_info "Nothing to do. Restarting PortProton..."
            stop_portwine &
            /usr/bin/env bash -c ${pw_full_command_line[*]} 
        fi
    }
    gui_prefix_manager
}

pw_winetricks () {
    update_winetricks
    export PW_USE_TERMINAL=1
    start_portwine
    pw_stop_progress_bar
    echo "WINETRICKS..." > "${PORT_WINE_TMP_PATH}/update_pfx_log"
    unset PW_TIMER
    while read -r line || [[ -n $(pgrep -a yad | grep "yad_new --text-info --tail --no-buttons --title="WINETRICKS"" | awk '{print $1}') ]] ; do
            sleep 0.005
            if [[ -n "${line}" ]] && [[ -z "$(echo "${line}" | grep -i "gstreamer")" ]] \
                                    && [[ -z "$(echo "${line}" | grep -i "kerberos")" ]] \
                                    && [[ -z "$(echo "${line}" | grep -i "ntlm")" ]]
            then
                echo "# ${line}"
            fi
            if [[ "${PW_TIMER}" != 1 ]] ; then
                sleep 3
                PW_TIMER=1
            fi
    done < "${PORT_WINE_TMP_PATH}/update_pfx_log" | "${pw_yad_new}" --text-info --tail --no-buttons --title="WINETRICKS" \
    --auto-close --skip-taskbar --width=$PW_GIF_SIZE_X --height=$PW_GIF_SIZE_Y &
    "${PORT_WINE_TMP_PATH}/winetricks" -q -r -f &>>"${PORT_WINE_TMP_PATH}/update_pfx_log"
    try_remove_file "${PORT_WINE_TMP_PATH}/update_pfx_log"
    kill -s SIGTERM "$(pgrep -a yad_new | grep "title=WINETRICKS" | awk '{print $1}')" > /dev/null 2>&1    
    stop_portwine
}

pw_start_cont_xterm () {
    cd "$HOME"
    unset PW_SANDBOX_HOME_PATH
    # export PW_ADD_TO_ARGS_IN_RUNTIME="--xterm"
    pw_init_runtime
    ${pw_runtime} xterm
}

pw_create_prefix_backup () {
    cd "$HOME"
    PW_PREFIX_TO_BACKUP=$("${pw_yad_new}" --file --directory --borders=5 --width=650 --height=500 --auto-close --center \
    --window-icon="$PW_GUI_ICON_PATH/port_proton.png" --title "BACKUP PREFIX TO...")
    YAD_STATUS="$?"
    if [[ "$YAD_STATUS" == "1" || "$YAD_STATUS" == "252" ]] ; then exit 0 ; fi
    if [[ -n "$(grep "/${PW_PREFIX_NAME}/" "${PORT_WINE_PATH}"/*.desktop )" ]] ; then
        try_remove_file "${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}/.create_shortcut"
        grep "/${PW_PREFIX_NAME}/" "${PORT_WINE_PATH}"/*.desktop | awk -F"/${PW_PREFIX_NAME}/" '{print $2}' \
        | awk -F\" '{print $1}' > "${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}/.create_shortcut"
    fi
    unset PW_SANDBOX_HOME_PATH
    export PW_ADD_TO_ARGS_IN_RUNTIME="--xterm"
    pw_init_runtime
    chmod -R u+w "${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}"
    ${pw_runtime} env PATH="${PATH}" LD_LIBRARY_PATH="${PW_LD_LIBRARY_PATH}" mksquashfs "${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}" "${PW_PREFIX_TO_BACKUP}/${PW_PREFIX_NAME}.ppack.part" -comp zstd &
    sleep 10
    while true ; do
        if [[ -n $(pgrep -a xterm | grep ".ppack.part" | head -n 1 | awk '{print $1}') ]] ; then
            sleep 0.5
        else
            kill -TERM $(pgrep -a mksquashfs | grep ".ppack.part" | head -n 1 | awk '{print $1}')
            sleep 0.3
            if [[ -z "$(pgrep -a mksquashfs | grep ".ppack.part" | head -n 1 | awk '{print $1}')" ]]
            then break
            else sleep 0.3
            fi
        fi
    done
    if [[ -f "${PW_PREFIX_TO_BACKUP}/${PW_PREFIX_NAME}.ppack.part" ]] ; then
        mv -f "${PW_PREFIX_TO_BACKUP}/${PW_PREFIX_NAME}.ppack.part" "${PW_PREFIX_TO_BACKUP}/${PW_PREFIX_NAME}.ppack"
        zenity_info "Backup for prefix \"${PW_PREFIX_NAME}\" successfully created."
    else 
        zenity_error "An error occurred while creating a backup for prefix: \"${PW_PREFIX_NAME}\" !"
    fi
    return 0
}

pw_edit_db () {
    pw_gui_for_edit_db \
    PW_MANGOHUD PW_MANGOHUD_x32 PW_MANGOHUD_USER_CONF ENABLE_VKBASALT PW_NO_ESYNC PW_NO_FSYNC PW_USE_DXR10 PW_USE_DXR11 \
    PW_USE_NVAPI_AND_DLSS PW_USE_FAKE_DLSS PW_WINE_FULLSCREEN_FSR PW_OLD_GL_STRING PW_HIDE_NVIDIA_GPU PW_VIRTUAL_DESKTOP PW_USE_TERMINAL \
    PW_GUI_DISABLED_CS PW_USE_GAMEMODE PW_DX12_DISABLE PW_PRIME_RENDER_OFFLOAD PW_USE_D3D_EXTRAS PW_FIX_VIDEO_IN_GAME \
    PW_FORCE_LARGE_ADDRESS_AWARE PW_USE_SHADER_CACHE PW_USE_WINE_DXGI
    if [ "$?" == 0 ] ; then
        echo "Restarting PP after update ppdb file..."
        /usr/bin/env bash -c ${pw_full_command_line[*]} &
        exit 0
    fi
    # PW_WINE_ALLOW_XIM PW_FORCE_USE_VSYNC PW_WINEDBG_DISABLE PW_USE_GSTREAMER PW_USE_AMDVLK_DRIVER
}

pw_autoinstall_from_db () {
    export PW_USER_TEMP="${PORT_WINE_TMP_PATH}"
    export PW_FORCE_LARGE_ADDRESS_AWARE=0
    export PW_USE_GAMEMODE=0
    export PW_CHECK_AUTOINSTAL=1
    export PW_GUI_DISABLED_CS=1
    export PW_WINEDBG_DISABLE=1
    export PW_NO_WRITE_WATCH=0
    export PW_VULKAN_USE=0
    export PW_NO_FSYNC=1
    export PW_NO_ESYNC=1
    unset PORTWINE_CREATE_SHORTCUT_NAME
    export PW_DISABLED_CREATE_DB=1
    export PW_MANGOHUD=0
    export ENABLE_VKBASALT=0
    export PW_USE_D3D_EXTRAS=1
    . "${PORT_SCRIPTS_PATH}/pw_autoinstall/${PW_YAD_SET}"
}

gui_credits () {
    . "${PORT_SCRIPTS_PATH}/credits"
}
export -f gui_credits

###MAIN###

# HOTFIX WGC TO LGC
if [[ ! -z "$(echo ${1} | grep 'wgc_api.exe')" ]] && [[ ! -f "${1}" ]] ; then
    export PW_YAD_SET=PW_LGC
    pw_autoinstall_from_db 
    exit 0
fi

# HOTFIX CALIBRE
if [[ ! -z "$(echo ${1} | grep '/Caliber/')" ]] ; then
    export PW_WINE_USE=PROTON_STEAM_6.3-8
fi

# CLI
case "${1}" in
    '--help' )
        files_from_autoinstall=$(ls "${PORT_SCRIPTS_PATH}/pw_autoinstall") 
        echo -e "
usege: [--reinstall] [--autoinstall]

--reinstall                                         reinstall files of the portproton to default settings
--autoinstall [script_frome_pw_autoinstall]         autoinstall from the list below:
"
        echo ${files_from_autoinstall}
        echo ""
        exit 0 ;;

    '--reinstall' )
        export PW_REINSTALL_FROM_TERMINAL=1
        pw_reinstall_pp ;;

    '--autoinstall' )
        export PW_YAD_SET="$2"
        pw_autoinstall_from_db 
        exit 0 ;;
esac

PW_PREFIX_NAME="$(echo "${PW_PREFIX_NAME}" | sed -e s/[[:blank:]]/_/g)"
PW_ALL_PREFIXES=$(ls "${PORT_WINE_PATH}/data/prefixes/" | sed -e s/"${PW_PREFIX_NAME}$"//g)
export PW_PREFIX_NAME PW_ALL_PREFIXES

# if [[ -n "${PORTWINE_DB}" ]] && [[ -z `echo "${PW_PREFIX_NAME}" | grep -i "$(echo "${PORTWINE_DB}" | sed -e s/[[:blank:]]/_/g)"` ]] ; then 
#     export PW_PREFIX_NAME="${PW_PREFIX_NAME}!`echo "${PORTWINE_DB}" | sed -e s/[[:blank:]]/_/g`"
# fi

unset PW_ADD_PREFIXES_TO_GUI
IFS_OLD=$IFS
IFS=$'\n'
for PAIG in ${PW_ALL_PREFIXES[*]} ; do 
    [[ "${PAIG}" != $(echo "${PORTWINE_DB^^}" | sed -e s/[[:blank:]]/_/g) ]] && \
    export PW_ADD_PREFIXES_TO_GUI="${PW_ADD_PREFIXES_TO_GUI}!${PAIG}"
done
IFS=$IFS_OLD
export PW_ADD_PREFIXES_TO_GUI="${PW_PREFIX_NAME^^}${PW_ADD_PREFIXES_TO_GUI}"

PW_ALL_DIST=$(ls "${PORT_WINE_PATH}/data/dist/" | sed -e s/"${PW_PROTON_GE_VER}$//g" | sed -e s/"${PW_PROTON_LG_VER}$//g")
unset DIST_ADD_TO_GUI
for DAIG in ${PW_ALL_DIST}
do
    export DIST_ADD_TO_GUI="${DIST_ADD_TO_GUI}!${DAIG}"
done
if [[ -n "${PORTWINE_DB_FILE}" ]] ; then
    [[ -z "${PW_COMMENT_DB}" ]] && PW_COMMENT_DB="${loc_gui_db_comments} <b>${PORTWINE_DB}</b>."
    if [[ -z "${PW_VULKAN_USE}" || -z "${PW_WINE_USE}" ]] ; then
        unset PW_GUI_DISABLED_CS
        [[ -z "${PW_VULKAN_USE}" ]] && export PW_VULKAN_USE=1
    fi
    case "${PW_VULKAN_USE}" in
            "0") export PW_DEFAULT_VULKAN_USE="${loc_gui_open_gl}!${loc_gui_vulkan_stable}!${loc_gui_vulkan_git}!${loc_gui_gallium_nine}" ;;
            "2") export PW_DEFAULT_VULKAN_USE="${loc_gui_vulkan_git}!${loc_gui_vulkan_stable}!${loc_gui_open_gl}!${loc_gui_gallium_nine}" ;;
            "3") export PW_DEFAULT_VULKAN_USE="${loc_gui_gallium_nine}!${loc_gui_vulkan_stable}!${loc_gui_vulkan_git}!${loc_gui_open_gl}" ;;
              *) export PW_DEFAULT_VULKAN_USE="${loc_gui_vulkan_stable}!${loc_gui_vulkan_git}!${loc_gui_open_gl}!${loc_gui_gallium_nine}" ;;
    esac
    if [[ -n $(echo "${PW_WINE_USE}" | grep "^PROTON_LG$") ]] ; then
        export PW_DEFAULT_WINE_USE="${PW_PROTON_LG_VER}!${PW_PROTON_GE_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
    elif [[ -n $(echo "${PW_WINE_USE}" | grep "^PROTON_GE$") ]] ; then
        export PW_DEFAULT_WINE_USE="${PW_PROTON_GE_VER}!${PW_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
    else
        if [[ "${PW_WINE_USE}" == "${PW_PROTON_LG_VER}" ]] ; then
            export PW_DEFAULT_WINE_USE="${PW_WINE_USE}!${PW_PROTON_GE_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE" 
        elif [[ "${PW_WINE_USE}" == "${PW_PROTON_GE_VER}" ]] ; then
            export PW_DEFAULT_WINE_USE="${PW_WINE_USE}!${PW_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE" 
        else
            export DIST_ADD_TO_GUI=$(echo "${DIST_ADD_TO_GUI}" | sed -e s/"\!${PW_WINE_USE}$//g")
            export PW_DEFAULT_WINE_USE="${PW_WINE_USE}!${PW_PROTON_GE_VER}!${PW_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
        fi
    fi
else
    export PW_DEFAULT_VULKAN_USE="${loc_gui_vulkan_stable}!${loc_gui_vulkan_git}!${loc_gui_open_gl}!${loc_gui_gallium_nine}"
    if [[ -n $(echo "${PW_WINE_USE}" | grep "^PROTON_LG$") ]] ; then
        export PW_DEFAULT_WINE_USE="${PW_PROTON_LG_VER}!${PW_PROTON_GE_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
    elif [[ -n $(echo "${PW_WINE_USE}" | grep "^PROTON_GE$") ]] ; then
        export PW_DEFAULT_WINE_USE="${PW_PROTON_GE_VER}!${PW_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
    else
        if [[ "${PW_WINE_USE}" == "${PW_PROTON_LG_VER}" ]] ; then
            export PW_DEFAULT_WINE_USE="${PW_WINE_USE}!${PW_PROTON_GE_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE" 
        elif [[ "${PW_WINE_USE}" == "${PW_PROTON_GE_VER}" ]] ; then
            export PW_DEFAULT_WINE_USE="${PW_WINE_USE}!${PW_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE" 
        else
            export DIST_ADD_TO_GUI=$(echo "${DIST_ADD_TO_GUI}" | sed -e s/"\!${PW_WINE_USE}$//g")
            export PW_DEFAULT_WINE_USE="${PW_WINE_USE}!${PW_PROTON_GE_VER}!${PW_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
        fi     
    fi
    unset PW_GUI_DISABLED_CS
fi
if [ -n "${portwine_exe}" ]; then
    if [[ -z "${PW_GUI_DISABLED_CS}" || "${PW_GUI_DISABLED_CS}" == 0 ]] ; then  
        pw_create_gui_png
        grep -il "${portwine_exe}" "${HOME}/.local/share/applications"/*.desktop
        if [[ "$?" != "0" ]] ; then
            PW_SHORTCUT="${loc_gui_create_shortcut}!$PW_GUI_ICON_PATH/separator.png!${loc_create_shortcut}:100"
        else
            PW_SHORTCUT="${loc_gui_delete_shortcut}!$PW_GUI_ICON_PATH/separator.png!${loc_delete_shortcut}:98"
        fi
        OUTPUT_START=$("${pw_yad}" --text-align=center --text "$PW_COMMENT_DB" --wrap-width=150 --borders=7 --form --center  \
        --title "${portname}-${install_ver} (${scripts_install_ver})" --image "${PW_ICON_FOR_YAD}" --separator=";" --keep-icon-size \
        --window-icon="$PW_GUI_ICON_PATH/port_proton.png" \
        --field="3D API  : :CB" "${PW_DEFAULT_VULKAN_USE}" \
        --field="  WINE  : :CB" "${PW_DEFAULT_WINE_USE}" \
        --field="PREFIX  : :CBE" "${PW_ADD_PREFIXES_TO_GUI}" \
        --field=":LBL" "" \
        --button="${loc_gui_vkbasalt_start}"!"$PW_GUI_ICON_PATH/separator.png"!"${ENABLE_VKBASALT_INFO}":120 \
        --button="${loc_gui_edit_db_start}"!"$PW_GUI_ICON_PATH/separator.png"!"${loc_edit_db} ${PORTWINE_DB}":118 \
        --button="${PW_SHORTCUT}" \
        --button="${loc_gui_debug}"!"$PW_GUI_ICON_PATH/separator.png"!"${loc_debug}":102 \
        --button="${loc_gui_launch}"!"$PW_GUI_ICON_PATH/separator.png"!"${loc_launch}":106 )
        export PW_YAD_SET="$?"
        if [[ "$PW_YAD_SET" == "1" || "$PW_YAD_SET" == "252" ]] ; then exit 0 ; fi
        export VULKAN_MOD=$(echo "${OUTPUT_START}" | grep \;\; | awk -F";" '{print $1}')
        export PW_WINE_VER=$(echo "${OUTPUT_START}" | grep \;\; | awk -F";" '{print $2}')
        export PW_PREFIX_NAME=$(echo "${OUTPUT_START}" | grep \;\; | awk -F";" '{print $3}' | sed -e s/[[:blank:]]/_/g)
        if [[ -z "${PW_PREFIX_NAME}" ]] || [[ -n "$(echo "${PW_PREFIX_NAME}" | grep -E '^_.*' )" ]] ; then
            export PW_PREFIX_NAME="DEFAULT"
        else
            export PW_PREFIX_NAME="${PW_PREFIX_NAME^^}"
        fi
    elif [ -n "${PORTWINE_DB_FILE}" ]; then
        portwine_launch
    fi
else
    button_click () {
        [[ -n "$1" ]] && echo "$1" > "${PORT_WINE_TMP_PATH}/tmp_yad_form"
        if [[ -n $(pidof -s yad) ]] || [[ -n $(pidof -s yad_new) ]] ; then
            kill -s SIGUSR1 $(pgrep -a yad | grep "\-\-key=${KEY} \-\-notebook" | awk '{print $1}') > /dev/null 2>&1
        fi
    }
    export -f button_click

    run_desktop_b_click () {
        [[ -n "$1" ]] && echo "$1" > "${PORT_WINE_TMP_PATH}/tmp_yad_form"
        if [[ -n $(pidof -s yad) ]] || [[ -n $(pidof -s yad_new) ]] ; then
            kill -s SIGUSR1 $(pgrep -a yad | grep "\-\-key=${KEY} \-\-notebook" | awk '{print $1}') > /dev/null 2>&1
        fi
        
        PW_EXEC_FROM_DESKTOP="$(cat "${PORT_WINE_PATH}/${PW_YAD_SET}"* | grep Exec | head -n 1 | awk -F"=env " '{print $2}')"
        echo ${PW_EXEC_FROM_DESKTOP[*]}

        echo "Restarting PP after choose desktop file..."
        # stop_portwine
        /usr/bin/env bash -c "${PW_EXEC_FROM_DESKTOP[*]}" &
        exit 0 
    }
    export -f run_desktop_b_click

    gui_clear_pfx () {
        if gui_question "${port_clear_pfx}" ; then
            pw_clear_pfx
            echo "Restarting PP after clearing prefix..."
            /usr/bin/env bash -c ${pw_full_command_line[*]} &
            exit 0
        fi
    }
    export -f gui_clear_pfx

    gui_rm_portproton () {
        if gui_question "${port_del2}" ; then
            rm -fr "${PORT_WINE_PATH}"
            rm -fr "${PORT_WINE_TMP_PATH}"
            rm -fr "${HOME}/PortWINE"
            rm -f $(grep -il PortProton "${HOME}/.local/share/applications"/*)
            update-desktop-database -q "${HOME}/.local/share/applications"
        fi
        exit 0
    }
    export -f gui_rm_portproton

    gui_pw_update () {
        try_remove_file "${PORT_WINE_TMP_PATH}/scripts_update_notifier"
        echo "Restarting PP for check update..."
        /usr/bin/env bash -c ${pw_full_command_line[*]} &
        exit 0
    }

    change_loc () {
        try_remove_file "${PORT_WINE_TMP_PATH}/PortProton_loc"
        echo "Restarting PP for change language..."
        /usr/bin/env bash -c ${pw_full_command_line[*]} &
        exit 0
    }

    gui_wine_uninstaller () {
        start_portwine
        pw_run uninstaller
    }
    export -f gui_wine_uninstaller

    gui_open_user_conf () {
        xdg-open "${PORT_WINE_PATH}/data/user.conf"
    }
    export -f gui_open_user_conf

    gui_open_scripts_from_backup () {
        cd "${PORT_WINE_TMP_PATH}/scripts_backup/"
        PW_SCRIPT_FROM_BACKUP=$("${pw_yad_new}" --file --borders=5 --width=650 --height=500 --auto-close --center \
        --window-icon="$PW_GUI_ICON_PATH/port_proton.png" --title "SCRIPTS FROM BACKUP" --file-filter="backup_scripts|scripts_v*.tar.gz")
        YAD_STATUS="$?"
        if [[ "$YAD_STATUS" == "1" || "$YAD_STATUS" == "252" ]] ; then exit 0 ; fi
        unpack_tar_gz "$PW_SCRIPT_FROM_BACKUP" "${PORT_WINE_PATH}/data/"
        echo "0" > "${PORT_WINE_TMP_PATH}/scripts_update_notifier"
        echo "Restarting PP after backup..."
        /usr/bin/env bash -c ${pw_full_command_line[*]} &
        exit 0
    }
    export -f gui_open_scripts_from_backup


    export KEY=$RANDOM
    "${pw_yad_new}" --plug=${KEY} --tabnum=4 --form --columns=3 --align-buttons --keep-icon-size  --separator=";" \
    --field="   $loc_gui_pw_reinstall_pp"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click gui_pw_reinstall_pp"' \
    --field="   $loc_gui_rm_pp"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click gui_rm_portproton"' \
    --field="   $loc_gui_upd_pp"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click gui_pw_update"' \
    --field="   $loc_gui_changelog"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click open_changelog"' \
    --field="   $loc_gui_change_loc"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click change_loc"' \
    --field="   $loc_gui_edit_usc"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click gui_open_user_conf"' \
    --field="   $loc_gui_scripts_fb"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click gui_open_scripts_from_backup"' \
    --field="   Xterm"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click pw_start_cont_xterm"' \
    --field="   $loc_gui_credits"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click gui_credits"' &

    "${pw_yad_new}" --plug=${KEY} --tabnum=3 --form --columns=3 --align-buttons --keep-icon-size --separator=";" \
    --field="  3D API  : :CB" "${loc_gui_vulkan_stable}!${loc_gui_vulkan_git}!${loc_gui_open_gl}!${loc_gui_gallium_nine}" \
    --field="  PREFIX  : :CBE" "${PW_ADD_PREFIXES_TO_GUI}" \
    --field="  WINE    : :CB" "${PW_DEFAULT_WINE_USE}" \
    --field="                  DOWNLOAD OTHER WINE"!"$PW_GUI_ICON_PATH/separator.png"!"${loc_download_other_wine}":"FBTN" '@bash -c "button_click gui_proton_downloader"' \
    --field='   WINECFG'!"$PW_GUI_ICON_PATH/separator.png"!"${loc_winecfg}":"FBTN" '@bash -c "button_click WINECFG"' \
    --field='   WINEFILE'!"$PW_GUI_ICON_PATH/separator.png"!"${loc_winefile}":"FBTN" '@bash -c "button_click WINEFILE"' \
    --field='   WINECMD'!"$PW_GUI_ICON_PATH/separator.png"!"${loc_winecmd}":"FBTN" '@bash -c "button_click WINECMD"' \
    --field='   WINEREG'!"$PW_GUI_ICON_PATH/separator.png"!"${loc_winereg}":"FBTN" '@bash -c "button_click WINEREG"' \
    --field='   WINETRICKS'!"$PW_GUI_ICON_PATH/separator.png"!"${loc_winetricks}":"FBTN" '@bash -c "button_click WINETRICKS"' \
    --field="   WINE UNINSTALLER"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click gui_wine_uninstaller"' \
    --field="   CLEAR PREFIX"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click gui_clear_pfx"' \
    --field="   CREATE PFX BACKUP"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click pw_create_prefix_backup"' &> "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" &

    "${pw_yad_new}" --plug=$KEY --tabnum=2 --form --columns=3 --align-buttons --keep-icon-size --scroll  \
    --field="   Dolphin 5.0"!"$PW_GUI_ICON_PATH/dolphin.png"!"":"FBTN" '@bash -c "button_click PW_DOLPHIN"' \
    --field="   MAME"!"$PW_GUI_ICON_PATH/mame.png"!"":"FBTN" '@bash -c "button_click PW_MAME"' \
    --field="   ScummVM"!"$PW_GUI_ICON_PATH/scummvm.png"!"":"FBTN" '@bash -c "button_click PW_SCUMMVM"' \
    --field="   RetroArch"!"$PW_GUI_ICON_PATH/retroarch.png"!"":"FBTN" '@bash -c "button_click PW_RETROARCH"' \
    --field="   PPSSPP Windows"!"$PW_GUI_ICON_PATH/ppsspp.png"!"":"FBTN" '@bash -c "button_click PW_PPSSPP"' \
    --field="   Citra"!"$PW_GUI_ICON_PATH/citra.png"!"":"FBTN" '@bash -c "button_click PW_CITRA"' \
    --field="   Cemu"!"$PW_GUI_ICON_PATH/cemu.png"!"":"FBTN" '@bash -c "button_click PW_CEMU"' \
    --field="   DuckStation"!"$PW_GUI_ICON_PATH/duckstation.png"!"":"FBTN" '@bash -c "button_click PW_DUCKSTATION"' \
    --field="   ePSXe"!"$PW_GUI_ICON_PATH/epsxe.png"!"":"FBTN" '@bash -c "button_click PW_EPSXE"' \
    --field="   Project64"!"$PW_GUI_ICON_PATH/project64.png"!"":"FBTN" '@bash -c "button_click PW_PROJECT64"' \
    --field="   VBA-M"!"$PW_GUI_ICON_PATH/vba-m.png"!"":"FBTN" '@bash -c "button_click PW_VBA-M"' \
    --field="   Yabause"!"$PW_GUI_ICON_PATH/yabause.png"!"":"FBTN" '@bash -c "button_click PW_YABAUSE"' &

    "${pw_yad_new}" --plug=$KEY --tabnum=1 --form --columns=3 --align-buttons --keep-icon-size --scroll \
    --field="   Wargaming Game Center"!"$PW_GUI_ICON_PATH/wgc.png"!"":"FBTN" '@bash -c "button_click PW_WGC"' \
    --field="   Battle.net Launcher"!"$PW_GUI_ICON_PATH/battle_net.png"!"":"FBTN" '@bash -c "button_click PW_BATTLE_NET"' \
    --field="   Epic Games Launcher"!"$PW_GUI_ICON_PATH/epicgames.png"!"":"FBTN" '@bash -c "button_click PW_EPIC"' \
    --field="   GoG Galaxy Launcher"!"$PW_GUI_ICON_PATH/gog.png"!"":"FBTN" '@bash -c "button_click PW_GOG"' \
    --field="   Ubisoft Game Launcher"!"$PW_GUI_ICON_PATH/ubc.png"!"":"FBTN" '@bash -c "button_click PW_UBC"' \
    --field="   EVE Online Launcher"!"$PW_GUI_ICON_PATH/eve.png"!"":"FBTN" '@bash -c "button_click PW_EVE"' \
    --field="   Lesta Game Center"!"$PW_GUI_ICON_PATH/lgc.png"!"":"FBTN" '@bash -c "button_click PW_LGC"' \
    --field="   EA App"!"$PW_GUI_ICON_PATH/eaapp.png"!"":"FBTN" '@bash -c "button_click PW_EAAPP"' \
    --field="   Rockstar Games Launcher"!"$PW_GUI_ICON_PATH/Rockstar.png"!"":"FBTN" '@bash -c "button_click PW_ROCKSTAR"' \
    --field="   vkPlay Games Center"!"$PW_GUI_ICON_PATH/mygames.png"!"":"FBTN" '@bash -c "button_click PW_VKPLAY"' \
    --field="   Ankama Launcher"!"$PW_GUI_ICON_PATH/ankama.png"!"":"FBTN" '@bash -c "button_click PW_ANKAMA"' \
    --field="   OSU"!"$PW_GUI_ICON_PATH/osu.png"!"":"FBTN" '@bash -c "button_click PW_OSU"' \
    --field="   League of Legends"!"$PW_GUI_ICON_PATH/lol.png"!"":"FBTN" '@bash -c "button_click PW_LOL"' \
    --field="   Gameforge Client"!"$PW_GUI_ICON_PATH/gameforge.png"!"":"FBTN" '@bash -c "button_click  PW_GAMEFORGE"' \
    --field="   World of Sea Battle (BETA)"!"$PW_GUI_ICON_PATH/wosb.png"!"":"FBTN" '@bash -c "button_click PW_WOSB"' \
    --field="   CALIBER"!"$PW_GUI_ICON_PATH/caliber.png"!"":"FBTN" '@bash -c "button_click PW_CALIBER"' \
    --field="   FULQRUM GAMES"!"$PW_GUI_ICON_PATH/fulqrumgames.png"!"":"FBTN" '@bash -c "button_click PW_FULQRUM_GAMES"' \
    --field="   Plarium Play"!"$PW_GUI_ICON_PATH/plariumplay.png"!"":"FBTN" '@bash -c "button_click PW_PLARIUM_PLAY"' \
    --field="   ITCH.IO"!"$PW_GUI_ICON_PATH/itch.png"!"":"FBTN" '@bash -c "button_click PW_ITCH"' \
    --field="   Steam (unstable)"!"$PW_GUI_ICON_PATH/steam.png"!"":"FBTN" '@bash -c "button_click PW_STEAM"' \
    --field="   Crossout"!"$PW_GUI_ICON_PATH/crossout.png"!"":"FBTN" '@bash -c "button_click PW_CROSSOUT"' \
    --field="   Indiegala Client"!"$PW_GUI_ICON_PATH/igclient.png"!"":"FBTN" '@bash -c "button_click PW_IGCLIENT"' \
    --field="   Warframe"!"$PW_GUI_ICON_PATH/warframe.png"!"":"FBTN" '@bash -c "button_click PW_WARFRAME"' \
    --field="   Panzar"!"$PW_GUI_ICON_PATH/panzar.png"!"":"FBTN" '@bash -c "button_click PW_PANZAR"' \
    --field="   STALCRAFT"!"$PW_GUI_ICON_PATH/stalcraft.png"!"":"FBTN" '@bash -c "button_click PW_STALCRAFT"' \
    --field="   Path of Exile"!"$PW_GUI_ICON_PATH/poe.png"!"":"FBTN" '@bash -c "button_click PW_POE"' &

    # --field="   Secret World Legends (ENG)"!"$PW_GUI_ICON_PATH/swl.png"!"":"FBTN" '@bash -c "button_click PW_SWL"'
    # --field="   Guild Wars 2"!"$PW_GUI_ICON_PATH/gw2.png"!"":"FBTN" '@bash -c "button_click PW_GUILD_WARS_2"'
    # --field="   Bethesda.net Launcher"!"$PW_GUI_ICON_PATH/bethesda.png"!"":"FBTN" '@bash -c "button_click PW_BETHESDA"'

    orig_IFS="$IFS" && IFS=$'\n'
    PW_ALL_DF="$(ls ${PORT_WINE_PATH}/ | grep .desktop | grep -v "PortProton" | grep -v "readme")"
    IFS="$orig_IFS"

    for PW_DESKTOP_FILES in ${PW_ALL_DF} ; do
        PW_NAME_D_NAME="$(cat "${PORT_WINE_PATH}/$PW_DESKTOP_FILES" | grep Name | awk -F= '{print $2}')"
        PW_NAME_D_ICON="$(cat "${PORT_WINE_PATH}/$PW_DESKTOP_FILES" | grep Icon | awk -F= '{print $2}')"

        PW_GENERATE_BUTTONS+="--field=  ${PW_NAME_D_NAME}!${PW_NAME_D_ICON}!:FBTN%@bash -c \"run_desktop_b_click ${PW_DESKTOP_FILES}\"%"
    done

    old_IFS=$IFS && IFS="%"
    "${pw_yad_new}" --plug=$KEY --tabnum=5 --form --columns=2 --align-buttons --keep-icon-size --scroll --separator=" " ${PW_GENERATE_BUTTONS} &
    IFS="$orig_IFS"


    "${pw_yad_new}" --key=$KEY --notebook --borders=5 --width=1000 --height=235 --no-buttons --auto-close --center \
    --window-icon="$PW_GUI_ICON_PATH/port_proton.png" --title "${portname}-${install_ver} (${scripts_install_ver})" \
    --tab-pos=bottom --keep-icon-size \
    --tab="$loc_mg_autoinstall"!"$PW_GUI_ICON_PATH/separator.png"!"" \
    --tab="$loc_mg_emulators"!"$PW_GUI_ICON_PATH/separator.png"!"" \
    --tab="$loc_mg_wine_settings"!"$PW_GUI_ICON_PATH/separator.png"!"" \
    --tab="$loc_mg_portproton_settings"!"$PW_GUI_ICON_PATH/separator.png"!""
    YAD_STATUS="$?"
    if [[ "$YAD_STATUS" == "1" || "$YAD_STATUS" == "252" ]] ; then exit 0 ; fi

    if [[ -f "${PORT_WINE_TMP_PATH}/tmp_yad_form" ]]; then
        export PW_YAD_SET=$(cat "${PORT_WINE_TMP_PATH}/tmp_yad_form" | head -n 1 | awk '{print $1}')
        echo "from tmp_yad_form $PW_YAD_SET, and cat tmp_yad_form"
        cat "${PORT_WINE_TMP_PATH}/tmp_yad_form"
    fi
    if [[ -f "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" ]] ; then
        export VULKAN_MOD=$(cat "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" | grep \;\;  | awk -F";" '{print $1}')
        export PW_PREFIX_NAME=$(cat "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" | grep \;\;  | awk -F";" '{print $2}' | sed -e "s/[[:blank:]]/_/g" )
        export PW_WINE_VER=$(cat "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" | grep \;\; | awk -F";" '{print $3}')
        if [[ -z "${PW_PREFIX_NAME}" ]] || [[ -n "$(echo "${PW_PREFIX_NAME}" | grep -E '^_.*' )" ]] ; then
            export PW_PREFIX_NAME="DEFAULT"
        else
            export PW_PREFIX_NAME="${PW_PREFIX_NAME^^}"
        fi
        try_remove_file "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan"
    fi
    export PW_DISABLED_CREATE_DB=1
fi

case "${VULKAN_MOD}" in
    "${loc_gui_open_gl}" )          export PW_VULKAN_USE="0" ;;
    "${loc_gui_vulkan_stable}" )    export PW_VULKAN_USE="1" ;;
    "${loc_gui_vulkan_git}" )       export PW_VULKAN_USE="2" ;;
    "${loc_gui_gallium_nine}" )     export PW_VULKAN_USE="3" ;;
esac

init_wine_ver

if [[ -z "${PW_DISABLED_CREATE_DB}" ]] ; then
    if [[ -n "${PORTWINE_DB}" ]] && [[ -z "${PORTWINE_DB_FILE}" ]] ; then
        PORTWINE_DB_FILE=$(grep -il "\#${PORTWINE_DB}.exe" "${PORT_SCRIPTS_PATH}/portwine_db"/*)
        if [[ -z "${PORTWINE_DB_FILE}" ]] ; then
            echo "#!/usr/bin/env bash"  > "${portwine_exe}".ppdb
            echo "#Author: "${USER}"" >> "${portwine_exe}".ppdb
            echo "#"${PORTWINE_DB}.exe"" >> "${portwine_exe}".ppdb
            echo "#Rating=1-5" >> "${portwine_exe}".ppdb
            cat "${PORT_SCRIPTS_PATH}/portwine_db/default" | grep "##" >> "${portwine_exe}".ppdb
            export PORTWINE_DB_FILE="${portwine_exe}".ppdb
        fi
    fi
    edit_db_from_gui PW_VULKAN_USE PW_WINE_USE PW_PREFIX_NAME 
fi

case "$PW_YAD_SET" in
    1|252) exit 0 ;;
    98) portwine_delete_shortcut ;;
    100) portwine_create_shortcut ;;
    DEBUG|102) portwine_start_debug ;;
    106) portwine_launch ;;
    WINECFG|108) pw_winecfg ;;
    WINEFILE|110) pw_winefile ;;
    WINECMD|112) pw_winecmd ;;
    WINEREG|114) pw_winereg ;;
    WINETRICKS|116) pw_prefix_manager ;;
    118) pw_edit_db ;;
    gui_clear_pfx) gui_clear_pfx ;;
    gui_open_user_conf) gui_open_user_conf ;;
    gui_wine_uninstaller) gui_wine_uninstaller ;;
    gui_rm_portproton) gui_rm_portproton ;;
    gui_pw_reinstall_pp) pw_reinstall_pp ;;
    gui_pw_update) gui_pw_update ;;
    gui_proton_downloader) gui_proton_downloader ;;
    gui_open_scripts_from_backup) gui_open_scripts_from_backup ;;
    open_changelog) open_changelog ;;
    change_loc) change_loc ;;
    120) gui_vkBasalt ;;
    pw_create_prefix_backup) pw_create_prefix_backup ;;
    gui_credits) gui_credits ;;
    pw_start_cont_xterm) pw_start_cont_xterm ;;
    PW_*) pw_autoinstall_from_db ;;
esac

stop_portwine
