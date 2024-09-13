#!/usr/bin/env bash
clear
cd "$(dirname "$(readlink -f "$0")")" && SELF_PATH="$(pwd)"

chmod 644 "$SELF_PATH/portwine_db/"*

orig_IFS="$IFS"
IFS=$'\n'

unset DUPLICATE
DUPLICATE="$(cat "$SELF_PATH/portwine_db/"* | grep -E ".exe" | grep '#' | uniq -D | sort -u)"
if [[ -n "$DUPLICATE" ]] ; then
    for duplicate_db in $DUPLICATE ; do
        echo -e "\nDuplicate:"
        grep -E "$duplicate_db" "$SELF_PATH/portwine_db/"* | awk -F"portwine_db/" '{print $2}'
    done
    exit 1
fi

for ppdb in $SELF_PATH/portwine_db/* ; do
    echo "$ppdb"

    sed -i '/##export/d' "$ppdb"
    sed -i '/##add_/d' "$ppdb"

    if echo "$ppdb" | grep -i "setup" ; then
        continue
    fi

    sed -i '/MANGOHUD/d' "$ppdb"
    sed -i '/FPS_LIMIT/d' "$ppdb"
    sed -i '/VKBASALT/d' "$ppdb"
    sed -i '/_RAY_TRACING/d' "$ppdb"
    sed -i '/_DLSS/d' "$ppdb"
    sed -i '/PW_GUI_DISABLED_CS/d' "$ppdb"
    sed -i '/PW_USE_GAMEMODE/d' "$ppdb"
    sed -i '/PW_USE_SYSTEM_VK_LAYERS/d' "$ppdb"
    sed -i '/PW_DISABLE_COMPOSITING/d' "$ppdb"
    sed -i '/PW_USE_EAC_AND_BE/d' "$ppdb"
    sed -i '/PW_USE_OBS_VKCAPTURE/d' "$ppdb"
    sed -i '/GAMESCOPE/d' "$ppdb"
    sed -i '/PW_GS/d' "$ppdb"

    if grep 'export PW_USE_DGVOODOO2="0"' "$ppdb" \
    || grep 'export PW_DGVOODOO2="0"' "$ppdb"
    then
        sed -i '/PW_USE_DGVOODOO2=/d' "$ppdb"
        sed -i '/PW_DGV/d' "$ppdb"
    fi

    if grep 'PW_WINE_USE="WINE_LG' "$ppdb" ; then
        sed -i /'export PW_WINE_USE=/c export PW_WINE_USE="WINE_LG"' "$ppdb"
    elif grep 'PW_WINE_USE="PROTON_LG' "$ppdb" ; then
        sed -i /'export PW_WINE_USE=/c export PW_WINE_USE="PROTON_LG"' "$ppdb"
    fi

    if [[ "$ppdb" == *.exe.ppdb ]] ; then
        mv -f "$ppdb" "$SELF_PATH/portwine_db/$(basename "$ppdb" .exe.ppdb).ppdb"
    elif [[ "$ppdb" == *.EXE.ppdb ]] ; then
        mv -f "$ppdb" "$SELF_PATH/portwine_db/$(basename "$ppdb" .EXE.ppdb).ppdb"
    elif [[ "$ppdb" != *.ppdb ]] ; then
        mv -f "$ppdb" "$SELF_PATH/portwine_db/$(basename "$ppdb").ppdb"
    fi
done
IFS="$orig_IFS"

echo -e "\nDONE!\n"
exit 0
