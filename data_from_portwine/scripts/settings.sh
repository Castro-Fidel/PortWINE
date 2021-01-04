#!/bin/bash
# Author: PortWINE-Linux.ru
##########################
. "$(dirname $(readlink -f "$0"))/runlib"
KILL_PORTWINE
##########################
PW_WINECFG ()
{
START_PORTWINE
$PW_TERM "${PW_RUNTIME}" "${port_on_run}" "run" "winecfg"
} 
##########################
PW_WINEFILE ()
{
START_PORTWINE
cd "${WINEPREFIX}/drive_c/"
if [ ! -z ${optirun_on} ]
then
    $PW_TERM "${PW_RUNTIME}" ${optirun_on} "${port_on_run}" "run" "explorer" 
else
    $PW_TERM "${PW_RUNTIME}" "${port_on_run}" "run" "explorer" 
fi
}
##########################
PW_WINECMD ()
{
export PW_USE_TERMINAL=1
START_PORTWINE
if [ ! -z ${optirun_on} ]
then
    $PW_TERM "${PW_RUNTIME}" "${optirun_on}" "${port_on_run}" "run" "cmd"
else
    $PW_TERM "${PW_RUNTIME}" "${port_on_run}" "run" "cmd"
fi
}
##########################
PW_WINEREG ()
{
START_PORTWINE
$PW_TERM "${PW_RUNTIME}" "${port_on_run}" "run" "regedit"
}
##########################
PW_WINETRICKS ()
{
W_TRX_URL="https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"
W_TRX_EXT_VER="$(curl -s --list-only ${W_TRX_URL} | grep -i 'WINETRICKS_VERSION=' | sed 's/WINETRICKS_VERSION=//')"
if  ! [[ -f "${PORT_WINE_TMP_PATH}/winetricks" ]] 
then
    wget -T 3 --output-document=${PORT_WINE_TMP_PATH}/winetricks ${W_TRX_URL}
    chmod u+x "${PORT_WINE_TMP_PATH}/winetricks"
else
W_TRX_INT_VER="$(cat "${PORT_WINE_TMP_PATH}/winetricks" | grep -i 'WINETRICKS_VERSION=' | sed 's/WINETRICKS_VERSION=//')"
        if  [[ $W_TRX_INT_VER != $W_TRX_EXT_VER ]]
        then
            rm -f "${PORT_WINE_TMP_PATH}/winetricks"
            wget -T 3 --output-document=${PORT_WINE_TMP_PATH}/winetricks ${W_TRX_URL}
            chmod u+x "${PORT_WINE_TMP_PATH}/winetricks"
        fi
fi #modded by Cefeiko
export PW_USE_TERMINAL=1
START_PORTWINE
$PW_TERM "${PW_RUNTIME}" "${PORT_WINE_TMP_PATH}/winetricks" -q --force
}
##########################
OUTPUT=$(yad --form \
--title "SETTINGS"  --image "winecfg" --separator=";" \
--field="WINE:CB" "DXVK ${PW_WINE_VER_DXVK}"!"VKD3D ${PW_WINE_VER_VKD3D}" \
--button='WINECFG'!winecfg!"Run winecfg for $portname":100 \
--button='WINEFILE'!winecfg!'проверка подсказки1':102 \
--button='WINECMD'!winecfg!'проверка подсказки2':104 \
--button='WINEREG'!winecfg!'проверка подсказки3':106 \
--button='WINETRICKS'!winecfg!'проверка подсказки4 - бла бла бла бла бла ла ла ла =)':108 )
PW_YAD_SET="$?"
export VULKAN_MOD=$(echo $OUTPUT | awk 'BEGIN {FS=";" } { print $1 }')
if [ "${VULKAN_MOD}" = "DXVK ${PW_WINE_VER_DXVK}" ]; then
    echo "0" > "${PORT_WINE_TMP_PATH}/dxvk_on"
else
    echo "off" > "${PORT_WINE_TMP_PATH}/dxvk_on"    
fi
case "$PW_YAD_SET" in
    100) PW_WINECFG ;;
    102) PW_WINEFILE ;;
    104) PW_WINECMD ;;
    106) PW_WINEREG ;;
    108) PW_WINETRICKS ;;
esac
##########################
STOP_PORTWINE
