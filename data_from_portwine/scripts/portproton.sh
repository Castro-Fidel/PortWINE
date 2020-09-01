#!/bin/bash
# Author: PortWINE-Linux.ru
. "$(dirname $(readlink -f "$0"))/runlib"
if [ -f "$1" ]; then
    portwine_exe="$1"
    portwine_exe_path="$(dirname $(readlink -f "$1"))"
    START_PORTWINE
    cd "${portwine_exe_path}"
    if [ ! -z ${optirun_on} ]; then
        ${optirun_on} "${port_on_run}" "run" "$portwine_exe"
    else
        "${port_on_run}" "run" "$portwine_exe"
    fi
    STOP_PORTWINE
else
    sh "${PORT_SCRIPTS_PATH}/winefile"
fi




