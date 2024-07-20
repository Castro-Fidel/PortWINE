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

$PW_DEBUG
if [[ $(id -u) = 0 ]] ; then
    echo "Do not run this script as root!"
    exit 1
fi

export PW_START_PID="$$"
export NO_AT_BRIDGE="1"
export GDK_BACKEND="x11"
export pw_full_command_line=("$0" $*)

MISSING_DESKTOP_FILE=0

unset PW_NO_RESTART_PPDB PW_DISABLED_CREATE_DB
if [[ "$1" == *.ppack ]] ; then
    export PW_NO_RESTART_PPDB="1"
    export PW_DISABLED_CREATE_DB="1"
    portwine_exe="$1"
elif [[ -f "$1" ]] ; then
    portwine_exe="$(realpath "$1")"
elif [[ -f "$OLDPWD/$1" ]] && [[ "$1" == *.exe ]] ; then
    portwine_exe="$(realpath "$OLDPWD/$1")"
elif [[ "$1" == "--debug" ]] && [[ -f "$2" ]] ; then
    portwine_exe="$(realpath "$2")"
elif [[ "$1" == "--debug" ]] && [[ -f "$OLDPWD/$2" ]] && [[ "$2" == *.exe ]] ; then
    portwine_exe="$(realpath "$OLDPWD/$2")"
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
unset PW_LOCALE_SELECT PW_SETTINGS_INDICATION PW_GUI_START PW_AUTOINSTALL_EXE NOSTSTDIR USE_DUPLICATE_GUI

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

try_remove_file "${PW_TMPFS_PATH}/update_pfx_log"

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

# choose branch
if [[ -z "$BRANCH" ]] ; then
    echo 'export BRANCH="master"' >> "$USER_CONF"
    export BRANCH="master"
fi
if [[ "$BRANCH" == "master" ]] ; then
    print_info "Branch in used: STABLE\n"
    export BRANCH_VERSION=""
else
    print_warning "Branch in used: DEVEL\n"
    export BRANCH_VERSION="-dev"
fi

# choose mirror
if [[ -z "$MIRROR" ]] \
&& [[ "$LANGUAGE" == "ru" ]] \
&& [[ "$BRANCH" != "devel" ]]
then
    echo 'export MIRROR="CDN"' >> "$USER_CONF"
    MIRROR="CDN"
elif [[ -z "$MIRROR" ]] ; then
    echo 'export MIRROR="GITHUB"' >> "$USER_CONF"
    MIRROR="GITHUB"
fi
export MIRROR
print_info "The first mirror in used: $MIRROR\n"


if [[ "${INSTALLING_PORT}" == 1 ]] ; then
    return 0
fi

# choose gui start
case "$PW_GUI_START" in
    PANED|NOTEBOOK) : ;;
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

    if timeout 3 gamescope --help 2> "${PW_TMPFS_PATH}/gamescope-help.tmp" ; then
        export GAMESCOPE_INSTALLED="1"
    else
        if ! command -v gamescope &>/dev/null ; then
            print_error "gamescope - not found!"
        else
            yad_error "gamescope - broken!"
        fi
    fi

    if timeout 3 vulkaninfo --summary 2>/dev/null > "${PW_TMPFS_PATH}/vulkaninfo.tmp" ; then
        VULKAN_DRIVER_NAME="$(grep -e 'driverName' "${PW_TMPFS_PATH}/vulkaninfo.tmp" | awk '{print$3}' | head -1)"
        GET_GPU_NAMES=$(awk -F '=' '/deviceName/{print $2}' "${PW_TMPFS_PATH}/vulkaninfo.tmp" | sed '/llvm/d'| sort -u | sed 's/^ //' | paste -sd '!')
        export VULKAN_DRIVER_NAME GET_GPU_NAMES
    else
        if ! command -v vulkaninfo &>/dev/null ; then
            print_warning "use portable vulkaninfo"
            $PW_PLUGINS_PATH/portable/bin/x86_64-linux-gnu-vulkaninfo 2>/dev/null > "${PW_TMPFS_PATH}/vulkaninfo.tmp"
            VULKAN_DRIVER_NAME="$(grep -e 'driverName' "${PW_TMPFS_PATH}/vulkaninfo.tmp" | awk '{print$3}' | head -1)"
            GET_GPU_NAMES=$(awk -F '=' '/deviceName/{print $2}' "${PW_TMPFS_PATH}/vulkaninfo.tmp" | sed '/llvm/d'| sort -u | sed 's/^ //' | paste -sd '!')
            export VULKAN_DRIVER_NAME GET_GPU_NAMES
        else
            yad_error "vulkaninfo - broken!"
        fi
    fi

    if timeout 3 lspci -k 2>/dev/null > "${PW_TMPFS_PATH}/lspci.tmp" ; then
        LSPCI_VGA="$(grep -e 'VGA|3D' "${PW_TMPFS_PATH}/lspci.tmp" | tr -d '\n')"
        export LSPCI_VGA
    else
        if ! command -v lspci &>/dev/null ; then
            print_error "lspci - not found!"
        else
            yad_error "lspci - broken!"
        fi
    fi

    if timeout 3 xrandr --current 2>/dev/null > "${PW_TMPFS_PATH}/xrandr.tmp" ; then
        PW_SCREEN_RESOLUTION="$(cat "${PW_TMPFS_PATH}/xrandr.tmp" | sed -rn 's/^.*primary.* ([0-9]+x[0-9]+).*$/\1/p')"
        PW_SCREEN_PRIMARY="$(grep -e 'primary' "${PW_TMPFS_PATH}/xrandr.tmp" | awk '{print $1}')"
        export PW_SCREEN_PRIMARY PW_SCREEN_RESOLUTION
        echo ""
        print_var PW_SCREEN_RESOLUTION PW_SCREEN_PRIMARY
    else
        if ! command -v xrandr &>/dev/null ; then
            print_error "xrandr - not found!"
        else
            yad_error "xrandr - broken!"
        fi
    fi
    echo ""

    logical_cores=$(grep -c "^processor" /proc/cpuinfo)
    if [[ "${logical_cores}" -le "4" ]] ; then
        GET_LOGICAL_CORE="1!$(seq -s! 1 $((${logical_cores} - 1)))"
    else
        GET_LOGICAL_CORE="1!2!$(seq -s! 4 4 $((${logical_cores} - 1)))"
    fi
    export GET_LOGICAL_CORE

    if timeout 3 locale -a 2>/dev/null > "${PW_TMPFS_PATH}/locale.tmp" ; then
        GET_LOCALE_LIST="ru_RU.utf en_US.utf zh_CN.utf ja_JP.utf ko_KR.utf"
        unset LOCALE_LIST
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
        if ! command -v locale &>/dev/null ; then
            print_error "locale - not found!"
        else
            yad_error "locale - broken!"
        fi
    fi

    PW_FILESYSTEM=$(stat -f -c %T "${PORT_WINE_PATH}")
    export PW_FILESYSTEM
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
use: [--repair] [--reinstall] [--autoinstall]

--repair                                            forces all scripts to be updated to a working state
                                                    (helps if PortProton is not working)
--reinstall                                         reinstall files of the portproton to default settings
--autoinstall [script_frome_pw_autoinstall]         autoinstall from the list below:
"
        echo ${files_from_autoinstall}

        echo "
--generate-pot                                      generated pot file
"
        echo "
--debug                                             debug scripts for PortProton
                                                    (saved log in "$PORT_WINE_PATH/scripts-debug.log")
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

    '--debug' )
        clear
        export PW_DEBUG="set -x"
        /usr/bin/env bash -c ${pw_full_command_line[*]} 2>&1 | tee "$PORT_WINE_PATH/scripts-debug.log" &
        exit 0 ;;
esac

### GUI ###

unset PW_ADD_PREFIXES_TO_GUI
if [[ -d "${PORT_WINE_PATH}/data/prefixes/" ]] ; then
    PW_PREFIX_NAME="${PW_PREFIX_NAME//[[:blank:]]/_}"
    for PAIG in ${PORT_WINE_PATH}/data/prefixes/* ; do
        if [[ "${PAIG//"${PORT_WINE_PATH}/data/prefixes/"/}" != "${PORTWINE_DB^^//[[:blank:]]/_}" ]] \
        && [[ "${PAIG//"${PORT_WINE_PATH}/data/prefixes/"/}" != "${PW_PREFIX_NAME}" ]] \
        && [[ "${PAIG//"${PORT_WINE_PATH}/data/prefixes/"/}" != "*" ]]
        then
            PW_ADD_PREFIXES_TO_GUI="${PW_ADD_PREFIXES_TO_GUI}!${PAIG//"${PORT_WINE_PATH}/data/prefixes/"/}"
        fi
    done
    PW_ADD_PREFIXES_TO_GUI="${PW_PREFIX_NAME^^}${PW_ADD_PREFIXES_TO_GUI}"
fi

unset DIST_ADD_TO_GUI
if command -v wine &>/dev/null
then DIST_ADD_TO_GUI="!USE_SYSTEM_WINE"
fi
if [[ -d "${PORT_WINE_PATH}/data/dist/" ]] ; then
    for DAIG in ${PORT_WINE_PATH}/data/dist/* ; do
        if [[ "${DAIG//"${PORT_WINE_PATH}/data/dist/"/}" != "${PW_WINE_LG_VER}" ]] \
        && [[ "${DAIG//"${PORT_WINE_PATH}/data/dist/"/}" != "${PW_PROTON_LG_VER}" ]] \
        && [[ "${DAIG//"${PORT_WINE_PATH}/data/dist/"/}" != "*" ]]
        then
            DIST_ADD_TO_GUI="${DIST_ADD_TO_GUI}!${DAIG//"${PORT_WINE_PATH}/data/dist/"/}"
        fi
    done
fi

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

if [[ ! -z "${PW_COMMENT_DB}" ]] ; then :
elif  [[ ! -z "${PORTPROTON_NAME}" ]] ; then
    PW_COMMENT_DB="$(gettext "Launching") <b>${PORTPROTON_NAME}</b>"
else
    PW_COMMENT_DB="$(gettext "Launching") <b>${PORTWINE_DB}</b>"
fi

if [[ $PW_WINE_USE == PROTON_LG ]] ; then
    PW_WINE_USE="${PW_PROTON_LG_VER}"
    PW_DEFAULT_WINE_USE="${PW_WINE_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
elif [[ $PW_WINE_USE == WINE_*_LG ]] \
|| [[ $PW_WINE_USE == WINE_LG ]]
then
    PW_WINE_USE="${PW_WINE_LG_VER}"
    PW_DEFAULT_WINE_USE="${PW_PROTON_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
else
    PW_DEFAULT_WINE_USE="${PW_PROTON_LG_VER}!${PW_WINE_LG_VER}${DIST_ADD_TO_GUI}!GET-OTHER-WINE"
fi

if [[ -z "${PORTWINE_DB_FILE}" ]] ; then
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
            --gui-type="settings-notebook" \
            --width="${PW_START_SIZE_W}" --tab-pos="${PW_TAB_POSITON}" --center \
            --title "PortProton-${install_ver} (${scripts_install_ver}${BRANCH_VERSION})" --expand \
            --window-icon="$PW_GUI_ICON_PATH/portproton.svg" \
            --tab="$(gettext "GENERAL")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" \
            --tab="$(gettext "SETTINGS")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" \
            --button="${PW_SHORTCUT}" \
            --button="$(gettext "DEBUG")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(gettext "Launch with the creation of a .log file at the root PortProton")":102 \
            --button="$(gettext "LAUNCH")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(gettext "Run file ...")":106 2>/dev/null

            PW_YAD_SET="$?"
            if [[ "$PW_YAD_SET" == "1" || "$PW_YAD_SET" == "252" ]] ; then exit 0 ; fi
            if [[ $(<"${PW_TMPFS_PATH}/tmp_yad_form") != "" ]] ; then
                PW_YAD_SET=$(head -n 1 "${PW_TMPFS_PATH}/tmp_yad_form" | awk '{print $1}')
                export PW_YAD_SET
                export PW_YAD_FORM_TAB="1"
            fi
            pw_yad_form_vulkan

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
            --gui-type="settings-paned" \
            --width="${PW_START_SIZE_W}" --tab-pos="${PW_TAB_POSITON}" \
            --title "PortProton-${install_ver} (${scripts_install_ver}${BRANCH_VERSION})" \
            --window-icon="$PW_GUI_ICON_PATH/portproton.svg" \
            --button="${PW_SHORTCUT}" \
            --button="$(gettext "DEBUG")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(gettext "Launch with the creation of a .log file at the root PortProton")":102 \
            --button="$(gettext "LAUNCH")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE.png"!"$(gettext "Run file ...")":106 2>/dev/null

            PW_YAD_SET="$?"
            if [[ "$PW_YAD_SET" == "1" || "$PW_YAD_SET" == "252" ]] ; then exit 0 ; fi
            pw_yad_set_form
            pw_yad_form_vulkan
        fi

    elif [[ -f "${PORTWINE_DB_FILE}" ]] ; then
        portwine_launch
    fi
else
    export KEY="$RANDOM"

    if [[ "$MIRROR" == "CDN" ]]
    then NEW_MIRROR="GITHUB"
    else NEW_MIRROR="CDN"
    fi

    if [[ "$BRANCH" == "master" ]]
    then NEW_BRANCH="DEVEL"
    else NEW_BRANCH="STABLE"
    fi

    orig_IFS="$IFS" && IFS=$'\n'
    PW_ALL_DF="$(ls "${PORT_WINE_PATH}"/ | grep .desktop | grep -vE '(PortProton|readme)')"
    if [[ -z "${PW_ALL_DF}" ]]
    then PW_GUI_SORT_TABS=(1 2 3 4 5)
    else PW_GUI_SORT_TABS=(2 3 4 5 1)
    fi
    PW_GENERATE_BUTTONS="--field=   $(gettext "Create shortcut...")!${PW_GUI_ICON_PATH}/find_48.svg!:FBTN%@bash -c \"button_click pw_find_exe\"%"
    if grep -i "[Desktop Entry]" "${PORT_WINE_PATH}/duplicate"/* &>/dev/null ; then
        PW_GENERATE_BUTTONS+="--field=   $(gettext "Duplicates")!${PW_GUI_ICON_PATH}/find_48.svg!:FBTN%@bash -c \"button_click pw_duplicate\"%"
    fi
    for PW_DESKTOP_FILES in ${PW_ALL_DF} ; do
        PW_NAME_D_ICON="$(grep Icon "${PORT_WINE_PATH}/${PW_DESKTOP_FILES}" | awk -F= '{print $2}')"
        PW_NAME_D_ICON_48="${PW_NAME_D_ICON//".png"/"_48.png"}"
        if [[ ! -f "${PW_NAME_D_ICON_48}" ]]  \
        && [[ -f "${PW_NAME_D_ICON}" ]] \
        && command -v "convert" 2>/dev/null
        then
            convert "${PW_NAME_D_ICON}" -resize 48x48 "${PW_NAME_D_ICON_48}"
        fi
        PW_DESKTOP_HELPER="${PW_DESKTOP_FILES// /@_@}"
        PW_GENERATE_BUTTONS+="--field=   ${PW_DESKTOP_FILES//".desktop"/""}!${PW_NAME_D_ICON_48}!:FBTN%@bash -c \"run_desktop_b_click "${PW_DESKTOP_HELPER}"\"%"
    done

    IFS="$orig_IFS"
    old_IFS=$IFS && IFS="%"
    "${pw_yad}" --plug=$KEY --tabnum="${PW_GUI_SORT_TABS[4]}" --form --columns="$MAIN_GUI_COLUMNS" --homogeneous-column \
    --gui-type-layout=${MAIN_MENU_GUI_TYPE_LAYOUT} \
    --align-buttons --scroll --separator=" " ${PW_GENERATE_BUTTONS} 2>/dev/null &
    IFS="$orig_IFS"

    "${pw_yad}" --plug=$KEY --tabnum="${PW_GUI_SORT_TABS[3]}" --form --columns=3 --align-buttons --separator=";" --homogeneous-column \
    --gui-type-layout=${MAIN_MENU_GUI_TYPE_LAYOUT} \
    --field="   $(gettext "Reinstall PortProton")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click gui_pw_reinstall_pp"' \
    --field="   $(gettext "Remove PortProton")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click gui_rm_portproton"' \
    --field="   $(gettext "Update PortProton")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click gui_pw_update"' \
    --field="   $(gettext "Changelog")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click open_changelog"' \
    --field="   $(gettext "Change language")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click change_loc"' \
    --field="   $(gettext "Edit user.conf")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click gui_open_user_conf"' \
    --field="   $(gettext "Scripts from backup")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click gui_open_scripts_from_backup"' \
    --field="   Xterm"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click pw_start_cont_xterm"' \
    --field="   $(gettext "Credits")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click gui_credits"' \
    --field="   $(gettext "Change mirror to") $NEW_MIRROR"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click change_mirror"' \
    --field="   $(gettext "Change branch to") $NEW_BRANCH"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click change_branch"' \
    --field="   $(gettext "Change start gui")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"FBTN" '@bash -c "button_click change_gui_start"' \
    2>/dev/null &

    "${pw_yad}" --plug=$KEY --tabnum="${PW_GUI_SORT_TABS[2]}" --form --columns=3 --align-buttons --separator=";" \
    --gui-type-layout=${MAIN_MENU_GUI_TYPE_LAYOUT} \
    --field="   3D API  : :CB" "${PW_DEFAULT_VULKAN_USE}" \
    --field="   PREFIX  : :CBE" "${PW_ADD_PREFIXES_TO_GUI}" \
    --field="     WINE  : :CB" "$(combobox_fix "${PW_WINE_USE}" "${PW_DEFAULT_WINE_USE}")" \
    --field="$(gettext "Create prefix backup")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"":"CFBTN" '@bash -c "button_click pw_create_prefix_backup"' \
    --field="   Winetricks"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"$(gettext "Run winetricks to install additional libraries to the selected prefix")":"FBTN" '@bash -c "button_click WINETRICKS"' \
    --field="   $(gettext "Clear prefix")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"$(gettext "Clear the prefix to fix problems")":"FBTN" '@bash -c "button_click gui_clear_pfx"' \
    --field="   $(gettext "Get other Wine")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"$(gettext "Open the menu to download other versions of WINE or PROTON")":"FBTN" '@bash -c "button_click gui_proton_downloader"' \
    --field="   $(gettext "Uninstaller")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"$(gettext "Run the program uninstaller built into wine")":"FBTN" '@bash -c "button_click gui_wine_uninstaller"' \
    --field="   $(gettext "Prefix Manager")     "!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"$(gettext "Run winecfg to edit the settings of the selected prefix")":"FBTN" '@bash -c "button_click WINECFG"' \
    --field="   $(gettext "File Manager")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"$(gettext "Run wine file manager")":"FBTN" '@bash -c "button_click WINEFILE"' \
    --field="   $(gettext "Command line")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"$(gettext "Run wine cmd")":"FBTN" '@bash -c "button_click WINECMD"' \
    --field="   $(gettext "Regedit")"!"$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png"!"$(gettext "Run wine regedit")":"FBTN" '@bash -c "button_click WINEREG"' 1> "${PW_TMPFS_PATH}/tmp_yad_form_vulkan" 2>/dev/null &

    "${pw_yad}" --plug=$KEY --tabnum="${PW_GUI_SORT_TABS[1]}" --form --columns="$MAIN_GUI_COLUMNS" --align-buttons --scroll --homogeneous-column \
    --gui-type-layout=${MAIN_MENU_GUI_TYPE_LAYOUT} \
    --field="   Dolphin 5.0"!"$PW_GUI_ICON_PATH/dolphin.png"!"$(gettext "Emulator for Nintendo game consoles with high compatibility")":"FBTN" '@bash -c "button_click PW_DOLPHIN"' \
    --field="   MAME"!"$PW_GUI_ICON_PATH/mame.png"!"$(gettext "Multi-arcade emulator that allows you to play old arcade games")":"FBTN" '@bash -c "button_click PW_MAME"' \
    --field="   RetroArch"!"$PW_GUI_ICON_PATH/retroarch.png"!"$(gettext "Multi-platform frontend for emulators with extensive settings")":"FBTN" '@bash -c "button_click PW_RETROARCH"' \
    --field="   PPSSPP Windows"!"$PW_GUI_ICON_PATH/ppsspp.png"!"$(gettext "Emulator for the PlayStation Portable (PSP) game console")":"FBTN" '@bash -c "button_click PW_PPSSPP"' \
    --field="   Citra"!"$PW_GUI_ICON_PATH/citra.png"!"$(gettext "Emulator for the Nintendo 3DS game console")":"FBTN" '@bash -c "button_click PW_CITRA"' \
    --field="   Cemu"!"$PW_GUI_ICON_PATH/cemu.png"!"$(gettext "Emulator for the Wii U game console")":"FBTN" '@bash -c "button_click PW_CEMU"' \
    --field="   ePSXe"!"$PW_GUI_ICON_PATH/epsxe.png"!"$(gettext "Emulator for the PlayStation 1 game console with high compatibility")":"FBTN" '@bash -c "button_click PW_EPSXE"' \
    --field="   Project64"!"$PW_GUI_ICON_PATH/project64.png"!"$(gettext "Emulator for the Nintendo 64 game console")":"FBTN" '@bash -c "button_click PW_PROJECT64"' \
    --field="   VBA-M"!"$PW_GUI_ICON_PATH/vba-m.png"!"$(gettext "Emulator for the Game Boy Advance game console")":"FBTN" '@bash -c "button_click PW_VBA-M"' \
    --field="   Yabause"!"$PW_GUI_ICON_PATH/yabause.png"!"$(gettext "Emulator for the Sega Saturn game console")":"FBTN" '@bash -c "button_click PW_YABAUSE"' \
    --field="   Xenia"!"$PW_GUI_ICON_PATH/xenia.png"!"$(gettext "Emulator for the Xbox 360 game console")":"FBTN" '@bash -c "button_click PW_XENIA"' \
    --field="   FCEUX"!"$PW_GUI_ICON_PATH/fceux.png"!"$(gettext "Emulator for the Nintendo Entertainment System (NES or Dendy) game console")":"FBTN" '@bash -c "button_click PW_FCEUX"' \
    --field="   xemu"!"$PW_GUI_ICON_PATH/xemu.png"!"$(gettext "Emulator for the Xbox game console")":"FBTN" '@bash -c "button_click PW_XEMU"' \
    --field="   Demul"!"$PW_GUI_ICON_PATH/demul.png"!"$(gettext "Emulator for the Sega Dreamcast game console")":"FBTN" '@bash -c "button_click PW_DEMUL"' 2>/dev/null &

    "${pw_yad}" --plug=$KEY --tabnum="${PW_GUI_SORT_TABS[0]}" --form --columns="$MAIN_GUI_COLUMNS" --align-buttons --scroll --homogeneous-column \
    --gui-type-layout=${MAIN_MENU_GUI_TYPE_LAYOUT} \
    --field="   Lesta Game Center"!"$PW_GUI_ICON_PATH/lgc.png"!"":"FBTN" '@bash -c "button_click PW_LGC"' \
    --field="   vkPlay Games Center"!"$PW_GUI_ICON_PATH/mygames.png"!"":"FBTN" '@bash -c "button_click PW_VKPLAY"' \
    --field="   Battle.net Launcher"!"$PW_GUI_ICON_PATH/battle_net.png"!"":"FBTN" '@bash -c "button_click PW_BATTLE_NET"' \
    --field="   Epic Games Launcher"!"$PW_GUI_ICON_PATH/epicgames.png"!"":"FBTN" '@bash -c "button_click PW_EPIC"' \
    --field="   GoG Galaxy Launcher"!"$PW_GUI_ICON_PATH/gog.png"!"":"FBTN" '@bash -c "button_click PW_GOG"' \
    --field="   Ubisoft Game Launcher"!"$PW_GUI_ICON_PATH/ubc.png"!"":"FBTN" '@bash -c "button_click PW_UBC"' \
    --field="   EVE Online Launcher"!"$PW_GUI_ICON_PATH/eve.png"!"":"FBTN" '@bash -c "button_click PW_EVE"' \
    --field="   Rockstar Games Launcher"!"$PW_GUI_ICON_PATH/Rockstar.png"!"":"FBTN" '@bash -c "button_click PW_ROCKSTAR"' \
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
    --field="   HoYoPlay"!"$PW_GUI_ICON_PATH/hoyoplay.png"!"":"FBTN" '@bash -c "button_click PW_HO_YO_PLAY"' \
    --field="   EA App (TEST)"!"$PW_GUI_ICON_PATH/eaapp.png"!"":"FBTN" '@bash -c "button_click PW_EAAPP"' \
    --field="   Battle Of Space Raiders"!"$PW_GUI_ICON_PATH/bsr.png"!"":"FBTN" '@bash -c "button_click PW_BSR"' \
    --field="   Black Desert Online (RU)"!"$PW_GUI_ICON_PATH/bdo.png"!"":"FBTN" '@bash -c "button_click PW_BDO"' \
    --field="   Pulse Online"!"$PW_GUI_ICON_PATH/pulseonline.png"!"":"FBTN" '@bash -c "button_click PW_PULSE_ONLINE"' \
    --field="   CatsLauncher (Front Edge)"!"$PW_GUI_ICON_PATH/catslauncher.png"!"":"FBTN" '@bash -c "button_click PW_CATSLAUNCHER"' \
    --field="   Russian Fishing 4"!"$PW_GUI_ICON_PATH/rf4launcher.png"!"":"FBTN" '@bash -c "button_click PW_RUSSIAN_FISHING"' \
    --field="   W3D Hub Launcher"!"$PW_GUI_ICON_PATH/w3dhub.png"!"":"FBTN" '@bash -c "button_click PW_W3D_HUB"' \
    --field="   Anomaly Zone"!"$PW_GUI_ICON_PATH/anomalyzone.png"!"":"FBTN" '@bash -c "button_click PW_ANOMALY_ZONE"' \
    2>/dev/null &

    # --field="   Secret World Legends (ENG)"!"$PW_GUI_ICON_PATH/swl.png"!"":"FBTN" '@bash -c "button_click PW_SWL"'
    # --field="   Bethesda.net Launcher"!"$PW_GUI_ICON_PATH/bethesda.png"!"":"FBTN" '@bash -c "button_click PW_BETHESDA"'
    # --field="   League of Legends"!"$PW_GUI_ICON_PATH/lol.png"!"":"FBTN" '@bash -c "button_click PW_LOL"'

    export START_FROM_PP_GUI=1

    if [[ -z "${PW_ALL_DF}" ]] ; then
        "${pw_yad}" --key=$KEY --notebook --expand \
        --gui-type="settings-notebook" \
        --width="${PW_MAIN_SIZE_W}" --height="${PW_MAIN_SIZE_H}" --no-buttons \
        --window-icon="$PW_GUI_ICON_PATH/portproton.svg" \
        --title "PortProton-${install_ver} (${scripts_install_ver}${BRANCH_VERSION})" \
        --tab-pos="bottom" \
        --tab="$(gettext "AUTOINSTALLS")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" \
        --tab="$(gettext "EMULATORS")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" \
        --tab="$(gettext "WINE SETTINGS")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" \
        --tab="$(gettext "PORTPROTON SETTINGS")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" \
        --tab="$(gettext "INSTALLED")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" 2>/dev/null
        YAD_STATUS="$?"
    else
        "${pw_yad}" --key=$KEY --notebook --expand \
        --gui-type="settings-notebook" \
        --width="${PW_MAIN_SIZE_W}" --height="${PW_MAIN_SIZE_H}" --no-buttons \
        --window-icon="$PW_GUI_ICON_PATH/portproton.svg" \
        --title "PortProton-${install_ver} (${scripts_install_ver}${BRANCH_VERSION})" \
        --tab-pos="bottom" \
        --tab="$(gettext "INSTALLED")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" \
        --tab="$(gettext "AUTOINSTALLS")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" \
        --tab="$(gettext "EMULATORS")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" \
        --tab="$(gettext "WINE SETTINGS")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" \
        --tab="$(gettext "PORTPROTON SETTINGS")"!"$PW_GUI_ICON_PATH/$TAB_SIZE.png"!"" 2>/dev/null
        YAD_STATUS="$?"
    fi

    if [[ "$YAD_STATUS" == "1" || "$YAD_STATUS" == "252" ]] ; then exit 0 ; fi
    pw_yad_set_form

    if [[ "$(<"${PW_TMPFS_PATH}/tmp_yad_form_vulkan")" != "" ]] ; then
        YAD_FORM_VULKAN=$(<"${PW_TMPFS_PATH}/tmp_yad_form_vulkan")
        VULKAN_MOD=$(echo "${YAD_FORM_VULKAN}" | grep \;\; | awk -F";" '{print $1}')
        PW_PREFIX_NAME=$(echo "${YAD_FORM_VULKAN}" | grep \;\; | awk -F";" '{print $2}' | sed -e s/[[:blank:]]/_/g)
        PW_WINE_VER=$(echo "${YAD_FORM_VULKAN}" | grep \;\; | awk -F";" '{print $3}')
        if [[ -z "${PW_PREFIX_NAME}" ]] || [[ ! -z "$(echo "${PW_PREFIX_NAME}" | grep -E '^_.*' )" ]] ; then
            PW_PREFIX_NAME="DEFAULT"
        else
            PW_PREFIX_NAME="${PW_PREFIX_NAME^^}"
        fi
        export PW_PREFIX_NAME PW_WINE_VER VULKAN_MOD
    fi
    export PW_DISABLED_CREATE_DB=1
fi

case "${VULKAN_MOD}" in
    "$SORT_OPENGL" )     export PW_VULKAN_USE="0" ;;
    "$SORT_STABLE" )     export PW_VULKAN_USE="1" ;;
    "$SORT_NEWEST" )     export PW_VULKAN_USE="2" ;;
    "$SORT_G_NINE" )     export PW_VULKAN_USE="3" ;;
    "$SORT_G_ZINK" )     export PW_VULKAN_USE="4" ;;
    "$SORT_LEGACY" )     export PW_VULKAN_USE="5" ;;
    "$SORT_VULKAN" )     export PW_VULKAN_USE="6" ;;
esac

init_wine_ver
if [[ -f "${PORTWINE_DB_FILE}" ]] ; then
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
    change_branch) change_branch ;;
    change_gui_start) change_gui_start ;;
    118) gui_edit_db ;;
    120) gui_vkbasalt ;;
    122) gui_mangohud ;;
    124) gui_dgvoodoo2 ;;
    126) gui_gamescope ;;
    pw_create_prefix_backup) pw_create_prefix_backup ;;
    gui_credits) gui_credits ;;
    pw_start_cont_xterm) pw_start_cont_xterm ;;
    pw_find_exe) pw_find_exe ;;
    pw_duplicate) pw_duplicate ;;
    PW_*) pw_autoinstall_from_db ;;
    *.desktop) run_desktop_b_click ;;
    1|252|*) exit 0 ;;
esac

stop_portwine
