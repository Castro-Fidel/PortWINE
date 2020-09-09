#!/bin/bash
# Author: PortWINE-Linux.ru
. "$(dirname $(readlink -f "$0"))/runlib"
if [ -f "$1" ]; then
    export portwine_exe="$(readlink -f "$1")"
    export PATH_TO_GAME="$(dirname $(readlink -f "$1"))"
    START_PORTWINE
    if [ ! -z ${optirun_on} ]; then
        ${optirun_on} "${port_on_run}" "run" "$portwine_exe"
    else
        "${port_on_run}" "run" "$portwine_exe"
    fi
    STOP_PORTWINE
else
    sh "${PORT_SCRIPTS_PATH}/winefile"
fi




