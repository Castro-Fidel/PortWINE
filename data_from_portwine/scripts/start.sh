#!/usr/bin/env bash
# Author: Castro-Fidel (linux-gaming.ru)
# Development assistants: Cefeiko; Dezert1r; Taz_mania; Anton_Famillianov; gavr; RidBowt; chal55rus; UserDiscord; Boria138; Vano; Akai
# shellcheck disable=SC2140,SC2119,SC2206
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
export NO_AT_BRIDGE="1"
export GDK_BACKEND="x11"
export pw_full_command_line=("$0" $*)

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
    portwine_exe="$(dirname "${portwine_exe}")/Modern Warships.exe"
    export portwine_exe
    MISSING_DESKTOP_FILE=0
fi

cd "$(dirname "$(readlink -f "$0")")" && PORT_SCRIPTS_PATH="$(pwd)" || fatal
cd "${PORT_SCRIPTS_PATH}/../../" && PORT_WINE_PATH="$(pwd)" || fatal
export PORT_SCRIPTS_PATH PORT_WINE_PATH

# shellcheck source=/dev/null
source gettext.sh
export TEXTDOMAIN="PortProton"
export TEXTDOMAINDIR="${PORT_WINE_PATH}/data/locales"

# shellcheck source=./functions_helper
source "${PORT_SCRIPTS_PATH}/functions_helper"

create_new_dir "${HOME}/.local/share/applications"
if [[ "${PW_SILENT_RESTART}" == 1 ]] || [[ "${START_FROM_STEAM}" == 1 ]] ; then
    export PW_GUI_DISABLED_CS=1
    unset PW_SILENT_RESTART
else
    unset PW_GUI_DISABLED_CS
fi

unset MANGOHUD MANGOHUD_DLSYM PW_NO_ESYNC PW_NO_FSYNC PW_VULKAN_USE WINEDLLOVERRIDES PW_NO_WRITE_WATCH PW_YAD_SET PW_ICON_FOR_YAD
unset PW_CHECK_AUTOINSTAL PW_VKBASALT_EFFECTS PW_VKBASALT_FFX_CAS PORTWINE_DB PORTWINE_DB_FILE PW_DISABLED_CREATE_DB RADV_PERFTEST
unset CHK_SYMLINK_FILE PW_MESA_GL_VERSION_OVERRIDE MESA_GL_VERSION_OVERRIDE PATH_TO_GAME PW_START_DEBUG PORTPROTON_NAME FLATPAK_IN_USE
unset PW_PREFIX_NAME WINEPREFIX VULKAN_MOD PW_WINE_VER PW_ADD_TO_ARGS_IN_RUNTIME PW_GAMEMODERUN_SLR AMD_VULKAN_ICD PW_WINE_CPU_TOPOLOGY
unset PW_NAME_D_NAME PW_NAME_D_ICON PW_NAME_D_EXEC PW_EXEC_FROM_DESKTOP PW_ALL_DF PW_GENERATE_BUTTONS PW_NAME_D_ICON PW_NAME_D_ICON_48
unset MANGOHUD_CONFIG PW_WINE_USE WINEDLLPATH WINE WINEDIR WINELOADER WINESERVER PW_USE_RUNTIME PORTWINE_CREATE_SHORTCUT_NAME MIRROR

export PORT_WINE_TMP_PATH="${PORT_WINE_PATH}/data/tmp"
rm -f "$PORT_WINE_TMP_PATH"/*{exe,msi,tar}*

echo "" > "${PORT_WINE_TMP_PATH}/tmp_yad_form"

create_new_dir "${PORT_WINE_PATH}/data/dist"
pushd "${PORT_WINE_PATH}/data/dist/" 1>/dev/null || fatal
for dist_dir in ./* ; do
    [[ -d "$dist_dir" ]] || continue
    dist_dir_new="${dist_dir//[[:blank:]]/_}"
    if [[ ! -d "${PORT_WINE_PATH}/data/dist/${dist_dir_new^^}" ]] ; then
        mv -- "${PORT_WINE_PATH}/data/dist/$dist_dir" "${PORT_WINE_PATH}/data/dist/${dist_dir_new^^}"
    fi
done
popd 1>/dev/null || fatal

create_new_dir "${PORT_WINE_PATH}/data/prefixes/DEFAULT"
create_new_dir "${PORT_WINE_PATH}/data/prefixes/DOTNET"
create_new_dir "${PORT_WINE_PATH}/data/prefixes/PROGRAMS"
try_force_link_dir "${PORT_WINE_PATH}/data/prefixes" "${PORT_WINE_PATH}"

pushd "${PORT_WINE_PATH}/data/prefixes/" 1>/dev/null || fatal
for pfx_dir in ./* ; do
    [[ -d "$pfx_dir" ]] || continue
    pfx_dir_new="${pfx_dir//[[:blank:]]/_}"
    if [[ ! -d "${PORT_WINE_PATH}/data/prefixes/${pfx_dir_new^^}" ]] ; then
        mv -- "${PORT_WINE_PATH}/data/prefixes/$pfx_dir" "${PORT_WINE_PATH}/data/prefixes/${pfx_dir_new^^}"
    fi
done
popd 1>/dev/null || fatal

create_new_dir "${PORT_WINE_TMP_PATH}"/gecko
create_new_dir "${PORT_WINE_TMP_PATH}"/mono

export PW_VULKAN_DIR="${PORT_WINE_TMP_PATH}/VULKAN"
create_new_dir "${PW_VULKAN_DIR}"

LSPCI_VGA="$(lspci -k | grep -E 'VGA|3D' | tr -d '\n')"
export LSPCI_VGA

if command -v xrandr &>/dev/null ; then
    try_remove_file "${PORT_WINE_TMP_PATH}/tmp_screen_configuration"
    if [[ $(xrandr | grep "primary" | awk '{print $1}') ]] ; then
        PW_SCREEN_RESOLUTION="$(xrandr | sed -rn 's/^.*primary.* ([0-9]+x[0-9]+).*$/\1/p')"
        PW_SCREEN_PRIMARY="$(xrandr | grep "primary" | awk '{print $1}')"
    elif [[ $(xrandr | grep -w "connected" | awk '{print $1}') ]] ; then
        # xrand не выводит primary в XFCE
		PW_SCREEN_RESOLUTION="$(xrandr | sed -rn 's/^.* connected.* ([0-9]+x[0-9]+).*$/\1/p')"
		PW_SCREEN_PRIMARY="$(xrandr | grep -w "connected" | awk '{print $1}')"
    fi
    export PW_SCREEN_PRIMARY PW_SCREEN_RESOLUTION
    print_var PW_SCREEN_RESOLUTION PW_SCREEN_PRIMARY
else
    print_error "xrandr - not found!"
fi

cd "${PORT_SCRIPTS_PATH}" || fatal

# shellcheck source=./var
source "${PORT_SCRIPTS_PATH}/var"

export STEAM_SCRIPTS="${PORT_WINE_PATH}/steam_scripts"
export PW_PLUGINS_PATH="${PORT_WINE_TMP_PATH}/plugins${PW_PLUGINS_VER}"
export PW_GUI_ICON_PATH="${PORT_WINE_PATH}/data/img/gui"
export PW_GUI_THEMES_PATH="${PORT_WINE_PATH}/data/themes"

change_locale

export urlg="https://linux-gaming.ru/portproton/"
export url_cdn="https://cdn.linux-gaming.ru"
export PW_WINELIB="${PORT_WINE_TMP_PATH}/libs${PW_LIBS_VER}"
try_remove_dir "${PW_WINELIB}/var"
install_ver="$(head -n 1 "${PORT_WINE_TMP_PATH}/PortProton_ver")"
export install_ver
export WINETRICKS_DOWNLOADER="curl"
export USER_CONF="${PORT_WINE_PATH}/data/user.conf"
check_user_conf
check_variables PW_LOG "0"

try_remove_file "${PORT_WINE_TMP_PATH}/update_pfx_log"

# shellcheck source=/dev/null
source "${USER_CONF}"

# check PortProton theme
if [[ ! -z "$GUI_THEME" ]] \
&& [[ -f "$PW_GUI_THEMES_PATH/$GUI_THEME.pptheme" ]]
then
    # shellcheck source=/dev/null
    source "$PW_GUI_THEMES_PATH/$GUI_THEME.pptheme"
else
    # shellcheck source=/dev/null
    source "$PW_GUI_THEMES_PATH/default.pptheme"
echo 'export GUI_THEME="default"' >> "$USER_CONF"
fi

# check tray icon theme
if gsettings get org.gnome.desktop.interface color-scheme &>/dev/null ; then
    COLOR_SCHEME="$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)"
    if [[ "$COLOR_SCHEME" == "'prefer-dark'" ]]
    then PW_DESKTOP_THEME="dark"
    fi
else
    PW_DESKTOP_THEME="universal"
fi
export PW_DESKTOP_THEME

# choose mirror
if [[ -z "$MIRROR" ]] \
&& [[ "$LANGUAGE" == "ru" ]]
then
    echo 'export MIRROR="CDN"' >> "$USER_CONF"
    export MIRROR="CDN"
elif [[ -z "$MIRROR" ]] ; then
    echo 'export MIRROR="GITHUB"' >> "$USER_CONF"
    export MIRROR="GITHUB"
fi
print_info "The first mirror in used: $MIRROR\n"

if [[ "${INSTALLING_PORT}" == 1 ]] ; then
    return 0
fi

if [[ "${SKIP_CHECK_UPDATES}" != 1 ]] \
&& [[ ! -f "/tmp/portproton.lock" ]]
then
    pw_port_update
else
    scripts_install_ver=$(head -n 1 "${PORT_WINE_TMP_PATH}/scripts_ver")
    export scripts_install_ver
fi
unset SKIP_CHECK_UPDATES

pw_check_and_download_plugins
export PW_VULKANINFO_PORTABLE="$PW_PLUGINS_PATH/portable/bin/x86_64-linux-gnu-vulkaninfo"
VULKAN_DRIVER_NAME="$("$PW_VULKANINFO_PORTABLE" 2>/dev/null | grep driverName | awk '{print$3}' | head -1)"
export VULKAN_DRIVER_NAME

if [[ -f "/tmp/portproton.lock" ]] ; then
    print_warning "Found lock file: /tmp/portproton.lock"
    yad_question "$(eval_gettext 'A running PortProton session was detected.\nDo you want to end the previous session?')" || exit 0
fi
touch "/tmp/portproton.lock"
rm_lock_file () {
    echo "Removing the lock file..."
    rm -fv "/tmp/portproton.lock" && echo "OK"
}
trap "rm_lock_file" EXIT

if check_flatpak
then try_remove_dir "${PORT_WINE_TMP_PATH}/libs${PW_LIBS_VER}"
else pw_download_libs
fi

pw_init_db
# change_locale
pw_check_and_download_dxvk_and_vkd3d
# shellcheck source=/dev/null
source "${USER_CONF}"

kill_portwine
killall -15 yad_v13_0 2>/dev/null
kill -TERM "$(pgrep -a yad | grep PortProton | head -n 1 | awk '{print $1}')" 2>/dev/null

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

if [[ ! -z $(basename "${portwine_exe}" | grep .ppack) ]] ; then
    unset PW_SANDBOX_HOME_PATH
    pw_init_runtime
    if check_flatpak
    then TMP_ALL_PATH=""
    else TMP_ALL_PATH="env PATH=\"${PATH}\" LD_LIBRARY_PATH=\"${PW_LD_LIBRARY_PATH}\""
    fi
    PW_PREFIX_NAME=$(basename "$1" | awk -F'.' '{print $1}')
cat << EOF > "${PORT_WINE_TMP_PATH}"/pp_pfx_unpack.sh
    #!/usr/bin/env bash
    ${TMP_ALL_PATH} unsquashfs -f -d "${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}" "$1" \
    || echo "ERROR" > "${PORT_WINE_TMP_PATH}"/pp_pfx_unpack_error
EOF
    chmod u+x "${PORT_WINE_TMP_PATH}"/pp_pfx_unpack.sh
    ${pw_runtime} ${PW_TERM} "${PORT_WINE_TMP_PATH}"/pp_pfx_unpack.sh
    if grep "ERROR" "${PORT_WINE_TMP_PATH}"/pp_pfx_unpack_error &>/dev/null ; then
        try_remove_file "${PORT_WINE_TMP_PATH}"/pp_pfx_unpack_error
        try_remove_file "${PORT_WINE_TMP_PATH}"/pp_pfx_unpack.sh
        yad_error "$(eval_gettext "Unpack has FAILED for prefix:") <b>\"${PW_PREFIX_NAME}\"</b>."
        exit 1
    else
        try_remove_file "${PORT_WINE_TMP_PATH}"/pp_pfx_unpack.sh
        if [[ -f "${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}/.create_shortcut" ]] ; then
            while IFS= read -r line
            do
                export portwine_exe="$PORT_WINE_PATH/data/prefixes/$PW_PREFIX_NAME/$line"
                portwine_create_shortcut "$PORT_WINE_PATH/data/prefixes/$PW_PREFIX_NAME/$line"
            done < "$PORT_WINE_PATH/data/prefixes/$PW_PREFIX_NAME/.create_shortcut"
        fi
        yad_info "$(eval_gettext "Unpack is DONE for prefix:") <b>\"${PW_PREFIX_NAME}\"</b>."
        exit 0
    fi
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

    '--generate-pot' )
        generate_pot
        exit 0 ;;
esac

### GUI ###

pushd "${PORT_WINE_PATH}/data/prefixes/" 1>/dev/null || fatal
unset PW_ADD_PREFIXES_TO_GUI
PW_PREFIX_NAME="${PW_PREFIX_NAME//[[:blank:]]/_}"
for PAIG in ./* ; do
    if [[ "${PAIG//'./'/}" != "${PORTWINE_DB^^//[[:blank:]]/_}" ]] \
    && [[ "${PAIG//'./'/}" != "${PW_PREFIX_NAME}" ]]
    then
        PW_ADD_PREFIXES_TO_GUI="${PW_ADD_PREFIXES_TO_GUI}!${PAIG//'./'/}"
    fi
done
PW_ADD_PREFIXES_TO_GUI="${PW_PREFIX_NAME^^}${PW_ADD_PREFIXES_TO_GUI}"
popd 1>/dev/null || fatal

pushd "${PORT_WINE_PATH}/data/dist/" 1>/dev/null || fatal
if command -v wine &>/dev/null
then DIST_ADD_TO_GUI="!USE_SYSTEM_WINE"
else unset DIST_ADD_TO_GUI
fi
for DAIG in ./* ; do
    if [[ "${DAIG//'./'/}" != "${PW_WINE_LG_VER}" ]] \
    && [[ "${DAIG//'./'/}" != "${PW_PROTON_LG_VER}" ]]
    then
        DIST_ADD_TO_GUI="${DIST_ADD_TO_GUI}!${DAIG//'./'/}"
    fi
done
popd 1>/dev/null || fatal

check_nvidia_rtx && check_variables PW_VULKAN_USE "2"

SORT_OPENGL="$(eval_gettext "OPENGL (For video cards without VULKAN)")"
SORT_STABLE="$(eval_gettext "Stable") DXVK ${DXVK_STABLE_VER}, VKD3D ${VKD3D_STABLE_VER}"
SORT_NEWEST="$(eval_gettext "Newest") DXVK ${DXVK_GIT_VER}, VKD3D ${VKD3D_GIT_VER}"
SORT_G_NINE="$(eval_gettext "GALLIUM_NINE (DX9 for MESA)")"
SORT_G_ZINK="$(eval_gettext "GALLIUM_ZINK (OpenGL for VULKAN)")"

case "${PW_VULKAN_USE}" in
    0) PW_DEFAULT_VULKAN_USE="$SORT_OPENGL!$SORT_STABLE!$SORT_NEWEST!$SORT_G_NINE!$SORT_G_ZINK" ;;
    1) PW_DEFAULT_VULKAN_USE="$SORT_STABLE!$SORT_NEWEST!$SORT_OPENGL!$SORT_G_NINE!$SORT_G_ZINK" ;;
    3) PW_DEFAULT_VULKAN_USE="$SORT_G_NINE!$SORT_STABLE!$SORT_NEWEST!$SORT_OPENGL!$SORT_G_ZINK" ;;
    4) PW_DEFAULT_VULKAN_USE="$SORT_G_ZINK!$SORT_STABLE!$SORT_NEWEST!$SORT_OPENGL!$SORT_G_NINE" ;;
    *) PW_DEFAULT_VULKAN_USE="$SORT_NEWEST!$SORT_STABLE!$SORT_OPENGL!$SORT_G_NINE!$SORT_G_ZINK" ;;
esac

if [[ ! -z "${PORTWINE_DB_FILE}" ]] ; then
    [[ -z "${PW_COMMENT_DB}" ]] && PW_COMMENT_DB="$(eval_gettext "PortProton database file was found for") <b>${PORTWINE_DB}</b>."
    if [[ ! -z $(echo "${PW_WINE_USE}" | grep "^PROTON_LG$") ]] ; then
        PW_DEFAULT_WINE_USE="${PW_PROTON_LG_VER}!${PW_WINE_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
    elif [[ ! -z $(echo "${PW_WINE_USE}" | grep "^PROTON_GE$") ]] ; then
        PW_DEFAULT_WINE_USE="${PW_WINE_LG_VER}!${PW_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
    else
        if [[ "${PW_WINE_USE}" == "${PW_PROTON_LG_VER}" ]] ; then
            PW_DEFAULT_WINE_USE="${PW_WINE_USE}!${PW_WINE_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
        elif [[ "${PW_WINE_USE}" == "${PW_WINE_LG_VER}" ]] ; then
            PW_DEFAULT_WINE_USE="${PW_WINE_USE}!${PW_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
        else
            DIST_ADD_TO_GUI="${DIST_ADD_TO_GUI//\"\!${PW_WINE_USE}$//}"
            PW_DEFAULT_WINE_USE="${PW_WINE_USE}!${PW_WINE_LG_VER}!${PW_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
        fi
    fi
else
    if [[ $PW_WINE_USE == PROTON_LG ]] ; then
        PW_DEFAULT_WINE_USE="${PW_PROTON_LG_VER}!${PW_WINE_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
    elif [[ $PW_WINE_USE == WINE_*_LG ]] ; then
        PW_DEFAULT_WINE_USE="${PW_WINE_LG_VER}!${PW_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
    else
        if [[ "${PW_WINE_USE}" == "${PW_PROTON_LG_VER}" ]] ; then
            PW_DEFAULT_WINE_USE="${PW_WINE_USE}!${PW_WINE_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
        elif [[ "${PW_WINE_USE}" == "${PW_WINE_LG_VER}" ]] ; then
            PW_DEFAULT_WINE_USE="${PW_WINE_USE}!${PW_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
        else
            DIST_ADD_TO_GUI="${DIST_ADD_TO_GUI//\"\!${PW_WINE_USE}$//}"
            PW_DEFAULT_WINE_USE="${PW_WINE_USE}!${PW_WINE_LG_VER}!${PW_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
        fi
    fi
    unset PW_GUI_DISABLED_CS
fi
if [[ -f "${portwine_exe}" ]] ; then
    if [[ "${PW_GUI_DISABLED_CS}" != 1 ]] ; then
        pw_create_gui_png
        grep -il "${portwine_exe}" "${HOME}/.local/share/applications"/*.desktop
        if [[ "$?" != "0" ]] ; then
            PW_SHORTCUT="$(eval_gettext "CREATE SHORTCUT")!$PW_GUI_ICON_PATH/$BUTTON_SIZE.png!$(eval_gettext "Create shortcut for select file..."):100"
        else
            PW_SHORTCUT="$(eval_gettext "DELETE SHORTCUT")!$PW_GUI_ICON_PATH/$BUTTON_SIZE.png!$(eval_gettext "Delete shortcut for select file..."):98"
        fi
        OUTPUT_START=$("${pw_yad}" --text-align=center --text "$PW_COMMENT_DB" --form \
        --title "PortProton-${install_ver} (${scripts_install_ver})" \
        --image "${PW_ICON_FOR_YAD}" --separator=";" \
        --window-icon="$PW_GUI_ICON_PATH/portproton.svg" \
        --field="3D API  : :CB" "${PW_DEFAULT_VULKAN_USE}" \
        --field="  WINE  : :CB" "${PW_DEFAULT_WINE_USE}" \
        --field="PREFIX  : :CBE" "${PW_ADD_PREFIXES_TO_GUI}" \
        --field=":LBL" "" \
        --button="$(eval_gettext "VKBASALT")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(eval_gettext "Enable vkBasalt by default to improve graphics in games running on Vulkan. (The HOME hotkey disables vkbasalt)")":120 \
        --button="$(eval_gettext "MANGOHUD")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(eval_gettext "Enable Mangohud by default (R_SHIFT + F12 keyboard shortcuts disable Mangohud)")":122 \
        --button="$(eval_gettext "EDIT DB")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(eval_gettext "Edit database file for") ${PORTWINE_DB}":118 \
        --button="${PW_SHORTCUT}" \
        --button="$(eval_gettext "DEBUG")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(eval_gettext "Launch with the creation of a .log file at the root PortProton")":102 \
        --button="$(eval_gettext "LAUNCH")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(eval_gettext "Run file ...")":106 2>/dev/null)
        PW_YAD_SET="$?"
        if [[ "$PW_YAD_SET" == "1" || "$PW_YAD_SET" == "252" ]] ; then exit 0 ; fi
        VULKAN_MOD=$(echo "${OUTPUT_START}" | grep \;\; | awk -F";" '{print $1}')
        PW_WINE_VER=$(echo "${OUTPUT_START}" | grep \;\; | awk -F";" '{print $2}')
        PW_PREFIX_NAME=$(echo "${OUTPUT_START}" | grep \;\; | awk -F";" '{print $3}' | sed -e s/[[:blank:]]/_/g)
        if [[ -z "${PW_PREFIX_NAME}" ]] || [[ ! -z "$(echo "${PW_PREFIX_NAME}" | grep -E '^_.*' )" ]] ; then
            PW_PREFIX_NAME="DEFAULT"
        else
            PW_PREFIX_NAME="${PW_PREFIX_NAME^^}"
        fi
        export PW_PREFIX_NAME PW_WINE_VER VULKAN_MOD
    elif [[ -f "${PORTWINE_DB_FILE}" ]] ; then
        portwine_launch
    fi
else
    export KEY="$RANDOM"

    orig_IFS="$IFS" && IFS=$'\n'
    PW_ALL_DF="$(ls "${PORT_WINE_PATH}"/ | grep .desktop | grep -vE '(PortProton|readme)')"
    if [[ -z "${PW_ALL_DF}" ]]
    then PW_GUI_SORT_TABS=(1 2 3 4 5)
    else PW_GUI_SORT_TABS=(2 3 4 5 1)
    fi
    PW_GENERATE_BUTTONS="--field=   $(eval_gettext "Create shortcut...")!${PW_GUI_ICON_PATH}/find_48.svg!:FBTN%@bash -c \"button_click pw_find_exe\"%"
    for PW_DESKTOP_FILES in ${PW_ALL_DF} ; do
        PW_NAME_D_ICON="$(grep Icon "${PORT_WINE_PATH}/${PW_DESKTOP_FILES}" | awk -F= '{print $2}')"
        PW_NAME_D_ICON_48="${PW_NAME_D_ICON//".png"/"_48.png"}"
        if [[ ! -f "${PW_NAME_D_ICON_48}" ]]  \
        && [[ -f "${PW_NAME_D_ICON}" ]] \
        && command -v "convert" 2>/dev/null
        then
            convert "${PW_NAME_D_ICON}" -resize 48x48 "${PW_NAME_D_ICON_48}"
        fi
        PW_GENERATE_BUTTONS+="--field=   ${PW_DESKTOP_FILES//".desktop"/""}!${PW_NAME_D_ICON_48}!:FBTN%@bash -c \"run_desktop_b_click "${PW_DESKTOP_FILES//" "/¬}"\"%"
    done

    IFS="$orig_IFS"
    old_IFS=$IFS && IFS="%"
    "${pw_yad_v13_0}" --plug=$KEY --tabnum="${PW_GUI_SORT_TABS[4]}" --form --columns="$MAIN_GUI_COLUMNS" \
    --align-buttons --scroll --separator=" " ${PW_GENERATE_BUTTONS} 2>/dev/null &
    IFS="$orig_IFS"

    "${pw_yad_v13_0}" --plug=${KEY} --tabnum="${PW_GUI_SORT_TABS[3]}" --form --columns=3 --align-buttons --separator=";" \
    --field="   $(eval_gettext "Reinstall PortProton")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click gui_pw_reinstall_pp"' \
    --field="   $(eval_gettext "Remove PortProton")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click gui_rm_portproton"' \
    --field="   $(eval_gettext "Update PortProton")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click gui_pw_update"' \
    --field="   $(eval_gettext "Changelog")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click open_changelog"' \
    --field="   $(eval_gettext "Change language")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click change_loc"' \
    --field="   $(eval_gettext "Edit user.conf")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click gui_open_user_conf"' \
    --field="   $(eval_gettext "Scripts from backup")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click gui_open_scripts_from_backup"' \
    --field="   Xterm"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click pw_start_cont_xterm"' \
    --field="   $(eval_gettext "Credits")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click gui_credits"' \
    --field="   $(eval_gettext "Change mirror")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click change_mirror"' \
    2>/dev/null &

    "${pw_yad_v13_0}" --plug=${KEY} --tabnum="${PW_GUI_SORT_TABS[2]}" --form --columns=3 --align-buttons --separator=";" \
    --field="  3D API  : :CB" "${PW_DEFAULT_VULKAN_USE}" \
    --field="  PREFIX  : :CBE" "${PW_ADD_PREFIXES_TO_GUI}" \
    --field="  WINE    : :CB" "${PW_DEFAULT_WINE_USE}" \
    --field="              $(eval_gettext "Create prefix backup")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click pw_create_prefix_backup"' \
    --field="   Winetricks"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"$(eval_gettext "Run winetricks to install additional libraries to the selected prefix")":"FBTN" '@bash -c "button_click WINETRICKS"' \
    --field="   $(eval_gettext "Clear prefix")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"$(eval_gettext "Clear the prefix to fix problems")":"FBTN" '@bash -c "button_click gui_clear_pfx"' \
    --field="   $(eval_gettext "Get other Wine")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"$(eval_gettext "Open the menu to download other versions of WINE or PROTON")":"FBTN" '@bash -c "button_click gui_proton_downloader"' \
    --field="   $(eval_gettext "Uninstaller")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"$(eval_gettext "Run the program uninstaller built into wine")":"FBTN" '@bash -c "button_click gui_wine_uninstaller"' \
    --field="   $(eval_gettext "Prefix Manager")     "!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"$(eval_gettext "Run winecfg to edit the settings of the selected prefix")":"FBTN" '@bash -c "button_click WINECFG"' \
    --field="   $(eval_gettext "File Manager")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"$(eval_gettext "Run wine file manager")":"FBTN" '@bash -c "button_click WINEFILE"' \
    --field="   $(eval_gettext "Command line")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"$(eval_gettext "Run wine cmd")":"FBTN" '@bash -c "button_click WINECMD"' \
    --field="   $(eval_gettext "Regedit")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"$(eval_gettext "Run wine regedit")":"FBTN" '@bash -c "button_click WINEREG"' 2>/dev/null 1> "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" &

    "${pw_yad_v13_0}" --plug=$KEY --tabnum="${PW_GUI_SORT_TABS[1]}" --form --columns="$MAIN_GUI_COLUMNS" --align-buttons --scroll \
    --field="   Dolphin 5.0"!"$PW_GUI_ICON_PATH/dolphin.png"!"$(eval_gettext "Emulator for Nintendo game consoles with high compatibility")":"FBTN" '@bash -c "button_click PW_DOLPHIN"' \
    --field="   MAME"!"$PW_GUI_ICON_PATH/mame.png"!"$(eval_gettext "Multi-arcade emulator that allows you to play old arcade games")":"FBTN" '@bash -c "button_click PW_MAME"' \
    --field="   RetroArch"!"$PW_GUI_ICON_PATH/retroarch.png"!"$(eval_gettext "Multi-platform frontend for emulators with extensive settings")":"FBTN" '@bash -c "button_click PW_RETROARCH"' \
    --field="   PPSSPP Windows"!"$PW_GUI_ICON_PATH/ppsspp.png"!"$(eval_gettext "Emulator for the PlayStation Portable (PSP) game console")":"FBTN" '@bash -c "button_click PW_PPSSPP"' \
    --field="   Citra"!"$PW_GUI_ICON_PATH/citra.png"!"$(eval_gettext "Emulator for the Nintendo 3DS game console")":"FBTN" '@bash -c "button_click PW_CITRA"' \
    --field="   Cemu"!"$PW_GUI_ICON_PATH/cemu.png"!"$(eval_gettext "Emulator for the Wii U game console")":"FBTN" '@bash -c "button_click PW_CEMU"' \
    --field="   ePSXe"!"$PW_GUI_ICON_PATH/epsxe.png"!"$(eval_gettext "Emulator for the PlayStation 1 game console with high compatibility")":"FBTN" '@bash -c "button_click PW_EPSXE"' \
    --field="   Project64"!"$PW_GUI_ICON_PATH/project64.png"!"$(eval_gettext "Emulator for the Nintendo 64 game console")":"FBTN" '@bash -c "button_click PW_PROJECT64"' \
    --field="   VBA-M"!"$PW_GUI_ICON_PATH/vba-m.png"!"$(eval_gettext "Emulator for the Game Boy Advance game console")":"FBTN" '@bash -c "button_click PW_VBA-M"' \
    --field="   Yabause"!"$PW_GUI_ICON_PATH/yabause.png"!"$(eval_gettext "Emulator for the Sega Saturn game console")":"FBTN" '@bash -c "button_click PW_YABAUSE"' \
    --field="   Xenia"!"$PW_GUI_ICON_PATH/xenia.png"!"$(eval_gettext "Emulator for the Xbox 360 game console")":"FBTN" '@bash -c "button_click PW_XENIA"' \
    --field="   FCEUX"!"$PW_GUI_ICON_PATH/fceux.png"!"$(eval_gettext "Emulator for the Nintendo Entertainment System (NES or Dendy) game console")":"FBTN" '@bash -c "button_click PW_FCEUX"' \
    --field="   xemu"!"$PW_GUI_ICON_PATH/xemu.png"!"$(eval_gettext "Emulator for the Xbox game console")":"FBTN" '@bash -c "button_click PW_XEMU"' \
    --field="   Demul"!"$PW_GUI_ICON_PATH/demul.png"!"$(eval_gettext "Emulator for the Sega Dreamcast game console")":"FBTN" '@bash -c "button_click PW_DEMUL"' 2>/dev/null &

    "${pw_yad_v13_0}" --plug=$KEY --tabnum="${PW_GUI_SORT_TABS[0]}" --form --columns="$MAIN_GUI_COLUMNS" --align-buttons --scroll \
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
    --field="   CatsLauncher (Front Edge)"!"$PW_GUI_ICON_PATH/catslauncher.png"!"":"FBTN" '@bash -c "button_click PW_CATSLAUNCHER"' \
    --field="   Russian Fishing 4"!"$PW_GUI_ICON_PATH/rf4launcher.png"!"":"FBTN" '@bash -c "button_click PW_RUSSIAN_FISHING"' \
    2>/dev/null &

    # --field="   Secret World Legends (ENG)"!"$PW_GUI_ICON_PATH/swl.png"!"":"FBTN" '@bash -c "button_click PW_SWL"'
    # --field="   Bethesda.net Launcher"!"$PW_GUI_ICON_PATH/bethesda.png"!"":"FBTN" '@bash -c "button_click PW_BETHESDA"'

    export START_FROM_PP_GUI=1

    if [[ -z "${PW_ALL_DF}" ]] ; then
        "${pw_yad_v13_0}" --key=$KEY --notebook --expand \
        --width="${PW_MAIN_SIZE_W}" --height="${PW_MAIN_SIZE_H}" --no-buttons \
        --auto-close --window-icon="$PW_GUI_ICON_PATH/portproton.svg" \
        --title "PortProton-${install_ver} (${scripts_install_ver})" \
        --tab-pos=bottom \
        --tab="$(eval_gettext "AUTOINSTALLS")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" \
        --tab="$(eval_gettext "EMULATORS")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" \
        --tab="$(eval_gettext "WINE SETTINGS")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" \
        --tab="$(eval_gettext "PORTPROTON SETTINGS")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" \
        --tab="$(eval_gettext "INSTALLED")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" 2>/dev/null
        YAD_STATUS="$?"
    else
        "${pw_yad_v13_0}" --key=$KEY --notebook --expand \
        --width="${PW_MAIN_SIZE_W}" --height="${PW_MAIN_SIZE_H}" --no-buttons \
        --auto-close --window-icon="$PW_GUI_ICON_PATH/portproton.svg" \
        --title "PortProton-${install_ver} (${scripts_install_ver})" \
        --tab-pos=bottom \
        --tab="$(eval_gettext "INSTALLED")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" \
        --tab="$(eval_gettext "AUTOINSTALLS")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" \
        --tab="$(eval_gettext "EMULATORS")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" \
        --tab="$(eval_gettext "WINE SETTINGS")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" \
        --tab="$(eval_gettext "PORTPROTON SETTINGS")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" 2>/dev/null
        YAD_STATUS="$?"
    fi

    if [[ "$YAD_STATUS" == "1" || "$YAD_STATUS" == "252" ]] ; then exit 0 ; fi

    if [[ -f "${PORT_WINE_TMP_PATH}/tmp_yad_form" ]]; then
        PW_YAD_SET=$(head -n 1 "${PORT_WINE_TMP_PATH}/tmp_yad_form" | awk '{print $1}')
        export PW_YAD_SET
    fi
    if [[ -f "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" ]] ; then
        VULKAN_MOD="$(grep \;\; "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" | awk -F";" '{print $1}')"
        PW_PREFIX_NAME="$(grep \;\; "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" | awk -F";" '{print $2}' | sed -e "s/[[:blank:]]/_/g" )"
        PW_WINE_VER="$(grep \;\; "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan" | awk -F";" '{print $3}')"
        if [[ -z "${PW_PREFIX_NAME}" ]] \
        || echo "${PW_PREFIX_NAME}" | grep -E '^_.*'
        then
            PW_PREFIX_NAME="DEFAULT"
        else
            PW_PREFIX_NAME="${PW_PREFIX_NAME^^}"
        fi
        export PW_PREFIX_NAME VULKAN_MOD PW_WINE_VER
        try_remove_file "${PORT_WINE_TMP_PATH}/tmp_yad_form_vulkan"
    fi
    export PW_DISABLED_CREATE_DB=1
fi

case "${VULKAN_MOD}" in
    "$SORT_OPENGL" )     export PW_VULKAN_USE="0" ;;
    "$SORT_STABLE" )     export PW_VULKAN_USE="1" ;;
    "$SORT_NEWEST" )     export PW_VULKAN_USE="2" ;;
    "$SORT_G_NINE" )     export PW_VULKAN_USE="3" ;;
    "$SORT_G_ZINK" )     export PW_VULKAN_USE="4" ;;
esac

init_wine_ver

if [[ "${PW_DISABLED_CREATE_DB}" != 1 ]] ; then
    if [[ ! -z "${PORTWINE_DB}" ]] \
    && [[ -z "${PORTWINE_DB_FILE}" ]]
    then
        PORTWINE_DB_FILE=$(grep -il "\#${PORTWINE_DB}.exe" "${PORT_SCRIPTS_PATH}/portwine_db"/*)
        if [[ -z "${PORTWINE_DB_FILE}" ]] ; then
            {
                echo "#!/usr/bin/env bash"
                echo "#Author: ${USER}"
                echo "#${PORTWINE_DB}.exe"
                echo "#Rating=1-5"
            } > "${portwine_exe}".ppdb
            export PORTWINE_DB_FILE="${portwine_exe}".ppdb
        fi
    fi
    edit_db_from_gui PW_VULKAN_USE PW_WINE_USE PW_PREFIX_NAME
fi

[[ ! -z "$PW_YAD_SET" ]] && case "$PW_YAD_SET" in
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
    change_mirror) change_mirror ;;
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
