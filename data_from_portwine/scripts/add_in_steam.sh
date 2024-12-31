#!/usr/bin/env bash
# GPL-3.0 license
# based on https://github.com/sonic2kk/steamtinkerlaunch/blob/master/steamtinkerlaunch
PROGNAME="PortProton"

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
generateShortcutVDFAppId() {
	seed="$(echo -n "$1" | md5sum | cut -c1-8)"
	echo "-$((16#${seed} % 1000000000))"
}

dec2hex() {
	printf '%x\n' "$1" | cut -c 9-  # cut removes the 'ffffffff' from the string (represents the sign) and starts from the 9th character
}

# Takes big-endian ("normal") hexidecimal number and converts to little-endian
bigToLittleEndian() {
	echo -n "$1" | tac -rs .. | tr -d '\n'
}

# Takes an signed 32bit integer and converts it to a 4byte little-endian hex number
generateShortcutVDFHexAppId() {
	bigToLittleEndian "$(dec2hex "$1")"
}

# Takes an signed 32bit integer and converts it to an unsigned 32bit integer
generateShortcutGridAppId() {
	echo $(($1 & 0xFFFFFFFF))
}
## ----------
### END MAGIC APPID FUNCTIONS

getSteamShortcutsVdfFileHex() {
	if [[ -z "${STCFGPATH}" ]]; then
		STCFGPATH="$(getUserPath)"
	fi
	if [[ -n "${STCFGPATH}" ]] && [[ -z "${SCPATH}" ]]; then
		SCPATH="${STCFGPATH}/shortcuts.vdf"
	fi
	if [[ -n "${SCPATH}" ]] && [[ -f "${SCPATH}" ]]; then
		LC_ALL=C perl -0777 -ne 'print unpack("H*", $_)' "${SCPATH}"
	fi
}

getSteamShortcutHex() {
	SHORTCUTVDFFILESTARTHEXPAT="0073686f7274637574730000300002"  # Bytes for beginning of the shortcuts.vdf file
	SHORTCUTVDFENTRYBEGINHEXPAT="00080800.*?0002"  # Pattern for beginning of shortcut entry in shortcuts.vdf -- Beginning of file has a different pattern, but every other pattern begins like this
	SHORTCUTSVDFENTRYENDHEXPAT="000808"  # Pattern for how shortcuts.vdf blocks end
	getSteamShortcutsVdfFileHex | grep -oP "(${SHORTCUTVDFFILESTARTHEXPAT}|${SHORTCUTVDFENTRYBEGINHEXPAT})\K.*?(?=${SHORTCUTSVDFENTRYENDHEXPAT})"  # Get entire shortcuts.vdf as hex, then grep each entry using the begin and end patterns for each block
}

getSteamShortcutEntryHex() {
	SHORTCUTSVDFINPUTHEX="$1"  # The hex block representing the shortcut
	SHORTCUTSVDFMATCHPATTERN="$2"  # The pattern to match against in the block
	SHORTCUTVDFENDPAT="0001"  # Generic end pattern for each shortcut.vdf column
	printf "%s" "${SHORTCUTSVDFINPUTHEX}" | grep -oP "${SHORTCUTSVDFMATCHPATTERN}\K.*?(?=${SHORTCUTVDFENDPAT})"
}

getAppTarget() {
	exe=$(listNonSteamGames | jq -r --arg id "$1" 'map(select(.id == $id)) | first(.[].exe)')
	if [[ -n "${exe}" ]]; then
		if [[ "${exe}" =~ .sh$ ]] ; then
			parseSteamTargetExe "${exe}"
		else
			echo "${exe}";
		fi
	fi
}

getSteamGameId() {
	printf "%u\n" $(($1 << 32 | 0x02000000))
}

getAppId() {
	listNonSteamGames | jq -r --arg exe "$1" 'map(select(.exe == $exe)) | first(.[]?.id)'
}

getSteamId() {
	unset SteamAppId
	local cache_file="${PORT_WINE_TMP_PATH:-/tmp}/steamid_cache.json"
	[[ -n "${1:-}" ]] && NOSTAPPNAME="$1"
	if [[ -z "${SteamIds:-}" ]] && [[ -f "${cache_file}" ]]; then
		SteamIds=$(<"${cache_file}")
	fi
	if [[ -n "${SteamIds:-}" ]] && jq -e --arg key "$NOSTAPPNAME" 'has($key)' <<< "${SteamIds}" > /dev/null; then
		SteamAppId=$(jq -r --arg key "${NOSTAPPNAME}" '.[$key]' <<< "${SteamIds}")
	else
		if [[ -n "${1:-}" ]]; then
			getSteamGridDBId "${NOSTAPPNAME}" > /dev/null
		fi
		if [[ $SteamGridDBTypeSteam == true ]]; then
			SRES=$(curl -Ls -e "https://www.steamgriddb.com/game/${SteamGridDBId}" "https://www.steamgriddb.com/api/public/game/${SteamGridDBId}")
			if jq -e ".success == true" <<< "${SRES}" > /dev/null 2>&1; then
				SteamAppId="$(jq -r '.data.platforms.steam.id' <<< "${SRES}")"
			fi
		fi
		SteamIds=$(jq --arg key "${NOSTAPPNAME}" --arg value "${SteamAppId:-}" '. + {($key): $value}' <<< "${SteamIds:-$(jq -n '{}')}")
		echo "${SteamIds}" > "${cache_file}"
	fi
	if [[ -n "${SteamAppId:-}" ]]; then
		echo "${SteamAppId}"
	fi
}

getSteamGridDBId() {
	unset SteamGridDBId
	NOSTAPPNAME="$1"
	SGDBRES=$(curl -Ls -H "Authorization: Bearer ${SGDBAPIKEY}" "${BASESTEAMGRIDDBAPI}/search/autocomplete/${NOSTAPPNAME// /_}")
	if jq -e ".success == true and (.data | length > 0)" <<< "${SGDBRES}" > /dev/null 2>&1; then
		if jq -e '.data[0].types | contains(["steam"])' <<< "${SGDBRES}" > /dev/null; then
			SteamGridDBTypeSteam=true
		else
			SteamGridDBTypeSteam=false
		fi
		SteamGridDBId="$(jq '.data[0].id' <<< "${SGDBRES}")"
		echo "${SteamGridDBId}"
	fi
}

getUserPath() {
	SLUF="${HOME}/.local/share/Steam/config/loginusers.vdf"
	if [[ -f "${SLUF}" ]]; then
		SLUFUB=false
		STUID64=""
		while read -r line; do
			if [[ "${line}" =~ ^[[:space:]]*\"([0-9]+)\"$ ]]; then
				STUIDCUR="${BASH_REMATCH[1]}"
				SLUFUB=true
			elif [[ "${line}" == *'"MostRecent"'*'"1"' && ${SLUFUB} = true ]]; then
				STUID64="${STUIDCUR}"
				break
			elif [[ "${line}" == "}" ]]; then
				SLUFUB=false
			fi
		done < "${SLUF}"
		if [ -n "${STUID64}" ]; then
			STUID32=$((STUID64 - 76561197960265728))
			STUIDPATH="${HOME}/.local/share/Steam/userdata/${STUID32}"
			if [[ -d "${STUIDPATH}" ]]; then
				if [[ -f "${STUIDPATH}/config/shortcuts.vdf" ]]; then
					echo "${STUIDPATH}/config"
				fi
			fi
		fi
	fi
}

listInstalledSteamGames() {
	manifests=("${HOME}/.local/share/Steam/steamapps"/appmanifest_*.acf)
	if [ ! -e "${manifests[0]}" ]; then
		jq -n '[]'
	else
		for manifest_file in "${manifests[@]}"; do
			name="$(grep -Po '"name"\s+"\K[^"]+' "$manifest_file")";
			if [[ ! "${name}" =~ ^(Proton |Steam Linux Runtime|Steamworks Common) ]]; then
				jq -n \
					--arg id "$(grep -Po '"appid"\s+"\K\d+' "$manifest_file")" \
					--arg name "${name}" \
					'{id: $id, name: $name}'
			fi
		done | jq -s '.'
	fi
}

listNonSteamGames() {
	getSteamShortcutHex | while read -r SCVDFE; do
		jq -n \
			--arg id "$(parseSteamShortcutEntryAppID "${SCVDFE}")" \
			--arg name "$(parseSteamShortcutEntryAppName "${SCVDFE}")" \
			--arg exe "$(parseSteamShortcutEntryExe "${SCVDFE}")" \
			'{id: $id, name: $name, exe: $exe}'
	done | jq -s '.'
}

listSteamGames() {
	(
	 	jq -r 'map({AppId: .id, SteamAppId: .id, SteamGameId: .id, Name: .name}) | .[] | tostring' <<< "$(listInstalledSteamGames)"
		jq -r '.[] | tostring' <<< "$(listNonSteamGames)" | while read game; do
			id=$(jq -r '.id' <<< "${game}")
			name=$(jq -r '.name' <<< "${game}")
			jq -r \
				--arg SteamAppId "$(getSteamId "${name}")" \
				--arg SteamGameId "$(getSteamGameId $id)" \
				'{AppId: .id, SteamAppId: ($SteamAppId | if . == "" then "0" else . end), SteamGameId: $SteamGameId, Name: .name} | tostring' <<< "${game}"
		done
	) | jq -s '.'
}

convertSteamShortcutAppID() {
    SHORTCUTAPPIDHEX="$1"
    SHORTCUTAPPIDLITTLEENDIAN="$( echo "${SHORTCUTAPPIDHEX}" | tac -rs .. | tr -d '\n' )"
    echo "$((16#${SHORTCUTAPPIDLITTLEENDIAN}))"
}

convertSteamShortcutHex() {
	# printf "%s" "$1" | xxd -r -p | tr -d '\0'
	LC_ALL=C perl -le 'print pack "H*", $ARGV[0]' "$1" | tr -d '\0'
}

parseSteamShortcutEntryHex() {
	SHORTCUTSVDFINPUTHEX="$1"  # The hex block representing the shortcut
	SHORTCUTSVDFMATCHPATTERN="$2"  # The pattern to match against in the block
	convertSteamShortcutHex "$(getSteamShortcutEntryHex "${SHORTCUTSVDFINPUTHEX}" "${SHORTCUTSVDFMATCHPATTERN}")"
}

parseSteamShortcutEntryExe() {
	SHORTCUTVDFEXEHEXPAT="000145786500"  # 'Exe' ('exe' is 6578650a if we ever need it)
	parseSteamShortcutEntryHex "$1" "${SHORTCUTVDFEXEHEXPAT}" | tr -d '"'
}

parseSteamShortcutEntryAppName() {
	SHORTCUTVDFNAMEHEXPAT="(014170704e616d6500|6170706e616d6500)"  # 'AppName' and 'appname'
	parseSteamShortcutEntryHex "$1" "${SHORTCUTVDFNAMEHEXPAT}"
}

parseSteamShortcutEntryAppID() {
	SHORTCUTVDFAPPIDHEXPAT="617070696400"  # 'appid'
	convertSteamShortcutAppID "$(printf "%s" "$1" | grep -oP "${SHORTCUTVDFAPPIDHEXPAT}\K.{8}")"
}

parseSteamTargetExe() {
	grep -E 'flatpak|start\.sh' "$1" | head -n 1 | awk -F'"' '{print $(NF-1)}'
}

restartSteam() {
	if [[ "${PW_SKIP_RESTART_STEAM}" != 1 ]] && pgrep -i steam &>/dev/null ; then
		if yad_question "${translations[For adding shortcut to STEAM, needed restart.\\n\\nRestart STEAM now?]}" ; then
			pw_start_progress_bar_block "${translations[Restarting STEAM... Please wait.]}"
			kill -s SIGTERM $(pgrep -a steam) &>/dev/null
			while pgrep -i steam &>/dev/null ; do
				sleep 0.5
			done
			steam &
			sleep 5
			pw_stop_progress_bar
			exit 0
		fi
	fi
	unset PW_SKIP_RESTART_STEAM
}

downloadImage() {
	if ! curl -Lf# -o "${STCFGPATH}/grid/$2" "$1"; then
		return 1
	fi
}

downloadImageSteam() {
	if [[ -z "${SteamAppId}" ]]; then
		getSteamId > /dev/null
	fi
	if [[ -n "${SteamAppId}" ]]; then
		downloadImage "https://cdn.cloudflare.steamstatic.com/steam/apps/${SteamAppId}/$1" "$2"
	else
		return 1
	fi
}

downloadImageSteamGridDB() {
	SGDBIMGAPI="${BASESTEAMGRIDDBAPI}/$1/game/${SteamGridDBId}?limit=1"
	[[ -n "$3" ]] && SGDBIMGAPI+="&$3"
	[[ -n "$4" ]] && SGDBIMGAPI+="&$4"
	SGDBIMGRES=$(curl -Ls -H "Authorization: Bearer ${SGDBAPIKEY}" "${SGDBIMGAPI}")
	if jq -e ".success == true and (.data | length > 0)" <<< "${SGDBIMGRES}" > /dev/null 2>&1; then
		SGDBIMGURL=$(jq -r '.data[0].url' <<< "${SGDBIMGRES}")
		downloadImage "${SGDBIMGURL}" "$2"
	elif [[ -n "$3" ]]; then
		downloadImageSteamGridDB "$1" "$2" "" "$4"
	else
		return 1
	fi
}

addGrids() {
	if [[ -n "${SGDBAPIKEY}" ]]; then
		getSteamGridDBId "${name_desktop}" > /dev/null
	fi
	if [[ -n "${SteamGridDBId}" ]]; then
		create_new_dir "${STCFGPATH}/grid"
		downloadImageSteamGridDB "grids" "${NOSTAIDGRID}.jpg" "mimes=image/jpeg" "dimensions=460x215,920x430" || downloadImageSteam "header.jpg" "${NOSTAIDGRID}.jpg" || echo "Failed to load header.jpg"
		downloadImageSteamGridDB "grids" "${NOSTAIDGRID}p.jpg" "mimes=image/jpeg" "dimensions=600x900,660x930" || downloadImageSteam "library_600x900_2x.jpg" "${NOSTAIDGRID}p.jpg" || echo "Failed to load library_600x900_2x.jpg"
		downloadImageSteamGridDB "heroes" "${NOSTAIDGRID}_hero.jpg" "mimes=image/jpeg" || downloadImageSteam "library_hero.jpg" "${NOSTAIDGRID}_hero.jpg" || echo "Failed to load library_hero.jpg"
		downloadImageSteamGridDB "logos" "${NOSTAIDGRID}_logo.png" "mimes=image/png" || downloadImageSteam "logo.png" "${NOSTAIDGRID}_logo.png" || echo "Failed to load logo.png"
	else
		echo "Game is not found"
	fi
}

removeNonSteamGame() {
	if [[ -z "${STCFGPATH}" ]]; then
		STCFGPATH="$(getUserPath)"
	fi
	if [[ -n "${STCFGPATH}" ]] && [[ -z "${SCPATH}" ]]; then
		SCPATH="${STCFGPATH}/shortcuts.vdf"
	fi
	if [[ -n "${SCPATH}" ]] && [[ -f "${SCPATH}" ]]; then
		cp "${SCPATH}" "${SCPATH//.vdf}_${PROGNAME}_backup.vdf" 2>/dev/null
	fi
	[[ -n "${1:-}" ]] && appid="$1"
	if [[ -n "${appid}" ]]; then
		NOSTAIDVDFHEX=$(bigToLittleEndian $(printf '%08x' "${appid}"))
		LC_ALL=C perl -pe '
			$hex = pack("H*", shift);
			$pos = index($_, $hex);
			if ($pos != -1) {
				$start_pos = rindex($_, "\x00", $pos - 1);
				$end_pos = index($_, "ppid", $pos);
				$end_pos = index($_, "\x08\x08", $pos) if $end_pos == -1;
				if ($start_pos != -1 && $end_pos != -1) {
					$end_pos += 4;
					$_ = substr($_, 0, $start_pos) . substr($_, $end_pos);
				}
			}
		' "${SCPATH}" "${NOSTAIDVDFHEX}" > "${SCPATH}~"
		mv "${SCPATH}~" "${SCPATH}"
		rm -f "${STCFGPATH}/grid/${appid}.jpg" "${STCFGPATH}/grid/${appid}p.jpg" "${STCFGPATH}/grid/${appid}_hero.jpg" "${STCFGPATH}/grid/${appid}_logo.png"
	fi
}

addNonSteamGame() {
	if [[ -z "${STCFGPATH}" ]]; then
		STCFGPATH="$(getUserPath)"
	fi
	if [[ -n "${STCFGPATH}" ]] && [[ -z "${SCPATH}" ]]; then
		SCPATH="${STCFGPATH}/shortcuts.vdf"
	fi
	if [[ -n "${SCPATH}" ]]; then
		NOSTAPPNAME="${name_desktop}"
		NOSTSHPATH="${STEAM_SCRIPTS}/${name_desktop}.sh"
		NOSTAIDGRID=$(getAppId "${NOSTSHPATH}")
		if [[ -z "${NOSTAIDGRID}" ]]; then
			NOSTEXEPATH="\"${NOSTSHPATH}\""
			if [[ -z "${NOSTSTDIR}" ]]; then
				NOSTSTDIR="\"${STEAM_SCRIPTS}\""
			fi
			NOSTICONPATH="${PORT_WINE_PATH}/data/img/${name_desktop_png}.png"
			NOSTAIDVDF="$(generateShortcutVDFAppId "${NOSTAPPNAME}${NOSTEXEPATH}")"  # signed integer AppID, stored in the VDF as hexidecimal - ex: -598031679
			NOSTAIDVDFHEX="$(generateShortcutVDFHexAppId "$NOSTAIDVDF")"  # 4byte little-endian hexidecimal of above 32bit signed integer, which we write out to the binary VDF - ex: c1c25adc
			NOSTAIDVDFHEXFMT="\x$(awk '{$1=$1}1' FPAT='.{2}' OFS="\\\x" <<< "$NOSTAIDVDFHEX")"  # binary-formatted string hex of the above which we actually write out - ex: \xc1\xc2\x5a\xdc
			NOSTAIDGRID="$(generateShortcutGridAppId "$NOSTAIDVDF")"  # unsigned 32bit ingeger version of "$NOSTAIDVDF", which is used as the AppID for Steam artwork ("grids"), as well as for our shortcuts

			create_new_dir "${STEAM_SCRIPTS}"
			echo "#!/usr/bin/env bash" > "${NOSTSHPATH}"
			echo "export START_FROM_STEAM=1" >> "${NOSTSHPATH}"
			echo "export LD_PRELOAD=" >> "${NOSTSHPATH}"
			if check_flatpak; then
				echo "flatpak run ru.linux_gaming.PortProton \"${portwine_exe}\" " >> "${NOSTSHPATH}"
			else
				echo "\"${PORT_SCRIPTS_PATH}/start.sh\" \"${portwine_exe}\" " >> "${NOSTSHPATH}"
			fi
			chmod u+x "${NOSTSHPATH}"

			if [[ -f "${SCPATH}" ]] ; then
				cp "${SCPATH}" "${SCPATH//.vdf}_${PROGNAME}_backup.vdf" 2>/dev/null
				truncate -s-2 "${SCPATH}"
				OLDSET="$(grep -aPo '\x00[0-9]\x00\x02appid' "${SCPATH}" | tail -n1 | tr -dc '0-9')"
				NEWSET=$((OLDSET + 1))
			else
				printf '\x00%s\x00' "shortcuts" > "${SCPATH}"
				NEWSET=0
			fi

			{
				printf '\x00%s\x00' "${NEWSET}"
				printf '\x02%s\x00%b' "appid" "${NOSTAIDVDFHEXFMT}"
				printf '\x01%s\x00%s\x00' "AppName" "${NOSTAPPNAME}"
				printf '\x01%s\x00%s\x00' "Exe" "${NOSTEXEPATH}"
				printf '\x01%s\x00%s\x00' "StartDir" "${NOSTSTDIR}"
				printf '\x01%s\x00%s\x00' "icon" "${NOSTICONPATH}"
				printf '\x01%s\x00%s\x00' "ShortcutPath" ""
				printf '\x01%s\x00%s\x00' "LaunchOptions" ""

				printf '\x02%s\x00%b\x00\x00\x00' "IsHidden" "\x00"
				printf '\x02%s\x00%b\x00\x00\x00' "AllowDesktopConfig" "\x00"

				# These values are now stored in localconfig.vdf under the "Apps" section,
				# under a block using the Non-Steam Game Signed 32bit AppID. (i.e., -223056321)
				# This is handled by `updateLocalConfigAppsValue` below
				#
				# Unsure if required, but still write these to the shortcuts.vdf file for consistency
				printf '\x02%s\x00%b\x00\x00\x00' "AllowOverlay" "\x00"
				printf '\x02%s\x00%b\x00\x00\x00' "OpenVR" "\x00"

				printf '\x02%s\x00\x00\x00\x00\x00' "Devkit"
				printf '\x01%s\x00\x00' "DevkitGameID"
				printf '\x02%s\x00\x00\x00\x00\x00' "DevkitOverrideAppID"
				printf '\x02%s\x00\x00\x00\x00\x00' "LastPlayTime"
				printf '\x01%s\x00\x00' "FlatpakAppID"
				printf '\x00%s\x00' "tags"
				printf '\x08\x08\x08\x08'
			} >> "${SCPATH}"

			# TODO: замень использование steamgriddb на steam так как сайт steamgriddb у многих без VPN не работает
			# а пока просто блочим использование
			export DOWNLOAD_STEAM_GRID="0"

			if [[ "${DOWNLOAD_STEAM_GRID}" == "1" ]] ; then
				pw_start_progress_bar_block "${translations[Please wait. downloading covers for]} ${NOSTAPPNAME}"
				addGrids
				pw_stop_progress_bar
			fi

			restartSteam
		fi
	else
		return 1
	fi
}
