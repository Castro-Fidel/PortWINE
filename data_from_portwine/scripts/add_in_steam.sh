#!/usr/bin/env bash
# GPL-3.0 license
# based on https://github.com/sonic2kk/steamtinkerlaunch/blob/master/steamtinkerlaunch
PROGNAME="PortProton"

# Generate random signed 32bit integer which can be converted into hex, using the first argument (AppName and Exe fields) as seed (in an attempt to reduce the chances of the same AppID being generated twice)
generateShortcutVDFAppId() {
	seed="$(echo -n "$1" | md5sum | cut -c1-8)"
	echo "-$((16#${seed} % 1000000000))"
}

dec2hex() {
	printf '%x\n' "$1" | cut -c 9-  # cut removes the 'ffffffff' from the string (represents the sign) and starts from the 9th character
}

# Takes an signed 32bit integer and converts it to an unsigned 32bit integer
extractSteamId32() {
# 	STUID32=$((STUID64 - 76561197960265728))
	echo $(($1 & 0xFFFFFFFF))
}

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

getAppExe() {
	[[ -n "$1" ]] && listNonSteamGames | jq -r --arg id "$1" 'map(select(.id == $id)) | first(.[].exe)'
}

getAppTarget() {
	exe=$(getAppExe "$1")
	[[ -n "${exe}" ]] && parseSteamTargetExe "${exe}"
}

getSteamGameId() {
	printf "%u\n" $(($1 << 32 | 0x02000000))
}

getAppId() {
	[[ -n "$1" ]] && listNonSteamGames | jq -r --arg exe "$1" 'map(select(.exe == $exe)) | first(.[]?.id)'
}

getSteamId() {
	unset SteamAppId
	local cache_file="${PORT_WINE_TMP_PATH:-/tmp}/steamid_cache.json"
	local applist_cache_file="${PORT_WINE_TMP_PATH:-/tmp}/steamapplist_cache.json"
	[[ -n "${1:-}" ]] && NOSTAPPNAME="$1"
	[[ -z "${NOSTAPPNAME}" ]] && return 1
	if [[ -z "${SteamIds:-}" ]] && [[ -f "${cache_file}" ]]; then
		SteamIds=$(<"${cache_file}")
	fi
	if [[ -n "${1:-}" ]] && [[ -n "${SteamIds:-}" ]] && jq -e --arg key "${NOSTAPPNAME}" 'has($key)' <<< "${SteamIds}" > /dev/null; then
		SteamAppId=$(jq -r --arg key "${NOSTAPPNAME}" '.[$key]' <<< "${SteamIds}")
	else
		if [[ -n "${2:-}" ]]; then
			NOSTAPPPATH="$2"
			[[ -f "${NOSTAPPPATH}.ppdb" ]] && source "${NOSTAPPPATH}.ppdb"
		fi
		[[ -n "${STEAM_APP_ID:-}" ]] && SteamAppId="${STEAM_APP_ID}"
		if [[ -z "${SteamAppId:-}" ]] && [[ -n "${NOSTAPPPATH:-}" ]]; then
			local paths=("steam_appid.txt" "steam_emu.ini" "steam_api.ini" "steam_api64.ini")
			local conditions=$(printf " -o -name %q" "${paths[@]}")
			local file=$(find "$(dirname "${NOSTAPPPATH}")" -type f \( ${conditions# -o} \) -print -quit 2>/dev/null)
			if [[ -n "${file}" ]]; then
				if [[ "${file}" == *"steam_appid.txt" ]]; then
					SteamAppId=$(cat "${file}" | tr -d '\r\n')
				else
					SteamAppId=$(grep -i "^AppId=" "${file}" | cut -d'=' -f2 | head -1 | tr -d '\r\n')
				fi
			fi
		fi
		if [[ -z "${SteamAppId:-}" ]]; then
			[[ "${USE_STEAMGRIDDB:-1}" == "1" ]] && getSteamGridDBId "${NOSTAPPNAME}" > /dev/null
			if [[ ${SteamGridDBTypeSteam} == true ]]; then
				SRES=$(curl -Ls --connect-timeout 5 -m 10 -e "https://www.steamgriddb.com/game/${SteamGridDBId}" "https://www.steamgriddb.com/api/public/game/${SteamGridDBId}")
				if jq -e ".success == true" <<< "${SRES}" > /dev/null 2>&1; then
					SteamAppId="$(jq -r '.data.platforms.steam.id' <<< "${SRES}")"
				fi
			elif [[ "${USE_STEAMGRIDDB:-1}" == "0" ]]; then
				if [[ ! -f "${applist_cache_file}" ]] || [[ $(find "${applist_cache_file}" -mmin +1440) ]]; then
					applist_data=$(curl -s --connect-timeout 5 "https://api.steampowered.com/ISteamApps/GetAppList/v2/")
					[[ -n "${applist_data}" ]] && echo "${applist_data}" > "${applist_cache_file}"
				else
					applist_data=$(<"${applist_cache_file}")
				fi
				[[ -n "${applist_data}" ]] && SteamAppId=$(jq --arg name "${NOSTAPPNAME,,}" '.applist.apps[] | select(.name == $name) | .appid' <<< "${applist_data,,}")
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
	if [[ "${USE_STEAMGRIDDB:-1}" == "1" ]] && [[ -n "${SGDBAPIKEY}" ]] && [[ -n "${BASESTEAMGRIDDBAPI}" ]] && curl -fs --connect-timeout 5 -m 10 -o /dev/null "${BASESTEAMGRIDDBAPI}"; then
		SGDBRES=$(curl -Ls --connect-timeout 5 -m 10 -H "Authorization: Bearer ${SGDBAPIKEY}" "${BASESTEAMGRIDDBAPI}/search/autocomplete/${NOSTAPPNAME// /_}")
		if jq -e ".success == true and (.data | length > 0)" <<< "${SGDBRES}" > /dev/null 2>&1; then
			if jq -e '.data[0].types | contains(["steam"])' <<< "${SGDBRES}" > /dev/null; then
				SteamGridDBTypeSteam=true
			else
				SteamGridDBTypeSteam=false
			fi
			SteamGridDBId="$(jq '.data[0].id' <<< "${SGDBRES}")"
			echo "${SteamGridDBId}"
		fi
	else
		USE_STEAMGRIDDB="0"
	fi
}

getUserIds() {
	[[ -z "${STEAM_BASE_FOLDER}" ]] && STEAM_BASE_FOLDER="$(getSteamPath)"
	SLUF="${STEAM_BASE_FOLDER}/config/loginusers.vdf"
	if [[ -f "${SLUF}" ]]; then
		STUIDS=()
		while read -r line; do
			if [[ "${line}" =~ ^[[:space:]]*\"([0-9]+)\"$ ]]; then
				STUIDS+=("$(extractSteamId32 "${BASH_REMATCH[1]}")")
			fi
		done < "${SLUF}"
		if [[ ${#STUIDS[@]} -gt 0 ]]; then
			echo "${STUIDS[@]}"
		fi
	fi
}

getUserId() {
	[[ -z "${STEAM_BASE_FOLDER}" ]] && STEAM_BASE_FOLDER="$(getSteamPath)"
	SLUF="${STEAM_BASE_FOLDER}/config/loginusers.vdf"
	if [[ -f "${SLUF}" ]]; then
		SLUFUB=false
		STUID=""
		while read -r line; do
			if [[ "${line}" =~ ^[[:space:]]*\"([0-9]+)\"$ ]]; then
				STUIDCUR="${BASH_REMATCH[1]}"
				SLUFUB=true
			elif [[ "${line}" == *'"MostRecent"'*'"1"' && ${SLUFUB} = true ]]; then
				STUID=$(extractSteamId32 "${STUIDCUR}")
				break
			elif [[ "${line}" == "}" ]]; then
				SLUFUB=false
			fi
		done < "${SLUF}"
	fi
	if [ -n "${STUID}" ]; then
		echo "${STUID}"
	fi
}

getUserPath() {
	if [[ -n "${1:-}" ]]; then
		STUID="$1"
	else
		STUID="$(getUserId)"
	fi
	if [ -n "${STUID}" ]; then
		[[ -z "${STEAM_BASE_FOLDER}" ]] && STEAM_BASE_FOLDER="$(getSteamPath)"
		STUIDPATH="${STEAM_BASE_FOLDER}/userdata/${STUID}"
		if [[ -d "${STUIDPATH}/config/" ]]; then
			echo "${STUIDPATH}/config"
		fi
	fi
}

getSteamPath() {
	local paths=("${HOME}/.steam/steam" "${HOME}/.local/share/Steam" "${HOME}/.var/app/com.valvesoftware.Steam/.steam/steam")
	for path in "${paths[@]}"; do
		if [[ -d "${path}" ]]; then
			STEAM_BASE_FOLDER="${path}"
			echo "${STEAM_BASE_FOLDER}"
			return 0
		fi
	done
	return 1
}

listInstalledSteamGames() {
	[[ -z "${STEAM_BASE_FOLDER}" ]] && STEAM_BASE_FOLDER="$(getSteamPath)"
	manifests=("${STEAM_BASE_FOLDER}/steamapps"/appmanifest_*.acf)
	if [ ! -e "${manifests[0]}" ]; then
		jq -n '[]'
	else
		for manifest_file in "${manifests[@]}"; do
			name="$(grep -Po '"name"\s+"\K[^"]+' "${manifest_file}")";
			stateflags="$(grep -Po '"StateFlags"\s+"\K\d+' "${manifest_file}")"
# 			if [[ ! "${name}" =~ ^(Proton |Steam Linux Runtime|Steamworks Common) ]]; then
			if ((stateflags & 4)) && grep -q '"SharedDepots"' "${manifest_file}"; then
				jq -n \
					--arg id "$(grep -Po '"appid"\s+"\K\d+' "${manifest_file}")" \
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
			--arg dir "$(parseSteamShortcutEntryStartDir "${SCVDFE}")" \
			--arg icon "$(parseSteamShortcutEntryIcon "${SCVDFE}")" \
			--arg args "$(parseSteamShortcutEntryLaunchOptions "${SCVDFE}")" \
			'{id: $id, name: $name, exe: $exe, dir: $dir, icon: $icon, args: $args}'
	done | jq -s '.'
}

listSteamGames() {
	(
		jq -r 'map({AppId: .id, SteamAppId: .id, SteamGameId: .id, Name: .name}) | .[] | tostring' <<< "$(listInstalledSteamGames)"
		jq -r '.[] | tostring' <<< "$(listNonSteamGames)" | while read -r game; do
			id=$(jq -r '.id' <<< "${game}")
			name=$(jq -r '.name' <<< "${game}")
			exe=$(jq -r '.exe' <<< "${game}")
			if [[ "${name}" =~ ^[0-9]+$ ]] && [[ "${exe}" =~ .sh$ ]]; then
				appid="${name}"
				name=$(basename "${exe}" .sh)
			else
				path="$(parseSteamTargetExe "${exe}")"
				appid="$(getSteamId "${name}" "${path}")"
				[[ -z "${appid}" ]] && appid="0"
			fi
			gid="$(getSteamGameId $id)"
			jq -n \
				--arg id "${id}" \
				--arg appid "${appid}" \
				--arg gid "${gid}" \
				--arg name "${name}" \
				'{AppId: $id, SteamAppId: $appid, SteamGameId: $gid, Name: $name}'
		done
	) | jq -s '.'
}

convertSteamShortcutAppID() {
	SHORTCUTAPPIDHEX="$1"
	SHORTCUTAPPIDLITTLEENDIAN="$( echo "${SHORTCUTAPPIDHEX}" | tac -rs .. | tr -d '\n' )"
	echo "$((16#${SHORTCUTAPPIDLITTLEENDIAN}))"
}

convertSteamShortcutHex() {
	LC_ALL=C perl -le 'print pack "H*", $ARGV[0]' "$1" | tr -d '\0'
}

convertStringToSteamShortcutHex() {
	LC_ALL=C perl -e 'print unpack "H*", "$ARGV[0]" . "\x00"' "$(echo "$1" | tr -cd '[:alpha:]')"
}

parseSteamShortcutEntryHex() {
	SHORTCUTSVDFINPUTHEX="$1"  # The hex block representing the shortcut
	SHORTCUTSVDFMATCHPATTERN="$2"  # The pattern to match against in the block
	convertSteamShortcutHex "$(getSteamShortcutEntryHex "${SHORTCUTSVDFINPUTHEX}" "${SHORTCUTSVDFMATCHPATTERN}")"
}

parseSteamShortcutEntryAppID() {
	SHORTCUTVDFAPPIDHEXPAT="617070696400"  # 'appid'
	convertSteamShortcutAppID "$(printf "%s" "$1" | grep -oP "${SHORTCUTVDFAPPIDHEXPAT}\K.{8}")"
}

parseSteamShortcutEntryAppName() {
	SHORTCUTVDFNAMEHEXPAT="(014170704e616d6500|6170706e616d6500)"  # 'AppName' and 'appname'
	parseSteamShortcutEntryHex "$1" "${SHORTCUTVDFNAMEHEXPAT}"
}

parseSteamShortcutEntryExe() {
	SHORTCUTVDFEXEHEXPAT="000145786500"  # 'Exe' ('exe' is 6578650a if we ever need it)
	parseSteamShortcutEntryHex "$1" "${SHORTCUTVDFEXEHEXPAT}" | tr -d '"'
}

parseSteamShortcutEntryStartDir() {
	SHORTCUTVDFSTARTDIRHEXPAT="0001537461727444697200"
	parseSteamShortcutEntryHex "$1" "${SHORTCUTVDFSTARTDIRHEXPAT}" | tr -d '"'
}

parseSteamShortcutEntryIcon() {
	SHORTCUTVDFICONHEXPAT="000169636f6e00"
	parseSteamShortcutEntryHex "$1" "${SHORTCUTVDFICONHEXPAT}"
}

parseSteamShortcutEntryLaunchOptions() {
	SHORTCUTVDFARGHEXPAT="00014c61756e63684f7074696f6e7300" # echo "0001$(convertStringToSteamShortcutHex "LaunchOptions")"
	parseSteamShortcutEntryHex "$1" "${SHORTCUTVDFARGHEXPAT}" | tr '\002' '\n' | head -n 1 | tr -d '\000'
}

parseSteamTargetExe() {
	if [[ "$1" =~ .sh$ ]]; then
		grep -E '^[^# ]*?(flatpak|start\.sh)' "$1" | head -n 1 | sed 's/ "\$@"//' | awk -F'"' '{print $(NF-1)}'
	fi
}

restartSteam() {
	if [[ "${PW_SKIP_RESTART_STEAM}" != 1 ]] && pgrep -i steam &>/dev/null ; then
		if yad_question "${translations[For adding shortcut to STEAM, needed restart.\\n\\nRestart STEAM now?]}" ; then
			pw_start_progress_bar_block "${translations[Restarting STEAM... Please wait.]}"
			kill -s SIGTERM $(pgrep -a steam) &>/dev/null
			while pgrep -i steam &>/dev/null ; do
				sleep 0.5
			done
			if command -v steam &>/dev/null; then
				steam &
			elif command -v flatpak >/dev/null 2>&1 && flatpak list | grep -q com.valvesoftware.Steam; then
				flatpak run com.valvesoftware.Steam &
			fi
			sleep 5
			pw_stop_progress_bar
			exit 0
		fi
	fi
	unset PW_SKIP_RESTART_STEAM
}

downloadImage() {
	if ! curl -Lf# --connect-timeout 5 -m 10 -o "${STCFGPATH}/grid/$2" "$1"; then
		return 1
	fi
}

downloadImageSteam() {
	if [[ -n "${SteamAppId}" ]]; then
		downloadImage "https://cdn.cloudflare.steamstatic.com/steam/apps/${SteamAppId}/$1" "$2"
	else
		return 1
	fi
}

downloadImageSteamGridDB() {
	if [[ -n "${SteamGridDBId}" ]]; then
		SGDBIMGAPI="${BASESTEAMGRIDDBAPI}/$1/game/${SteamGridDBId}?limit=1"
		[[ -n "$3" ]] && SGDBIMGAPI+="&$3"
		[[ -n "$4" ]] && SGDBIMGAPI+="&$4"
		SGDBIMGRES=$(curl -Ls --connect-timeout 5 -m 10 -H "Authorization: Bearer ${SGDBAPIKEY}" "${SGDBIMGAPI}")
		if jq -e ".success == true and (.data | length > 0)" <<< "${SGDBIMGRES}" > /dev/null 2>&1; then
			SGDBIMGURL=$(jq -r '.data[0].url' <<< "${SGDBIMGRES}")
			downloadImage "${SGDBIMGURL}" "$2"
		elif [[ -n "$3" ]]; then
			downloadImageSteamGridDB "$1" "$2" "" "$4"
		else
			return 1
		fi
	else
		return 1
	fi
}

addGrids() {
	local AppId="${NOSTAPPID:-0}"
	local in=("header.jpg" "library_600x900_2x.jpg" "library_hero.jpg" "logo.png")
	local out=("${AppId}.jpg" "${AppId}"p".jpg" "${AppId}"_hero".jpg" "${AppId}"_logo".png")
	local gtype=("grids" "grids" "heroes" "logos")
	local mimes=("image/jpeg" "image/jpeg" "image/jpeg" "image/png")
	local dims=("460x215,920x430" "600x900,660x930" "" "")
	if [[ -z "${SteamGridDBId}" ]] && [[ -z "${SteamAppId}" ]]; then
		getSteamId > /dev/null
	fi
	if [[ -n "${SteamGridDBId}" ]] || [[ -n "${SteamAppId}" ]]; then
		create_new_dir "${STCFGPATH}/grid"
		for i in "${!in[@]}"; do
			downloadImageSteam "${in[${i}]}" "${out[${i}]}" || \
				downloadImageSteamGridDB "${gtype[${i}]}" "${out[${i}]}" ${mimes[${i}]:+"mimes=${mimes[${i}]}"} ${dims[${i}]:+"dimensions=${dims[${i}]}"} || \
				echo "Failed to load ${in[${i}]}"
		done
	else
		echo "Game is not found"
	fi
}

addEntry() {
	if [[ -n "${SCPATH}" ]]; then
		if [[ -f "${SCPATH}" ]] ; then
			truncate -s-2 "${SCPATH}"
			OLDSET="$(grep -aPo '\x00[0-9]\x00\x02appid' "${SCPATH}" | tail -n1 | tr -dc '0-9')"
			NEWSET=$((OLDSET + 1))
		else
			printf '\x00%s\x00' "shortcuts" > "${SCPATH}"
			NEWSET=0
		fi
		NOSTAIDVDFHEXFMT=$(printf '\\x%02x\\x%02x\\x%02x\\x%02x' \
			$((${NOSTAPPID} & 0xFF)) \
			$(((${NOSTAPPID} >> 8) & 0xFF)) \
			$(((${NOSTAPPID} >> 16) & 0xFF)) \
			$(((${NOSTAPPID} >> 24) & 0xFF)))
		{
			printf '\x00%s\x00' "${NEWSET}"
			printf '\x02%s\x00%b' "appid" "${NOSTAIDVDFHEXFMT}"
			printf '\x01%s\x00%s\x00' "AppName" "${NOSTAPPNAME}"
			printf '\x01%s\x00%s\x00' "Exe" "\"${NOSTEXEPATH}\""
			printf '\x01%s\x00%s\x00' "StartDir" "\"${NOSTSTDIR}\""
			printf '\x01%s\x00%s\x00' "icon" "${NOSTICONPATH}"
			printf '\x01%s\x00%s\x00' "ShortcutPath" ""
			printf '\x01%s\x00%s\x00' "LaunchOptions" "${NOSTARGS:-}"
			printf '\x02%s\x00\x00\x00\x00\x00' "IsHidden"
			printf '\x02%s\x00\x01\x00\x00\x00' "AllowDesktopConfig"
			printf '\x02%s\x00\x01\x00\x00\x00' "AllowOverlay"
			printf '\x02%s\x00\x00\x00\x00\x00' "OpenVR"
			printf '\x02%s\x00\x00\x00\x00\x00' "Devkit"
			printf '\x01%s\x00\x00' "DevkitGameID"
			printf '\x02%s\x00\x00\x00\x00\x00' "DevkitOverrideAppID"
			printf '\x02%s\x00\x00\x00\x00\x00' "LastPlayTime"
			printf '\x01%s\x00\x00' "FlatpakAppID"
			printf '\x00%s\x00' "tags"
			printf '\x08\x08\x08\x08'
		} >> "${SCPATH}"
	fi
}

removeNonSteamGame() {
	[[ -n "$1" ]] && appid="$1"
	[[ -n "$2" ]] && NOSTSHPATH="$2"
	[[ -z "${STUID}" ]] && STUID=$(getUserId)
	[[ -z "${STCFGPATH}" ]] && STCFGPATH="$(getUserPath ${STUID})"
	[[ -z "${STEAM_BASE_FOLDER}" ]] && STEAM_BASE_FOLDER="$(getSteamPath)"
	if [[ -n "${STCFGPATH}" ]] && [[ -z "${SCPATH}" ]]; then
		SCPATH="${STCFGPATH}/shortcuts.vdf"
	fi
	if [[ -n "${appid}" ]]; then
		games=$(listNonSteamGames)
		[[ -z "${NOSTSHPATH}" ]] && NOSTSHPATH=$(jq -r --arg id "${appid}" 'map(select(.id == $id)) | first(.[].exe)' <<< "${games}")
		if [[ -n "${NOSTSHPATH}" ]]; then
			mv "${SCPATH}" "${SCPATH//.vdf}_${PROGNAME}_backup.vdf" 2>/dev/null
			jq --arg id "${appid}" 'map(select(.id != $id))' <<< "${games}" | jq -c '.[]' | while read -r game; do
				NOSTAPPID=$(jq -r '.id' <<< "${game}")
				NOSTAPPNAME=$(jq -r '.name' <<< "${game}")
				NOSTEXEPATH=$(jq -r '.exe' <<< "${game}")
				NOSTSTDIR=$(jq -r '.dir' <<< "${game}")
				NOSTICONPATH=$(jq -r '.icon' <<< "${game}")
				NOSTARGS=$(jq -r '.args' <<< "${game}")
				addEntry
			done
			rm -f "${STCFGPATH}/grid/${appid}.jpg" "${STCFGPATH}/grid/${appid}p.jpg" "${STCFGPATH}/grid/${appid}_hero.jpg" "${STCFGPATH}/grid/${appid}_logo.png"
			rm -rf "${STEAM_BASE_FOLDER}/steamapps/compatdata/${appid}"
			rm -rf "${STEAM_BASE_FOLDER}/steamapps/shadercache/${appid}"
			if [[ -f "${NOSTSHPATH}" ]]; then
				isInstallGame=false
				for STUIDCUR in $(getUserIds); do
					[[ "${STUIDCUR}" == "${STUID}" ]] && continue
					STCFGPATH="$(getUserPath ${STUIDCUR})"
					SCPATH="${STCFGPATH}/shortcuts.vdf"
					if [[ -n "$(getAppId "${NOSTSHPATH}")" ]]; then
						isInstallGame=true
						break
					fi
				done
				unset STCFGPATH SCPATH
				if [[ ${isInstallGame} == false ]]; then
					rm "${NOSTSHPATH}"
				fi
			fi
			restartSteam
		fi
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
		[[ -z "${NOSTSHPATH}" ]] && NOSTSHPATH="${STEAM_SCRIPTS}/${name_desktop}.sh"
		NOSTAPPNAME="${name_desktop}"
		NOSTAPPPATH="${portwine_exe}"
		NOSTAPPID=$(getAppId "${NOSTSHPATH}")
		if [[ ! -f "${NOSTSHPATH}" ]]; then
			create_new_dir "${STEAM_SCRIPTS}"
			cat <<-EOF > "${NOSTSHPATH}"
				#!/usr/bin/env bash
				export LD_PRELOAD=
				export START_FROM_STEAM=1
				export START_FROM_FLATPAK=$(check_flatpak && echo 1 || echo 0)
				"${PORT_SCRIPTS_PATH}/start.sh" "${NOSTAPPPATH}" "\$@"
			EOF
			chmod u+x "${NOSTSHPATH}"
		fi
		if [[ -z "${NOSTAPPID}" ]]; then
			[[ -z "${NOSTSTDIR}" ]] && NOSTSTDIR="${STEAM_SCRIPTS}"
			NOSTEXEPATH="${NOSTSHPATH}"
			NOSTICONPATH="${PORT_WINE_PATH}/data/img/${name_desktop_png}.png"
			NOSTAIDVDF="$(generateShortcutVDFAppId "${NOSTAPPNAME}${NOSTEXEPATH}")"  # signed integer AppID, stored in the VDF as hexidecimal - ex: -598031679
			NOSTAPPID="$(extractSteamId32 "${NOSTAIDVDF}")"  # unsigned 32bit ingeger version of "$NOSTAIDVDF", which is used as the AppID for Steam artwork ("grids"), as well as for our shortcuts

			if [[ -f "${SCPATH}" ]] ; then
				cp "${SCPATH}" "${SCPATH//.vdf}_${PROGNAME}_backup.vdf" 2>/dev/null
			fi

			if [[ "${USE_STEAMAPPID_AS_NAME:-0}" == "1" ]]; then
				getSteamId > /dev/null
				[[ -n "${SteamAppId}" ]] && NOSTAPPNAME="${SteamAppId}"
			fi

			addEntry

			if [[ "${DOWNLOAD_STEAM_GRID}" == "1" ]] ; then
				NOSTAPPNAME="${name_desktop}"
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
