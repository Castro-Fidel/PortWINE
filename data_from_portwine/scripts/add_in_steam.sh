#!/usr/bin/env bash
# GPL-3.0 license
# based on https://github.com/sonic2kk/steamtinkerlaunch/blob/master/steamtinkerlaunch
PROGNAME="PortProton"
NOSTAPPNAME="$name_desktop"
NOSTSHPATH="${STEAM_SCRIPTS}/${name_desktop}.sh"
NOSTEXEPATH="\"${NOSTSHPATH}\""
NOSTICONPATH="${PORT_WINE_PATH}/data/img/$name_desktop_png.png"
if [[ -z "${NOSTSTDIR}" ]] ; then
	NOSTSTDIR="\"${STEAM_SCRIPTS}\""
fi

## How Non-Steam AppIDs work, because it took me almost a year to figure this out
## ----------------------
## Steam stores shortcuts in a binary 'shortcuts.vdf', at SROOT/userdata/<id>/config
##
## Non-Steam AppIDs are 32bit little-endian (reverse byte order) signed integers, stored as hexidecimal
## This is probably generated using a crc32 generated from AppName + Exe, but it can actually be anything
## Steam likely does this to ensure "uniqueness" among entries, tools like Steam-ROM-Manager do the same thing likely for similar reasons
##
## For simplicity we generate a random 32bit signed integer using an md5, which we'll then convert to hex to store in the AppID file
## Though we can write any AppID we want, Steam will reject invalid ones (i.e. big endian hex) it will overwrite our AppID
## We can also convert this to an unsigned 32bit integer to get the AppID used for grids and other things, the unsigned int is just what Steam stores
##
## We can later re-use these functions to do several things:
## - Check for and remove stray STL configs for no longer stored Non-Steam Game AppIDs (if we had Non-Steam Games we previously used with STL that we no longer use, we can remove these configs in case there is a conflict in future)

### BEGIN MAGIC APPID FUNCTIONS
## ----------
# Generate random signed 32bit integer which can be converted into hex, using the first argument (AppName and Exe fields) as seed (in an attempt to reduce the chances of the same AppID being generated twice)
function generateShortcutVDFAppId {
	seed="$( echo -n "$1" | md5sum | cut -c1-8 )"
	echo "-$(( 16#${seed} % 1000000000 ))"
}

function dec2hex {
	printf '%x\n' "$1" | cut -c 9-  # cut removes the 'ffffffff' from the string (represents the sign) and starts from the 9th character
}

# Takes big-endian ("normal") hexidecimal number and converts to little-endian
function bigToLittleEndian {
	echo -n "$1" | tac -rs .. | tr -d '\n'
}

# Takes an signed 32bit integer and converts it to a 4byte little-endian hex number
function generateShortcutVDFHexAppId {
	bigToLittleEndian "$( dec2hex "$1" )"
}

# Takes an signed 32bit integer and converts it to an unsigned 32bit integer
function generateShortcutGridAppId {
	echo $(( $1 & 0xFFFFFFFF ))
}
## ----------
### END MAGIC APPID FUNCTIONS

NOSTAIDVDF="$(generateShortcutVDFAppId "${NOSTAPPNAME}${NOSTEXEPATH}")"  # signed integer AppID, stored in the VDF as hexidecimal - ex: -598031679
NOSTAIDVDFHEX="$(generateShortcutVDFHexAppId "$NOSTAIDVDF")"  # 4byte little-endian hexidecimal of above 32bit signed integer, which we write out to the binary VDF - ex: c1c25adc
NOSTAIDVDFHEXFMT="\x$(awk '{$1=$1}1' FPAT='.{2}' OFS="\\\x" <<< "$NOSTAIDVDFHEX")"  # binary-formatted string hex of the above which we actually write out - ex: \xc1\xc2\x5a\xdc
NOSTAIDGRID="$(generateShortcutGridAppId "$NOSTAIDVDF")"  # unsigned 32bit ingeger version of "$NOSTAIDVDF", which is used as the AppID for Steam artwork ("grids"), as well as for our shortcuts

if [[ -f "$SCPATH" ]] ; then
	cp "$SCPATH" "${SCPATH//.vdf}_${PROGNAME}_backup.vdf" 2>/dev/null
	truncate -s-2 "$SCPATH"
	OLDSET="$(grep -aPo '\x00[0-9]\x00\x02appid' "$SCPATH" | tail -n1 | tr -dc '0-9')"
	NEWSET=$((OLDSET + 1))
else
	printf '\x00%s\x00' "shortcuts" > "$SCPATH"
	NEWSET=0
fi

export AppName="${NOSTAPPNAME}"
export AppId="${NOSTAIDGRID}"
if [[ "$DOWNLOAD_STEAM_GRID" == "1" ]] ; then
	pw_start_progress_bar_block "${translations[Please wait. downloading covers for]} ${AppName}"
	source "${PORT_SCRIPTS_PATH}/get_images.sh"
	pw_stop_progress_bar
fi

echo "#!/usr/bin/env bash" > "${NOSTSHPATH}"
echo "# AppName=\""${AppName}\""" >> "${NOSTSHPATH}"
echo "# AppId=${AppId}" >> "${NOSTSHPATH}"
echo "# SteamAppId=${SteamAppId:-0}" >> "${NOSTSHPATH}"
echo "# SteamGridDBId=${SteamGridDBId:-0}" >> "${NOSTSHPATH}"
echo "export START_FROM_STEAM=1" >> "${NOSTSHPATH}"
echo "export LD_PRELOAD=" >> "${NOSTSHPATH}"
if check_flatpak
then echo "flatpak run ru.linux_gaming.PortProton \"${portwine_exe}\" " >> "${NOSTSHPATH}"
else echo "\"${PORT_SCRIPTS_PATH}/start.sh\" \"${portwine_exe}\" " >> "${NOSTSHPATH}"
fi
chmod u+x "${NOSTSHPATH}"

{
	printf '\x00%s\x00' "$NEWSET"
	printf '\x02%s\x00%b' "appid" "$NOSTAIDVDFHEXFMT"
	printf '\x01%s\x00%s\x00' "AppName" "$NOSTAPPNAME"
	printf '\x01%s\x00%s\x00' "Exe" "$NOSTEXEPATH"
	printf '\x01%s\x00%s\x00' "StartDir" "$NOSTSTDIR"
	printf '\x01%s\x00%s\x00' "icon" "$NOSTICONPATH"
	printf '\x01%s\x00%s\x00' "ShortcutPath" ""
	printf '\x01%s\x00%s\x00' "LaunchOptions" "$NOSTLAOP"

	printf '\x02%s\x00%b\x00\x00\x00' "IsHidden" "\x0${NOSTHIDE:-0}"
	printf '\x02%s\x00%b\x00\x00\x00' "AllowDesktopConfig" "\x0${NOSTADC:-0}"

	# These values are now stored in localconfig.vdf under the "Apps" section,
	# under a block using the Non-Steam Game Signed 32bit AppID. (i.e., -223056321)
	# This is handled by `updateLocalConfigAppsValue` below
	#
	# Unsure if required, but still write these to the shortcuts.vdf file for consistency
	printf '\x02%s\x00%b\x00\x00\x00' "AllowOverlay" "\x0${NOSTAO:-0}"
	printf '\x02%s\x00%b\x00\x00\x00' "OpenVR" "\x0${NOSTVR:-0}"

	printf '\x02%s\x00\x00\x00\x00\x00' "Devkit"
	printf '\x01%s\x00\x00' "DevkitGameID"
	printf '\x02%s\x00\x00\x00\x00\x00' "DevkitOverrideAppID"
	printf '\x02%s\x00\x00\x00\x00\x00' "LastPlayTime"
	printf '\x01%s\x00\x00' "FlatpakAppID"
	printf '\x00%s\x00' "tags"
	printf '\x08\x08\x08\x08'
} >> "$SCPATH"
