#!/usr/bin/env bash
# Author: linux-gaming.ru
export NO_AT_BRIDGE=1
export pp_full_command_line=("$0" $*)
if [ -f "$1" ]; then
    export portwine_exe="$(readlink -f "$1")"
fi
. "$(dirname $(readlink -f "$0"))/runlib"
kill_portwine
pp_stop_progress_bar

if [[ -f "/usr/bin/portproton" ]] && [[ -f "${HOME}/.local/share/applications/PortProton.desktop" ]] ; then
    /usr/bin/env bash "/usr/bin/portproton" "$@" & 
    exit 0
fi

if [[ "${XDG_SESSION_TYPE}" = "wayland" ]] && [[ ! -f "${PORT_WINE_TMP_PATH}/check_wayland" ]]; then
    zenity_info "$PP_WAYLAND_INFO"
    echo "1" > "${PORT_WINE_TMP_PATH}/check_wayland"
fi

if [[ -n $(basename "${portwine_exe}" | grep .ppack) ]] ; then
    export PP_ADD_TO_ARGS_IN_RUNTIME="--xterm"
    unset PP_SANDBOX_HOME_PATH
    pp_init_runtime
    export PP_PREFIX_NAME=$(basename "$1" | awk -F'.' '{print $1}')
    ${pp_runtime} env PATH="${PATH}" LD_LIBRARY_PATH="${PP_LD_LIBRARY_PATH}" unsquashfs -f -d "${PORT_WINE_PATH}/data/prefixes/${PP_PREFIX_NAME}" "$1" &
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
    if [[ -f "${PORT_WINE_PATH}/data/prefixes/${PP_PREFIX_NAME}/.create_shortcut" ]] ; then
        orig_IFS="$IFS"
        IFS=$'\n'
        for crfb in $(cat "${PORT_WINE_PATH}/data/prefixes/${PP_PREFIX_NAME}/.create_shortcut") ; do
            export portwine_exe="${PORT_WINE_PATH}/data/prefixes/${PP_PREFIX_NAME}/${crfb}"
            portwine_create_shortcut "${PORT_WINE_PATH}/data/prefixes/${PP_PREFIX_NAME}/${crfb}"
        done
        IFS="$orig_IFS"
    fi
    exit 0
fi

portwine_launch () {
    start_portwine
    PORTWINE_MSI=$(basename "${portwine_exe}" | grep .msi)
    PORTWINE_BAT=$(basename "${portwine_exe}" | grep .bat)
    if [[ -n "${PP_VIRTUAL_DESKTOP}" && "${PP_VIRTUAL_DESKTOP}" == "1" ]] ; then
        pp_screen_resolution=$(xrandr --current | grep "*" | awk '{print $1;}' | head -1)
        pp_run explorer "/desktop=portwine,${pp_screen_resolution}" ${WINE_WIN_START} "$portwine_exe"
    elif [ -n "${PORTWINE_MSI}" ]; then
        pp_run msiexec /i "$portwine_exe"
    elif [[ -n "${PORTWINE_BAT}" || -n "${portwine_exe}" ]] ; then
        pp_run ${WINE_WIN_START} "$portwine_exe"
    else
        pp_run winefile
    fi
}

portwine_start_debug () {
    kill_portwine
    export PP_LOG=1
    export PP_WINEDBG_DISABLE=0
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
    if [ "${PP_USE_RUNTIME}" = 0 ] ; then
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
    if [[ "${PP_VULKAN_USE}" = "0" ]] ; then 
        echo "PP_VULKAN_USE=${PP_VULKAN_USE} - DX9-11 to OpenGL" >> "${PORT_WINE_PATH}/${portname}.log"
    elif [[ "${PP_VULKAN_USE}" = "3" ]] ; then 
        echo "PP_VULKAN_USE=${PP_VULKAN_USE} - native DX9 on MESA drivers" >> "${PORT_WINE_PATH}/${portname}.log"
    else 
        echo "PP_VULKAN_USE=${PP_VULKAN_USE}" >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    echo "--------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Version WINE in the Port:" >> "${PORT_WINE_PATH}/${portname}.log"
    print_var PP_WINE_USE >> "${PORT_WINE_PATH}/${portname}.log"
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
    "${PP_WINELIB}/portable/bin/inxi" -G >> "${PORT_WINE_PATH}/${portname}.log"
    echo "----------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Vulkan info device name:" >> "${PORT_WINE_PATH}/${portname}.log"
    [[ `which vulkaninfo` ]] && vulkaninfo | grep deviceName >> "${PORT_WINE_PATH}/${portname}.log"
    "${PP_WINELIB}/portable/bin/vkcube" --c 50
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
    if [[ "${PP_USE_D3D_EXTRAS}" != 1 ]]
    then echo "D3D_EXTRAS - disabled" >> "${PORT_WINE_PATH}/${portname}.log"
    else echo "D3D_EXTRAS - enabled" >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    echo "------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "winetricks.log:" >> "${PORT_WINE_PATH}/${portname}.log"
    cat "${PORT_WINE_PATH}/data/prefixes/${PP_PREFIX_NAME}/winetricks.log" | sed -e /"^d3dcomp*"/d -e /"^d3dx*"/d >> "${PORT_WINE_PATH}/${portname}.log"
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
    pp_stop_progress_bar_cover
    unset PP_TIMER
    while read -r line || [[ -n $(pgrep -a yad | grep "yad_new --text-info --tail --button="STOP":0 --title="DEBUG"" | awk '{print $1}') ]] ; do
            sleep 0.005
            if [[ -n "${line}" ]] && [[ -z "$(echo "${line}" | grep -i "gstreamer")" ]] \
                                    && [[ -z "$(echo "${line}" | grep -i "kerberos")" ]] \
                                    && [[ -z "$(echo "${line}" | grep -i "ntlm")" ]]
            then
                echo "# ${line}"
            fi
            if [[ "${PP_TIMER}" != 1 ]] ; then
                sleep 3
                PP_TIMER=1
            fi
    done < "${PORT_WINE_PATH}/${portname}.log" | "${pp_yad_new}" --text-info --tail --button="STOP":0 --title="DEBUG" \
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
    "$pp_yad" --title="${portname}.log" --borders=7 --no-buttons --text-align=center \
    --text-info --show-uri --wrap --center --width=1200 --height=550  --uri-color=red \
    --filename="${PORT_WINE_PATH}/${portname}.log"
    stop_portwine
}

pp_winecfg () {
    start_portwine
    pp_run winecfg
}

pp_winefile () {
    start_portwine
    pp_run winefile
}

pp_winecmd () {
    export PP_USE_TERMINAL=1
    start_portwine
    cd "${PORT_WINE_PATH}/data/prefixes/${PP_PREFIX_NAME}/drive_c"
    ${pp_runtime} env LD_LIBRARY_PATH="${PP_LD_LIBRARY_PATH}" xterm -e "${WINELOADER}" cmd
    stop_portwine
}

pp_winereg () {
    start_portwine
    pp_run regedit
}

pp_prefix_manager () {
    update_winetricks
    start_portwine
    if [ ! -f "${PORT_WINE_PATH}/data/prefixes/${PP_PREFIX_NAME}/winetricks.log" ] ; then
        touch "${PORT_WINE_PATH}/data/prefixes/${PP_PREFIX_NAME}/winetricks.log"
    fi

    pp_start_progress_bar_block "Starting prefix manager..."
    "${PORT_WINE_TMP_PATH}/winetricks" dlls list | awk -F'(' '{print $1}' 1> "${PORT_WINE_TMP_PATH}/dll_list"
    "${PORT_WINE_TMP_PATH}/winetricks" fonts list | awk -F'(' '{print $1}' 1> "${PORT_WINE_TMP_PATH}/fonts_list"
    "${PORT_WINE_TMP_PATH}/winetricks" settings list | awk -F'(' '{print $1}' 1> "${PORT_WINE_TMP_PATH}/settings_list"
    pp_stop_progress_bar

    gui_prefix_manager () {
        pp_start_progress_bar_block "Starting prefix manager..."
        unset SET_FROM_PFX_MANAGER_TMP SET_FROM_PFX_MANAGER
        old_IFS=$IFS
        IFS=$'\n'
        try_remove_file  "${PORT_WINE_TMP_PATH}/dll_list_tmp"
        while read PP_BOOL_IN_DLL_LIST ; do
            if [[ -z $(echo "${PP_BOOL_IN_DLL_LIST}" | grep -E 'd3d|directx9|dont_use|dxvk|vkd3d|galliumnine|faudio1') ]] ; then
                if grep "^$(echo ${PP_BOOL_IN_DLL_LIST} | awk '{print $1}')$" "${PORT_WINE_PATH}/data/prefixes/${PP_PREFIX_NAME}/winetricks.log" ; then
                    echo -e "true\n$(echo ${PP_BOOL_IN_DLL_LIST} | awk '{print $1}')\n`echo ${PP_BOOL_IN_DLL_LIST} | awk '{ $1 = ""; print substr($0, 2) }'`" >> "${PORT_WINE_TMP_PATH}/dll_list_tmp"
                else
                    echo -e "false\n`echo "${PP_BOOL_IN_DLL_LIST}" | awk '{print $1}'`\n`echo ${PP_BOOL_IN_DLL_LIST} | awk '{ $1 = ""; print substr($0, 2) }'`" >> "${PORT_WINE_TMP_PATH}/dll_list_tmp"
                fi
            fi
        done < "${PORT_WINE_TMP_PATH}/dll_list"
        try_remove_file  "${PORT_WINE_TMP_PATH}/fonts_list_tmp"
        while read PP_BOOL_IN_FONTS_LIST ; do
            if [[ -z $(echo "${PP_BOOL_IN_FONTS_LIST}" | grep -E 'dont_use') ]] ; then
                if grep "^$(echo "${PP_BOOL_IN_FONTS_LIST}" | awk '{print $1}')$" "${PORT_WINE_PATH}/data/prefixes/${PP_PREFIX_NAME}/winetricks.log" ; then
                    echo -e "true\n$(echo "${PP_BOOL_IN_FONTS_LIST}" | awk '{print $1}')\n$(echo "${PP_BOOL_IN_FONTS_LIST}" | awk '{ $1 = ""; print substr($0, 2) }')" >> "${PORT_WINE_TMP_PATH}/fonts_list_tmp"
                else
                    echo -e "false\n$(echo "${PP_BOOL_IN_FONTS_LIST}" | awk '{print $1}')\n$(echo "${PP_BOOL_IN_FONTS_LIST}" | awk '{ $1 = ""; print substr($0, 2) }')" >> "${PORT_WINE_TMP_PATH}/fonts_list_tmp"
                fi
            fi
        done < "${PORT_WINE_TMP_PATH}/fonts_list"
        try_remove_file  "${PORT_WINE_TMP_PATH}/settings_list_tmp"
        while read PP_BOOL_IN_FONTS_LIST ; do
            if [[ -z $(echo "${PP_BOOL_IN_FONTS_LIST}" | grep -E 'vista|alldlls|autostart_|bad|good|win|videomemory|vd=|isolate_home') ]] ; then
                if grep "^$(echo "${PP_BOOL_IN_FONTS_LIST}" | awk '{print $1}')$" "${PORT_WINE_PATH}/data/prefixes/${PP_PREFIX_NAME}/winetricks.log" ; then
                    echo -e "true\n$(echo "${PP_BOOL_IN_FONTS_LIST}" | awk '{print $1}')\n$(echo "${PP_BOOL_IN_FONTS_LIST}" | awk '{ $1 = ""; print substr($0, 2) }')" >> "${PORT_WINE_TMP_PATH}/settings_list_tmp"
                else
                    echo -e "false\n$(echo "${PP_BOOL_IN_FONTS_LIST}" | awk '{print $1}')\n$(echo "${PP_BOOL_IN_FONTS_LIST}" | awk '{ $1 = ""; print substr($0, 2) }')" >> "${PORT_WINE_TMP_PATH}/settings_list_tmp"
                fi
            fi
        done < "${PORT_WINE_TMP_PATH}/settings_list"
        pp_stop_progress_bar

        KEY_EDIT_MANAGER_GUI=$RANDOM
        "${pp_yad_new}" --plug=$KEY_EDIT_MANAGER_GUI --tabnum=1 --list --checklist \
        --text="Select components to install in prefix: <b>\"${PP_PREFIX_NAME}\"</b>, using wine: <b>\"${PP_WINE_USE}\"</b>" \
        --column=set --column=dll --column=info < "${PORT_WINE_TMP_PATH}/dll_list_tmp" 1>> "${PORT_WINE_TMP_PATH}/to_winetricks" &

        "${pp_yad_new}" --plug=$KEY_EDIT_MANAGER_GUI --tabnum=2 --list --checklist \
        --text="Select fonts to install in prefix: <b>\"${PP_PREFIX_NAME}\"</b>, using wine: <b>\"${PP_WINE_USE}\"</b>" \
        --column=set --column=dll --column=info < "${PORT_WINE_TMP_PATH}/fonts_list_tmp" 1>> "${PORT_WINE_TMP_PATH}/to_winetricks" &

        "${pp_yad_new}" --plug=$KEY_EDIT_MANAGER_GUI --tabnum=3 --list --checklist \
        --text="Change config for prefix: <b>\"${PP_PREFIX_NAME}\"</b>" \
        --column=set --column=dll --column=info < "${PORT_WINE_TMP_PATH}/settings_list_tmp" 1>> "${PORT_WINE_TMP_PATH}/to_winetricks" &

        "${pp_yad_new}" --key=$KEY_EDIT_MANAGER_GUI --notebook --borders=5 --width=700 --height=600 --center \
        --window-icon="$PP_GUI_ICON_PATH/port_proton.png" --title "PREFIX MANAGER..." --tab-pos=bottom --tab="DLL" --tab="FONTS" --tab="SETTINGS"
        YAD_STATUS="$?"
        if [[ "$YAD_STATUS" == "1" || "$YAD_STATUS" == "252" ]] ; then
            stop_portwine
            exit 0
        fi 
        try_remove_file  "${PORT_WINE_TMP_PATH}/dll_list_tmp"
        try_remove_file  "${PORT_WINE_TMP_PATH}/fonts_list_tmp"
        try_remove_file  "${PORT_WINE_TMP_PATH}/settings_list_tmp"

        for STPFXMNG in $(cat "${PORT_WINE_TMP_PATH}/to_winetricks") ; do
            grep $(echo ${STPFXMNG} | awk -F'|' '{print $2}') "${PORT_WINE_PATH}/data/prefixes/${PP_PREFIX_NAME}/winetricks.log" &>/dev/null
            if [ "$?" == "1" ] ; then
                [[ -n "${STPFXMNG}" ]] && SET_FROM_PFX_MANAGER+="$(echo "${STPFXMNG}" | awk -F'|' '{print $2}') "
            fi
        done
        IFS=${old_IFS}
        try_remove_file  "${PORT_WINE_TMP_PATH}/to_winetricks"

        if [[ -n ${SET_FROM_PFX_MANAGER} ]] ; then
            export PP_ADD_TO_ARGS_IN_RUNTIME="--xterm"
            pp_init_runtime
            ${pp_runtime} env PATH="${PATH}" LD_LIBRARY_PATH="${PP_LD_LIBRARY_PATH}" "${PORT_WINE_TMP_PATH}/winetricks" -q -r -f ${SET_FROM_PFX_MANAGER}
            gui_prefix_manager
        else
            print_info "Nothing to do. Restarting PortProton..."
            stop_portwine &
            /usr/bin/env bash -c ${pp_full_command_line[*]} 
        fi
    }
    gui_prefix_manager
}

pp_winetricks () {
    update_winetricks
    export PP_USE_TERMINAL=1
    start_portwine
    pp_stop_progress_bar
    echo "WINETRICKS..." > "${PORT_WINE_TMP_PATH}/update_pfx_log"
    unset PP_TIMER
    while read -r line || [[ -n $(pgrep -a yad | grep "yad_new --text-info --tail --no-buttons --title="WINETRICKS"" | awk '{print $1}') ]] ; do
            sleep 0.005
            if [[ -n "${line}" ]] && [[ -z "$(echo "${line}" | grep -i "gstreamer")" ]] \
                                    && [[ -z "$(echo "${line}" | grep -i "kerberos")" ]] \
                                    && [[ -z "$(echo "${line}" | grep -i "ntlm")" ]]
            then
                echo "# ${line}"
            fi
            if [[ "${PP_TIMER}" != 1 ]] ; then
                sleep 3
                PP_TIMER=1
            fi
    done < "${PORT_WINE_TMP_PATH}/update_pfx_log" | "${pp_yad_new}" --text-info --tail --no-buttons --title="WINETRICKS" \
    --auto-close --skip-taskbar --width=$PP_GIF_SIZE_X --height=$PP_GIF_SIZE_Y &
    "${PORT_WINE_TMP_PATH}/winetricks" -q -r -f &>>"${PORT_WINE_TMP_PATH}/update_pfx_log"
    try_remove_file "${PORT_WINE_TMP_PATH}/update_pfx_log"
    kill -s SIGTERM "$(pgrep -a yad_new | grep "title=WINETRICKS" | awk '{print $1}')" > /dev/null 2>&1    
    stop_portwine
}

pp_start_cont_xterm () {
    cd "$HOME"
    unset PP_SANDBOX_HOME_PATH
    # export PP_ADD_TO_ARGS_IN_RUNTIME="--xterm"
    pp_init_runtime
    ${pp_runtime} xterm
}

pp_create_prefix_backup () {
    cd "$HOME"
    PP_PREFIX_TO_BACKUP=$("${pp_yad_new}" --file --directory --borders=5 --width=650 --height=500 --auto-close --center \
    --window-icon="$PP_GUI_ICON_PATH/port_proton.png" --title "BACKUP PREFIX TO...")
    YAD_STATUS="$?"
    if [[ "$YAD_STATUS" == "1" || "$YAD_STATUS" == "252" ]] ; then exit 0 ; fi
    if [[ -n "$(grep "/${PP_PREFIX_NAME}/" "${PORT_WINE_PATH}"/*.desktop )" ]] ; then
        try_remove_file "${PORT_WINE_PATH}/data/prefixes/${PP_PREFIX_NAME}/.create_shortcut"
        grep "/${PP_PREFIX_NAME}/" "${PORT_WINE_PATH}"/*.desktop | awk -F"/${PP_PREFIX_NAME}/" '{print $2}' \
        | awk -F\" '{print $1}' > "${PORT_WINE_PATH}/data/prefixes/${PP_PREFIX_NAME}/.create_shortcut"
    fi
    unset PP_SANDBOX_HOME_PATH
    export PP_ADD_TO_ARGS_IN_RUNTIME="--xterm"
    pp_init_runtime
    chmod -R u+w "${PORT_WINE_PATH}/data/prefixes/${PP_PREFIX_NAME}"
    ${pp_runtime} env PATH="${PATH}" LD_LIBRARY_PATH="${PP_LD_LIBRARY_PATH}" mksquashfs "${PORT_WINE_PATH}/data/prefixes/${PP_PREFIX_NAME}" "${PP_PREFIX_TO_BACKUP}/${PP_PREFIX_NAME}.ppack.part" -comp zstd &
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
    if [[ -f "${PP_PREFIX_TO_BACKUP}/${PP_PREFIX_NAME}.ppack.part" ]] ; then
        mv -f "${PP_PREFIX_TO_BACKUP}/${PP_PREFIX_NAME}.ppack.part" "${PP_PREFIX_TO_BACKUP}/${PP_PREFIX_NAME}.ppack"
        zenity_info "Backup for prefix \"${PP_PREFIX_NAME}\" successfully created."
    else 
        zenity_error "An error occurred while creating a backup for prefix: \"${PP_PREFIX_NAME}\" !"
    fi
    return 0
}

pp_edit_db () {
    pp_gui_for_edit_db \
    PP_MANGOHUD PP_MANGOHUD_USER_CONF ENABLE_VKBASALT PP_NO_ESYNC PP_NO_FSYNC PP_USE_DXR10 PP_USE_DXR11 \
    PP_USE_NVAPI_AND_DLSS PP_USE_FAKE_DLSS PP_WINE_FULLSCREEN_FSR PP_OLD_GL_STRING PP_HIDE_NVIDIA_GPU PP_FORCE_USE_VSYNC PP_VIRTUAL_DESKTOP \
    PP_WINEDBG_DISABLE PP_USE_TERMINAL PP_WINE_ALLOW_XIM PP_HEAP_DELAY_FREE PP_GUI_DISABLED_CS PP_USE_GSTREAMER \
    PP_USE_GAMEMODE PP_DX12_DISABLE PP_PRIME_RENDER_OFFLOAD PP_USE_D3D_EXTRAS PP_FIX_VIDEO_IN_GAME PP_USE_AMDVLK_DRIVER \
    PP_FORCE_LARGE_ADDRESS_AWARE PP_USE_SHADER_CACHE 
    if [ "$?" == 0 ] ; then
        /usr/bin/env bash -c ${pp_full_command_line[*]} &
        exit 0
    fi
}

pp_autoinstall_from_db () {
    export PP_USER_TEMP="${PORT_WINE_TMP_PATH}"
    export PP_FORCE_LARGE_ADDRESS_AWARE=0
    export PP_USE_GAMEMODE=0
    export PP_CHECK_AUTOINSTAL=1
    export PP_GUI_DISABLED_CS=1
    export PP_WINEDBG_DISABLE=1
    export PP_NO_WRITE_WATCH=0
    export PP_VULKAN_USE=0
    export PP_NO_FSYNC=1
    export PP_NO_ESYNC=1
    unset PORTWINE_CREATE_SHORTCUT_NAME
    export PP_DISABLED_CREATE_DB=1
    export PP_MANGOHUD=0
    export ENABLE_VKBASALT=0
    export PP_USE_D3D_EXTRAS=1
    . "${PORT_SCRIPTS_PATH}/pp_autoinstall/${PP_YAD_SET}"
}

gui_credits () {
    . "${PORT_SCRIPTS_PATH}/credits"
}
export -f gui_credits

###MAIN###
PP_PREFIX_NAME="$(echo "${PP_PREFIX_NAME}" | sed -e s/[[:blank:]]/_/g)"
PP_ALL_PREFIXES=$(ls "${PORT_WINE_PATH}/data/prefixes/" | sed -e s/"${PP_PREFIX_NAME}$"//g)
export PP_PREFIX_NAME PP_ALL_PREFIXES

# if [[ -n "${PORTWINE_DB}" ]] && [[ -z `echo "${PP_PREFIX_NAME}" | grep -i "$(echo "${PORTWINE_DB}" | sed -e s/[[:blank:]]/_/g)"` ]] ; then 
#     export PP_PREFIX_NAME="${PP_PREFIX_NAME}!`echo "${PORTWINE_DB}" | sed -e s/[[:blank:]]/_/g`"
# fi

unset PP_ADD_PREFIXES_TO_GUI
IFS_OLD=$IFS
IFS=$'\n'
for PAIG in ${PP_ALL_PREFIXES[*]} ; do 
    [[ "${PAIG}" != $(echo "${PORTWINE_DB^^}" | sed -e s/[[:blank:]]/_/g) ]] && \
    export PP_ADD_PREFIXES_TO_GUI="${PP_ADD_PREFIXES_TO_GUI}!${PAIG}"
done
IFS=$IFS_OLD
export PP_ADD_PREFIXES_TO_GUI="${PP_PREFIX_NAME^^}${PP_ADD_PREFIXES_TO_GUI}"

PP_ALL_DIST=$(ls "${PORT_WINE_PATH}/data/dist/" | sed -e s/"${PP_PROTON_GE_VER}$//g" | sed -e s/"${PP_PROTON_LG_VER}$//g")
unset DIST_ADD_TO_GUI
for DAIG in ${PP_ALL_DIST}
do
    export DIST_ADD_TO_GUI="${DIST_ADD_TO_GUI}!${DAIG}"
done
if [[ -n "${PORTWINE_DB_FILE}" ]] ; then
    [[ -z "${PP_COMMENT_DB}" ]] && PP_COMMENT_DB="PortWINE database file for "\"${PORTWINE_DB}"\" was found."
    if [[ -z "${PP_VULKAN_USE}" || -z "${PP_WINE_USE}" ]] ; then
        unset PP_GUI_DISABLED_CS
        [[ -z "${PP_VULKAN_USE}" ]] && export PP_VULKAN_USE=1
    fi
    case "${PP_VULKAN_USE}" in
            "0") export PP_DEFAULT_VULKAN_USE='OPENGL!VULKAN (DXVK and VKD3D)!VULKAN (WINE DXGI)!GALLIUM_NINE (native DX9 on MESA)' ;;
            "2") export PP_DEFAULT_VULKAN_USE='VULKAN (WINE DXGI)!VULKAN (DXVK and VKD3D)!OPENGL!GALLIUM_NINE (native DX9 on MESA)' ;;
            "3") export PP_DEFAULT_VULKAN_USE='GALLIUM_NINE (native DX9 on MESA)!VULKAN (DXVK and VKD3D)!VULKAN (WINE DXGI)!OPENGL' ;;
              *) export PP_DEFAULT_VULKAN_USE='VULKAN (DXVK and VKD3D)!VULKAN (WINE DXGI)!OPENGL!GALLIUM_NINE (native DX9 on MESA)' ;;
    esac
    if [[ -n $(echo "${PP_WINE_USE}" | grep "^PROTON_LG$") ]] ; then
        export PP_DEFAULT_WINE_USE="${PP_PROTON_LG_VER}!${PP_PROTON_GE_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
    elif [[ -n $(echo "${PP_WINE_USE}" | grep "^PROTON_GE$") ]] ; then
        export PP_DEFAULT_WINE_USE="${PP_PROTON_GE_VER}!${PP_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
    else
        if [[ "${PP_WINE_USE}" == "${PP_PROTON_LG_VER}" ]] ; then
            export PP_DEFAULT_WINE_USE="${PP_WINE_USE}!${PP_PROTON_GE_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE" 
        elif [[ "${PP_WINE_USE}" == "${PP_PROTON_GE_VER}" ]] ; then
            export PP_DEFAULT_WINE_USE="${PP_WINE_USE}!${PP_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE" 
        else
            export DIST_ADD_TO_GUI=$(echo "${DIST_ADD_TO_GUI}" | sed -e s/"\!${PP_WINE_USE}$//g")
            export PP_DEFAULT_WINE_USE="${PP_WINE_USE}!${PP_PROTON_GE_VER}!${PP_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
        fi
    fi
else
    export PP_DEFAULT_VULKAN_USE='VULKAN (DXVK and VKD3D)!VULKAN (WINE DXGI)!OPENGL!GALLIUM_NINE (native DX9 on MESA)'
    if [[ -n $(echo "${PP_WINE_USE}" | grep "^PROTON_LG$") ]] ; then
        export PP_DEFAULT_WINE_USE="${PP_PROTON_LG_VER}!${PP_PROTON_GE_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
    elif [[ -n $(echo "${PP_WINE_USE}" | grep "^PROTON_GE$") ]] ; then
        export PP_DEFAULT_WINE_USE="${PP_PROTON_GE_VER}!${PP_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
    else
        if [[ "${PP_WINE_USE}" == "${PP_PROTON_LG_VER}" ]] ; then
            export PP_DEFAULT_WINE_USE="${PP_WINE_USE}!${PP_PROTON_GE_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE" 
        elif [[ "${PP_WINE_USE}" == "${PP_PROTON_GE_VER}" ]] ; then
            export PP_DEFAULT_WINE_USE="${PP_WINE_USE}!${PP_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE" 
        else
            export DIST_ADD_TO_GUI=$(echo "${DIST_ADD_TO_GUI}" | sed -e s/"\!${PP_WINE_USE}$//g")
            export PP_DEFAULT_WINE_USE="${PP_WINE_USE}!${PP_PROTON_GE_VER}!${PP_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
        fi     
    fi
    unset PP_GUI_DISABLED_CS
fi
if [ -n "${portwine_exe}" ]; then
    if [[ -z "${PP_GUI_DISABLED_CS}" || "${PP_GUI_DISABLED_CS}" == 0 ]] ; then  
        pp_create_gui_png
        grep -il "${portwine_exe}" "${HOME}/.local/share/applications"/*.desktop
        if [[ "$?" != "0" ]] ; then
            PP_SHORTCUT="CREATE SHORTCUT!!${loc_create_shortcut}:100"
        else
            PP_SHORTCUT="DELETE SHORTCUT!!${loc_delete_shortcut}:98"
        fi
        OUTPUT_START=$("${pp_yad}" --text-align=center --text "$PP_COMMENT_DB" --wrap-width=150 --borders=7 --form --center  \
        --title "${portname}-${install_ver} (${scripts_install_ver})"  --image "${PP_ICON_FOR_YAD}" --separator=";" \
        --window-icon="$PP_GUI_ICON_PATH/port_proton.png" \
        --field="3D API  : :CB" "${PP_DEFAULT_VULKAN_USE}" \
        --field="  WINE  : :CB" "${PP_DEFAULT_WINE_USE}" \
        --field="PREFIX  : :CBE" "${PP_ADD_PREFIXES_TO_GUI}" \
        --field=":LBL" "" \
        --button='VKBASALT'!!"${ENABLE_VKBASALT_INFO}":120 \
        --button='EDIT  DB'!!"${loc_edit_db} ${PORTWINE_DB}":118 \
        --button="${PP_SHORTCUT}" \
        --button='DEBUG'!!"${loc_debug}":102 \
        --button='LAUNCH'!!"${loc_launch}":106 )
        export PP_YAD_SET="$?"
        if [[ "$PP_YAD_SET" == "1" || "$PP_YAD_SET" == "252" ]] ; then exit 0 ; fi
        export VULKAN_MOD=$(echo "${OUTPUT_START}" | grep \;\; | awk -F";" '{print $1}')
        export PP_WINE_VER=$(echo "${OUTPUT_START}" | grep \;\; | awk -F";" '{print $2}')
        export PP_PREFIX_NAME=$(echo "${OUTPUT_START}" | grep \;\; | awk -F";" '{print $3}' | sed -e s/[[:blank:]]/_/g)
        if [[ -z "${PP_PREFIX_NAME}" ]] || [[ -n "$(echo "${PP_PREFIX_NAME}" | grep -E '^_.*' )" ]] ; then
            export PP_PREFIX_NAME="DEFAULT"
        else
            export PP_PREFIX_NAME="${PP_PREFIX_NAME^^}"
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

    gui_clear_pfx () {
        if gui_question "${port_clear_pfx}" ; then
            pp_clear_pfx
            /usr/bin/env bash -c ${pp_full_command_line[*]} &
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

    gui_pp_update () {
        try_remove_file "${PORT_WINE_TMP_PATH}/scripts_update_notifier"
        /usr/bin/env bash -c ${pp_full_command_line[*]} &
        exit 0
    }

    gui_wine_uninstaller () {
        start_portwine
        pp_run uninstaller
    }
    export -f gui_wine_uninstaller

    gui_open_user_conf () {
        xdg-open "${PORT_WINE_PATH}/data/user.conf"
    }
    export -f gui_open_user_conf

    gui_open_scripts_from_backup () {
        cd "${PORT_WINE_TMP_PATH}/scripts_backup/"
        PP_SCRIPT_FROM_BACKUP=$("${pp_yad_new}" --file --borders=5 --width=650 --height=500 --auto-close --center \
        --window-icon="$PP_GUI_ICON_PATH/port_proton.png" --title "SCRIPTS FROM BACKUP" --file-filter="backup_scripts|scripts_v*.tar.gz")
        YAD_STATUS="$?"
        if [[ "$YAD_STATUS" == "1" || "$YAD_STATUS" == "252" ]] ; then exit 0 ; fi
        unpack_tar_gz "$PP_SCRIPT_FROM_BACKUP" "${PORT_WINE_PATH}/data/"
        echo "0" > "${PORT_WINE_TMP_PATH}/scripts_update_notifier"
        /usr/bin/env bash -c ${pp_full_command_line[*]} &
        exit 0
    }
    export -f gui_open_scripts_from_backup

    export KEY=$RANDOM
    "${pp_yad_new}" --plug=${KEY} --tabnum=4 --columns=3 --align-buttons --form --separator=";" \
    --field="   $loc_gui_rm_pp"!""!"":"FBTN" '@bash -c "button_click gui_rm_portproton"' \
    --field="   $loc_gui_upd_pp"!""!"":"FBTN" '@bash -c "button_click gui_pp_update"' \
    --field="   $loc_gui_changelog"!""!"":"FBTN" '@bash -c "button_click open_changelog"' \
    --field="   $loc_gui_edit_usc"!""!"":"FBTN" '@bash -c "button_click gui_open_user_conf"' \
    --field="   $loc_gui_scripts_fb"!""!"":"FBTN" '@bash -c "button_click gui_open_scripts_from_backup"' \
    --field="   Xterm"!""!"":"FBTN" '@bash -c "button_click pp_start_cont_xterm"' \
    --field="   $loc_gui_credits"!""!"":"FBTN" '@bash -c "button_click gui_credits"' &

    "${pp_yad_new}" --plug=${KEY} --tabnum=3 --columns=3 --align-buttons --form --separator=";" \
    --field="  3D API  : :CB" "VULKAN (DXVK and VKD3D)!VULKAN (WINE DXGI)!OPENGL!GALLIUM_NINE (native DX9 on MESA)" \
    --field="  PREFIX  : :CBE" "${PP_ADD_PREFIXES_TO_GUI}" \
    --field="  WINE    : :CB" "${PP_DEFAULT_WINE_USE}" \
    --field="                    DOWNLOAD OTHER WINE "!"${loc_download_other_wine}":"FBTN" '@bash -c "button_click gui_proton_downloader"' \
    --field='   WINECFG'!""!"${loc_winecfg}":"FBTN" '@bash -c "button_click WINECFG"' \
    --field='   WINEFILE'!""!"${loc_winefile}":"FBTN" '@bash -c "button_click WINEFILE"' \
    --field='   WINECMD'!""!"${loc_winecmd}":"FBTN" '@bash -c "button_click WINECMD"' \
    --field='   WINEREG'!""!"${loc_winereg}":"FBTN" '@bash -c "button_click WINEREG"' \
    --field='   WINETRICKS'!""!"${loc_winetricks}":"FBTN" '@bash -c "button_click WINETRICKS"' \
    --field="   WINE UNINSTALLER"!""!"":"FBTN" '@bash -c "button_click gui_wine_uninstaller"' \
    --field="   CLEAR PREFIX"!""!"":"FBTN" '@bash -c "button_click gui_clear_pfx"' \
    --field="   CREATE PFX BACKUP"!""!"":"FBTN" '@bash -c "button_click pp_create_prefix_backup"' &> "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" &

    "${pp_yad_new}" --plug=$KEY --tabnum=2 --form --columns=3 --align-buttons --keep-icon-size --scroll  \
    --field="   Dolphin 5.0"!"$PP_GUI_ICON_PATH/dolphin.png"!"":"FBTN" '@bash -c "button_click PP_DOLPHIN"' \
    --field="   MAME"!"$PP_GUI_ICON_PATH/mame.png"!"":"FBTN" '@bash -c "button_click PP_MAME"' \
    --field="   ScummVM"!"$PP_GUI_ICON_PATH/scummvm.png"!"":"FBTN" '@bash -c "button_click PP_SCUMMVM"' \
    --field="   RetroArch"!"$PP_GUI_ICON_PATH/retroarch.png"!"":"FBTN" '@bash -c "button_click PP_RETROARCH"' \
    --field="   PPSSPP Windows"!"$PP_GUI_ICON_PATH/ppsspp.png"!"":"FBTN" '@bash -c "button_click PP_PPSSPP"' \
    --field="   Citra"!"$PP_GUI_ICON_PATH/citra.png"!"":"FBTN" '@bash -c "button_click PP_CITRA"' \
    --field="   Cemu"!"$PP_GUI_ICON_PATH/cemu.png"!"":"FBTN" '@bash -c "button_click PP_CEMU"' \
    --field="   DuckStation"!"$PP_GUI_ICON_PATH/duckstation.png"!"":"FBTN" '@bash -c "button_click PP_DUCKSTATION"' \
    --field="   ePSXe"!"$PP_GUI_ICON_PATH/epsxe.png"!"":"FBTN" '@bash -c "button_click PP_EPSXE"' \
    --field="   Project64"!"$PP_GUI_ICON_PATH/project64.png"!"":"FBTN" '@bash -c "button_click PP_PROJECT64"' \
    --field="   VBA-M"!"$PP_GUI_ICON_PATH/vba-m.png"!"":"FBTN" '@bash -c "button_click PP_VBA-M"' \
    --field="   Yabause"!"$PP_GUI_ICON_PATH/yabause.png"!"":"FBTN" '@bash -c "button_click PP_YABAUSE"' &

    "${pp_yad_new}" --plug=$KEY --tabnum=1 --form --columns=3 --align-buttons --keep-icon-size --scroll \
    --field="   Wargaming Game Center"!"$PP_GUI_ICON_PATH/wgc.png"!"":"FBTN" '@bash -c "button_click PP_WGC"' \
    --field="   Battle.net Launcher"!"$PP_GUI_ICON_PATH/battle_net.png"!"":"FBTN" '@bash -c "button_click PP_BATTLE_NET"' \
    --field="   Epic Games Launcher"!"$PP_GUI_ICON_PATH/epicgames.png"!"":"FBTN" '@bash -c "button_click PP_EPIC"' \
    --field="   GoG Galaxy Launcher"!"$PP_GUI_ICON_PATH/gog.png"!"":"FBTN" '@bash -c "button_click PP_GOG"' \
    --field="   Ubisoft Game Launcher"!"$PP_GUI_ICON_PATH/ubc.png"!"":"FBTN" '@bash -c "button_click PP_UBC"' \
    --field="   EVE Online Launcher"!"$PP_GUI_ICON_PATH/eve.png"!"":"FBTN" '@bash -c "button_click PP_EVE"' \
    --field="   Origin Launcher"!"$PP_GUI_ICON_PATH/origin.png"!"":"FBTN" '@bash -c "button_click PP_ORIGIN"' \
    --field="   Rockstar Games Launcher"!"$PP_GUI_ICON_PATH/Rockstar.png"!"":"FBTN" '@bash -c "button_click PP_ROCKSTAR"' \
    --field="   My.Games Launcher"!"$PP_GUI_ICON_PATH/mygames.png"!"":"FBTN" '@bash -c "button_click PP_MYGAMES"' \
    --field="   Ankama Launcher"!"$PP_GUI_ICON_PATH/ankama.png"!"":"FBTN" '@bash -c "button_click PP_ANKAMA"' \
    --field="   OSU"!"$PP_GUI_ICON_PATH/osu.png"!"":"FBTN" '@bash -c "button_click PP_OSU"' \
    --field="   League of Legends"!"$PP_GUI_ICON_PATH/lol.png"!"":"FBTN" '@bash -c "button_click PP_LOL"' \
    --field="   Gameforge Client"!"$PP_GUI_ICON_PATH/gameforge.png"!"":"FBTN" '@bash -c "button_click  PP_GAMEFORGE"' \
    --field="   World of Sea Battle (BETA)"!"$PP_GUI_ICON_PATH/wosb.png"!"":"FBTN" '@bash -c "button_click PP_WOSB"' \
    --field="   ITCH.IO"!"$PP_GUI_ICON_PATH/itch.png"!"":"FBTN" '@bash -c "button_click PP_ITCH"' & 

    # --field="   Steam Client Launcher"!"$PP_GUI_ICON_PATH/steam.png"!"":"FBTN" '@bash -c "button_click PP_STEAM"'
    # --field="   Bethesda.net Launcher"!"$PP_GUI_ICON_PATH/bethesda.png"!"":"FBTN" '@bash -c "button_click PP_BETHESDA"'

    "${pp_yad_new}" --key=$KEY --notebook --borders=5 --width=900 --height=235 --no-buttons --auto-close --center \
    --window-icon="$PP_GUI_ICON_PATH/port_proton.png" --title "${portname}-${install_ver} (${scripts_install_ver})" \
    --tab-pos=bottom --tab=" $loc_mg_autoinstall"!""!"" --tab=" $loc_mg_emulators"!""!"" --tab=" $loc_mg_wine_settings"!""!"" --tab=" $loc_mg_portproton_settings"!""!""
    YAD_STATUS="$?"
    if [[ "$YAD_STATUS" == "1" || "$YAD_STATUS" == "252" ]] ; then exit 0 ; fi

    if [[ -f "${PORT_WINE_TMP_PATH}/tmp_yad_form" ]]; then
        export PP_YAD_SET=$(cat "${PORT_WINE_TMP_PATH}/tmp_yad_form" | head -n 1 | awk '{print $1}')
        try_remove_file "${PORT_WINE_TMP_PATH}/tmp_yad_form"
    fi
    if [[ -f "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" ]] ; then
        export VULKAN_MOD=$(cat "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" | grep \;\;  | awk -F";" '{print $1}')
        export PP_PREFIX_NAME=$(cat "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" | grep \;\;  | awk -F";" '{print $2}' | sed -e "s/[[:blank:]]/_/g" )
        export PP_WINE_VER=$(cat "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" | grep \;\; | awk -F";" '{print $3}')
        if [[ -z "${PP_PREFIX_NAME}" ]] || [[ -n "$(echo "${PP_PREFIX_NAME}" | grep -E '^_.*' )" ]] ; then
            export PP_PREFIX_NAME="DEFAULT"
        else
            export PP_PREFIX_NAME="${PP_PREFIX_NAME^^}"
        fi
        try_remove_file "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan"
    fi
    export PP_DISABLED_CREATE_DB=1
fi

if [[ -n "${VULKAN_MOD}" && "${VULKAN_MOD}" = "OPENGL" ]] 
then export PP_VULKAN_USE="0"
elif [[ -n "${VULKAN_MOD}" && "${VULKAN_MOD}" = "VULKAN (DXVK and VKD3D)" ]] 
then export PP_VULKAN_USE="1"
elif [[ -n "${VULKAN_MOD}" && "${VULKAN_MOD}" = "VULKAN (WINE DXGI)" ]] 
then export PP_VULKAN_USE="2"
elif [[ -n "${VULKAN_MOD}" && "${VULKAN_MOD}" = "GALLIUM_NINE (native DX9 on MESA)" ]] 
then export PP_VULKAN_USE="3"
fi

init_wine_ver

if [[ -z "${PP_DISABLED_CREATE_DB}" ]] ; then
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
    edit_db_from_gui PP_VULKAN_USE PP_WINE_USE PP_PREFIX_NAME 
fi

case "$PP_YAD_SET" in
    1|252) exit 0 ;;
    98) portwine_delete_shortcut ;;
    100) portwine_create_shortcut ;;
    DEBUG|102) portwine_start_debug ;;
    106) portwine_launch ;;
    WINECFG|108) pp_winecfg ;;
    WINEFILE|110) pp_winefile ;;
    WINECMD|112) pp_winecmd ;;
    WINEREG|114) pp_winereg ;;
    WINETRICKS|116) pp_prefix_manager ;;
    118) pp_edit_db ;;
    gui_clear_pfx) gui_clear_pfx ;;
    gui_open_user_conf) gui_open_user_conf ;;
    gui_wine_uninstaller) gui_wine_uninstaller ;;
    gui_rm_portproton) gui_rm_portproton ;;
    gui_pp_update) gui_pp_update ;;
    gui_proton_downloader) gui_proton_downloader ;;
    gui_open_scripts_from_backup) gui_open_scripts_from_backup ;;
    open_changelog) open_changelog ;;
    120) gui_vkBasalt ;;
    pp_create_prefix_backup) pp_create_prefix_backup ;;
    gui_credits) gui_credits ;;
    pp_start_cont_xterm) pp_start_cont_xterm ;;
    PP_*) pp_autoinstall_from_db ;;
esac

stop_portwine
