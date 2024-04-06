#!/usr/bin/env bash
# Author: Castro-Fidel (linux-gaming.ru)
# Development assistants: Cefeiko; Dezert1r; Taz_mania; Anton_Famillianov; gavr; RidBowt; chal55rus; UserDiscord; Boria138; Vano; Akai
########################################################################
echo '
            █░░ █ █▄░█ █░█ ▀▄▀ ▄▄ █▀▀ ▄▀█ █▀▄▀█ █ █▄░█ █▀▀ ░ █▀█ █░█
            █▄▄ █ █░▀█ █▄█ █░█ ░░ █▄█ █▀█ █░▀░█ █ █░▀█ █▄█ ▄ █▀▄ █▄█

██████╗░░█████╗░██████╗░████████╗██████╗░██████╗░░█████╗░████████╗░█████╗░███╗░░██╗
██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗████╗░██║
██████╔╝██║░░██║██████╔╝░░░██║░░░██████╔╝██████╔╝██║░░██║░░░██║░░░██║░░██║██╔██╗██║
██╔═══╝░██║░░██║██╔══██╗░░░██║░░░██╔═══╝░██╔══██╗██║░░██║░░░██║░░░██║░░██║██║╚████║
██║░░░░░╚█████╔╝██║░░██║░░░██║░░░██║░░░░░██║░░██║╚█████╔╝░░░██║░░░╚█████╔╝██║░╚███║
╚═╝░░░░░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░░╚════╝░╚═╝░░╚══╝

'
if [[ $(id -u) = 0 ]] ; then
    echo "Do not run this script as root!"
    exit 1
fi

export PW_START_PID="$$"
export NO_AT_BRIDGE=1
export pw_full_command_line=("$0" $*)
export YAD_OPTIONS="--borders=3 --tab-borders=0 --keep-icon-size"

MISSING_DESKTOP_FILE=0

if [[ -f "$1" ]] ; then
    export portwine_exe="$1"
elif [[ "$1" == *.exe ]] ; then
    export portwine_exe="$1"
    MISSING_DESKTOP_FILE=1
fi

# HOTFIX - ModernWarships
if echo "$portwine_exe" | grep ModernWarships &>/dev/null \
&& [[ -f "$(dirname "${portwine_exe}")/Modern Warships.exe" ]]
then
    export portwine_exe="$(dirname "${portwine_exe}")/Modern Warships.exe"
    MISSING_DESKTOP_FILE=0
fi

. "$(dirname $(readlink -f "$0"))/functions_helper"

if [[ -z "${LANG}" ]] ; then
    export LANG=C
    export FORCE_ENG_LANG=1
elif [[ "${START_FROM_STEAM}" == 1 ]] ; then
    export FORCE_ENG_LANG=1
else
    unset FORCE_ENG_LANG
fi

create_new_dir "${HOME}/.local/share/applications"
if [[ "${PW_SILENT_RESTART}" == 1 ]] || [[ "${START_FROM_STEAM}" == 1 ]] ; then
    export PW_GUI_DISABLED_CS=1
    unset PW_SILENT_RESTART
else
    unset PW_GUI_DISABLED_CS
fi
unset MANGOHUD MANGOHUD_DLSYM PW_NO_ESYNC PW_NO_FSYNC PW_VULKAN_USE WINEDLLOVERRIDES PW_NO_WRITE_WATCH PW_YAD_SET PW_ICON_FOR_YAD
unset PW_CHECK_AUTOINSTAL PW_VKBASALT_EFFECTS PW_VKBASALT_FFX_CAS PORTWINE_DB PORTWINE_DB_FILE PW_DISABLED_CREATE_DB RADV_PERFTEST
unset CHK_SYMLINK_FILE MESA_GL_VERSION_OVERRIDE PATH_TO_GAME PW_START_DEBUG PORTPROTON_NAME PORTWINE_CREATE_SHORTCUT_NAME FLATPAK_IN_USE
unset PW_PREFIX_NAME WINEPREFIX VULKAN_MOD PW_WINE_VER PW_ADD_TO_ARGS_IN_RUNTIME PW_GAMEMODERUN_SLR AMD_VULKAN_ICD PW_WINE_CPU_TOPOLOGY
unset PW_NAME_D_NAME PW_NAME_D_ICON PW_NAME_D_EXEC PW_EXEC_FROM_DESKTOP PW_ALL_DF PW_GENERATE_BUTTONS PW_NAME_D_ICON PW_NAME_D_ICON_48
unset MANGOHUD_CONFIG PW_WINE_USE WINEDLLPATH WINE WINEDIR WINELOADER WINESERVER PW_USE_RUNTIME

export portname=PortProton

cd "$(dirname "`readlink -f "$0"`")" && export PORT_SCRIPTS_PATH="$(pwd)"
cd "${PORT_SCRIPTS_PATH}/../../" && export PORT_WINE_PATH="$(pwd)"
export PORT_WINE_TMP_PATH="${PORT_WINE_PATH}/data/tmp"

rm -f $PORT_WINE_TMP_PATH/*{exe,msi,tar}*

echo "" > "${PORT_WINE_TMP_PATH}/tmp_yad_form"

if [[ -d "${PORT_WINE_PATH}/data/dist" ]] ; then
    try_remove_file "${PORT_WINE_PATH}/data/dist/VERSION"
    orig_IFS="$IFS"
    IFS=$'\n'
    for dist_dir in $(ls -1 "${PORT_WINE_PATH}/data/dist/") ; do
        dist_dir_new=`echo "${dist_dir}" | awk '$1=$1' | sed -e s/[[:blank:]]/_/g`
        if [[ ! -d "${PORT_WINE_PATH}/data/dist/${dist_dir_new^^}" ]] ; then
            mv -- "${PORT_WINE_PATH}/data/dist/$dist_dir" "${PORT_WINE_PATH}/data/dist/${dist_dir_new^^}"
        fi
    done
    IFS="$orig_IFS"
else
    create_new_dir "${PORT_WINE_PATH}/data/dist"
fi
create_new_dir "${PORT_WINE_PATH}/data/prefixes/DEFAULT"
create_new_dir "${PORT_WINE_PATH}/data/prefixes/DOTNET"
create_new_dir "${PORT_WINE_PATH}/data/prefixes/PROGRAMS"
try_force_link_dir "${PORT_WINE_PATH}/data/prefixes" "${PORT_WINE_PATH}"

orig_IFS="$IFS"
IFS=$'\n'
for pfx_dir in $(ls -1 "${PORT_WINE_PATH}/data/prefixes/") ; do
    pfx_dir_new=`echo "${pfx_dir}" | awk '$1=$1' | sed -e s/[[:blank:]]/_/g`
    if [[ ! -d "${PORT_WINE_PATH}/data/prefixes/${pfx_dir_new^^}" ]] ; then
        mv -- "${PORT_WINE_PATH}/data/prefixes/$pfx_dir" "${PORT_WINE_PATH}/data/prefixes/${pfx_dir_new^^}"
    fi
done
IFS="$orig_IFS"

create_new_dir "${PORT_WINE_TMP_PATH}"/gecko
create_new_dir "${PORT_WINE_TMP_PATH}"/mono

export PW_VULKAN_DIR="${PORT_WINE_TMP_PATH}/VULKAN"
create_new_dir "${PW_VULKAN_DIR}"

export LSPCI_VGA="$(lspci -k | grep -E 'VGA|3D' | tr -d '\n')"

if command -v xrandr &>/dev/null ; then
    try_remove_file "${PORT_WINE_TMP_PATH}/tmp_screen_configuration"
    export PW_SCREEN_RESOLUTION="$(xrandr | sed -rn 's/^.*primary.* ([0-9]+x[0-9]+).*$/\1/p')"
    export PW_SCREEN_PRIMARY="$(xrandr | grep "primary" | awk '{print $1}')"
    print_var PW_SCREEN_RESOLUTION PW_SCREEN_PRIMARY
else
    print_error "xrandr - not found!"
fi

cd "${PORT_SCRIPTS_PATH}"
. "${PORT_SCRIPTS_PATH}/var"

export STEAM_SCRIPTS="${PORT_WINE_PATH}/steam_scripts"
export PW_PLUGINS_PATH="${PORT_WINE_TMP_PATH}/plugins${PW_PLUGINS_VER}"
export PW_GUI_ICON_PATH="${PORT_WINE_PATH}/data/img/gui"

export PW_GUI_THEMES_PATH="${PORT_WINE_PATH}/data/themes"
export YAD_OPTIONS+=" --css=$PW_GUI_THEMES_PATH/default.css"

. "${PORT_SCRIPTS_PATH}"/lang

export urlg="https://linux-gaming.ru/portproton/"
export PW_WINELIB="${PORT_WINE_TMP_PATH}/libs${PW_LIBS_VER}"
try_remove_dir "${PW_WINELIB}/var"
export install_ver=`cat "${PORT_WINE_TMP_PATH}/${portname}_ver" | head -n 1`
export WINETRICKS_DOWNLOADER="curl"
export USER_CONF="${PORT_WINE_PATH}/data/user.conf"
check_user_conf
check_variables PW_LOG "0"

try_remove_file "${PORT_WINE_TMP_PATH}/update_pfx_log"

# TODO: remove this later...
try_remove_file "${PORT_SCRIPTS_PATH}/runlib"
try_remove_file "${PORT_SCRIPTS_PATH}/yad_gui"

if [[ "${INSTALLING_PORT}" == 1 ]] ; then
    return 0
fi

. "${USER_CONF}"
if [[ "${SKIP_CHECK_UPDATES}" != 1 ]] \
&& [[ ! -f "/tmp/portproton.lock" ]]
then
    pw_port_update
fi
unset SKIP_CHECK_UPDATES

pw_check_and_download_plugins

if [[ -f "/tmp/portproton.lock" ]] ; then
    print_warning "Found lock file: /tmp/portproton.lock"
    yad_question "$loc_gui_portproton_lock" || exit 0
fi
touch "/tmp/portproton.lock"
rm_lock_file () {
    echo "Removing the lock file..."
    rm -fv "/tmp/portproton.lock" && echo "OK"
}
trap "rm_lock_file" EXIT

pw_download_libs
export PW_VULKANINFO_PORTABLE="$PW_PLUGINS_PATH/portable/bin/x86_64-linux-gnu-vulkaninfo"
export VULKAN_API_DRIVER_VERSION="$("$PW_VULKANINFO_PORTABLE" 2>/dev/null | grep "api" | head -n 1 | awk '{print $3}')"
export VULKAN_DRIVER_NAME="$("$PW_VULKANINFO_PORTABLE" 2>/dev/null | grep driverName | awk '{print$3}' | head -1)"
pw_init_db
. "${PORT_SCRIPTS_PATH}"/lang
pw_check_and_download_dxvk_and_vkd3d
. "${USER_CONF}"

kill_portwine
killall -15 yad_v13_0 2>/dev/null
kill -TERM `pgrep -a yad | grep ${portname} | head -n 1 | awk '{print $1}'` 2>/dev/null

if [[ -f "/usr/bin/portproton" ]] \
&& [[ -f "${HOME}/.local/share/applications/PortProton.desktop" ]]
then
    rm -f "${HOME}/.local/share/applications/PortProton.desktop"
fi

if grep "SteamOS" "/etc/os-release" &>/dev/null \
&& [[ ! -f  "${HOME}/.local/share/applications/PortProton.desktop" ]]
then
	cp -f "${PORT_WINE_PATH}/PortProton.desktop" "${HOME}/.local/share/applications/"
	update-desktop-database -q "${HOME}/.local/share/applications"
fi

[[ "$MISSING_DESKTOP_FILE" == 1 ]] && portwine_missing_shortcut

if [[ -f "${PORT_WINE_TMP_PATH}/tmp_main_gui_size" ]] && [[ ! -z "$(cat ${PORT_WINE_TMP_PATH}/tmp_main_gui_size)" ]] ; then
    export PW_MAIN_SIZE_W="$(cat ${PORT_WINE_TMP_PATH}/tmp_main_gui_size | awk '{print $1}')"
    export PW_MAIN_SIZE_H="$(cat ${PORT_WINE_TMP_PATH}/tmp_main_gui_size | awk '{print $2}')"
else
    export PW_MAIN_SIZE_W="1100"
    export PW_MAIN_SIZE_H="350"
fi

if [[ ! -z $(basename "${portwine_exe}" | grep .ppack) ]] ; then
    export PW_ADD_TO_ARGS_IN_RUNTIME="--xterm"
    unset PW_SANDBOX_HOME_PATH
    pw_init_runtime
    export PW_PREFIX_NAME=$(basename "$1" | awk -F'.' '{print $1}')
    ${pw_runtime} "${PW_PLUGINS_PATH}/portable/bin/xterm" -e env PATH="${PATH}" LD_LIBRARY_PATH="${PW_LD_LIBRARY_PATH}" unsquashfs -f -d "${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}" "$1" &
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

### CLI ###

case "${1}" in
    '--help' )
        files_from_autoinstall=$(ls "${PORT_SCRIPTS_PATH}/pw_autoinstall")
        echo -e "
use: [--reinstall] [--autoinstall]

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

### GUI ###

export PW_PREFIX_NAME="$(echo "${PW_PREFIX_NAME}" | sed -e s/[[:blank:]]/_/g)"
export PW_ALL_PREFIXES=$(ls "${PORT_WINE_PATH}/data/prefixes/" | sed -e s/"${PW_PREFIX_NAME}$"//g)

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
if command -v wine &>/dev/null \
&& ! check_flatpak
then DIST_ADD_TO_GUI="!USE_SYSTEM_WINE"
else unset DIST_ADD_TO_GUI
fi
for DAIG in ${PW_ALL_DIST}
do
    export DIST_ADD_TO_GUI="${DIST_ADD_TO_GUI}!${DAIG}"
done

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
        OUTPUT_START=$("${pw_yad}" --text-align=center --text "$PW_COMMENT_DB" --form \
        --title "${portname}-${install_ver} (${scripts_install_ver})" \
        --image "${PW_ICON_FOR_YAD}" --separator=";" \
        --window-icon="$PW_GUI_ICON_PATH/portproton.svg" \
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
    "${pw_yad_v13_0}" --plug=$KEY --tabnum=${PW_GUI_SORT_TABS[4]} --form --columns=3 --align-buttons --scroll --separator=" " ${PW_GENERATE_BUTTONS} 2>/dev/null &
    IFS="$orig_IFS"

    "${pw_yad_v13_0}" --plug=${KEY} --tabnum=${PW_GUI_SORT_TABS[3]} --form --columns=3 --align-buttons --separator=";" \
    --field="   $loc_gui_pw_reinstall_pp"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click gui_pw_reinstall_pp"' \
    --field="   $loc_gui_rm_pp"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click gui_rm_portproton"' \
    --field="   $loc_gui_upd_pp"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click gui_pw_update"' \
    --field="   $loc_gui_changelog"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click open_changelog"' \
    --field="   $loc_gui_change_loc"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click change_loc"' \
    --field="   $loc_gui_edit_usc"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click gui_open_user_conf"' \
    --field="   $loc_gui_scripts_fb"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click gui_open_scripts_from_backup"' \
    --field="   Xterm"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click pw_start_cont_xterm"' \
    --field="   $loc_gui_credits"!"$PW_GUI_ICON_PATH/separator.png"!"":"FBTN" '@bash -c "button_click gui_credits"'  2>/dev/null &

    "${pw_yad_v13_0}" --plug=${KEY} --tabnum=${PW_GUI_SORT_TABS[2]} --form --columns=3 --align-buttons --separator=";" \
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

    "${pw_yad_v13_0}" --plug=$KEY --tabnum=${PW_GUI_SORT_TABS[1]} --form --columns=3 --align-buttons --scroll  \
    --field="   Dolphin 5.0"!"$PW_GUI_ICON_PATH/dolphin.png"!"${loc_dolphin}":"FBTN" '@bash -c "button_click PW_DOLPHIN"' \
    --field="   MAME"!"$PW_GUI_ICON_PATH/mame.png"!"${loc_mame}":"FBTN" '@bash -c "button_click PW_MAME"' \
    --field="   RetroArch"!"$PW_GUI_ICON_PATH/retroarch.png"!"${loc_retroarch}":"FBTN" '@bash -c "button_click PW_RETROARCH"' \
    --field="   PPSSPP Windows"!"$PW_GUI_ICON_PATH/ppsspp.png"!"${loc_ppsspp_windows}":"FBTN" '@bash -c "button_click PW_PPSSPP"' \
    --field="   Citra"!"$PW_GUI_ICON_PATH/citra.png"!"${loc_citra}":"FBTN" '@bash -c "button_click PW_CITRA"' \
    --field="   Cemu"!"$PW_GUI_ICON_PATH/cemu.png"!"${loc_cemu}":"FBTN" '@bash -c "button_click PW_CEMU"' \
    --field="   ePSXe"!"$PW_GUI_ICON_PATH/epsxe.png"!"${loc_epsxe}":"FBTN" '@bash -c "button_click PW_EPSXE"' \
    --field="   Project64"!"$PW_GUI_ICON_PATH/project64.png"!"${loc_project64}":"FBTN" '@bash -c "button_click PW_PROJECT64"' \
    --field="   VBA-M"!"$PW_GUI_ICON_PATH/vba-m.png"!"${loc_vba_m}":"FBTN" '@bash -c "button_click PW_VBA-M"' \
    --field="   Yabause"!"$PW_GUI_ICON_PATH/yabause.png"!"${loc_yabause}":"FBTN" '@bash -c "button_click PW_YABAUSE"' \
    --field="   Xenia"!"$PW_GUI_ICON_PATH/xenia.png"!"${loc_xenia}":"FBTN" '@bash -c "button_click PW_XENIA"' \
    --field="   FCEUX"!"$PW_GUI_ICON_PATH/fceux.png"!"${loc_fceux}":"FBTN" '@bash -c "button_click PW_FCEUX"' \
    --field="   xemu"!"$PW_GUI_ICON_PATH/xemu.png"!"${loc_xemu}":"FBTN" '@bash -c "button_click PW_XEMU"' \
    --field="   Demul"!"$PW_GUI_ICON_PATH/demul.png"!"${loc_demul}":"FBTN" '@bash -c "button_click PW_DEMUL"' 2>/dev/null &

    "${pw_yad_v13_0}" --plug=$KEY --tabnum=${PW_GUI_SORT_TABS[0]} --form --columns=3 --align-buttons --scroll \
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
    --field="   EA App (TEST)"!"$PW_GUI_ICON_PATH/eaapp.png"!"":"FBTN" '@bash -c "button_click PW_EAAPP"' \
    --field="   Battle Of Space Raiders"!"$PW_GUI_ICON_PATH/bsr.png"!"":"FBTN" '@bash -c "button_click PW_BSR"' \
    --field="   Black Desert Online (RU)"!"$PW_GUI_ICON_PATH/bdo.png"!"":"FBTN" '@bash -c "button_click PW_BDO"' \
    --field="   Pulse Online"!"$PW_GUI_ICON_PATH/pulseonline.png"!"":"FBTN" '@bash -c "button_click PW_PULSE_ONLINE"' \
    --field="   CatsLauncher (Front Edge)"!"$PW_GUI_ICON_PATH/catslauncher.png"!"":"FBTN" '@bash -c "button_click PW_CATSLAUNCHER"' 2>/dev/null &

    # --field="   Secret World Legends (ENG)"!"$PW_GUI_ICON_PATH/swl.png"!"":"FBTN" '@bash -c "button_click PW_SWL"'
    # --field="   Bethesda.net Launcher"!"$PW_GUI_ICON_PATH/bethesda.png"!"":"FBTN" '@bash -c "button_click PW_BETHESDA"'
    # --field="   ROBLOX"!"$PW_GUI_ICON_PATH/roblox.png"!"":"FBTN" '@bash -c "button_click PW_ROBLOX"'

    # if command -v wmctrl &>/dev/null ; then
    #     sleep 2
    #     while [[ -n $(pgrep -a yad_v13_0 | head -n 1 | awk '{print $1}' 2>/dev/null) ]] ; do
    #         sleep 2
    #         PW_MAIN_GUI_SIZE_TMP="$(wmctrl -lG | grep "PortProton-${install_ver}" | awk '{print $5" "$6}' 2>/dev/null)"
    #         if [[ ! -z "${PW_MAIN_GUI_SIZE_TMP}" ]] ; then
    #             echo "${PW_MAIN_GUI_SIZE_TMP}" > "${PORT_WINE_TMP_PATH}/tmp_main_gui_size"
    #         fi
    #     done
    # fi &

    export START_FROM_PP_GUI=1

    if [[ -z "${PW_ALL_DF}" ]] ; then
        "${pw_yad_v13_0}" --key=$KEY --notebook --expand \
        --width="${PW_MAIN_SIZE_W}" --height="${PW_MAIN_SIZE_H}" --no-buttons \
        --auto-close --window-icon="$PW_GUI_ICON_PATH/portproton.svg" \
        --title "${portname}-${install_ver} (${scripts_install_ver})" \
        --tab-pos=bottom \
        --tab="$loc_mg_autoinstall"!"$PW_GUI_ICON_PATH/separator.png"!"" \
        --tab="$loc_mg_emulators"!"$PW_GUI_ICON_PATH/separator.png"!"" \
        --tab="$loc_mg_wine_settings"!"$PW_GUI_ICON_PATH/separator.png"!"" \
        --tab="$loc_mg_portproton_settings"!"$PW_GUI_ICON_PATH/separator.png"!"" \
        --tab="$loc_mg_installed"!"$PW_GUI_ICON_PATH/separator.png"!"" 2>/dev/null
        YAD_STATUS="$?"
    else
        "${pw_yad_v13_0}" --key=$KEY --notebook --expand \
        --width="${PW_MAIN_SIZE_W}" --height="${PW_MAIN_SIZE_H}" --no-buttons \
        --auto-close --window-icon="$PW_GUI_ICON_PATH/portproton.svg" \
        --title "${portname}-${install_ver} (${scripts_install_ver})" \
        --tab-pos=bottom \
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
    if [[ ! -z "${PORTWINE_DB}" ]] \
    && [[ -z "${PORTWINE_DB_FILE}" ]]
    then
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
