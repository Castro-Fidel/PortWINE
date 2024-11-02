#!/bin/bash
# AppName= AppId= SteamAppId= SteamGridDBId= SGGRIDDIR= ./get_images.sh

if [[ -z "${SGDBAPIKEY}" || -z "${BASESTEAMGRIDDBAPI}" ]]; then
	source "${PORT_SCRIPTS_PATH:-$(dirname "$(readlink --canonicalize-existing "$0")")}/var"
fi

function downloadImage {
	local path="${SGGRIDDIR:-${PWD}}"
	local url="$1"
	local files="$2"
	local cur='';
	if [[ -n "${url}" && -n "${files}" ]]; then
		for file in ${files[@]}; do
			if [[ -z "$cur" ]]; then
				curl -Lf# -o "${path}/${file}" "${url}"
			else
				cp "${path}/${cur}" "${path}/${file}"
			fi
			cur="${file}"
		done
	fi
}

function downloadImageSteam {
	downloadImage "https://cdn.cloudflare.steamstatic.com/steam/apps/$1" "$2"
}

function downloadImageSteamgriddb {
	SGDBIMGRES=$(curl -Ls -H "Authorization: Bearer ${SGDBAPIKEY}" "${BASESTEAMGRIDDBAPI}/$1&limit=1")
	if jq -e ".success == true and (.data | length > 0)" <<< "${SGDBIMGRES}" > /dev/null 2>&1; then
		SGDBIMGURL=$(jq -r '.data[0].url' <<< "${SGDBIMGRES}")
		downloadImage "${SGDBIMGURL}" "$2"
	fi
}

if [[ -z "${SteamAppId}" && -z "${SteamGridDBId}" && -n "${AppName}" && -n "${SGDBAPIKEY}" ]]; then
	SGDBRES=$(curl -Ls -H "Authorization: Bearer ${SGDBAPIKEY}" "${BASESTEAMGRIDDBAPI}/search/autocomplete/${AppName// /_}")
	if jq -e ".success == true and (.data | length > 0)" <<< "${SGDBRES}" > /dev/null 2>&1; then
		export SteamGridDBId="$(jq '.data[0].id' <<< "${SGDBRES}")"
		if jq -e '.data[0].types | contains(["steam"])' <<< "${SGDBRES}" > /dev/null; then
			SRES=$(curl -Ls -e "https://www.steamgriddb.com/game/${SteamGridDBId}" "https://www.steamgriddb.com/api/public/game/${SteamGridDBId}")
			if jq -e ".success == true" <<< "${SRES}" > /dev/null 2>&1; then
				export SteamAppId="$(jq -r '.data.platforms.steam.id' <<< "${SRES}")"
			fi
		fi
	fi
fi

if [[ -n "${SteamAppId}" ]]; then
	downloadImageSteam "${SteamAppId}/header.jpg" "${AppId:-0}.jpg"
	downloadImageSteam "${SteamAppId}/library_600x900_2x.jpg" "${AppId:-0}p.jpg"
	downloadImageSteam "${SteamAppId}/library_hero.jpg" "${AppId:-0}_hero.jpg"
	downloadImageSteam "${SteamAppId}/logo.png" "${AppId:-0}_logo.png"
elif [[ -n "${SteamGridDBId}" && -n "${SGDBAPIKEY}" ]]; then
	downloadImageSteamgriddb "grids/game/${SteamGridDBId}?mimes=image/jpeg" "${AppId:-0}.jpg ${AppId:-0}p.jpg"
	downloadImageSteamgriddb "heroes/game/${SteamGridDBId}?mimes=image/jpeg" "${AppId:-0}_hero.jpg"
	downloadImageSteamgriddb "logos/game/${SteamGridDBId}?mimes=image/png" "${AppId:-0}_logo.png"
else
	echo "Game is not found"
fi
