#!/usr/bin/env bash
# Author: Castro-Fidel (linux-gaming.ru)
# Development assistants: Cefeiko; Dezert1r; Taz_mania; Anton_Famillianov; gavr; RidBowt; chal55rus; UserDiscord; Boria138; Vano; Akai; Htylol
########################################################################
export url_site="https://linux-gaming.ru/portproton/"
export url_cloud="https://cloud.linux-gaming.ru/portproton"
export url_git="https://git.linux-gaming.ru/CastroFidel/PortWINE"
########################################################################
if [[ "${START_FROM_FLATPAK:-0}" == 1 ]] \
&& [[ -z "${STEAM_COMPAT_DATA_PATH:-}" ]] \
&& command -v "flatpak" &>/dev/null
then
    unset START_FROM_FLATPAK
    flatpak run ru.linux_gaming.PortProton "$@"
    exit
fi
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

if [[ $(id -u) = 0 ]] \
&& [[ ! -e "/userdata/system/batocera.conf" ]]
then
    echo "Do not run this script as root!"
    exit 1
fi

PORT_SCRIPTS_PATH="$(cd "$(dirname "$0")" && pwd)"
PORT_WINE_PATH="$(dirname "$(dirname "$PORT_SCRIPTS_PATH")")"
PW_LOG_FILE="${PORT_WINE_PATH}/PortProton.log"
export PORT_SCRIPTS_PATH PORT_WINE_PATH PW_LOG_FILE

# shellcheck source=/dev/null
source "$PORT_SCRIPTS_PATH/functions_helper"

export PORT_WINE_TMP_PATH="${PORT_WINE_PATH}/data/tmp"
create_new_dir "$PORT_WINE_TMP_PATH"
rm -f "$PORT_WINE_TMP_PATH"/*.{exe,msi,tar}*

if mkdir -p "/tmp/PortProton_$USER" ; then
    export PW_TMPFS_PATH="/tmp/PortProton_$USER"
else
    create_new_dir "${PORT_WINE_PATH}/data/tmp/PortProton_$USER"
    export PW_TMPFS_PATH="${PORT_WINE_PATH}/data/tmp/PortProton_$USER"
fi

export PW_GUI_ICON_PATH="${PORT_WINE_PATH}/data/img/gui"
export PW_GUI_THEMES_PATH="${PORT_WINE_PATH}/data/themes"

export PW_START_PID="$$"
export NO_AT_BRIDGE="1"
export GDK_BACKEND="x11"
read -r -a pw_full_command_line <<< "$0 $*"
export pw_full_command_line
export orig_IFS="$IFS"

MISSING_DESKTOP_FILE="0"

unset PW_NO_RESTART_PPDB PW_DISABLED_CREATE_DB

if [[ ${1,,} == "cli" ]] ; then
    export PW_CLI="1"
    export PROCESS_LOG="1"
    shift
fi
check_variables PW_CLI "0"

if [[ "${1,,}" =~ \.ppack$ ]] ; then
    export PW_NO_RESTART_PPDB="1"
    export PW_DISABLED_CREATE_DB="1"
    portwine_exe="$1"
elif [[ "${1,,}" =~ \.ppdb$ ]] ; then
    update_ext_ppdb "$1"
elif [[ "$1" == portproton://* ]] ; then
    PPDB_URL="${1#portproton://}"
    PPDB_URL="${PPDB_URL//https\/\//https:\/\/}"
    PW_TMP_PPDB_FILE="$PW_TMPFS_PATH/tmp_from_url.ppdb"

    print_info "Downloading PPDB from: $PPDB_URL"
    if curl -fsSL "$PPDB_URL" -o "$PW_TMP_PPDB_FILE" ; then
        update_ext_ppdb "$PW_TMP_PPDB_FILE" "url"
    else
        fatal "Failed to download PPDB from URL: $PPDB_URL"
    fi
elif [[ "${1,,}" =~ \.(exe|bat|msi|reg|lnk)$ ]] ; then
    if [[ -f "$1" ]] ; then
        portwine_exe="$(realpath -s "$1")"
    elif [[ -f "$OLDPWD/$1" ]] ; then
        portwine_exe="$(realpath -s "$OLDPWD/$1")"
    elif [[ ! -f "$1" ]] ; then
        portwine_exe="$1"
        MISSING_DESKTOP_FILE="1"
    fi
    if [[ -n "${portwine_exe}" && "${1,,}" =~ \.lnk$ ]] ; then
        get_lnk "${portwine_exe}"
        portwine_exe="$(realpath "${link_path}" 2>/dev/null)"
    fi
elif [[ "$1" =~ ^--(debug|launch|edit-db)$ && "${2,,}" =~ \.(exe|bat|msi|reg)$ ]] ; then
    if [[ -f "$2" ]] ; then
        portwine_exe="$(realpath -s "$2")"
    elif [[ -f "$OLDPWD/$2" ]] ; then
        portwine_exe="$(realpath -s "$OLDPWD/$2")"
    fi
fi
export portwine_exe

# HOTFIX - ModernWarships
if echo "$portwine_exe" | grep ModernWarships &>/dev/null \
&& [[ -f "$(dirname "${portwine_exe}")/Modern Warships.exe" ]]
then
    portwine_exe="$(dirname "${portwine_exe}")/Modern Warships.exe"
    export portwine_exe
    MISSING_DESKTOP_FILE="0"
fi

create_new_dir "${HOME}/.local/share/applications"
if [[ "${PW_SILENT_RESTART}" == "1" ]] \
|| [[ "${START_FROM_STEAM}" == "1" ]]
then
    export PW_GUI_DISABLED_CS="1"
    unset PW_SILENT_RESTART
else
    unset PW_GUI_DISABLED_CS
fi

unset MANGOHUD PW_VULKAN_USE WINEDLLOVERRIDES PW_NO_WRITE_WATCH PW_YAD_SET PW_CPU_NUMA_NODE_INDEX PW_TASKSET_SLR PW_PPDB_URL
unset PW_CHECK_AUTOINSTALL PW_VKBASALT_EFFECTS PW_VKBASALT_FFX_CAS PORTWINE_DB PORTWINE_DB_FILE RADV_PERFTEST PW_USE_RUNTIME
unset CHK_SYMLINK_FILE PW_MESA_GL_VERSION_OVERRIDE PW_VKD3D_FEATURE_LEVEL PATH_TO_GAME PW_START_DEBUG PORTPROTON_NAME PW_PATH
unset PW_PREFIX_NAME VULKAN_MOD PW_WINE_VER PW_ADD_TO_ARGS_IN_RUNTIME PW_GAMEMODERUN_SLR PW_WINE_CPU_TOPOLOGY LAUNCH_URI
unset MANGOHUD_CONFIG FPS_LIMIT PW_WINE_USE WINEDLLPATH WINE WINEDIR WINELOADER WINESERVER PORTWINE_CREATE_SHORTCUT_NAME MIRROR
unset PW_LOCALE_SELECT PW_SETTINGS_INDICATION PW_GUI_START PW_AUTOINSTALL_EXE NOSTSTDIR RADV_DEBUG PW_NO_AUTO_CREATE_SHORTCUT
unset PW_TERM PW_EXEC_FROM_DESKTOP WEBKIT_DISABLE_DMABUF_RENDERER PW_AMD_VULKAN_USE PW_VK_ICD_FILENAMES PW_USE_SETUP_FILE

echo "" > "${PW_TMPFS_PATH}/tmp_yad_form"
echo "" > "${PW_TMPFS_PATH}/tmp_yad_form_vulkan"

create_new_dir "${PORT_WINE_PATH}/data/dist"
IFS=$'\n'
for dist_dir in $(lsbash "${PORT_WINE_PATH}/data/dist/") ; do
    dist_dir_new=$(echo "${dist_dir}" | awk '$1=$1' | sed -e s/[[:blank:]]/_/g)
    if [[ ! -d "${PORT_WINE_PATH}/data/dist/${dist_dir_new^^}" ]] ; then
        mv -- "${PORT_WINE_PATH}/data/dist/$dist_dir" "${PORT_WINE_PATH}/data/dist/${dist_dir_new^^}"
    fi
done
IFS="$orig_IFS"

create_new_dir "${PORT_WINE_PATH}/data/prefixes/DEFAULT"
create_new_dir "${PORT_WINE_PATH}/data/prefixes/DOTNET"
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

# shellcheck source=/dev/null
source "${PORT_SCRIPTS_PATH}/var"

export STEAM_SCRIPTS="${PORT_WINE_PATH}/steam_scripts"
create_new_dir "$STEAM_SCRIPTS"

export PW_PLUGINS_PATH="${PORT_WINE_TMP_PATH}/plugins${PW_PLUGINS_VER}"
export pw_yad="${PW_GUI_THEMES_PATH}/gui/yad_gui_pp"

export PW_WINELIB="${PORT_WINE_TMP_PATH}/libs${PW_LIBS_VER}"
try_remove_dir "${PW_WINELIB}/var"
install_ver="$(<"${PORT_WINE_TMP_PATH}/PortProton_ver")"
export install_ver
if [[ -f "${PORT_WINE_TMP_PATH}/scripts_ver" ]]
then scripts_install_ver="$(<"${PORT_WINE_TMP_PATH}/scripts_ver")"
else scripts_install_ver="2026"
fi
export scripts_install_ver
export WINETRICKS_DOWNLOADER="curl"

check_user_conf
check_translations
# shellcheck source=/dev/null
source "$PW_CACHE_LANG_PATH/$LANGUAGE"

check_variables PW_LOG "0"
try_remove_file "${PW_TMPFS_PATH}/update_pfx_log"

[[ ! -f "$PORT_WINE_TMP_PATH/statistics" ]] && touch "$PORT_WINE_TMP_PATH/statistics"

if [[ -n "${STEAM_COMPAT_DATA_PATH:-}" ]]; then
    steamplay_launch "${@:2}"
    exit
fi
unset WINEPREFIX

# check PortProton theme
if [[ -n "$GUI_THEME" ]] \
&& [[ -f "$PW_GUI_THEMES_PATH/$GUI_THEME.pptheme" ]]
then
    # shellcheck source=/dev/null
    source "$PW_GUI_THEMES_PATH/$GUI_THEME.pptheme"
else
    # shellcheck source=/dev/null
    source "$PW_GUI_THEMES_PATH/default.pptheme"
    echo 'export GUI_THEME="default"' >> "$USER_CONF"
fi
export YAD_OPTIONS+="--center"

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
&& [[ "$LANGUAGE" == "ru" ]]
then
    echo 'export MIRROR="CLOUD"' >> "$USER_CONF"
    export MIRROR="CLOUD"
elif [[ -z "$MIRROR" ]] ; then
    echo 'export MIRROR="GITHUB"' >> "$USER_CONF"
    export MIRROR="GITHUB"
fi

if [[ $USE_ONLY_LG_RU == "1" ]] ; then
    export MIRROR="CLOUD"
    edit_user_conf_from_gui MIRROR USE_ONLY_LG_RU
    print_info "Force used linux-gaming.ru for all updates.\n"
fi
print_info "The first mirror in used: $MIRROR\n"

# choose downloading covers from SteamGridDB or not
if [[ -z "$DOWNLOAD_STEAM_GRID" ]] ; then
    echo 'export DOWNLOAD_STEAM_GRID="1"' >> "$USER_CONF"
    export DOWNLOAD_STEAM_GRID="1"
fi

[[ "${INSTALLING_PORT}" == 1 ]] && return 0

# choose gui start
if [[ ! $PW_GUI_START =~ (PANED|NOTEBOOK) ]] ; then
    sed -i '/export PW_GUI_START=/d' "$USER_CONF"
    echo 'export PW_GUI_START="NOTEBOOK"' >> "$USER_CONF"
    export PW_GUI_START="NOTEBOOK"
fi

# DESKTOP_WITH_TIME by default displays hours and minutes
if [[ -z $DESKTOP_WITH_TIME ]] ; then
    echo 'export DESKTOP_WITH_TIME="posnumber1"' >> "$USER_CONF"
    export DESKTOP_WITH_TIME="posnumber1"
fi

# SORT_WITH_TIME by default sorts from the last run
if [[ -z $SORT_WITH_TIME ]] ; then
    echo 'export SORT_WITH_TIME="lastlaunch"' >> "$USER_CONF"
    export SORT_WITH_TIME="lastlaunch"
fi

if check_gamescope_session
then PW_TERM="env LANG=C xterm -fullscreen -bg black -fg white -e"
else PW_TERM="env LANG=C xterm -bg black -fg white -e"
fi

if [[ "${PW_CLI}" != 1 ]] ; then
    pw_check_and_download_plugins
fi

# check skip update
if [[ "${SKIP_CHECK_UPDATES}" != 1  || "${PW_CLI}" != 1 ]] ; then
    pw_port_update

    PW_FILESYSTEM=$(stat -f -c %T "${PORT_WINE_PATH}")
    export PW_FILESYSTEM

    background_pid --start "pw_check_vulkan" "1"
    background_pid --start "pw_get_tmp_files" "2"
fi

if [[ -z $PW_GPU_USE || $PW_GPU_USE == "disabled" ]] ; then
    PW_GPU_USE="disabled"
    pw_check_dxvk
fi

# create lock file
if ! check_flatpak ; then
    if [[ -f "${PW_TMPFS_PATH}/portproton.lock" ]] ; then
        print_warning "Found lock file: ${PW_TMPFS_PATH}/portproton.lock"
        if ! check_start_from_steam
        then yad_question "${translations[A running PortProton session was detected.\\nDo you want to end the previous session?]}" || exit 0
        fi
    fi
    touch "${PW_TMPFS_PATH}/portproton.lock"
fi

pw_cleanup () {
    CURL_PID="$(pgrep -a curl | grep -i "portproton" | cut -d' ' -f1)"
    if [[ -n $CURL_PID ]] ; then
        for pid in $CURL_PID ; do
            kill "$pid" &>/dev/null
        done
    fi

    rm -fv "${PW_TMPFS_PATH}"/*.log
    if [[ -f "${PW_TMPFS_PATH}/portproton.lock" ]] ; then
        rm -fv "${PW_TMPFS_PATH}/portproton.lock"
    fi
}
trap "pw_cleanup" EXIT

if check_flatpak ; then
    try_remove_dir "${PORT_WINE_TMP_PATH}/libs${PW_LIBS_VER}"
else pw_download_libs
fi

if [[ ${portwine_exe,,} =~ (setup|install|.msi$) ]] ; then
    export PW_DISABLED_CREATE_DB="1"
    export PW_VULKAN_USE="1"
    export PW_MANGOHUD="0"
    export PW_USE_NTSYNC="0"
    export PW_USE_FSYNC="0"
    export PW_USE_ESYNC="0"
    export PW_USE_GAMEMODE="0"
    export PW_DLL_INSTALL=""
    # export WINEDLLOVERRIDES="mscoree,mshtml="
    export PW_WINE_USE="PROTON_LG"

    export PW_USE_SETUP_FILE="1"
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
    killall -15 yad_gui_pp &>/dev/null
    kill -TERM "$(pgrep -a yad | grep PortProton | head -n 1 | awk '{print $1}')" &>/dev/null

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

export SKIP_CHECK_UPDATES="1"

[[ "$MISSING_DESKTOP_FILE" == "1" ]] && portwine_missing_shortcut

if [[ $(basename "${portwine_exe,,}") =~ .ppack$ ]] ; then
    if ! pw_unpack_prefix "$portwine_exe" ; then
        yad_error "${translations[Unpack has FAILED for prefix:]} <b>\"${PW_PREFIX_NAME}\"</b>."
        exit 1
    else       
        if ! check_start_from_steam
        then yad_info "${translations[Unpack is DONE for prefix:]} <b>\"${PW_PREFIX_NAME}\"</b>."
        fi
        exit 0
    fi
fi

### CLI ###
get_wine_and_pfx () {
    [[ -n $1 ]] && export PW_WINE_USE="$1"
    [[ -n $2 ]] && export PW_PREFIX_NAME="$2"
    # drop create_new_dir "${PATH_TO_VKD3D_FILES}/vkd3d_cache" and create_new_dir "${PATH_TO_DXVK_FILES}/dxvk_cache"
    unset PW_USE_SUPPLIED_DXVK_VKD3D
}

case "$1" in
    --help)
        help_info () {
            files_from_autoinstall=$(ls "${PORT_SCRIPTS_PATH}/pw_autoinstall")
            echo -e "${translations[use]}: [--repair] [--reinstall] [--autoinstall]

--repair                                            ${translations[Forces all scripts to be updated to a working state
                                                    (helps if PortProton is not working)]}
--reinstall                                         ${translations[Reinstalls PortProton and resets all settings to default]}
--generate-pot                                      ${translations[Creates a files with translations .pot and .po]}
--debug                                             ${translations[Debug scripts for PortProton
                                                    (saved log in]} $PORT_WINE_PATH/scripts-debug.log)
--update                                            ${translations[Check update scripts for PortProton]}
--launch                                            ${translations[Launches the application immediately, requires the path to the .exe file]}
--edit-db                                           ${translations[After the variable, the path to the .exe file is required and then the variables.
                                                    (List their variables and values for example PW_MANGOHUD=1 PW_VKBASALT=0, etc.)]}
--autoinstall                                       ${translations[--autoinstall and the name of what needs to be installed is given in the list below:]}

$(echo $files_from_autoinstall | awk '{for (i = 1; i <= NF; i++) {if (i % 10 == 0) {print ""} printf "%s ", $i}}')
            "
        }
        help_info
        exit 0
        ;;
    --reinstall)
        export PW_REINSTALL_FROM_TERMINAL=1
        pw_reinstall_pp
        ;;
    --autoinstall)
        export PW_YAD_SET="$2"
        pw_autoinstall_from_db
        exit 0
        ;;
    --generate-pot)
        generate_pot
        exit 0
        ;;
    --debug)
        clear
        export PW_DEBUG="set -x"
        /usr/bin/env bash -c "${pw_full_command_line[@]}" 2>&1 | tee "$PORT_WINE_PATH/scripts-debug.log" &
        exit 0
        ;;
    --update)
        gui_pw_update
        ;;
    --launch)
        portwine_launch
        stop_portwine
        ;;
    --edit-db)
        # --edit-db /полный/путь/до/файла.exe PW_MANGOHUD=1 PW_VKBASALT=0 (и т.д) для примера
        set_several_variables "${@:3}"
        edit_db_from_gui $keys_all
        exit 0
        ;;
    --list-db)
        export pw_yad=""
        gui_edit_db
        pw_skip_get_info
        declare -A NODE_MAP
        INDEX=0
        while read -r line; do
            NODE_MAP[$INDEX]="$line"
            ((INDEX++))
        done < <(lscpu | grep -Po "NUMA node\d+ CPU\(s\):\s+\K.*" 2>/dev/null || true)
        for i in "${!NODE_MAP[@]}"; do
            echo "NUMA_NODE_${i}=${NODE_MAP[$i]}"
        done
        echo "IS_AMD=$([[ $(check_vendor_gpu) == \"amd\" ]] && echo true || echo false)"
        echo "LOGICAL_CORE_OPTIONS=$GET_LOGICAL_CORE"
        [[ -n "$LOCALE_LIST" ]] && echo "LOCALE_LIST=$LOCALE_LIST"
        [[ -n "$AMD_VULKAN_DRIVER_LIST" ]] && echo "AMD_VULKAN_DRIVER_LIST=$AMD_VULKAN_DRIVER_LIST"
        for var in "${PW_EDIT_DB_FINAL_LIST[@]}"; do
            if echo "$DISABLE_EDIT_DB_LIST" | grep -qw "$var"; then
                echo "$var blocked"
            else
                echo "$var"
            fi
        done
        exit 0
        ;;
    --show-ppdb)
        # --show-ppdb /полный/путь/до/файла.exe ИЛИ /полный/путь/до/файла.exe.ppdb
        input_path="$2"

        case "$input_path" in
            *.ppdb) exe_path="${input_path%.ppdb}" ;;
            *.exe)  exe_path="$input_path" ;;
        esac

        ppdb_path="${exe_path}.ppdb"
        if [[ ! -f "$ppdb_path" ]]; then
            export portwine_exe="$exe_path"
            pw_init_db
        fi

        grep -E '^export ' "$ppdb_path" \
        | sed '/^[[:space:]]*$/d' \
        | while IFS= read -r line; do
            line="${line#export }"
            if [[ "$line" =~ ^([^=]+)=\"([^\"]*)\"[[:space:]]*#.*$ ]]; then
                echo "${BASH_REMATCH[1]}=\"${BASH_REMATCH[2]}\""
            elif [[ "$line" =~ ^([^=]+)=([^#[:space:]]+)[[:space:]]*#.*$ ]]; then
                echo "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
            else
                echo "$line"
            fi
        done
        exit 0
        ;;
    --backup-prefix)
        # portproton --backup-prefix <PREFIX_NAME> <BACKUP_DIR>
        pw_create_prefix_backup_cli "$2" "$3"
        exit $?
        ;;
    --restore-prefix)
        # portproton --restore-prefix <PREFIX_BACKUP_FILE.ppack>
        pw_unpack_prefix "$2"
        exit $?
        ;;
    --winefile)
        get_wine_and_pfx "$2" "$3"
        pw_winefile
        exit $?
        ;;
    --winecfg)
        get_wine_and_pfx "$2" "$3"
        pw_winecfg
        exit $?
        ;;
    --winecmd)
        get_wine_and_pfx "$2" "$3"
        pw_winecmd
        exit $?
        ;;
    --winereg)
        get_wine_and_pfx "$2" "$3"
        pw_winereg
        exit $?
        ;;
    --wine_uninstaller)
        get_wine_and_pfx "$2" "$3"
        wine_uninstaller
        exit $?
        ;;
    --clear_pfx)
        get_wine_and_pfx "$2" "$3"
        pw_clear_pfx
        exit $?
        ;;
    --initial)
        exit 0
        ;;
esac

### GUI ###

INFO_3DAPI=${translations[Select DXVK and VKD3D versions for DirectX to Vulkan translation:
   - The newest ones work only with MESA 25+ drivers, or NVIDIA 550.54.14+
   - Stable ones work with any drivers, provided that the video card supports Vulkan version 1.3+
   - Sarek works with almost any video card that supports Vulkan
   - WineD3D OpenGL works on any PC, but with low performance and old games]}
INFO_WINE=${translations[Selecting a WINE version.]}
INFO_PREFIX=${translations[Select a prefix to launch the game/application (if you enter a non-existent name, a new prefix will be created).]}

unset PW_ADD_PREFIXES_TO_GUI
if [[ -d "${PORT_WINE_PATH}/data/prefixes/" ]] ; then
    for PAIG in "${PORT_WINE_PATH}"/data/prefixes/* ; do
        if [[ ! "${PAIG//"${PORT_WINE_PATH}/data/prefixes/"/}" =~ ^($PW_PREFIX_NAME|'*')$ ]]
        then
            PW_ADD_PREFIXES_TO_GUI="${PW_ADD_PREFIXES_TO_GUI}!${PAIG//"${PORT_WINE_PATH}/data/prefixes/"/}"
        fi
    done
    PW_ADD_PREFIXES_TO_GUI="${PW_PREFIX_NAME}${PW_ADD_PREFIXES_TO_GUI}"
fi

unset DIST_ADD_TO_GUI
if [[ -d "${PORT_WINE_PATH}/data/dist/" ]] ; then
    for DAIG in "${PORT_WINE_PATH}"/data/dist/* ; do
        if [[ ! "${DAIG//"${PORT_WINE_PATH}/data/dist/"/}" =~ ^($PW_WINE_LG_VER|$PW_PROTON_LG_VER|'*')$ ]]
        then
            DIST_ADD_TO_GUI="${DIST_ADD_TO_GUI}!${DAIG//"${PORT_WINE_PATH}/data/dist/"/}"
        fi
    done
fi
if command -v wine &>/dev/null
then DIST_ADD_TO_GUI+="!${translations[USE_SYSTEM_WINE]}"
fi

SORT_OPENGL="${translations[WineD3D OpenGL (For video cards without Vulkan)]}"
SORT_SAREK="${translations[DXVK, VKD3D (Sarek) (Vulkan v1.1+)]}"
SORT_STABLE="${translations[DXVK, VKD3D (Stable) (Vulkan v1.3+)]}"
SORT_NEWEST="${translations[DXVK, VKD3D (Newest) (Vulkan v1.3+)]}"

if [[ $PW_WINE_USE == PROTON_LG ]] ; then
    PW_WINE_USE="${PW_PROTON_LG_VER}"
    PW_DEFAULT_WINE_USE="${PW_WINE_LG_VER}${DIST_ADD_TO_GUI}!${translations[GET-OTHER-WINE]}"
elif [[ $PW_WINE_USE == WINE_*_LG ]] \
|| [[ $PW_WINE_USE == WINE_LG ]]
then
    PW_WINE_USE="${PW_WINE_LG_VER}"
    PW_DEFAULT_WINE_USE="${PW_PROTON_LG_VER}${DIST_ADD_TO_GUI}!${translations[GET-OTHER-WINE]}"
else
    PW_DEFAULT_WINE_USE="${PW_PROTON_LG_VER}!${PW_WINE_LG_VER}${DIST_ADD_TO_GUI}!${translations[GET-OTHER-WINE]}"
fi

if [[ -z "$PORTWINE_DB_FILE" ]] ; then
    unset PW_GUI_DISABLED_CS
fi

if [[ -f "$portwine_exe" ]] ; then
    unset TAB_MAIN_MENU
    if [[ "$RESTART_PP_USED" == "edit_db" ]] ; then
        unset RESTART_PP_USED
        gui_edit_db
    elif [[ "$RESTART_PP_USED" == "userconf" ]] ; then
        unset RESTART_PP_USED
        gui_userconf
    fi

    [[ $PW_VULKAN_USE == [3-5] ]] && unset PW_VULKAN_USE
    pw_check_dxvk

    if [[ $PW_GUI_DISABLED_CS != 1 ]] ; then
        pw_create_gui_png
        if ! grep -il "$portwine_exe" "$PORT_WINE_PATH"/*.desktop &>/dev/null ; then
            PW_SHORTCUT="${translations[CREATE SHORTCUT]}!$PW_GUI_ICON_PATH/$BUTTON_SIZE.png!${translations[Create shortcut for select file...]}:100"
        else
            PW_SHORTCUT="${translations[CHANGE SHORTCUT]}!$PW_GUI_ICON_PATH/$BUTTON_SIZE.png!${translations[Change shortcut for select file...]}:98"
        fi

        create_name_desktop

        if [[ -n $PW_PPDB_URL ]]
        then PW_COMMENT_URL="<a href=\"$PW_PPDB_URL\">\(PPDB\)</a>"
        fi
        
        if [[ -n $PW_COMMENT_DB ]] ; then
            PW_COMMENT_DB="$PW_COMMENT_DB $PW_COMMENT_URL$(seconds_to_time "$TIME_CURRENT")"
        else
            if [[ $PW_USE_SETUP_FILE == "1" ]] ; then
                PW_COMMENT_DB="${translations[Launching]} <b>$(print_wrapped "$PW_NAME_DESKTOP_PROXY" "50")</b>"
            else
                PW_COMMENT_DB="${translations[Launching]} <b>$(print_wrapped "$PW_NAME_DESKTOP_PROXY" "50")</b> $PW_COMMENT_URL $(seconds_to_time "$TIME_CURRENT")"
            fi
        fi

        KEY_START="$RANDOM"
        "$pw_yad" --plug=$KEY_START --tabnum="1" --form --separator=";" $START_GUI_TYPE \
        --gui-type-box="$START_GUI_TYPE_BOX" --gui-type-layout="$START_GUI_TYPE_LAYOUT_UP" \
        --gui-type-text="$START_GUI_TYPE_TEXT" --gui-type-images="$START_GUI_TYPE_IMAGE" \
        --image="$PW_ICON_FOR_YAD" --text-align="center" --text "$PW_COMMENT_DB" \
        --field="3D API  : !$INFO_3DAPI:CB" "$PW_DEFAULT_VULKAN_USE" \
        --field="  WINE  : !$INFO_WINE:CB" "$(combobox_fix "$PW_WINE_USE" "$PW_DEFAULT_WINE_USE")" \
        --field="PREFIX  : !$INFO_PREFIX:CBE" "$PW_ADD_PREFIXES_TO_GUI" \
        1> "$PW_TMPFS_PATH/tmp_yad_form_vulkan" 2>/dev/null &

        if [[ $PW_GUI_START == "NOTEBOOK" ]]
        then PW_GUI_START_TABNUM2="--columns=$START_GUI_NOTEBOOK_COLUMNS --gui-type-layout=$START_GUI_TYPE_LAYOUT_NOTEBOOK"
        elif [[ $PW_GUI_START == "PANED" ]]
        then PW_GUI_START_TABNUM2="--columns=$START_GUI_PANED_COLUMNS --gui-type-layout=$START_GUI_TYPE_LAYOUT_PANED --homogeneous-row"
        fi

        "$pw_yad" --plug=$KEY_START --tabnum="2" --form --align-buttons --homogeneous-column $PW_GUI_START_TABNUM2  \
        --field="   ${translations[Base settings]}!$PW_GUI_ICON_PATH/$BUTTON_SIZE.png!${translations[Edit database file for]} ${PORTWINE_DB}":"FBTN" '@bash -c "button_click --start 118"' \
        --field="   ${translations[Open directory]}!$PW_GUI_ICON_PATH/$BUTTON_SIZE.png!${translations[Open directory with <b>.ppdb</b> file]}":"FBTN" '@bash -c "button_click --start open_game_folder"' \
        --field="   vkBasalt!$PW_GUI_ICON_PATH/$BUTTON_SIZE.png!${translations[Enable vkBasalt by default to improve graphics in games running on Vulkan. (The HOME hotkey disables vkbasalt)]}":"FBTN" '@bash -c "button_click --start 120"' \
        --field="   MangoHud!$PW_GUI_ICON_PATH/$BUTTON_SIZE.png!${translations[Enable Mangohud by default (R_SHIFT + F12 keyboard shortcuts disable Mangohud)]}":"FBTN" '@bash -c "button_click --start 122"' \
        --field="   dgVoodoo2!$PW_GUI_ICON_PATH/$BUTTON_SIZE.png!${translations[Enable dgVoodoo2 by default (This wrapper fixes many compatibility and rendering issues when running old games)]}":"FBTN" '@bash -c "button_click --start 124"' \
        --field="   GameScope!$PW_GUI_ICON_PATH/$BUTTON_SIZE.png!${translations[Enable GameScope by default (Wayland micro compositor)]}":"FBTN" '@bash -c "button_click --start 126"' \
        2>/dev/null &

        if [[ $PW_GUI_START == "NOTEBOOK" ]] ; then
            if [[ "$PW_YAD_FORM_TAB" == "1" ]] \
            && [[ -n "$TAB_START" ]]
            then
                export TAB_START="2"
                unset PW_YAD_FORM_TAB
            else
                export TAB_START="1"
            fi
            PW_GUI_START_TABNUM3="--notebook --active-tab=$TAB_START --gui-type=settings-notebook --expand"
        elif [[ $PW_GUI_START == "PANED" ]] ; then
            PW_GUI_START_TABNUM3="--paned --gui-type=settings-paned"
        fi

        "$pw_yad" --key=$KEY_START $PW_GUI_START_TABNUM3 \
        --width="$PW_START_SIZE_W" --tab-pos="$PW_TAB_POSITON" \
        --title "PortProton-$install_ver (${scripts_install_ver}${BRANCH_VERSION})" \
        --window-icon="$PW_GUI_ICON_PATH/portproton.svg" \
        --tab="${translations[GENERAL]}!$PW_GUI_ICON_PATH/$TAB_SIZE.png!" \
        --tab="${translations[SETTINGS]}!$PW_GUI_ICON_PATH/$TAB_SIZE.png!" \
        --button="${translations[MAIN MENU]}!$PW_GUI_ICON_PATH/$BUTTON_SIZE.png!${translations[Main menu]}":128 \
        --button="${PW_SHORTCUT}" \
        --button="${translations[DEBUG]}!$PW_GUI_ICON_PATH/$BUTTON_SIZE.png!${translations[Launch with the creation of a .log file at the root PortProton]}":102 \
        --button="${translations[LAUNCH]}!$PW_GUI_ICON_PATH/$BUTTON_SIZE.png!${translations[Run file ...]}":106 2>/dev/null
        PW_YAD_SET="$?"
        [[ $PW_GUI_START == "NOTEBOOK" ]] && export PW_YAD_FORM_TAB="1"

        case "$PW_YAD_SET" in
            128)
                [[ "$PW_GUI_START" == "NOTEBOOK" ]] && unset PW_YAD_FORM_TAB
                PORTWINE_DB_FOR_UNSET=$(sed -n '/export/p' "$PORTWINE_DB_FILE" | sed 's/\(export\|=.*\| \)//g' | sort -u)
                for db_unset in $PORTWINE_DB_FOR_UNSET ; do
                    unset "$db_unset"
                done
                unset portwine_exe KEY_START name_desktop_png PW_ICON_FOR_YAD
                print_info "Restarting..."
                restart_pp
                ;;
            1|252)
                exit 0
                ;;
        esac
        pw_yad_set_form
        pw_yad_form_vulkan
    elif [[ -f "$PORTWINE_DB_FILE" ]] ; then
        portwine_launch
    fi
else
    if [[ "$RESTART_PP_USED" == "userconf" ]] ; then
        unset RESTART_PP_USED
        gui_userconf
    fi

    unset PW_NAME_D_ICON PW_ICON_PATH PW_GAME_TIME PW_ALL_DF PW_AMOUNT_NEW_DESKTOP 
    unset PW_DESKTOP_FILES_REGEX PW_AMOUNT_OLD_DESKTOP PW_DESKTOP_FILES PW_LAST_LAUNCH
    # Поиск .desktop файлов
    AMOUNT_GENERATE_BUTTONS="0"
    for desktop_file in "$PORT_WINE_PATH"/* ; do
        desktop_file_new="${desktop_file//"$PORT_WINE_PATH/"/}"
        if [[ $desktop_file_new =~ .desktop$ ]] ; then
            if [[ ! $desktop_file_new =~ (PortProton|readme) ]] ; then
                while read -r line1 ; do
                    if [[ $line1 =~ ^Exec= ]] ; then
                        if check_flatpak ; then
                            PW_NAME_D_ICON["$AMOUNT_GENERATE_BUTTONS"]=${line1//Exec=flatpak run ru.linux_gaming.PortProton /}
                        else
                            PW_NAME_D_ICON["$AMOUNT_GENERATE_BUTTONS"]=${line1//Exec=env \"$PORT_SCRIPTS_PATH\/start.sh\" /}
                        fi
                    fi
                    [[ $line1 =~ ^Icon= ]] && PW_ICON_PATH["$AMOUNT_GENERATE_BUTTONS"]=${line1//Icon=/}
                done < "$desktop_file"
                if fix_icon_name_png "${PW_ICON_PATH["$AMOUNT_GENERATE_BUTTONS"]}" "$desktop_file" ; then
                    ICON_NAME_REGEX=(\! % \$ \& \<)
                    for i in "${ICON_NAME_REGEX[@]}" ; do
                        PW_ICON_PATH["$AMOUNT_GENERATE_BUTTONS"]="${PW_ICON_PATH["$AMOUNT_GENERATE_BUTTONS"]//$i/}"
                    done
                fi
                PW_ALL_DF["$AMOUNT_GENERATE_BUTTONS"]="$desktop_file_new"
                # Для конвертации существующих .desktop файлов flatpak в натив и наоборот
                if [[ ${PW_NAME_D_ICON["$AMOUNT_GENERATE_BUTTONS"]} =~ ^"Exec=flatpak run ru.linux_gaming.PortProton " ]] ; then
                    PW_NAME_D_ICON["$AMOUNT_GENERATE_BUTTONS"]=${PW_NAME_D_ICON["$AMOUNT_GENERATE_BUTTONS"]//Exec=flatpak run ru.linux_gaming.PortProton /}
                    sed -i "s|Exec=flatpak run ru.linux_gaming.PortProton|Exec=env \"$PORT_SCRIPTS_PATH/start.sh\"|" "$desktop_file"
                elif [[ ${PW_NAME_D_ICON["$AMOUNT_GENERATE_BUTTONS"]} =~ ^"Exec=env \"$PORT_SCRIPTS_PATH/start.sh\" " ]] ; then
                    PW_NAME_D_ICON["$AMOUNT_GENERATE_BUTTONS"]=${PW_NAME_D_ICON["$AMOUNT_GENERATE_BUTTONS"]//Exec=env \"$PORT_SCRIPTS_PATH\/start.sh\" /}
                    sed -i "s|Exec=env \"$PORT_SCRIPTS_PATH/start.sh\"|Exec=flatpak run ru.linux_gaming.PortProton|" "$desktop_file"
                fi
                while read -r -a line2 ; do
                    if [[ \"${line2[0]//#@_@#/ }\" == "${PW_NAME_D_ICON["$AMOUNT_GENERATE_BUTTONS"]}" ]] ; then
                        [[ $SORT_WITH_TIME == "bytime" ]] && PW_GAME_TIME["$AMOUNT_GENERATE_BUTTONS"]=${line2[2]}
                        if [[ $SORT_WITH_TIME == "lastlaunch" ]] ; then
                            [[ -n ${line2[5]} ]] && PW_LAST_LAUNCH["$AMOUNT_GENERATE_BUTTONS"]=${line2[5]//L5-/}
                        fi
                        break
                    else
                        [[ $SORT_WITH_TIME == "bytime" ]] && PW_GAME_TIME["$AMOUNT_GENERATE_BUTTONS"]=0
                        [[ $SORT_WITH_TIME == "lastlaunch" ]] && PW_LAST_LAUNCH["$AMOUNT_GENERATE_BUTTONS"]=0
                    fi
                done < "$PORT_WINE_TMP_PATH/statistics"
                if [[ $SORT_WITH_TIME != "disabled" ]] && [[ ${line2[3]} == "NEW_DESKTOP" ]] ; then
                    sed -i "s/${line2[1]} ${line2[2]} NEW_DESKTOP/${line2[1]} ${line2[2]} OLD_DESKTOP/" "$PORT_WINE_TMP_PATH/statistics"
                    PW_AMOUNT_NEW_DESKTOP+=("$AMOUNT_GENERATE_BUTTONS")
                else
                    PW_AMOUNT_OLD_DESKTOP+=("$AMOUNT_GENERATE_BUTTONS")
                fi
                (( AMOUNT_GENERATE_BUTTONS++ ))
            fi
        fi
    done
    # Переопределение элементов в массивах в зависимости от PW_GAME_TIME, от большего значения к меньшему.
    if [[ $SORT_WITH_TIME == "bytime" ]] && [[ -n ${PW_GAME_TIME[1]} ]] ; then
        for i in "${PW_AMOUNT_OLD_DESKTOP[@]}" ; do
            for j in "${PW_AMOUNT_OLD_DESKTOP[@]}" ; do
                if (( ${PW_GAME_TIME[$i]} > ${PW_GAME_TIME[$j]} )) ; then
                    tmp_0=${PW_GAME_TIME[$i]}
                    tmp_1=${PW_ALL_DF[$i]}
                    tmp_2=${PW_NAME_D_ICON[$i]}
                    tmp_4=${PW_ICON_PATH[$i]}

                    PW_GAME_TIME[i]=${PW_GAME_TIME[$j]}
                    PW_ALL_DF[i]=${PW_ALL_DF[$j]}
                    PW_NAME_D_ICON[i]=${PW_NAME_D_ICON[$j]}
                    PW_ICON_PATH[i]=${PW_ICON_PATH[$j]}

                    PW_GAME_TIME[j]=$tmp_0
                    PW_ALL_DF[j]=$tmp_1
                    PW_NAME_D_ICON[j]=$tmp_2
                    PW_ICON_PATH[j]=$tmp_4
                fi
            done
        done
    fi
    # Переопределение элементов в массивах в зависимости от того, какое приложение в последний раз использовалось
    if [[ $SORT_WITH_TIME == "lastlaunch" ]] && [[ -n ${PW_LAST_LAUNCH[1]} ]] ; then
        for i in "${PW_AMOUNT_OLD_DESKTOP[@]}" ; do
            for j in "${PW_AMOUNT_OLD_DESKTOP[@]}" ; do
                if (( ${PW_LAST_LAUNCH[$i]} > ${PW_LAST_LAUNCH[$j]} )) ; then
                    tmp_0=${PW_LAST_LAUNCH[$i]}
                    tmp_1=${PW_ALL_DF[$i]}
                    tmp_2=${PW_NAME_D_ICON[$i]}
                    tmp_4=${PW_ICON_PATH[$i]}

                    PW_LAST_LAUNCH[i]=${PW_LAST_LAUNCH[$j]}
                    PW_ALL_DF[i]=${PW_ALL_DF[$j]}
                    PW_NAME_D_ICON[i]=${PW_NAME_D_ICON[$j]}
                    PW_ICON_PATH[i]=${PW_ICON_PATH[$j]}

                    PW_LAST_LAUNCH[j]=$tmp_0
                    PW_ALL_DF[j]=$tmp_1
                    PW_NAME_D_ICON[j]=$tmp_2
                    PW_ICON_PATH[j]=$tmp_4
                fi
            done
        done
    fi
    # Генерация .desktop баттанов для главного меню
    IFS=$'\n'
    PW_GENERATE_BUTTONS="--field=   ${translations[Create shortcut...]}!${PW_GUI_ICON_PATH}/find_48.svg!:FBTNR%@bash -c \"button_click --normal pw_find_exe\"%"
    for dp in "${PW_AMOUNT_NEW_DESKTOP[@]}" "${PW_AMOUNT_OLD_DESKTOP[@]}" ; do
        PW_DESKTOP_FILES="${PW_ALL_DF[$dp]}"
        PW_DESKTOP_FILES_SHOW="$PW_DESKTOP_FILES"

        if [[ $PW_DESKTOP_FILES =~ [\(\)\!\$\%\&\`\'\"\>\<\\\|\;] ]] ; then
            PW_DESKTOP_FILES_REGEX=(\( \) \! \$ % \& \` \' \" \> \< \\ \| \;)
            count=1
            for j in "${PW_DESKTOP_FILES_REGEX[@]}" ; do
                PW_DESKTOP_FILES="${PW_DESKTOP_FILES//$j/#+_$count#}"
                (( count++ ))
            done
        fi

        if [[ $PW_DESKTOP_FILES_SHOW =~ [\!\%\$\&\<] ]] ; then
            PW_DESKTOP_FILES_SHOW_REGEX=(\! % \$ \& \<)
            for i in "${PW_DESKTOP_FILES_SHOW_REGEX[@]}" ; do
                PW_DESKTOP_FILES_SHOW="${PW_DESKTOP_FILES_SHOW//$i/}"
            done
        fi

        PW_ICON_PATH[dp]=${PW_ICON_PATH[dp]%.png}
        PW_NAME_D_ICON_NEW="${PW_NAME_D_ICON[dp]//\"/}"

        resize_png "$PW_NAME_D_ICON_NEW" "${PW_ICON_PATH[dp]//"${PORT_WINE_PATH}/data/img/"/}" "48" "128"

        PW_GENERATE_BUTTONS+="--field=   $(print_wrapped "${PW_DESKTOP_FILES_SHOW//".desktop"/""}" "25" "...")!${PW_ICON_PATH[dp]}_48.png!:FBTNR%@bash -c \"button_click --desktop "${PW_DESKTOP_FILES// /#@_@#}"\"%"
    done

    if [[ $AMOUNT_GENERATE_BUTTONS == 1 ]] ; then
        MAIN_GUI_ROWS=1
    elif (( AMOUNT_GENERATE_BUTTONS <= 5 )) ; then
        MAIN_GUI_ROWS=2
    else
        MAIN_GUI_ROWS="$(( ( AMOUNT_GENERATE_BUTTONS + 1 ) / MAIN_GUI_COLUMNS + 1 ))"
    fi

    if [[ $PW_EMULS == "1" ]] ; then
        if [[ -z $PW_DESKTOP_FILES ]]
        then export PW_GUI_SORT_TABS=(1 2 3 4 5)
        else export PW_GUI_SORT_TABS=(2 3 4 5 1)
        fi
    else
        if [[ -z $PW_DESKTOP_FILES ]]
        then export PW_GUI_SORT_TABS=(1 0 2 3 4)
        else export PW_GUI_SORT_TABS=(2 0 3 4 1)
        fi
    fi

    PW_DEFAULT_VULKAN_USE="$SORT_NEWEST!$SORT_STABLE!$SORT_SAREK!$SORT_OPENGL"

    KEY_MENU="$RANDOM"

    IFS="%"
    "${pw_yad}" --plug=$KEY_MENU --tabnum="${PW_GUI_SORT_TABS[4]}" --form --columns="$MAIN_GUI_ROWS" --homogeneous-column \
    --gui-type-layout="${MAIN_MENU_GUI_TYPE_LAYOUT}" \
    --align-buttons --scroll --separator=" " ${PW_GENERATE_BUTTONS} 2>/dev/null &
    IFS="$orig_IFS"

    "${pw_yad}" --plug=$KEY_MENU --tabnum="${PW_GUI_SORT_TABS[3]}" --form --columns=3 --align-buttons --separator=";" --homogeneous-column \
    --gui-type-layout="${MAIN_MENU_GUI_TYPE_LAYOUT}" \
    --field="   ${translations[Reinstall PortProton]}!$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png!":"FBTN" '@bash -c "button_click --normal gui_pw_reinstall_pp"' \
    --field="   ${translations[Remove PortProton]}!$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png!":"FBTN" '@bash -c "button_click --normal gui_rm_portproton"' \
    --field="   ${translations[Update PortProton]}!$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png!":"FBTN" '@bash -c "button_click --normal gui_pw_update"' \
    --field="   ${translations[Changelog]}!$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png!":"FBTN" '@bash -c "button_click --normal open_changelog"' \
    --field="   ${translations[Change language]}!$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png!":"FBTN" '@bash -c "button_click --normal change_loc"' \
    --field="   ${translations[Global settings (user.conf)]}!$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png!":"FBTN" '@bash -c "button_click --normal 128"' \
    --field="   ${translations[Scripts from backup]}!$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png!":"FBTN" '@bash -c "button_click --normal gui_open_scripts_from_backup"' \
    --field="   Xterm!$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png!":"FBTN" '@bash -c "button_click --normal pw_start_cont_xterm"' \
    --field="   ${translations[Credits]}!$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png!":"FBTN" '@bash -c "button_click --normal gui_credits"' \
    2>/dev/null &

    "${pw_yad}" --plug=$KEY_MENU --tabnum="${PW_GUI_SORT_TABS[2]}" --form --columns=3 --align-buttons --separator=";" \
    --gui-type-layout="$MAIN_MENU_GUI_TYPE_LAYOUT" \
    --field="   3D API  : !$INFO_3DAPI:CB" "$PW_DEFAULT_VULKAN_USE" \
    --field="   PREFIX  : !$INFO_PREFIX:CBE" "$PW_ADD_PREFIXES_TO_GUI" \
    --field="     WINE  : !$INFO_WINE:CB" "$(combobox_fix "$PW_WINE_USE" "$PW_DEFAULT_WINE_USE")" \
    --field="${translations[Create prefix backup]}!$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png!":"CFBTN" '@bash -c "button_click --normal pw_create_prefix_backup"' \
    --field="   Winetricks!$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png!${translations[Run winetricks to install additional libraries to the selected prefix]}":"FBTN" '@bash -c "button_click --normal WINETRICKS"' \
    --field="   ${translations[Clear prefix]}!$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png!${translations[Clear the prefix to fix problems]}":"FBTN" '@bash -c "button_click --normal gui_clear_pfx"' \
    --field="   ${translations[Get other Wine]}!$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png!${translations[Open the menu to download other versions of WINE or PROTON]}":"FBTN" '@bash -c "button_click --normal gui_proton_downloader"' \
    --field="   ${translations[Uninstaller]}!$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png!${translations[Run the program uninstaller built into wine]}":"FBTN" '@bash -c "button_click --normal wine_uninstaller"' \
    --field="   ${translations[Prefix Manager]}     !$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png!${translations[Run winecfg to edit the settings of the selected prefix]}":"FBTN" '@bash -c "button_click --normal WINECFG"' \
    --field="   ${translations[File Manager]}!$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png!${translations[Run wine file manager]}":"FBTN" '@bash -c "button_click --normal WINEFILE"' \
    --field="   ${translations[Command line]}!$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png!${translations[Run wine cmd]}":"FBTN" '@bash -c "button_click --normal WINECMD"' \
    --field="   ${translations[Regedit]}!$PW_GUI_ICON_PATH/$BUTTON_SIZE_MM.png!${translations[Run wine regedit]}":"FBTN" '@bash -c "button_click --normal WINEREG"' 1> "${PW_TMPFS_PATH}/tmp_yad_form_vulkan" 2>/dev/null &

    unset AI_TYPE AI_NAME AI_IMAGE AI_INFO AI_FILE_ARRAY AI_TRUE_FILE AI_FILE_UNSORTED AI_FILE_SORTED AI_FILE_ENG
    if [[ $AI_SKIP != 1 ]] ; then
        # AI_TOP_GAMES используется для сортировки автоинсталлов (работает на эмуляторы тоже)
        AI_AMOUNT_GAMES="0" && AI_AMOUNT_EMULS="0" && AI_AMOUNT_ARRAY="0"
        for ai_file in "$PORT_SCRIPTS_PATH"/pw_autoinstall/* ; do
            while read -r line ; do
                [[ $line =~ "##########" ]] && break
                [[ $line =~ "# type: " ]] && AI_TYPE["$AI_AMOUNT_ARRAY"]="${line//# type: /}"
                [[ $line =~ "# name: " ]] && AI_NAME["$AI_AMOUNT_ARRAY"]="${line//# name: /}"
                [[ $line =~ "# image: " ]] && AI_IMAGE["$AI_AMOUNT_ARRAY"]="${line//# image: /}"
                if [[ "$LANGUAGE" == ru ]] ; then
                    [[ $line =~ "# info_ru: " ]] && AI_INFO["$AI_AMOUNT_ARRAY"]="${line//# info_ru: /}"
                else
                    [[ $line =~ "# info_en: " ]] && AI_INFO["$AI_AMOUNT_ARRAY"]="${line//# info_en: /}"
                fi
            done < "$ai_file"
            AI_FILE="${ai_file//"$PORT_SCRIPTS_PATH/pw_autoinstall/"/}"
            AI_FILE_CHECK="$AI_FILE=$AI_AMOUNT_ARRAY"
            AI_FILE_ARRAY+=("$AI_FILE")
            if [[ $AI_TOP_GAMES =~ ${AI_FILE_CHECK//=*/} ]] ; then
                AI_TRUE_FILE+=("$AI_FILE_CHECK")
            else
                if [[ ${AI_NAME["$AI_AMOUNT_ARRAY"]} =~ \(ENG\) ]] ; then
                    AI_FILE_ENG+=("$AI_AMOUNT_ARRAY")
                else
                    AI_FILE_UNSORTED+=("$AI_AMOUNT_ARRAY")
                fi
            fi
            (( AI_AMOUNT_ARRAY++ ))
        done

        for ai_sort in $AI_TOP_GAMES ; do
            if [[ ${AI_TRUE_FILE[*]} =~ $ai_sort ]] ; then
                AI_TRUE_FILE_NEW=("${AI_TRUE_FILE[@]//$ai_sort=/}")
                AI_TRUE_FILE_NEW=("${AI_TRUE_FILE_NEW[*]//*=*/}")
                AI_FILE_SORTED+=("${AI_TRUE_FILE_NEW[*]// /}")
            fi
        done

        IFS=$'\n'
        for ai in "${AI_FILE_SORTED[@]}" "${AI_FILE_UNSORTED[@]}" "${AI_FILE_ENG[@]}" ; do
            case ${AI_TYPE[$ai]} in
                games)
                    export PW_GENERATE_BUTTONS_GAMES+="--field=   ${AI_NAME[$ai]}!$PW_GUI_ICON_PATH/${AI_IMAGE[$ai]}.png!${AI_INFO[$ai]}:FBTNR%@bash -c \"button_click --normal ${AI_FILE_ARRAY[$ai]}\"%"
                    (( AI_AMOUNT_GAMES++ ))
                    ;;
                emulators)
                    export PW_GENERATE_BUTTONS_EMULS+="--field=   ${AI_NAME[$ai]}!$PW_GUI_ICON_PATH/${AI_IMAGE[$ai]}.png!${AI_INFO[$ai]}:FBTNR%@bash -c \"button_click --normal ${AI_FILE_ARRAY[$ai]}\"%"
                    (( AI_AMOUNT_EMULS++ ))
                    ;;
                *)
                    yad_error "Line: \"type\" not found in file ${AI_FILE_ARRAY[$ai]} or misspelled."
                    ;;
            esac
        done
        export MAIN_GUI_ROWS_GAMES="$(( AI_AMOUNT_GAMES / MAIN_GUI_COLUMNS + 1 ))"
        export MAIN_GUI_ROWS_EMULS="$(( AI_AMOUNT_EMULS / MAIN_GUI_COLUMNS + 1 ))"

        export AI_SKIP="1"
    fi

    IFS="%"
    if [[ $PW_EMULS == "1" ]] ; then
        "${pw_yad}" --plug=$KEY_MENU --tabnum="${PW_GUI_SORT_TABS[1]}" --form --columns="$MAIN_GUI_ROWS_EMULS" --align-buttons --scroll --homogeneous-column \
        --gui-type-layout="${MAIN_MENU_GUI_TYPE_LAYOUT}" --separator=" " ${PW_GENERATE_BUTTONS_EMULS} 2>/dev/null &
    fi
    "${pw_yad}" --plug=$KEY_MENU --tabnum="${PW_GUI_SORT_TABS[0]}" --form --columns="$MAIN_GUI_ROWS_GAMES" --align-buttons --scroll --homogeneous-column \
    --gui-type-layout="${MAIN_MENU_GUI_TYPE_LAYOUT}" --separator=" " ${PW_GENERATE_BUTTONS_GAMES} 2>/dev/null &
    IFS="$orig_IFS"

    export START_FROM_PP_GUI="1"
    if [[ -z ${TAB_MAIN_MENU} ]] ; then
        export TAB_MAIN_MENU="1"
    fi

    if [[ $PW_EMULS == "1" ]] ; then
        if [[ -z $PW_DESKTOP_FILES ]] ; then
            "${pw_yad}" --key=$KEY_MENU --notebook --expand \
            --gui-type="settings-notebook" --active-tab="${TAB_MAIN_MENU}" \
            --width="${PW_MAIN_SIZE_W}" --height="${PW_MAIN_SIZE_H}" --no-buttons \
            --window-icon="$PW_GUI_ICON_PATH/portproton.svg" \
            --title "PortProton-${install_ver} (${scripts_install_ver}${BRANCH_VERSION})" \
            --tab-pos="bottom" \
            --tab="${translations[AUTOINSTALLS]}!$PW_GUI_ICON_PATH/$TAB_SIZE.png!" \
            --tab="${translations[EMULATORS]}!$PW_GUI_ICON_PATH/$TAB_SIZE.png!" \
            --tab="${translations[WINE SETTINGS]}!$PW_GUI_ICON_PATH/$TAB_SIZE.png!" \
            --tab="${translations[PORTPROTON SETTINGS]}!$PW_GUI_ICON_PATH/$TAB_SIZE.png!" \
            --tab="${translations[INSTALLED]}!$PW_GUI_ICON_PATH/$TAB_SIZE.png!" 2>/dev/null
            YAD_STATUS="$?"
        else
            "${pw_yad}" --key=$KEY_MENU --notebook --expand \
            --gui-type="settings-notebook" --active-tab="${TAB_MAIN_MENU}" \
            --width="${PW_MAIN_SIZE_W}" --height="${PW_MAIN_SIZE_H}" --no-buttons \
            --window-icon="$PW_GUI_ICON_PATH/portproton.svg" \
            --title "PortProton-${install_ver} (${scripts_install_ver}${BRANCH_VERSION})" \
            --tab-pos="bottom" \
            --tab="${translations[INSTALLED]}!$PW_GUI_ICON_PATH/$TAB_SIZE.png!" \
            --tab="${translations[AUTOINSTALLS]}!$PW_GUI_ICON_PATH/$TAB_SIZE.png!" \
            --tab="${translations[EMULATORS]}!$PW_GUI_ICON_PATH/$TAB_SIZE.png!" \
            --tab="${translations[WINE SETTINGS]}!$PW_GUI_ICON_PATH/$TAB_SIZE.png!" \
            --tab="${translations[PORTPROTON SETTINGS]}!$PW_GUI_ICON_PATH/$TAB_SIZE.png!" 2>/dev/null
            YAD_STATUS="$?"
        fi
    else
        if [[ -z $PW_DESKTOP_FILES ]] ; then
            "${pw_yad}" --key=$KEY_MENU --notebook --expand \
            --gui-type="settings-notebook" --active-tab="${TAB_MAIN_MENU}" \
            --width="${PW_MAIN_SIZE_W}" --height="${PW_MAIN_SIZE_H}" --no-buttons \
            --window-icon="$PW_GUI_ICON_PATH/portproton.svg" \
            --title "PortProton-${install_ver} (${scripts_install_ver}${BRANCH_VERSION})" \
            --tab-pos="bottom" \
            --tab="${translations[AUTOINSTALLS]}!$PW_GUI_ICON_PATH/$TAB_SIZE.png!" \
            --tab="${translations[WINE SETTINGS]}!$PW_GUI_ICON_PATH/$TAB_SIZE.png!" \
            --tab="${translations[PORTPROTON SETTINGS]}!$PW_GUI_ICON_PATH/$TAB_SIZE.png!" \
            --tab="${translations[INSTALLED]}!$PW_GUI_ICON_PATH/$TAB_SIZE.png!" 2>/dev/null
            YAD_STATUS="$?"
        else
            "${pw_yad}" --key=$KEY_MENU --notebook --expand \
            --gui-type="settings-notebook" --active-tab="${TAB_MAIN_MENU}" \
            --width="${PW_MAIN_SIZE_W}" --height="${PW_MAIN_SIZE_H}" --no-buttons \
            --window-icon="$PW_GUI_ICON_PATH/portproton.svg" \
            --title "PortProton-${install_ver} (${scripts_install_ver}${BRANCH_VERSION})" \
            --tab-pos="bottom" \
            --tab="${translations[INSTALLED]}!$PW_GUI_ICON_PATH/$TAB_SIZE.png!" \
            --tab="${translations[AUTOINSTALLS]}!$PW_GUI_ICON_PATH/$TAB_SIZE.png!" \
            --tab="${translations[WINE SETTINGS]}!$PW_GUI_ICON_PATH/$TAB_SIZE.png!" \
            --tab="${translations[PORTPROTON SETTINGS]}!$PW_GUI_ICON_PATH/$TAB_SIZE.png!" 2>/dev/null
            YAD_STATUS="$?"
        fi
    fi


    if [[ "$YAD_STATUS" == "1" || "$YAD_STATUS" == "252" ]] ; then exit 0 ; fi
    pw_yad_set_form
    pw_yad_form_vulkan
    export PW_DISABLED_CREATE_DB="1"
fi

case "${VULKAN_MOD}" in
    "$SORT_OPENGL" )     export PW_VULKAN_USE="0" ;;
    "$SORT_SAREK"  )     export PW_VULKAN_USE="1" ;;
    "$SORT_STABLE" )     export PW_VULKAN_USE="2" ;;
    "$SORT_NEWEST" )     export PW_VULKAN_USE="6" ;;
esac

init_wine_ver
if [[ -f "${PORTWINE_DB_FILE}" ]] ; then
    edit_db_from_gui PW_VULKAN_USE PW_WINE_USE PW_PREFIX_NAME
fi

case "$PW_YAD_SET" in
    gui_pw_reinstall_pp|open_changelog|\
    128|gui_pw_update|gui_rm_portproton|\
    change_loc|gui_open_scripts_from_backup|\
    gui_credits|pw_start_cont_xterm)
        if [[ $PW_EMULS == "1" ]]
        then [[ -z $PW_DESKTOP_FILES ]] && TAB_MAIN_MENU="4" || TAB_MAIN_MENU="5"
        else [[ -z $PW_DESKTOP_FILES ]] && TAB_MAIN_MENU="3" || TAB_MAIN_MENU="4"
        fi ;;
    gui_proton_downloader|WINETRICKS|\
    116|pw_create_prefix_backup|\
    gui_clear_pfx|WINEREG|WINECMD|\
    WINEFILE|WINECFG|wine_uninstaller)
        if [[ $PW_EMULS == "1" ]]
        then [[ -z $PW_DESKTOP_FILES ]] && TAB_MAIN_MENU="3" || TAB_MAIN_MENU="4"
        else [[ -z $PW_DESKTOP_FILES ]] && TAB_MAIN_MENU="2" || TAB_MAIN_MENU="3"
        fi ;;
    pw_find_exe)
        if [[ $PW_EMULS == "1" ]]
        then [[ -z $PW_DESKTOP_FILES ]] && TAB_MAIN_MENU="5" || TAB_MAIN_MENU="1"
        else [[ -z $PW_DESKTOP_FILES ]] && TAB_MAIN_MENU="4" || TAB_MAIN_MENU="1"
        fi ;;
esac
export TAB_MAIN_MENU

case "$PW_YAD_SET" in
    '') ;;
    98) portwine_change_shortcut ;;
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
    wine_uninstaller) wine_uninstaller ;;
    gui_rm_portproton) gui_rm_portproton ;;
    gui_pw_reinstall_pp) pw_reinstall_pp ;;
    gui_pw_update) gui_pw_update ;;
    gui_proton_downloader) gui_proton_downloader ;;
    gui_open_scripts_from_backup) gui_open_scripts_from_backup ;;
    open_changelog) open_changelog ;;
    change_loc) change_loc ;;
    open_game_folder) open_game_folder ;;
    118) gui_edit_db ;;
    120) gui_vkbasalt ;;
    122) gui_mangohud ;;
    124) gui_dgvoodoo2 ;;
    126) gui_gamescope ;;
    128) gui_userconf ;;
    pw_create_prefix_backup) pw_create_prefix_backup ;;
    gui_credits) gui_credits ;;
    pw_start_cont_xterm) pw_start_cont_xterm ;;
    pw_find_exe) pw_find_exe ;;
    PW_*) pw_autoinstall_from_db ;;
    *.desktop) button_click --desktop ;;
    1|252|*) exit 0 ;;
esac

stop_portwine
