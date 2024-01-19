#!/usr/bin/env bash
# Author: linux-gaming.ru

export NO_AT_BRIDGE=1
export pw_full_command_line=("$0" $*)
MISSING_DESKTOP_FILE=0

if [[ -f "$1" ]] ; then
    export portwine_exe="$1"
elif [[ "$1" == *.exe ]] ; then
    export portwine_exe="$1"
    MISSING_DESKTOP_FILE=1
fi
. "$(dirname $(readlink -f "$0"))/runlib"
kill_portwine
killall -15 yad_v12_3 2>/dev/null
kill -TERM `pgrep -a yad | grep ${portname} | head -n 1 | awk '{print $1}'` 2>/dev/null

if [[ -f "/usr/bin/portproton" ]] && [[ -f "${HOME}/.local/share/applications/PortProton.desktop" ]] ; then
    /usr/bin/env bash "/usr/bin/portproton" "$@" & 
    exit 0
fi

[[ "$MISSING_DESKTOP_FILE" == 1 ]] && portwine_missing_shortcut

if [[ -f "${PORT_WINE_TMP_PATH}/tmp_main_gui_size" ]] && [[ ! -z "$(cat ${PORT_WINE_TMP_PATH}/tmp_main_gui_size)" ]] ; then
    export PW_MAIN_SIZE_W="$(cat ${PORT_WINE_TMP_PATH}/tmp_main_gui_size | awk '{print $1}')"
    export PW_MAIN_SIZE_H="$(cat ${PORT_WINE_TMP_PATH}/tmp_main_gui_size | awk '{print $2}')"
else
    export PW_MAIN_SIZE_W="1100"
    export PW_MAIN_SIZE_H="300"
fi    

if [[ ! -z $(basename "${portwine_exe}" | grep .ppack) ]] ; then
    export PW_ADD_TO_ARGS_IN_RUNTIME="--xterm"
    unset PW_SANDBOX_HOME_PATH
    pw_init_runtime
    export PW_PREFIX_NAME=$(basename "$1" | awk -F'.' '{print $1}')
    ${pw_runtime} env PATH="${PATH}" LD_LIBRARY_PATH="${PW_LD_LIBRARY_PATH}" unsquashfs -f -d "${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}" "$1" &
    sleep 10
    while true ; do
        if [[ ! -z $(pgrep -a xterm | grep ".ppack" | head -n 1 | awk '{print $1}') ]] ; then
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
    if [[ ! -z "${PW_VIRTUAL_DESKTOP}" && "${PW_VIRTUAL_DESKTOP}" == "1" ]] ; then
        pw_screen_resolution=$(xrandr --current | grep "*" | awk '{print $1;}' | head -1)
        pw_run explorer "/desktop=PortProton,${pw_screen_resolution}" ${WINE_WIN_START} "$portwine_exe"
    elif [ ! -z "${PORTWINE_MSI}" ]; then
        pw_run msiexec /i "$portwine_exe"
    elif [[ ! -z "${PORTWINE_BAT}" || -n "${portwine_exe}" ]] ; then
        pw_run ${WINE_WIN_START} "$portwine_exe"
    else
        pw_run winefile
    fi
}

portwine_start_debug () {
    kill_portwine
    export PW_LOG=1
    export PW_WINEDBG_DISABLE=0
    if [[ -z "$VULKAN_DRIVER_NAME" ]] || [[ "$VULKAN_DRIVER_NAME" == "llvmpipe" ]] ; then
	zenity_info "Attention working version of vulkan not detected!\nIt is recommended to run games in OpenGL (low performance possible)!"
    fi
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
    if [ ! -z "${portwine_exe}" ] ; then
        echo "Debug for programm:" >> "${PORT_WINE_PATH}/${portname}.log"
        echo "${portwine_exe}" >> "${PORT_WINE_PATH}/${portname}.log"
        echo "---------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    echo "GLIBC version:" >> "${PORT_WINE_PATH}/${portname}.log"
    echo $(ldd --version | grep -m1 ldd | awk '{print $NF}') >> "${PORT_WINE_PATH}/${portname}.log"
    echo "--------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    if [[ "${PW_VULKAN_USE}" = "0" ]] ; then 
        echo "PW_VULKAN_USE=${PW_VULKAN_USE} - DX9-11 to ${loc_gui_open_gl}" >> "${PORT_WINE_PATH}/${portname}.log"
    elif [[ "${PW_VULKAN_USE}" = "1" ]] ; then
        echo "PW_VULKAN_USE=${PW_VULKAN_USE} - DXVK v.${DXVK_STABLE_VER} and VKD3D-PROTON v.${VKD3D_STABLE_VER}" >> "${PORT_WINE_PATH}/${portname}.log"
    elif [[ "${PW_VULKAN_USE}" = "2" ]] ; then
        echo "PW_VULKAN_USE=${PW_VULKAN_USE} - DXVK v.${DXVK_GIT_VER} and VKD3D-PROTON v.${VKD3D_GIT_VER}" >> "${PORT_WINE_PATH}/${portname}.log"
    elif [[ "${PW_VULKAN_USE}" = "3" ]] ; then 
        echo "PW_VULKAN_USE=${PW_VULKAN_USE} - native DX9 on MESA drivers" >> "${PORT_WINE_PATH}/${portname}.log"
    elif [[ "${PW_VULKAN_USE}" = "4" ]] ; then
        echo "PW_VULKAN_USE=${PW_VULKAN_USE} - DirectX to wined3d vulkan" >> "${PORT_WINE_PATH}/${portname}.log"
    else 
        echo "PW_VULKAN_USE=${PW_VULKAN_USE}" >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    echo "--------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Version WINE in use:" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "$PW_WINE_USE" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "-------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Program bit depth:" >> "${PORT_WINE_PATH}/${portname}.log"
    if [[ $(file "$portwine_exe") =~ x86-64 ]]; then
        echo "64 bit" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "-----------------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    else
        echo "32 bit" >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    echo "--------------------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Date and time of start debug for ${portname}:" >> "${PORT_WINE_PATH}/${portname}.log"
    date >> "${PORT_WINE_PATH}/${portname}.log"
    echo "-----------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "The installation path of the ${portname}:" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "$PORT_WINE_PATH" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "------------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Operating system:" >> "${PORT_WINE_PATH}/${portname}.log"
    cat /etc/os-release | grep -oP 'PRETTY_NAME="\K[^"]+' >> "${PORT_WINE_PATH}/${portname}.log"
    echo "--------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Desktop environment:" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Desktop session: ${DESKTOP_SESSION}" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Current desktop: ${XDG_CURRENT_DESKTOP}" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Session type: ${XDG_SESSION_TYPE}" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "---------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Kernel:" >> "${PORT_WINE_PATH}/${portname}.log"
    uname -r >> "${PORT_WINE_PATH}/${portname}.log"
    echo "-------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "CPU:" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "CPU physical cores:$(cat /proc/cpuinfo | grep 'cpu cores' | sort -u | cut -d':' -f2)" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "CPU logical cores: $(cat /proc/cpuinfo | grep 'processor' | wc -l)" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "CPU model name:$(cat /proc/cpuinfo | grep 'model name' | sort -u | cut -d':' -f2)" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "RAM:" >> "${PORT_WINE_PATH}/${portname}.log"
    free -m >> "${PORT_WINE_PATH}/${portname}.log"
    echo "-----------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Graphic cards and drivers:" >> "${PORT_WINE_PATH}/${portname}.log"
    echo 'lspci -k | grep -EA3 VGA|3D|Display :' >> "${PORT_WINE_PATH}/${portname}.log"
    echo "$(lspci -k | grep -EA3 'VGA|3D|Display')" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "----" >> "${PORT_WINE_PATH}/${portname}.log"
    [[ `command -v glxinfo` ]] && glxinfo -B >> "${PORT_WINE_PATH}/${portname}.log"
    echo "-----" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "inxi -G:" >> "${PORT_WINE_PATH}/${portname}.log"
    "${PW_WINELIB}/portable/bin/inxi" -Gc0 >> "${PORT_WINE_PATH}/${portname}.log"
    if echo "$LSPCI_VGA" | grep -i nvidia &>/dev/null ; then 
        if command -v ldconfig &>/dev/null ; then
            echo "------" >> "${PORT_WINE_PATH}/${portname}.log"
            echo "ldconfig -p | grep libGLX_nvidia" >> "${PORT_WINE_PATH}/${portname}.log"
            ldconfig -p | grep libGLX_nvidia >> "${PORT_WINE_PATH}/${portname}.log"
        fi
    fi
    echo "----------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "Vulkan info device name:" >> "${PORT_WINE_PATH}/${portname}.log"
    "$PW_VULKANINFO_PORTABLE" 2>/dev/null | grep -E '^GPU|deviceName|driverName' >> "${PORT_WINE_PATH}/${portname}.log"
    "${PW_WINELIB}/portable/bin/vkcube" --c 50
    if [ $? -eq 0 ]; then
        echo "Vulkan cube test passed successfully" >> "${PORT_WINE_PATH}/${portname}.log"
    else
        echo "Vulkan cube test completed with error" >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    echo "----------------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo 'locale:' >> "${PORT_WINE_PATH}/${portname}.log"
    locale >> "${PORT_WINE_PATH}/${portname}.log"
    echo "---" >> "${PORT_WINE_PATH}/${portname}.log"
    echo 'locale -a | grep -i "$(locale | grep -e '^LANG=' | sed 's/LANG=//' | sed  's/\-8//')" :' >> "${PORT_WINE_PATH}/${portname}.log"
    locale -a | grep -i "$(locale | grep -e '^LANG=' | sed 's/LANG=//' | sed  's/\-8//')" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "-------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    if [[ "${PW_USE_D3D_EXTRAS}" != 1 ]]
    then echo "D3D_EXTRAS - disabled" >> "${PORT_WINE_PATH}/${portname}.log"
    else echo "D3D_EXTRAS - enabled" >> "${PORT_WINE_PATH}/${portname}.log"
    fi
    echo "------------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    echo "winetricks.log:" >> "${PORT_WINE_PATH}/${portname}.log"
    cat "${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}/winetricks.log" | sed -e /"^d3dcomp*"/d -e /"^d3dx*"/d >> "${PORT_WINE_PATH}/${portname}.log"
    echo "-----------------------------------------" >> "${PORT_WINE_PATH}/${portname}.log"
    if [ ! -z "${PORTWINE_DB_FILE}" ]; then
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
    while read -r line || [[ ! -z $(pgrep -a yad | grep "yad_v12_3 --text-info --tail --button="STOP":0 --title="DEBUG"" | awk '{print $1}') ]] ; do
            sleep 0.005
            if [[ ! -z "${line}" ]] && [[ -z "$(echo "${line}" | grep -i "kerberos")" ]] \
                                    && [[ -z "$(echo "${line}" | grep -i "ntlm")" ]]
            then
                echo "# ${line}"
            fi
            if [[ "${PW_TIMER}" != 1 ]] ; then
                sleep 3
                PW_TIMER=1
            fi
    done < "${PORT_WINE_PATH}/${portname}.log" | "${pw_yad_v12_3}" --text-info --tail --button="STOP":0 --title="DEBUG" \
    --skip-taskbar --width=800 --height=400 --text "${port_debug}" 2>/dev/null &&
    kill_portwine
    sed -i '/.fx$/d' "${PORT_WINE_PATH}/${portname}.log"
    sed -i '/HACK_does_openvr_work/d' "${PORT_WINE_PATH}/${portname}.log"
    sed -i '/Uploading is disabled/d' "${PORT_WINE_PATH}/${portname}.log"
    sed -i '/dlopen failed - libgamemode.so/d' "${PORT_WINE_PATH}/${portname}.log"
    sed -i '/gamemodeauto: /d' "${PORT_WINE_PATH}/${portname}.log"
    sed -i '/wine: RLIMIT_NICE is <= 20/d' "${PORT_WINE_PATH}/${portname}.log"
    deb_text=$(cat "${PORT_WINE_PATH}/${portname}.log"  | awk '! a[$0]++') 
    echo "$deb_text" > "${PORT_WINE_PATH}/${portname}.log"
    "$pw_yad" --title="${portname}.log" --borders=3 --no-buttons --text-align=center \
    --text-info --show-uri --wrap --width=1200 --height=550  --uri-color=red \
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
        "${pw_yad_v12_3}" --plug=$KEY_EDIT_MANAGER_GUI --tabnum=1 --list --checklist \
        --text="${loc_prefix_manager_comp} <b>\"${PW_PREFIX_NAME}\"</b>, ${loc_prefix_manager_wine} <b>\"${PW_WINE_USE}\"</b>" \
        --column=set --column=dll --column=info < "${PORT_WINE_TMP_PATH}/dll_list_tmp" 1>> "${PORT_WINE_TMP_PATH}/to_winetricks" 2>/dev/null &

        "${pw_yad_v12_3}" --plug=$KEY_EDIT_MANAGER_GUI --tabnum=2 --list --checklist \
        --text="${loc_prefix_manager_font} <b>\"${PW_PREFIX_NAME}\"</b>, ${loc_prefix_manager_wine} <b>\"${PW_WINE_USE}\"</b>" \
        --column=set --column=dll --column=info < "${PORT_WINE_TMP_PATH}/fonts_list_tmp" 1>> "${PORT_WINE_TMP_PATH}/to_winetricks" 2>/dev/null &

        "${pw_yad_v12_3}" --plug=$KEY_EDIT_MANAGER_GUI --tabnum=3 --list --checklist \
        --text="${loc_prefix_manager_conf} <b>\"${PW_PREFIX_NAME}\"</b>" \
        --column=set --column=dll --column=info < "${PORT_WINE_TMP_PATH}/settings_list_tmp" 1>> "${PORT_WINE_TMP_PATH}/to_winetricks" 2>/dev/null &

        "${pw_yad_v12_3}" --key=$KEY_EDIT_MANAGER_GUI --notebook --borders=3 --width=900 --height=800 \
        --window-icon="$PW_GUI_ICON_PATH/port_proton.png" --title "$loc_pm" --tab-pos=bottom --tab="$loc_pm_dlls" --tab="$loc_pm_fonts" --tab="$loc_pm_settings" 2>/dev/null
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
                [[ ! -z "${STPFXMNG}" ]] && SET_FROM_PFX_MANAGER+="$(echo "${STPFXMNG}" | awk -F'|' '{print $2}') "
            fi
        done
        IFS=${old_IFS}
        try_remove_file  "${PORT_WINE_TMP_PATH}/to_winetricks"

        if [[ ! -z ${SET_FROM_PFX_MANAGER} ]] ; then
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
    while read -r line || [[ ! -z $(pgrep -a yad | grep "yad_v12_3 --text-info --tail --no-buttons --title="WINETRICKS"" | awk '{print $1}') ]] ; do
            sleep 0.005
            if [[ ! -z "${line}" ]] && [[ -z "$(echo "${line}" | grep -i "gstreamer")" ]] \
                                    && [[ -z "$(echo "${line}" | grep -i "kerberos")" ]] \
                                    && [[ -z "$(echo "${line}" | grep -i "ntlm")" ]]
            then
                echo "# ${line}"
            fi
            if [[ "${PW_TIMER}" != 1 ]] ; then
                sleep 3
                PW_TIMER=1
            fi
    done < "${PORT_WINE_TMP_PATH}/update_pfx_log" | "${pw_yad_v12_3}" --text-info --tail --no-buttons --title="WINETRICKS" \
    --auto-close --skip-taskbar --width=$PW_GIF_SIZE_X --height=$PW_GIF_SIZE_Y 2>/dev/null &
    "${PORT_WINE_TMP_PATH}/winetricks" -q -r -f &>>"${PORT_WINE_TMP_PATH}/update_pfx_log"
    try_remove_file "${PORT_WINE_TMP_PATH}/update_pfx_log"
    kill -s SIGTERM "$(pgrep -a yad_v12_3 | grep "title=WINETRICKS" | awk '{print $1}')" > /dev/null 2>&1    
    stop_portwine
}

pw_start_cont_xterm () {
    cd "$HOME"
    unset PW_SANDBOX_HOME_PATH
    # export PW_ADD_TO_ARGS_IN_RUNTIME="--xterm"
    pw_init_runtime
    ${pw_runtime} \
    env PATH="${PATH}" \
    LD_LIBRARY_PATH="${PW_LD_LIBRARY_PATH}" \
    LD_PRELOAD="${PW_LD_PRELOAD}" \
    VK_LAYER_PATH="${PW_VK_LAYER_PATH}" \
    VK_INSTANCE_LAYERS="${PW_VK_INSTANCE_LAYERS}" \
    ${PW_GAMEMODERUN_SLR} \
    ${PW_MANGOHUD_SLR} \
    xterm
}

pw_create_prefix_backup () {
    cd "$HOME"
    PW_PREFIX_TO_BACKUP=$("${pw_yad_v12_3}" --file --directory --borders=3 --width=650 --height=500 --auto-close \
    --window-icon="$PW_GUI_ICON_PATH/port_proton.png" --title "$loc_create_pfx_backup_path" 2>/dev/null )
    YAD_STATUS="$?"
    if [[ "$YAD_STATUS" == "1" || "$YAD_STATUS" == "252" ]] ; then exit 0 ; fi
    if [[ ! -z "$(grep "/${PW_PREFIX_NAME}/" "${PORT_WINE_PATH}"/*.desktop )" ]] ; then
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
        if [[ ! -z $(pgrep -a xterm | grep ".ppack.part" | head -n 1 | awk '{print $1}') ]] ; then
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
        zenity_info "$PW_PFX_BACKUP_SUCCESS"
        if [[ ! -f "${PORT_WINE_TMP_PATH}/pfx_backup_info" ]] ; then
            zenity_info "$PW_PFX_BACKUP_INFO"
            echo "1" > "${PORT_WINE_TMP_PATH}/pfx_backup_info"
        fi
    else 
        zenity_error "$PW_PFX_BACKUP_ERROR"
    fi

    return 0
}

pw_edit_db () {
    if [[ "${XDG_SESSION_TYPE}" == "wayland" ]] ; then
        pw_gui_for_edit_db \
        PW_MANGOHUD PW_MANGOHUD_USER_CONF ENABLE_VKBASALT PW_NO_ESYNC PW_NO_FSYNC PW_USE_RAY_TRACING \
        PW_USE_NVAPI_AND_DLSS PW_USE_FAKE_DLSS PW_WINE_FULLSCREEN_FSR PW_HIDE_NVIDIA_GPU PW_VIRTUAL_DESKTOP PW_USE_TERMINAL \
        PW_GUI_DISABLED_CS PW_USE_GAMEMODE PW_USE_D3D_EXTRAS PW_FIX_VIDEO_IN_GAME  \
        PW_USE_GSTREAMER PW_FORCE_LARGE_ADDRESS_AWARE PW_USE_SHADER_CACHE \
        PW_USE_WINE_DXGI PW_USE_EAC_AND_BE PW_USE_SYSTEM_VK_LAYERS PW_USE_OBS_VKCAPTURE PW_USE_GALLIUM_ZINK PW_USE_GAMESCOPE
    else
        pw_gui_for_edit_db \
        PW_MANGOHUD PW_MANGOHUD_USER_CONF ENABLE_VKBASALT PW_NO_ESYNC PW_NO_FSYNC PW_USE_RAY_TRACING \
        PW_USE_NVAPI_AND_DLSS PW_USE_FAKE_DLSS PW_WINE_FULLSCREEN_FSR PW_HIDE_NVIDIA_GPU PW_VIRTUAL_DESKTOP PW_USE_TERMINAL \
        PW_GUI_DISABLED_CS PW_USE_GAMEMODE PW_USE_D3D_EXTRAS PW_FIX_VIDEO_IN_GAME  \
        PW_REDUCE_PULSE_LATENCY PW_USE_US_LAYOUT PW_RESTORE_RESOLUTION PW_USE_GSTREAMER PW_FORCE_LARGE_ADDRESS_AWARE PW_USE_SHADER_CACHE \
        PW_USE_WINE_DXGI PW_USE_EAC_AND_BE PW_USE_SYSTEM_VK_LAYERS PW_USE_OBS_VKCAPTURE PW_USE_GALLIUM_ZINK PW_USE_GAMESCOPE
    fi
    if [[ "$?" == 0 ]] ; then
        print_info "Restarting PP after update ppdb file..."
        /usr/bin/env bash -c ${pw_full_command_line[*]} &
        exit 0
    fi
    # PW_FORCE_USE_VSYNC PW_WINEDBG_DISABLE HEAP_DELAY_FREE
}

pw_autoinstall_from_db () {
    export PW_USER_TEMP="${PORT_WINE_TMP_PATH}"
    export PW_FORCE_LARGE_ADDRESS_AWARE=1
    export PW_USE_GAMEMODE=0
    export PW_CHECK_AUTOINSTAL=1
    export PW_GUI_DISABLED_CS=1
    export PW_WINEDBG_DISABLE=1
    export PW_NO_WRITE_WATCH=0
    export PW_VULKAN_USE=1
    export PW_USE_EAC_AND_BE=0
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

# if [[ ! -z "${PORTWINE_DB}" ]] && [[ -z `echo "${PW_PREFIX_NAME}" | grep -i "$(echo "${PORTWINE_DB}" | sed -e s/[[:blank:]]/_/g)"` ]] ; then 
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

PW_ALL_DIST=$(ls "${PORT_WINE_PATH}/data/dist/" | sed -e s/"${PW_WINE_LG_VER}$//g" | sed -e s/"${PW_PROTON_LG_VER}$//g")
unset DIST_ADD_TO_GUI
for DAIG in ${PW_ALL_DIST}
do
    export DIST_ADD_TO_GUI="${DIST_ADD_TO_GUI}!${DAIG}"
done

# if [[ $VULKAN_API_DRIVER_VERSION == 1.[1-2].* ]]
# then check_variables PW_VULKAN_USE "1"
# else check_variables PW_VULKAN_USE "2"
# fi
check_nvidia_rtx && check_variables PW_VULKAN_USE "2"

case "${PW_VULKAN_USE}" in
    0) export PW_DEFAULT_VULKAN_USE="${loc_gui_open_gl}!${loc_gui_vulkan_stable}!${loc_gui_vulkan_git}!${loc_gui_gallium_nine}" ;;
    1) export PW_DEFAULT_VULKAN_USE="${loc_gui_vulkan_stable}!${loc_gui_vulkan_git}!${loc_gui_open_gl}!${loc_gui_gallium_nine}" ;;
    3) export PW_DEFAULT_VULKAN_USE="${loc_gui_gallium_nine}!${loc_gui_vulkan_stable}!${loc_gui_vulkan_git}!${loc_gui_open_gl}" ;;
    *) export PW_DEFAULT_VULKAN_USE="${loc_gui_vulkan_git}!${loc_gui_vulkan_stable}!${loc_gui_open_gl}!${loc_gui_gallium_nine}" ;;
esac

if [[ ! -z "${PORTWINE_DB_FILE}" ]] ; then
    [[ -z "${PW_COMMENT_DB}" ]] && PW_COMMENT_DB="${loc_gui_db_comments} <b>${PORTWINE_DB}</b>."
    if [[ ! -z $(echo "${PW_WINE_USE}" | grep "^PROTON_LG$") ]] ; then
        export PW_DEFAULT_WINE_USE="${PW_PROTON_LG_VER}!${PW_WINE_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
    elif [[ ! -z $(echo "${PW_WINE_USE}" | grep "^PROTON_GE$") ]] ; then
        export PW_DEFAULT_WINE_USE="${PW_WINE_LG_VER}!${PW_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
    else
        if [[ "${PW_WINE_USE}" == "${PW_PROTON_LG_VER}" ]] ; then
            export PW_DEFAULT_WINE_USE="${PW_WINE_USE}!${PW_WINE_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE" 
        elif [[ "${PW_WINE_USE}" == "${PW_WINE_LG_VER}" ]] ; then
            export PW_DEFAULT_WINE_USE="${PW_WINE_USE}!${PW_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE" 
        else
            export DIST_ADD_TO_GUI=$(echo "${DIST_ADD_TO_GUI}" | sed -e s/"\!${PW_WINE_USE}$//g")
            export PW_DEFAULT_WINE_USE="${PW_WINE_USE}!${PW_WINE_LG_VER}!${PW_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
        fi
    fi
else
    if [[ $PW_WINE_USE == PROTON_LG ]] ; then
        export PW_DEFAULT_WINE_USE="${PW_PROTON_LG_VER}!${PW_WINE_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
    elif [[ $PW_WINE_USE == WINE_*_LG ]] ; then
        export PW_DEFAULT_WINE_USE="${PW_WINE_LG_VER}!${PW_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
    else
        if [[ "${PW_WINE_USE}" == "${PW_PROTON_LG_VER}" ]] ; then
            export PW_DEFAULT_WINE_USE="${PW_WINE_USE}!${PW_WINE_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE" 
        elif [[ "${PW_WINE_USE}" == "${PW_WINE_LG_VER}" ]] ; then
            export PW_DEFAULT_WINE_USE="${PW_WINE_USE}!${PW_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE" 
        else
            export DIST_ADD_TO_GUI=$(echo "${DIST_ADD_TO_GUI}" | sed -e s/"\!${PW_WINE_USE}$//g")
            export PW_DEFAULT_WINE_USE="${PW_WINE_USE}!${PW_WINE_LG_VER}!${PW_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
        fi     
    fi
    unset PW_GUI_DISABLED_CS
fi
if [[ -f "${portwine_exe}" ]] ; then
    if [[ "${PW_GUI_DISABLED_CS}" != 1 ]] ; then 
        pw_create_gui_png
        grep -il "${portwine_exe}" "${HOME}/.local/share/applications"/*.desktop
        if [[ "$?" != "0" ]] ; then
            PW_SHORTCUT="${loc_gui_create_shortcut}!$PW_GUI_ICON_PATH/separator.png!${loc_create_shortcut}:100"
        else
            PW_SHORTCUT="${loc_gui_delete_shortcut}!$PW_GUI_ICON_PATH/separator.png!${loc_delete_shortcut}:98"
        fi
        OUTPUT_START=$("${pw_yad}" --text-align=center --text "$PW_COMMENT_DB" --borders=3 --form \
        --title "${portname}-${install_ver} (${scripts_install_ver})" --image "${PW_ICON_FOR_YAD}" --separator=";" --keep-icon-size \
        --window-icon="$PW_GUI_ICON_PATH/port_proton.png" \
        --field="3D API  : :CB" "${PW_DEFAULT_VULKAN_USE}" \
        --field="  WINE  : :CB" "${PW_DEFAULT_WINE_USE}" \
        --field="PREFIX  : :CBE" "${PW_ADD_PREFIXES_TO_GUI}" \
        --field=":LBL" "" \
        --button="${loc_gui_vkbasalt_start}"!"$PW_GUI_ICON_PATH/separator.png"!"${ENABLE_VKBASALT_INFO}":120 \
        --button="${loc_gui_mh_start}"!"$PW_GUI_ICON_PATH/separator.png"!"${ENABLE_MANGOHUD_INFO}":122 \
        --button="${loc_gui_edit_db_start}"!"$PW_GUI_ICON_PATH/separator.png"!"${loc_edit_db} ${PORTWINE_DB}":118 \
        --button="${PW_SHORTCUT}" \
        --button="${loc_gui_debug}"!"$PW_GUI_ICON_PATH/separator.png"!"${loc_debug}":102 \
        --button="${loc_gui_launch}"!"$PW_GUI_ICON_PATH/separator.png"!"${loc_launch}":106 2>/dev/null)
        export PW_YAD_SET="$?"
        if [[ "$PW_YAD_SET" == "1" || "$PW_YAD_SET" == "252" ]] ; then exit 0 ; fi
        export VULKAN_MOD=$(echo "${OUTPUT_START}" | grep \;\; | awk -F";" '{print $1}')
        export PW_WINE_VER=$(echo "${OUTPUT_START}" | grep \;\; | awk -F";" '{print $2}')
        export PW_PREFIX_NAME=$(echo "${OUTPUT_START}" | grep \;\; | awk -F";" '{print $3}' | sed -e s/[[:blank:]]/_/g)
        if [[ -z "${PW_PREFIX_NAME}" ]] || [[ ! -z "$(echo "${PW_PREFIX_NAME}" | grep -E '^_.*' )" ]] ; then
            export PW_PREFIX_NAME="DEFAULT"
        else
            export PW_PREFIX_NAME="${PW_PREFIX_NAME^^}"
        fi
    elif [[ -f "${PORTWINE_DB_FILE}" ]] ; then
        portwine_launch
    fi
else
    button_click () {
        [[ ! -z "$1" ]] && echo "$1" > "${PORT_WINE_TMP_PATH}/tmp_yad_form"
        if [[ ! -z $(pidof -s yad) ]] || [[ ! -z $(pidof -s yad_v12_3) ]] ; then
            kill -s SIGUSR1 $(pgrep -a yad | grep "\--key=${KEY} \--notebook" | awk '{print $1}') > /dev/null 2>&1
        fi
    }
    export -f button_click

    run_desktop_b_click () {
        [[ ! -z "$1" ]] && echo "$1" > "${PORT_WINE_TMP_PATH}/tmp_yad_form"
        if [[ ! -z $(pidof -s yad) ]] || [[ ! -z $(pidof -s yad_v12_3) ]] ; then
            kill -s SIGUSR1 $(pgrep -a yad | grep "\--key=${KEY} \--notebook" | awk '{print $1}') > /dev/null 2>&1
        fi
        PW_EXEC_FROM_DESKTOP="$(cat "${PORT_WINE_PATH}/${PW_YAD_SET//¬/" "}" | grep Exec | head -n 1 | awk -F"=env " '{print $2}')"

        print_info "Restarting PP after choose desktop file..."
        # stop_portwine
        /usr/bin/env bash -c "${PW_EXEC_FROM_DESKTOP}" &
        exit 0 
    }
    export -f run_desktop_b_click

    gui_clear_pfx () {
        if gui_question "${port_clear_pfx}" ; then
            pw_clear_pfx
            print_info "Restarting PP after clearing prefix..."
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
        print_info "Restarting PP for check update..."
        /usr/bin/env bash -c ${pw_full_command_line[*]} &
        exit 0
    }

    change_loc () {
        try_remove_file "${PORT_WINE_TMP_PATH}/${portname}_loc"
        print_info "Restarting PP for change language..."
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
        PW_SCRIPT_FROM_BACKUP=$("${pw_yad_v12_3}" --file --borders=3 --width=650 --height=500 --auto-close \
        --window-icon="$PW_GUI_ICON_PATH/port_proton.png" --title "SCRIPTS FROM BACKUP" --file-filter="backup_scripts|scripts_v*.tar.gz" 2>/dev/null )
        YAD_STATUS="$?"
        if [[ "$YAD_STATUS" == "1" || "$YAD_STATUS" == "252" ]] ; then exit 0 ; fi
        unpack_tar_gz "$PW_SCRIPT_FROM_BACKUP" "${PORT_WINE_PATH}/data/"
        echo "0" > "${PORT_WINE_TMP_PATH}/scripts_update_notifier"
        print_info "Restarting PP after backup..."
        /usr/bin/env bash -c ${pw_full_command_line[*]} &
        exit 0
    }
    export -f gui_open_scripts_from_backup


    export KEY="$RANDOM"
    
    orig_IFS="$IFS" && IFS=$'\n'
    PW_ALL_DF="$(ls ${PORT_WINE_PATH}/ | grep .desktop | grep -vE '(PortProton|readme)')"
    if [[ -z "${PW_ALL_DF}" ]]
    then PW_GUI_SORT_TABS=(1 2 3 4 5)
    else PW_GUI_SORT_TABS=(2 3 4 5 1)
    fi  
    PW_GENERATE_BUTTONS="--field=   $loc_create_shortcut_from_gui!${PW_GUI_ICON_PATH}/find_48.png!:FBTN%@bash -c \"button_click pw_find_exe\"%"
    for PW_DESKTOP_FILES in ${PW_ALL_DF} ; do
        PW_NAME_D_ICON="$(cat "${PORT_WINE_PATH}/${PW_DESKTOP_FILES}" | grep Icon | awk -F= '{print $2}')"
        PW_NAME_D_ICON_48="${PW_NAME_D_ICON//".png"/"_48.png"}"
        if [[ ! -f "${PW_NAME_D_ICON_48}" ]]  && [[ -f "${PW_NAME_D_ICON}" ]] && [[ -x "`command -v "convert" 2>/dev/null`" ]] ; then
            convert "${PW_NAME_D_ICON}" -resize 48x48 "${PW_NAME_D_ICON_48}" 
        fi
        PW_GENERATE_BUTTONS+="--field=   ${PW_DESKTOP_FILES//".desktop"/""}!${PW_NAME_D_ICON_48}!:FBTN%@bash -c \"run_desktop_b_click "${PW_DESKTOP_FILES//" "/¬}"\"%"
    done

    IFS="$orig_IFS"
    old_IFS=$IFS && IFS="%"
    "${pw_yad_v12_3}" --plug=$KEY --tabnum=${PW_GUI_SORT_TABS[4]} --form --columns=3 --align-buttons --keep-icon-size --scroll --separator=" " ${PW_GENERATE_BUTTONS} 2>/dev/null &
    IFS="$orig_IFS"

    "${pw_yad_v12_3}" --plug=${KEY} --tabnum=${PW_GUI_SORT_TABS[3]} --form --columns=3 --align-buttons --keep-icon-size --separator=";" \
    --field="   $loc_gui_pw_reinstall_pp"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click gui_pw_reinstall_pp"' \
    --field="   $loc_gui_rm_pp"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click gui_rm_portproton"' \
    --field="   $loc_gui_upd_pp"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click gui_pw_update"' \
    --field="   $loc_gui_changelog"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click open_changelog"' \
    --field="   $loc_gui_change_loc"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click change_loc"' \
    --field="   $loc_gui_edit_usc"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click gui_open_user_conf"' \
    --field="   $loc_gui_scripts_fb"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click gui_open_scripts_from_backup"' \
    --field="   Xterm"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click pw_start_cont_xterm"' \
    --field="   $loc_gui_credits"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click gui_credits"'  2>/dev/null &

    "${pw_yad_v12_3}" --plug=${KEY} --tabnum=${PW_GUI_SORT_TABS[2]} --form --columns=3 --align-buttons --keep-icon-size --separator=";" \
    --field="  3D API  : :CB" "${PW_DEFAULT_VULKAN_USE}" \
    --field="  PREFIX  : :CBE" "${PW_ADD_PREFIXES_TO_GUI}" \
    --field="  WINE    : :CB" "${PW_DEFAULT_WINE_USE}" \
    --field="              $loc_gui_create_pfx_backup"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click pw_create_prefix_backup"' \
    --field="   WINETRICKS"!"$PW_GUI_ICON_PATH/separator.png"!"${loc_winetricks}":"FBTN" '@bash -c "button_click WINETRICKS"' \
    --field="   $loc_gui_clear_pfx"!"$PW_GUI_ICON_PATH/separator.png"!"${loc_clear_pfx}":"FBTN" '@bash -c "button_click gui_clear_pfx"' \
    --field="   $loc_gui_download_other_wine"!"$PW_GUI_ICON_PATH/separator.png"!"${loc_download_other_wine}":"FBTN" '@bash -c "button_click gui_proton_downloader"' \
    --field="   $loc_gui_wine_uninstaller"!"$PW_GUI_ICON_PATH/separator.png"!"${loc_wineuninstaller}":"FBTN" '@bash -c "button_click gui_wine_uninstaller"' \
    --field="   $loc_gui_wine_cfg     "!"$PW_GUI_ICON_PATH/separator.png"!"${loc_winecfg}":"FBTN" '@bash -c "button_click WINECFG"' \
    --field="   $loc_gui_wine_file"!"$PW_GUI_ICON_PATH/separator.png"!"${loc_winefile}":"FBTN" '@bash -c "button_click WINEFILE"' \
    --field="   $loc_gui_wine_cmd"!"$PW_GUI_ICON_PATH/separator.png"!"${loc_winecmd}":"FBTN" '@bash -c "button_click WINECMD"' \
    --field="   $loc_gui_wine_reg"!"$PW_GUI_ICON_PATH/separator.png"!"${loc_winereg}":"FBTN" '@bash -c "button_click WINEREG"' 2>/dev/null 1> "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" &

    "${pw_yad_v12_3}" --plug=$KEY --tabnum=${PW_GUI_SORT_TABS[1]} --form --columns=3 --align-buttons --keep-icon-size --scroll  \
    --field="   Dolphin 5.0"!"$PW_GUI_ICON_PATH/dolphin.png"!"${loc_dolphin}":"FBTN" '@bash -c "button_click PW_DOLPHIN"' \
    --field="   MAME"!"$PW_GUI_ICON_PATH/mame.png"!"${loc_mame}":"FBTN" '@bash -c "button_click PW_MAME"' \
    --field="   ScummVM"!"$PW_GUI_ICON_PATH/scummvm.png"!"${loc_scummvm}":"FBTN" '@bash -c "button_click PW_SCUMMVM"' \
    --field="   RetroArch"!"$PW_GUI_ICON_PATH/retroarch.png"!"${loc_retroarch}":"FBTN" '@bash -c "button_click PW_RETROARCH"' \
    --field="   PPSSPP Windows"!"$PW_GUI_ICON_PATH/ppsspp.png"!"${loc_ppsspp_windows}":"FBTN" '@bash -c "button_click PW_PPSSPP"' \
    --field="   Citra"!"$PW_GUI_ICON_PATH/citra.png"!"${loc_citra}":"FBTN" '@bash -c "button_click PW_CITRA"' \
    --field="   Cemu"!"$PW_GUI_ICON_PATH/cemu.png"!"${loc_cemu}":"FBTN" '@bash -c "button_click PW_CEMU"' \
    --field="   DuckStation"!"$PW_GUI_ICON_PATH/duckstation.png"!"${loc_duckstation}":"FBTN" '@bash -c "button_click PW_DUCKSTATION"' \
    --field="   ePSXe"!"$PW_GUI_ICON_PATH/epsxe.png"!"${loc_epsxe}":"FBTN" '@bash -c "button_click PW_EPSXE"' \
    --field="   Project64"!"$PW_GUI_ICON_PATH/project64.png"!"${loc_project64}":"FBTN" '@bash -c "button_click PW_PROJECT64"' \
    --field="   VBA-M"!"$PW_GUI_ICON_PATH/vba-m.png"!"${loc_vba_m}":"FBTN" '@bash -c "button_click PW_VBA-M"' \
    --field="   Yabause"!"$PW_GUI_ICON_PATH/yabause.png"!"${loc_yabause}":"FBTN" '@bash -c "button_click PW_YABAUSE"' \
    --field="   Xenia"!"$PW_GUI_ICON_PATH/xenia.png"!"${loc_xenia}":"FBTN" '@bash -c "button_click PW_XENIA"' \
    --field="   FCEUX"!"$PW_GUI_ICON_PATH/fceux.png"!"${loc_fceux}":"FBTN" '@bash -c "button_click PW_FCEUX"' \
    --field="   xemu"!"$PW_GUI_ICON_PATH/xemu.png"!"${loc_xemu}":"FBTN" '@bash -c "button_click PW_XEMU"' \
    --field="   Demul"!"$PW_GUI_ICON_PATH/demul.png"!"${loc_demul}":"FBTN" '@bash -c "button_click PW_DEMUL"' \
    --field="   Rpcs3"!"$PW_GUI_ICON_PATH/rpcs3.png"!"${loc_rpcs3}":"FBTN" '@bash -c "button_click PW_RPCS3"' 2>/dev/null &

    "${pw_yad_v12_3}" --plug=$KEY --tabnum=${PW_GUI_SORT_TABS[0]} --form --columns=3 --align-buttons --keep-icon-size --scroll \
    --field="   Lesta Game Center"!"$PW_GUI_ICON_PATH/lgc.png"!"":"FBTN" '@bash -c "button_click PW_LGC"' \
    --field="   vkPlay Games Center"!"$PW_GUI_ICON_PATH/mygames.png"!"":"FBTN" '@bash -c "button_click PW_VKPLAY"' \
    --field="   Battle.net Launcher"!"$PW_GUI_ICON_PATH/battle_net.png"!"":"FBTN" '@bash -c "button_click PW_BATTLE_NET"' \
    --field="   Epic Games Launcher"!"$PW_GUI_ICON_PATH/epicgames.png"!"":"FBTN" '@bash -c "button_click PW_EPIC"' \
    --field="   GoG Galaxy Launcher"!"$PW_GUI_ICON_PATH/gog.png"!"":"FBTN" '@bash -c "button_click PW_GOG"' \
    --field="   Ubisoft Game Launcher"!"$PW_GUI_ICON_PATH/ubc.png"!"":"FBTN" '@bash -c "button_click PW_UBC"' \
    --field="   EVE Online Launcher"!"$PW_GUI_ICON_PATH/eve.png"!"":"FBTN" '@bash -c "button_click PW_EVE"' \
    --field="   Rockstar Games Launcher"!"$PW_GUI_ICON_PATH/Rockstar.png"!"":"FBTN" '@bash -c "button_click PW_ROCKSTAR"' \
    --field="   League of Legends"!"$PW_GUI_ICON_PATH/lol.png"!"":"FBTN" '@bash -c "button_click PW_LOL"' \
    --field="   Gameforge Client"!"$PW_GUI_ICON_PATH/gameforge.png"!"":"FBTN" '@bash -c "button_click  PW_GAMEFORGE"' \
    --field="   World of Sea Battle (x64)"!"$PW_GUI_ICON_PATH/wosb.png"!"":"FBTN" '@bash -c "button_click PW_WOSB"' \
    --field="   CALIBER"!"$PW_GUI_ICON_PATH/caliber.png"!"":"FBTN" '@bash -c "button_click PW_CALIBER"' \
    --field="   Crossout"!"$PW_GUI_ICON_PATH/crossout.png"!"":"FBTN" '@bash -c "button_click PW_CROSSOUT"' \
    --field="   Warframe"!"$PW_GUI_ICON_PATH/warframe.png"!"":"FBTN" '@bash -c "button_click PW_WARFRAME"' \
    --field="   Panzar"!"$PW_GUI_ICON_PATH/panzar.png"!"":"FBTN" '@bash -c "button_click PW_PANZAR"' \
    --field="   STALCRAFT"!"$PW_GUI_ICON_PATH/stalcraft.png"!"":"FBTN" '@bash -c "button_click PW_STALCRAFT"' \
    --field="   CONTRACT WARS"!"$PW_GUI_ICON_PATH/cwc.png"!"":"FBTN" '@bash -c "button_click PW_CWC"' \
    --field="   Stalker Online"!"$PW_GUI_ICON_PATH/so.png"!"":"FBTN" '@bash -c "button_click PW_SO"' \
    --field="   Modern Warships"!"$PW_GUI_ICON_PATH/mw.png"!"":"FBTN" '@bash -c "button_click PW_MW"' \
    --field="   Metal War Online"!"$PW_GUI_ICON_PATH/mwo.png"!"":"FBTN" '@bash -c "button_click PW_MWO"' \
    --field="   Ankama Launcher"!"$PW_GUI_ICON_PATH/ankama.png"!"":"FBTN" '@bash -c "button_click PW_ANKAMA"' \
    --field="   Indiegala Client"!"$PW_GUI_ICON_PATH/igclient.png"!"":"FBTN" '@bash -c "button_click PW_IGCLIENT"' \
    --field="   Plarium Play"!"$PW_GUI_ICON_PATH/plariumplay.png"!"":"FBTN" '@bash -c "button_click PW_PLARIUM_PLAY"' \
    --field="   Wargaming Game Center"!"$PW_GUI_ICON_PATH/wgc.png"!"":"FBTN" '@bash -c "button_click PW_WGC"' \
    --field="   OSU"!"$PW_GUI_ICON_PATH/osu.png"!"":"FBTN" '@bash -c "button_click PW_OSU"' \
    --field="   ITCH.IO"!"$PW_GUI_ICON_PATH/itch.png"!"":"FBTN" '@bash -c "button_click PW_ITCH"' \
    --field="   Steam (unstable)"!"$PW_GUI_ICON_PATH/steam.png"!"":"FBTN" '@bash -c "button_click PW_STEAM"' \
    --field="   Path of Exile"!"$PW_GUI_ICON_PATH/poe.png"!"":"FBTN" '@bash -c "button_click PW_POE"' \
    --field="   Guild Wars 2"!"$PW_GUI_ICON_PATH/gw2.png"!"":"FBTN" '@bash -c "button_click PW_GUILD_WARS_2"' \
    --field="   Genshin Impact"!"$PW_GUI_ICON_PATH/genshinimpact.png"!"":"FBTN" '@bash -c "button_click PW_GENSHIN_IMPACT"' \
    --field="   Battle Of Space Raiders"!"$PW_GUI_ICON_PATH/bsr.png"!"":"FBTN" '@bash -c "button_click PW_BSR"' 2>/dev/null &

    # --field="   Electronic Arts App"!"$PW_GUI_ICON_PATH/eaapp.png"!"":"FBTN" '@bash -c "button_click PW_EAAPP"' 
    # --field="   Secret World Legends (ENG)"!"$PW_GUI_ICON_PATH/swl.png"!"":"FBTN" '@bash -c "button_click PW_SWL"'
    # --field="   Bethesda.net Launcher"!"$PW_GUI_ICON_PATH/bethesda.png"!"":"FBTN" '@bash -c "button_click PW_BETHESDA"'
    # --field="   ROBLOX"!"$PW_GUI_ICON_PATH/roblox.png"!"":"FBTN" '@bash -c "button_click PW_ROBLOX"'

    if  [[ `command -v wmctrl` ]] &>/dev/null ; then
        sleep 2
        while [[ $(pgrep -a yad_v12_3 | head -n 1 | awk '{print $1}' 2>/dev/null) ]] ; do
            sleep 2
            PW_MAIN_GUI_SIZE_TMP="$(wmctrl -lG | grep PortProton-1.0 | awk '{print $5" "$6}' 2>/dev/null)"
            if [[ ! -z "${PW_MAIN_GUI_SIZE_TMP}" ]] ; then
                echo "${PW_MAIN_GUI_SIZE_TMP}" > "${PORT_WINE_TMP_PATH}/tmp_main_gui_size"
            fi
        done
    fi &

    export START_FROM_PP_GUI=1

    if [[ -z "${PW_ALL_DF}" ]] ; then
        "${pw_yad_v12_3}" --key=$KEY --notebook --borders=3 --width="${PW_MAIN_SIZE_W}" --height="${PW_MAIN_SIZE_H}" --no-buttons --auto-close \
        --window-icon="$PW_GUI_ICON_PATH/port_proton.png" --title "${portname}-${install_ver} (${scripts_install_ver})" \
        --tab-pos=bottom --keep-icon-size \
        --tab="$loc_mg_autoinstall"!"$PW_GUI_ICON_PATH/separator.png"!"" \
        --tab="$loc_mg_emulators"!"$PW_GUI_ICON_PATH/separator.png"!"" \
        --tab="$loc_mg_wine_settings"!"$PW_GUI_ICON_PATH/separator.png"!"" \
        --tab="$loc_mg_portproton_settings"!"$PW_GUI_ICON_PATH/separator.png"!"" \
        --tab="$loc_mg_installed"!"$PW_GUI_ICON_PATH/separator.png"!"" 2>/dev/null
        YAD_STATUS="$?"
    else
        "${pw_yad_v12_3}" --key=$KEY --notebook --borders=3 --width="${PW_MAIN_SIZE_W}" --height="${PW_MAIN_SIZE_H}" --no-buttons --auto-close \
        --window-icon="$PW_GUI_ICON_PATH/port_proton.png" --title "${portname}-${install_ver} (${scripts_install_ver})" \
        --tab-pos=bottom --keep-icon-size \
        --tab="$loc_mg_installed"!"$PW_GUI_ICON_PATH/separator.png"!"" \
        --tab="$loc_mg_autoinstall"!"$PW_GUI_ICON_PATH/separator.png"!"" \
        --tab="$loc_mg_emulators"!"$PW_GUI_ICON_PATH/separator.png"!"" \
        --tab="$loc_mg_wine_settings"!"$PW_GUI_ICON_PATH/separator.png"!"" \
        --tab="$loc_mg_portproton_settings"!"$PW_GUI_ICON_PATH/separator.png"!"" 2>/dev/null
        YAD_STATUS="$?"
    fi

    if [[ "$YAD_STATUS" == "1" || "$YAD_STATUS" == "252" ]] ; then exit 0 ; fi

    if [[ -f "${PORT_WINE_TMP_PATH}/tmp_yad_form" ]]; then
        export PW_YAD_SET=$(cat "${PORT_WINE_TMP_PATH}/tmp_yad_form" | head -n 1 | awk '{print $1}')
    fi
    if [[ -f "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" ]] ; then
        export VULKAN_MOD=$(cat "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" | grep \;\;  | awk -F";" '{print $1}')
        export PW_PREFIX_NAME=$(cat "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" | grep \;\;  | awk -F";" '{print $2}' | sed -e "s/[[:blank:]]/_/g" )
        export PW_WINE_VER=$(cat "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" | grep \;\; | awk -F";" '{print $3}')
        if [[ -z "${PW_PREFIX_NAME}" ]] || [[ ! -z "$(echo "${PW_PREFIX_NAME}" | grep -E '^_.*' )" ]] ; then
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

if [[ "${PW_DISABLED_CREATE_DB}" != 1 ]] ; then
    if [[ ! -z "${PORTWINE_DB}" ]] && [[ -z "${PORTWINE_DB_FILE}" ]] ; then
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

[ ! -z "$PW_YAD_SET" ] && case "$PW_YAD_SET" in
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
    122) gui_MangoHud ;;
    pw_create_prefix_backup) pw_create_prefix_backup ;;
    gui_credits) gui_credits ;;
    pw_start_cont_xterm) pw_start_cont_xterm ;;
    pw_find_exe) pw_find_exe ;;
    PW_*) pw_autoinstall_from_db ;;
    *.desktop) run_desktop_b_click ;;
    1|252|*) exit 0 ;;
esac

stop_portwine
