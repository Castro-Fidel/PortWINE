#!/bin/bash
# Author: PortWINE-Linux.ru
. "$(dirname $(readlink -f "$0"))/runlib"
START_PORTWINE
if [ -f "$1" ]; then
    export portwine_exe="$(readlink -f "$1")"
    export PATH_TO_GAME="$( cd "$( dirname "$1" )" >/dev/null 2>&1 && pwd )"
    if [ ! -z ${optirun_on} ]; then
        "${PW_RUNTIME}" $PW_TERM ${optirun_on} "${port_on_run}" "run" "$portwine_exe"
    else
        "${PW_RUNTIME}" $PW_TERM "${port_on_run}" "run" "$portwine_exe"
    fi
else
    if [ ! -z ${optirun_on} ]
    then
        "${PW_RUNTIME}" $PW_TERM ${optirun_on} "${port_on_run}" "run" "explorer" 
    else
        "${PW_RUNTIME}" $PW_TERM "${port_on_run}" "run" "explorer" 
    fi
fi
STOP_PORTWINE
