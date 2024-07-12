#!/usr/bin/env bash
# Author: Castro-Fidel (linux-gaming.ru)
# Development assistants: Cefeiko; Dezert1r; Taz_mania; Anton_Famillianov; gavr; RidBowt; chal55rus; UserDiscord; Boria138; Vano; Akai; Htylol
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

if [[ "$1" == *.ppack ]] ; then
    export PW_NO_RESTART_PPDB="1"
    export PW_DISABLED_CREATE_DB="1"
    portwine_exe="$1"
elif [[ -f "$1" ]] ; then
    portwine_exe="$(realpath "$1")"
elif [[ -f "$OLDPWD/$1" ]] && [[ "$1" == *.exe ]] ; then
    portwine_exe="$(realpath "$OLDPWD/$1")"
elif [[ "$1" == *.exe ]] ; then
    portwine_exe="$1"
    MISSING_DESKTOP_FILE=1
fi
export portwine_exe

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
export TEXTDOMAIN="PortProton"
export TEXTDOMAINDIR="${PORT_WINE_PATH}/data/locales"

if [[ ! -d "$TEXTDOMAINDIR" ]] \
&& ! command -v gettext &>/dev/null
then
    gettext() { echo "$1"; }
fi

# shellcheck source=./functions_helper
source "${PORT_SCRIPTS_PATH}/functions_helper"

create_new_dir "${HOME}/.local/share/applications"
if [[ "${PW_SILENT_RESTART}" == 1 ]] \
|| [[ "${START_FROM_STEAM}" == 1 ]]
then
    export PW_GUI_DISABLED_CS=1
    unset PW_SILENT_RESTART
else
    unset PW_GUI_DISABLED_CS
fi

unset MANGOHUD MANGOHUD_DLSYM PW_NO_ESYNC PW_NO_FSYNC PW_VULKAN_USE WINEDLLOVERRIDES PW_NO_WRITE_WATCH PW_YAD_SET PW_ICON_FOR_YAD
unset PW_CHECK_AUTOINSTALL PW_VKBASALT_EFFECTS PW_VKBASALT_FFX_CAS PORTWINE_DB PORTWINE_DB_FILE RADV_PERFTEST
unset CHK_SYMLINK_FILE PW_MESA_GL_VERSION_OVERRIDE PW_VKD3D_FEATURE_LEVEL PATH_TO_GAME PW_START_DEBUG PORTPROTON_NAME PW_PATH
unset PW_PREFIX_NAME WINEPREFIX VULKAN_MOD PW_WINE_VER PW_ADD_TO_ARGS_IN_RUNTIME PW_GAMEMODERUN_SLR AMD_VULKAN_ICD PW_WINE_CPU_TOPOLOGY
unset PW_NAME_D_NAME PW_NAME_D_ICON PW_NAME_D_EXEC PW_EXEC_FROM_DESKTOP PW_ALL_DF PW_GENERATE_BUTTONS PW_NAME_D_ICON PW_NAME_D_ICON_48
unset MANGOHUD_CONFIG FPS_LIMIT PW_WINE_USE WINEDLLPATH WINE WINEDIR WINELOADER WINESERVER PW_USE_RUNTIME PORTWINE_CREATE_SHORTCUT_NAME MIRROR
unset PW_LOCALE_SELECT PW_SETTINGS_INDICATION PW_GUI_START PW_AUTOINSTALL_EXE NOSTSTDIR

export PORT_WINE_TMP_PATH="${PORT_WINE_PATH}/data/tmp"
rm -f "$PORT_WINE_TMP_PATH"/*{exe,msi,tar}*

if mkdir -p "/tmp/PortProton" ; then
    export PW_TMPFS_PATH="/tmp/PortProton"
else
    create_new_dir "${PORT_WINE_PATH}/data/tmp/PortProton"
    export PW_TMPFS_PATH="${PORT_WINE_PATH}/data/tmp/PortProton"
fi

echo "" > "${PW_TMPFS_PATH}/tmp_yad_form"
echo "" > "${PW_TMPFS_PATH}/tmp_yad_form_vulkan"

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

cd "${PORT_SCRIPTS_PATH}" || fatal

# shellcheck source=./var
source "${PORT_SCRIPTS_PATH}/var"

export STEAM_SCRIPTS="${PORT_WINE_PATH}/steam_scripts"
export PW_PLUGINS_PATH="${PORT_WINE_TMP_PATH}/plugins${PW_PLUGINS_VER}"
export PW_GUI_ICON_PATH="${PORT_WINE_PATH}/data/img/gui"
export PW_GUI_THEMES_PATH="${PORT_WINE_PATH}/data/themes"
export pw_yad="${PW_GUI_THEMES_PATH}/gui/yad_gui_pp"

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

# choose gui start
case "$PW_GUI_START" in
       PANED) : ;;
    NOTEBOOK) : ;;
           *)
              sed -i '/export PW_GUI_START=/d' "$USER_CONF"
              echo 'export PW_GUI_START="NOTEBOOK"' >> "$USER_CONF"
              export PW_GUI_START="NOTEBOOK"
              ;;
esac

pw_check_and_download_plugins

# check skip update
if [[ "${SKIP_CHECK_UPDATES}" != 1 ]] ; then
    pw_port_update
    if command gamescope --help 2> "${PW_TMPFS_PATH}/gamescope-help.tmp" ; then
        export GAMESCOPE_INSTALLED="1"
    fi
    if command -v vulkaninfo &>/dev/null ; then
        vulkaninfo --summary 2>/dev/null > "${PW_TMPFS_PATH}/vulkaninfo.tmp"
    else
        $PW_PLUGINS_PATH/portable/bin/x86_64-linux-gnu-vulkaninfo 2>/dev/null > "${PW_TMPFS_PATH}/vulkaninfo.tmp"
    fi
    VULKAN_DRIVER_NAME="$(grep -e 'driverName' "${PW_TMPFS_PATH}/vulkaninfo.tmp" | awk '{print$3}' | head -1)"
    GET_GPU_NAMES=$(awk -F '=' '/deviceName/{print $2}' "${PW_TMPFS_PATH}/vulkaninfo.tmp" | sed '/llvm/d'| sort -u | sed 's/^ //' | paste -sd '!')
    LSPCI_VGA="$(lspci -k 2>/dev/null | grep -E 'VGA|3D' | tr -d '\n')"
    export VULKAN_DRIVER_NAME GET_GPU_NAMES LSPCI_VGA

    if command xrandr --current 2>/dev/null > "${PW_TMPFS_PATH}/xrandr.tmp" ; then
        PW_SCREEN_RESOLUTION="$(cat "${PW_TMPFS_PATH}/xrandr.tmp" | sed -rn 's/^.*primary.* ([0-9]+x[0-9]+).*$/\1/p')"
        PW_SCREEN_PRIMARY="$(grep -e 'primary' "${PW_TMPFS_PATH}/xrandr.tmp" | awk '{print $1}')"
        export PW_SCREEN_PRIMARY PW_SCREEN_RESOLUTION
        echo ""
        print_var PW_SCREEN_RESOLUTION PW_SCREEN_PRIMARY
    else
        print_error "xrandr - not found!"
    fi
    echo ""

    logical_cores=$(grep -c "^processor" /proc/cpuinfo)
    if [[ "${logical_cores}" -le "4" ]] ; then
        GET_LOGICAL_CORE="1!$(seq -s! 1 $((${logical_cores} - 1)))"
    else
        GET_LOGICAL_CORE="1!2!$(seq -s! 4 4 $((${logical_cores} - 1)))"
    fi
    export GET_LOGICAL_CORE

    GET_LOCALE_LIST="ru_RU.utf en_US.utf zh_CN.utf ja_JP.utf ko_KR.utf"
    unset LOCALE_LIST
    locale -a 2>/dev/null > "${PW_TMPFS_PATH}/locale.tmp"
    for LOCALE in $GET_LOCALE_LIST ; do
        if grep -e $LOCALE "${PW_TMPFS_PATH}/locale.tmp" &>/dev/null ; then
            if [[ ! -z "$LOCALE_LIST" ]]
            then LOCALE_LIST+="!$(grep -e $LOCALE "${PW_TMPFS_PATH}/locale.tmp")"
            else LOCALE_LIST="$(grep -e $LOCALE "${PW_TMPFS_PATH}/locale.tmp")"
            fi
        fi
    done
    export LOCALE_LIST
else
    scripts_install_ver=$(head -n 1 "${PORT_WINE_TMP_PATH}/scripts_ver")
    export scripts_install_ver
fi


# create lock file
if ! check_flatpak ; then
if [[ -f "${PW_TMPFS_PATH}/portproton.lock" ]] ; then
    print_warning "Found lock file: "${PW_TMPFS_PATH}/portproton.lock""
    yad_question "$(gettext 'A running PortProton session was detected.\nDo you want to end the previous session?')" || exit 0
fi
touch "${PW_TMPFS_PATH}/portproton.lock"
rm_lock_file () {
    echo "Removing the lock file..."
    rm -fv "${PW_TMPFS_PATH}/portproton.lock" && echo "OK"
}
trap "rm_lock_file" EXIT
fi

if check_flatpak
then try_remove_dir "${PORT_WINE_TMP_PATH}/libs${PW_LIBS_VER}"
else pw_download_libs
fi

pw_init_db

if [[ ! -d "${HOME}/PortProton" ]] \
&& check_flatpak 
then
    ln -s "${PORT_WINE_PATH}" "${HOME}/PortProton"
fi

pw_check_and_download_dxvk_and_vkd3d
# shellcheck source=/dev/null
source "${USER_CONF}"

if [[ "${SKIP_CHECK_UPDATES}" != 1 ]] ; then
    kill_portwine
    killall -15 yad_gui_pp 2>/dev/null
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
fi

[[ "$MISSING_DESKTOP_FILE" == 1 ]] && portwine_missing_shortcut

if [[ ! -z $(basename "${portwine_exe}" | grep .ppack) ]] ; then
    unset PW_SANDBOX_HOME_PATH
    pw_init_runtime
    if check_flatpak
    then TMP_ALL_PATH=""
    else TMP_ALL_PATH="LD_LIBRARY_PATH=\"${PW_LD_LIBRARY_PATH}\""
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
        yad_error "$(gettext "Unpack has FAILED for prefix:") <b>\"${PW_PREFIX_NAME}\"</b>."
        exit 1
    else
        try_remove_file "${PORT_WINE_TMP_PATH}"/pp_pfx_unpack.sh
        if [[ -f "${PORT_WINE_PATH}/data/prefixes/${PW_PREFIX_NAME}/.create_shortcut" ]] ; then
            while IFS= read -r line
            do
                export portwine_exe="$PORT_WINE_PATH/data/prefixes/$PW_PREFIX_NAME/$line"
                portwine_create_shortcut
            done < "$PORT_WINE_PATH/data/prefixes/$PW_PREFIX_NAME/.create_shortcut"
        fi
        yad_info "$(gettext "Unpack is DONE for prefix:") <b>\"${PW_PREFIX_NAME}\"</b>."
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

        echo "
--generate-pot                                      generated pot file
"
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
    && [[ "${PAIG//'./'/}" != "${PW_PREFIX_NAME}" ]] \
    && [[ -d "${PAIG}" ]]
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

# [[ "${PW_DGVOODOO2}" == "1" ]] && DGV2_TXT='<b>dgVoodoo2 </b>' || unset DGV2_TXT
# [[ "${PW_VKBASALT}" == "1" ]] && VKBASALT_TXT='<b>vkBasalt </b>' || unset VKBASALT_TXT
# [[ "${PW_MANGOHUD}" == "1" ]] && MANGOHUD_TXT='<b>MangoHud </b>' || unset MANGOHUD_TXT

SORT_OPENGL="$(gettext 'WineD3D OpenGL (For video cards without Vulkan)')"
SORT_VULKAN="$(gettext 'WineD3D Vulkan (Damavand experimental)')"
SORT_LEGACY="$(gettext 'Legacy DXVK (Vulkan v1.1)')"
SORT_STABLE="$(gettext 'Stable DXVK, VKD3D (Vulkan v1.2)')"
SORT_NEWEST="$(gettext 'Newest DXVK, VKD3D, D8VK (Vulkan v1.3+)')"
SORT_G_NINE="$(gettext 'Gallium Nine (DirectX 9 for MESA)')"
SORT_G_ZINK="$(gettext 'Gallium Zink (OpenGL to Vulkan)')"

case "${PW_VULKAN_USE}" in
    0) PW_DEFAULT_VULKAN_USE="$SORT_OPENGL!$SORT_NEWEST!$SORT_STABLE!$SORT_LEGACY!$SORT_G_ZINK!$SORT_G_NINE!$SORT_VULKAN" ;;
    6) PW_DEFAULT_VULKAN_USE="$SORT_VULKAN!$SORT_NEWEST!$SORT_STABLE!$SORT_LEGACY!$SORT_G_ZINK!$SORT_G_NINE!$SORT_OPENGL" ;;
    1) PW_DEFAULT_VULKAN_USE="$SORT_STABLE!$SORT_NEWEST!$SORT_LEGACY!$SORT_G_ZINK!$SORT_G_NINE!$SORT_OPENGL!$SORT_VULKAN" ;;
    5) PW_DEFAULT_VULKAN_USE="$SORT_LEGACY!$SORT_NEWEST!$SORT_STABLE!$SORT_G_ZINK!$SORT_G_NINE!$SORT_OPENGL!$SORT_VULKAN" ;;
    4) PW_DEFAULT_VULKAN_USE="$SORT_G_ZINK!$SORT_NEWEST!$SORT_STABLE!$SORT_LEGACY!$SORT_G_NINE!$SORT_OPENGL!$SORT_VULKAN" ;;
    3) PW_DEFAULT_VULKAN_USE="$SORT_G_NINE!$SORT_NEWEST!$SORT_STABLE!$SORT_LEGACY!$SORT_G_ZINK!$SORT_OPENGL!$SORT_VULKAN" ;;
    *) PW_DEFAULT_VULKAN_USE="$SORT_NEWEST!$SORT_STABLE!$SORT_LEGACY!$SORT_G_ZINK!$SORT_G_NINE!$SORT_OPENGL!$SORT_VULKAN" ;;
esac

if [[ ! -z "${PORTWINE_DB_FILE}" ]] ; then
    [[ -z "${PW_COMMENT_DB}" ]] && PW_COMMENT_DB="$(gettext "Launching") <b>${PORTWINE_DB}</b>."
    PW_DEFAULT_WINE_USE="${PW_WINE_USE}!${PW_PROTON_LG_VER}!${PW_WINE_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
else
    if [[ $PW_WINE_USE == PROTON_LG ]] ; then
        PW_DEFAULT_WINE_USE="${PW_PROTON_LG_VER}!${PW_WINE_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
    elif [[ $PW_WINE_USE == WINE_*_LG ]] \
    || [[ $PW_WINE_USE == WINE_LG ]]
    then
        PW_DEFAULT_WINE_USE="${PW_WINE_LG_VER}!${PW_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
    else
        PW_DEFAULT_WINE_USE="${PW_WINE_USE}!${PW_PROTON_LG_VER}!${PW_WINE_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
    fi
    unset PW_GUI_DISABLED_CS
fi

if [[ -f "${portwine_exe}" ]] ; then
    if [[ "${PW_GUI_DISABLED_CS}" != 1 ]] ; then
        pw_create_gui_png
        grep -il "${portwine_exe}" "${HOME}/.local/share/applications"/*.desktop
        if [[ "$?" != "0" ]] ; then
            PW_SHORTCUT="$(gettext "CREATE SHORTCUT")!$PW_GUI_ICON_PATH/$BUTTON_SIZE.png!$(gettext "Create shortcut for select file..."):100"
        else
            PW_SHORTCUT="$(gettext "DELETE SHORTCUT")!$PW_GUI_ICON_PATH/$BUTTON_SIZE.png!$(gettext "Delete shortcut for select file..."):98"
        fi

        export KEY_START="$RANDOM"
        if [[ "${PW_GUI_START}" == "NOTEBOOK" ]] ; then
            "${pw_yad}" --plug=$KEY_START --tabnum=1 --form --separator=";" ${START_GUI_TYPE} \
            --gui-type-box=${START_GUI_TYPE_BOX} --gui-type-layout=${START_GUI_TYPE_LAYOUT_UP} \
            --gui-type-text=${START_GUI_TYPE_TEXT} --gui-type-images=${START_GUI_TYPE_IMAGE} \
            --image="${PW_ICON_FOR_YAD}" --text-align="center" --text "$PW_COMMENT_DB" \
            --field="3D API  : :CB" "${PW_DEFAULT_VULKAN_USE}" \
            --field="  WINE  : :CB" "$(combobox_fix "${PW_WINE_USE}" "${PW_DEFAULT_WINE_USE}")" \
            --field="PREFIX  : :CBE" "${PW_ADD_PREFIXES_TO_GUI}" \
            1> "${PW_TMPFS_PATH}/tmp_yad_form_vulkan" 2>/dev/null &

            "${pw_yad}" --plug=$KEY_START --tabnum=2 --form --columns="${START_GUI_NOTEBOOK_COLUMNS}" --align-buttons --homogeneous-column \
            --gui-type-layout=${START_GUI_TYPE_LAYOUT_NOTEBOOK} \
            --field="   $(gettext "Base settings")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(gettext "Edit database file for") ${PORTWINE_DB}":"FBTN" '@bash -c "button_click_start 118"' \
            --field="   vkBasalt"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(gettext "Enable vkBasalt by default to improve graphics in games running on Vulkan. (The HOME hotkey disables vkbasalt)")":"FBTN" '@bash -c "button_click_start 120"' \
            --field="   MangoHud"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(gettext "Enable Mangohud by default (R_SHIFT + F12 keyboard shortcuts disable Mangohud)")":"FBTN" '@bash -c "button_click_start 122"' \
            --field="   dgVoodoo2"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(gettext "Enable dgVoodoo2 by default (This wrapper fixes many compatibility and rendering issues when running old games)")":"FBTN" '@bash -c "button_click_start 124"' \
            --field="   GameScope"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(gettext "Enable GameScope by default (Wayland micro compositor)")":"FBTN" '@bash -c "button_click_start 126"' \
            2>/dev/null &

            if [[ "${PW_YAD_FORM_TAB}" == "1" ]] \
            && [[ ! -z "${TAB_START}" ]]
            then
                export TAB_START="2"
                unset PW_YAD_FORM_TAB
            else
                export TAB_START="1"
            fi

            "${pw_yad}" --key=$KEY_START --notebook --active-tab=${TAB_START} \
            --gui-type=settings-notebook \
            --width="${PW_START_SIZE_W}" --tab-pos="${PW_TAB_POSITON}" --center \
            --title "PortProton-${install_ver} (${scripts_install_ver})" --expand \
            --window-icon="$PW_GUI_ICON_PATH/portproton.svg" \
            --tab="$(gettext "GENERAL")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" \
            --tab="$(gettext "SETTINGS")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" \
            --button="$(gettext "MAIN MENU")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(gettext "Main menu")":128 \
            --button="${PW_SHORTCUT}" \
            --button="$(gettext "DEBUG")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(gettext "Launch with the creation of a .log file at the root PortProton")":102 \
            --button="$(gettext "LAUNCH")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(gettext "Run file ...")":106 2>/dev/null

            PW_YAD_SET="$?"
            if [[ "$PW_YAD_SET" == "1" || "$PW_YAD_SET" == "252" ]] ; then exit 0 ; fi
            if [[ $(<"${PW_TMPFS_PATH}/tmp_yad_form") != "" ]]; then
                PW_YAD_SET=$(head -n 1 "${PW_TMPFS_PATH}/tmp_yad_form" | awk '{print $1}')
                export PW_YAD_SET
                export PW_YAD_FORM_TAB="1"
            fi
            pw_yad_form_vulkan
            pw_yad_set

        elif [[ "${PW_GUI_START}" == "PANED" ]] ; then
            "${pw_yad}" --plug=$KEY_START --tabnum=1 --form --separator=";" ${START_GUI_TYPE} \
            --gui-type-box=${START_GUI_TYPE_BOX} --gui-type-layout=${START_GUI_TYPE_LAYOUT_UP} \
            --gui-type-text=${START_GUI_TYPE_TEXT} --gui-type-images=${START_GUI_TYPE_IMAGE} \
            --image="${PW_ICON_FOR_YAD}" --text-align="center" --text "$PW_COMMENT_DB" \
            --field="3D API  : :CB" "${PW_DEFAULT_VULKAN_USE}" \
            --field="  WINE  : :CB" "$(combobox_fix "${PW_WINE_USE}" "${PW_DEFAULT_WINE_USE}")" \
            --field="PREFIX  : :CBE" "${PW_ADD_PREFIXES_TO_GUI}" \
            1> "${PW_TMPFS_PATH}/tmp_yad_form_vulkan" 2>/dev/null &

            "${pw_yad}" --plug=$KEY_START --tabnum=2 --form --columns="${START_GUI_PANED_COLUMNS}" \
            --gui-type-layout=${START_GUI_TYPE_LAYOUT_PANED} \
            --align-buttons --homogeneous-row --homogeneous-column \
            --field="   $(gettext "Base settings")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(gettext "Edit database file for") ${PORTWINE_DB}":"FBTN" '@bash -c "button_click_start 118"' \
            --field="   vkBasalt"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(gettext "Enable vkBasalt by default to improve graphics in games running on Vulkan. (The HOME hotkey disables vkbasalt)")":"FBTN" '@bash -c "button_click_start 120"' \
            --field="   MangoHud"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(gettext "Enable Mangohud by default (R_SHIFT + F12 keyboard shortcuts disable Mangohud)")":"FBTN" '@bash -c "button_click_start 122"' \
            --field="   dgVoodoo2"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(gettext "Enable dgVoodoo2 by default (This wrapper fixes many compatibility and rendering issues when running old games)")":"FBTN" '@bash -c "button_click_start 124"' \
            --field="   GameScope"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(gettext "Enable GameScope by default (Wayland micro compositor)")":"FBTN" '@bash -c "button_click_start 126"' \
            2>/dev/null &

            "${pw_yad}" --key=$KEY_START --paned --center \
            --gui-type=settings-paned \
            --width="${PW_START_SIZE_W}" --tab-pos="${PW_TAB_POSITON}" \
            --title "PortProton-${install_ver} (${scripts_install_ver})" \
            --window-icon="$PW_GUI_ICON_PATH/portproton.svg" \
            --button="$(gettext "MAIN MENU")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(gettext "Main menu")":128 \
            --button="${PW_SHORTCUT}" \
            --button="$(gettext "DEBUG")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(gettext "Launch with the creation of a .log file at the root PortProton")":102 \
            --button="$(gettext "LAUNCH")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(gettext "Run file ...")":106 2>/dev/null

            PW_YAD_SET="$?"
            if [[ "$PW_YAD_SET" == "1" || "$PW_YAD_SET" == "252" ]] ; then exit 0 ; fi
            pw_yad_set_form
            pw_yad_form_vulkan
            pw_yad_set
        fi

    elif [[ -f "${PORTWINE_DB_FILE}" ]] ; then
        portwine_launch
    fi
else
   gui_mainmenu
fi

stop_portwine
