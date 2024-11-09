#!/bin/bash
# AppName= AppId= SteamAppId= SteamGridDBId= SGGRIDDIR= ./get_images.sh

if [[ -z "${SGDBAPIKEY}" || -z "${BASESTEAMGRIDDBAPI}" ]]; then
	source "${PORT_SCRIPTS_PATH:-$(dirname "${BASH_SOURCE[0]}")}/var"
fi

downloadImage() {
	local path="${SGGRIDDIR:-${PWD}}"
	local url="$1"
	local files=("$2")
	local cur='';
	if [[ -n "${url}" && -n "${files}" ]]; then
		for file in ${files[@]}; do
			if [[ -z "$cur" ]]; then
				if ! curl -Lf# -o "${path}/${file}" "${url}"; then
					return 1
				fi
			else
				cp "${path}/${cur}" "${path}/${file}"
			fi
			cur="${file}"
		done
	fi
}

downloadImageSteam() {
	if [[ -n "${SteamAppId}" ]]; then
		downloadImage "https://cdn.cloudflare.steamstatic.com/steam/apps/$1" "$2"
	else
		return 1
	fi
}

downloadImageSteamGridDB() {
	if [[ -n "${SteamGridDBId}" && -n "${SGDBAPIKEY}" ]]; then
		SGDBIMGAPI="${BASESTEAMGRIDDBAPI}/$1?limit=1"
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
	else
		return 1
	fi
}

getSteamId() {
	SRES=$(curl -Ls -e "https://www.steamgriddb.com/game/${SteamGridDBId}" "https://www.steamgriddb.com/api/public/game/${SteamGridDBId}")
	if jq -e ".success == true" <<< "${SRES}" > /dev/null 2>&1; then
		export SteamAppId="$(jq -r '.data.platforms.steam.id' <<< "${SRES}")"
	fi
}

getSteamGridDBId() {
	SGDBRES=$(curl -Ls -H "Authorization: Bearer ${SGDBAPIKEY}" "${BASESTEAMGRIDDBAPI}/search/autocomplete/${AppName// /_}")
	if jq -e ".success == true and (.data | length > 0)" <<< "${SGDBRES}" > /dev/null 2>&1; then
		export SteamGridDBId="$(jq '.data[0].id' <<< "${SGDBRES}")"
		if jq -e '.data[0].types | contains(["steam"])' <<< "${SGDBRES}" > /dev/null; then
			getSteamId
		fi
	fi
}

if [[ -z "${SteamAppId}" && -z "${SteamGridDBId}" && -n "${AppName}" && -n "${SGDBAPIKEY}" ]]; then
	getSteamGridDBId
fi

if [[ -n "${SteamAppId}" ]] || [[ -n "${SteamGridDBId}" && -n "${SGDBAPIKEY}" ]]; then
	downloadImageSteam "${SteamAppId}/header.jpg" "${AppId:-0}.jpg" || downloadImageSteamGridDB "grids/game/${SteamGridDBId}" "${AppId:-0}.jpg" "mimes=image/jpeg" "dimensions=460x215,920x430" || echo "Failed to load header.jpg"
	downloadImageSteam "${SteamAppId}/library_600x900_2x.jpg" "${AppId:-0}p.jpg" || downloadImageSteamGridDB "grids/game/${SteamGridDBId}" "${AppId:-0}p.jpg" "mimes=image/jpeg" "dimensions=600x900,660x930" || echo "Failed to load library_600x900_2x.jpg"
	downloadImageSteam "${SteamAppId}/library_hero.jpg" "${AppId:-0}_hero.jpg" || downloadImageSteamGridDB "heroes/game/${SteamGridDBId}" "${AppId:-0}_hero.jpg" "mimes=image/jpeg" || echo "Failed to load library_hero.jpg"
	downloadImageSteam "${SteamAppId}/logo.png" "${AppId:-0}_logo.png" || downloadImageSteamGridDB "logos/game/${SteamGridDBId}" "${AppId:-0}_logo.png" "mimes=image/png" || echo "Failed to load logo.png"
else
	echo "Game is not found"
fi
