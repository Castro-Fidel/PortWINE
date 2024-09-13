#!/bin/bash
# GPL-3.0 license
# based on https://github.com/sonic2kk/steamtinkerlaunch/blob/master/steamtinkerlaunch
PROGNAME="PortProton"
name_desktop_png="${name_desktop// /_}"
NOSTAPPNAME="$name_desktop"
NOSTEXEPATH="\"${STEAM_SCRIPTS}/${name_desktop}.sh\""
# NOSTSTDIR="\"${PATH_TO_GAME}\""
if [[ -z "${NOSTSTDIR}" ]] ; then
	NOSTSTDIR="\"${STEAM_SCRIPTS}\""
fi
NOSTICONPATH="${PORT_WINE_PATH}/data/img/$name_desktop_png.png"
BASESTEAMGRIDDBAPI="https://www.steamgriddb.com/api/v2"

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

NOSTAIDVDF="$(generateShortcutVDFAppId "${NOSTAPPNAME}${NOSTEXEPATH}" )"  # signed integer AppID, stored in the VDF as hexidecimal - ex: -598031679
NOSTAIDVDFHEX="$( generateShortcutVDFHexAppId "$NOSTAIDVDF" )"  # 4byte little-endian hexidecimal of above 32bit signed integer, which we write out to the binary VDF - ex: c1c25adc
NOSTAIDVDFHEXFMT="\x$(awk '{$1=$1}1' FPAT='.{2}' OFS="\\\x" <<< "$NOSTAIDVDFHEX")"  # binary-formatted string hex of the above which we actually write out - ex: \xc1\xc2\x5a\xdc
NOSTAIDGRID="$( generateShortcutGridAppId "$NOSTAIDVDF" )"  # unsigned 32bit ingeger version of "$NOSTAIDVDF", which is used as the AppID for Steam artwork ("grids"), as well as for our shortcuts

# Set artwork for Steam game by copying/linking/moving passed artwork to steam grid folder
function setGameArt {
	function applyGameArt {
		GAMEARTAPPID="$1"
		GAMEARTSOURCE="$2"  # e.g. /home/gaben/GamesArt/cs2_hero.png
		GAMEARTSUFFIX="$3"  # e.g. "_hero" etc
		GAMEARTCMD="$4"

		GAMEARTBASE="$( basename "$GAMEARTSOURCE" )"
		GAMEARTDEST="${SGGRIDDIR}/${GAMEARTAPPID}${GAMEARTSUFFIX}.${GAMEARTBASE#*.}"  # path to filename in grid e.g. turns "/home/gaben/GamesArt/cs2_hero.png" into "~/.local/share/Steam/userdata/1234567/config/grid/4440654_hero.png"

		if [[ -n "$GAMEARTSOURCE" ]] ; then
			if [[ -f "$GAMEARTDEST" ]] ; then
				rm "$GAMEARTDEST"
			fi

			if [[ -f "$GAMEARTSOURCE" ]] ; then
				$GAMEARTCMD "$GAMEARTSOURCE" "$GAMEARTDEST"
			fi
		fi
	}

	GAME_APPID="$1"  # We don't validate AppID as it would drastically slow down the process for large libraries

	SETARTCMD="cp"  # Default command will copy art
	for i in "$@"; do
		case $i in
			-hr=*|--hero=*)
				SGHERO="${i#*=}"  # <appid>_hero.png -- Banner used on game screen, logo goes on top of this
				shift ;;
			-lg=*|--logo=*)
				SGLOGO="${i#*=}"  # <appid>_logo.png -- Logo used e.g. on game screen
				shift ;;
			-ba=*|--boxart=*)
				SGBOXART="${i#*=}"  # <appid>p.png -- Used in library
				shift ;;
			-tf=*|--tenfoot=*)
				SGTENFOOT="${i#*=}"  # <appid>.png -- Used as small boxart for e.g. most recently played banner
				shift ;;
			--copy)
				SETARTCMD="cp"  # Copy file to grid folder -- Default
				shift ;;
			--link)
				SETARTCMD="ln -s"  # Symlink file to grid folder
				shift ;;
			--move)
				SETARTCMD="mv"  # Move file to grid folder
				shift ;;
		esac
	done

	applyGameArt "$GAME_APPID" "$SGHERO" "_hero" "$SETARTCMD"
	applyGameArt "$GAME_APPID" "$SGLOGO" "_logo" "$SETARTCMD"
	applyGameArt "$GAME_APPID" "$SGBOXART" "p" "$SETARTCMD"
	applyGameArt "$GAME_APPID" "$SGTENFOOT" "" "$SETARTCMD"
}

# This is formatted as a flag because we can pass "$SGACOPYMETHOD" as an argument to setGameArt, and it will be interpreted as --copy
SGACOPYMETHOD="${SGACOPYMETHOD:---copy}"

## Generic function to fetch some artwork from SteamGridDB based on an endpoint
## TODO: Steam only officially supports PNGs, test to see if WebP works when manually copied, and if it doesn't, we should try to only download PNG files
## TODO: Add max filesize option? Some artworks are really big, we should skip ones that are too large (though this may mean many animated APNG artworks will get skipped, because APNG can be huge)
function downloadArtFromSteamGridDB {
    # Required parameters
    SEARCHID="$1"
    SEARCHENDPOINT="$2"
    SGDBFILENAME="${3:-SEARCHID}"

    # Optional parameters
    SEARCHSTYLES="$4"
    SEARCHDIMS="$5"
    SEARCHTYPES="$6"
    SEARCHNSFW="$7"
    SEARCHHUMOR="$8"
    SEARCHEPILEPSY="$9"

    SGDBHASFILE="${10:-SGDBHASFILE}"
    FORCESGDBDLTOSTEAM="${11}"

    SGDB_ENDPOINT_STR="${SEARCHENDPOINT}/$(echo "$SEARCHID" | awk '{print $1}' | paste -s -d, -)?"

    [[ -n "$SEARCHSTYLES" ]] && SGDB_ENDPOINT_STR+="&styles=${SEARCHSTYLES}"
    [[ -n "$SEARCHDIMS" ]] && SGDB_ENDPOINT_STR+="&dimensions=${SEARCHDIMS}"
    [[ -n "$SEARCHTYPES" ]] && SGDB_ENDPOINT_STR+="&types=${SEARCHTYPES}"
    [[ -n "$SEARCHNSFW" ]] && SGDB_ENDPOINT_STR+="&nsfw=${SEARCHNSFW}"
    [[ -n "$SEARCHHUMOR" ]] && SGDB_ENDPOINT_STR+="&humor=${SEARCHHUMOR}"
    [[ -n "$SEARCHEPILEPSY" ]] && SGDB_ENDPOINT_STR+="&epilepsy=${SEARCHEPILEPSY}"

    set -o pipefail
    RESPONSE=$(curl -H "Authorization: Bearer $SGDBAPIKEY" -s "$SGDB_ENDPOINT_STR" 2> >(grep -v "SSL_INIT"))
    if [[ "${PIPESTATUS[0]}" != 0 ]] && [[ "$DOWNLOAD_STEAM_GRID" != 0 ]] ; then
		pw_notify_send -i info \
		"$(gettext "SteamGridDB is not response, force disable cover download")"
		sed -i 's/DOWNLOAD_STEAM_GRID=.*/DOWNLOAD_STEAM_GRID="0"/' "$USER_CONF"
		export DOWNLOAD_STEAM_GRID="0"
		return
    fi


    if ! jq -e '.success' <<< "$RESPONSE" > /dev/null; then
        echo "The server response wasn't 'success' for this batch of requested games."
        return
    fi

    RESPONSE_LENGTH=$(jq '.data | length' <<< "$RESPONSE")

    if [[ "$RESPONSE_LENGTH" == "0" ]] ; then
        echo "No grid found to download - maybe loosen filters?"
    fi

    if jq -e ".data[0].url" <<< "$RESPONSE" > /dev/null; then
        RESPONSE="{\"success\":true,\"data\":[$RESPONSE]}"
        RESPONSE_LENGTH=1
    fi

    for i in $(seq 0 $(("$RESPONSE_LENGTH" - 1))); do
        if ! jq -e ".data[$i].success" <<< "$RESPONSE" > /dev/null; then
            echo "The server response for '$SEARCHID' wasn't 'success'"
        fi
        if ! URLSTR=$(jq -e -r ".data[$i].data[0].url" <<< "$RESPONSE"); then
            echo "No grid found to download for '$SEARCHID' - maybe loosen filters?"
        fi

        GRIDDLURL="${URLSTR//\"}"
        if grep -q "^https" <<< "$GRIDDLURL"; then
            DLSRC="${GRIDDLURL//\"}"
            GRIDDLDIR="${SGGRIDDIR}"
            mkdir -p "$GRIDDLDIR"
            DLDST="${GRIDDLDIR}/${SGDBFILENAME}.${GRIDDLURL##*.}"
            STARTDL=1

            if [[ -f "$DLDST" ]] ; then
                if [[ "$SGDBHASFILE" == "backup" ]] ; then
                    BACKDIR="${GRIDDLDIR}/backup"
                    mkdir -p "$BACKDIR"
                    mv "$DLDST" "$BACKDIR"
                elif [[ "$SGDBHASFILE" == "replace" ]] ; then
                    rm "$DLDST" 2>/dev/null
                fi
            fi

            if [[ "$STARTDL" -eq 1 ]] ; then
				filename="$(basename "$DLDST")"
                curl -f -# -A 'Mozilla/5.0 (compatible; Konqueror/2.1.1; X11)' -H 'Cache-Control: no-cache, no-store' -H 'Pragma: no-cache' -L "$DLSRC" -o "$DLDST" 2>&1 | \
                 tr '\r' '\n' | sed -ur 's|[# ]+||g;s|.*=.*||g;s|.*|#Downloading at &\n&|g' | \
				"$pw_yad" --progress --text="$(gettext "Downloading") $filename" --auto-close --no-escape \
				--auto-kill --text-align="center" --fixed --no-buttons --title "PortProton" --width=500 --height=90 \
				--window-icon="$PW_GUI_ICON_PATH/portproton.svg" --borders="$PROGRESS_BAR_BORDERS_SIZE"
            fi
        else
            echo "No grid found to download for '$SEARCHID' - maybe loosen filters?"
        fi
    done
}

if [[ -f "$SCPATH" ]] ; then
	cp "$SCPATH" "${SCPATH//.vdf}_${PROGNAME}_backup.vdf" 2>/dev/null
	truncate -s-2 "$SCPATH"
	OLDSET="$(grep -aPo '\x00[0-9]\x00\x02appid' "$SCPATH" | tail -n1 | tr -dc '0-9')"
	NEWSET=$((OLDSET + 1))
else
	printf '\x00%s\x00' "shortcuts" > "$SCPATH"
	NEWSET=0
fi

# Search SteamGridDB endpoint using game title and return the first (best match) Game ID
function getSGDBGameIDFromTitle {
	SGDBSEARCHNAME="$1"

	if [[ -n "$SGDBSEARCHNAME" ]] ; then
		SGDBSEARCHENDPOINT="${BASESTEAMGRIDDBAPI}/search/autocomplete/${SGDBSEARCHNAME}"
		SGDBSEARCHNAMERESP="$(curl -H "Authorization: Bearer $SGDBAPIKEY" -s "$SGDBSEARCHENDPOINT" 2>  >(grep -v "SSL_INIT") )"
		if jq -e '.success' 1> /dev/null <<< "$SGDBSEARCHNAMERESP"; then
			if [[ "$(jq '.data | length' <<< "$SGDBSEARCHNAMERESP" )" -gt 0 ]] ; then
				SGDBSEARCH_FOUNDNAME="$(jq '.data[0].name' <<< "$SGDBSEARCHNAMERESP" )"
				SGDBSEARCH_FOUNDGAID="$(jq '.data[0].id' <<< "$SGDBSEARCHNAMERESP" )"

				echo "$SGDBSEARCH_FOUNDGAID"
			fi
		fi
	else
		echo "No game name given."
	fi
}

# Used to get either Steam or Non-Steam artwork depending on a flag -- Used internally and for commandline usage
function commandlineGetSteamGridDBArtwork {
	GSGDBA_HASFILE="$SGDBHASFILE"  # Optional override for how to handle existinf file (downloadArtFromSteamGridDB defaults to '$SGDBHASFILE')
	GSGDBA_APPLYARTWORK="$SGDBDLTOSTEAM"
	GSGDBA_SEARCHNAME=""
	GSGDBA_FOUNDGAMEID=""  # ID found from SteamGridDB endpoint using GSGDBA_SEARCHNAME
	for i in "${@}"; do
		case $i in
			--search-name=*)
				GSGDBA_SEARCHNAME="${i#*=}"  # Optional SteamGridDB Game Name -- Will use this to try and find matching SteamGridDB Game Art
				shift ;;
			--nonsteam)
				SGDBENDPOINTTYPE="game"
				shift ;;
			--filename-appid=*)
				GSGDBA_FILENAME="${i#*=}"  # AppID to use in filename (Non-Steam Games need a different AppID)
				shift ;;
			## Override Global Menu setting for how to handle existing artwork
			## in case user wants to replace all existing artwork, default STL setting is 'skip' and will only copy files over to grid dir if they don't exist, so user can easily fill in missing artwork only)
			--replace-existing)
				GSGDBA_HASFILE="replace"
				shift ;;
			--backup-existing)
				GSGDBA_HASFILE="backup"
				shift ;;
			## Flag to force downloading to SteamGridDB folder (used for addNonSteamGame internally)
			--apply)
				GSGDBA_APPLYARTWORK="1"
				shift ;;
		esac
	done

	# If we pass a name to search on and we get a Game ID back from SteamGridDB, set this as the ID to search for artwork on
	if [[ -n "$GSGDBA_SEARCHNAME" ]] ; then
		if [[ -n "$GSGDBA_FILENAME" ]] ; then
			GSGDBA_FOUNDGAMEID="$( getSGDBGameIDFromTitle "$GSGDBA_SEARCHNAME" )"
			if [[ -n "$GSGDBA_FOUNDGAMEID" ]] ; then
				GSGDBA_APPID="$GSGDBA_FOUNDGAMEID"
				SGDBENDPOINTTYPE="game"
			fi
		else
			echo "You must provide a filename AppID when searching with SteamGridDB Game Name"
		fi
	fi

	SGDBSEARCHENDPOINT_HERO="${BASESTEAMGRIDDBAPI}/heroes/${SGDBENDPOINTTYPE}"
	SGDBSEARCHENDPOINT_LOGO="${BASESTEAMGRIDDBAPI}/logos/${SGDBENDPOINTTYPE}"
	SGDBSEARCHENDPOINT_BOXART="${BASESTEAMGRIDDBAPI}/grids/${SGDBENDPOINTTYPE}"	 # Grid endpoint is used for Boxart and Tenfoot, which SteamGridDB counts as vertical/horizontal grids respectively


	# Download Hero, Logo, Boxart, Tenfoot from SteamGridDB from given endpoint using given AppID
	# On SteamGridDB tenfoot called horizontal Steam grid, so fetch it by passing specific dimensions matching this -- Users can override this, but default is what SteamGridDB expects for the tenfoot sizes
	downloadArtFromSteamGridDB "$GSGDBA_APPID" "$SGDBSEARCHENDPOINT_HERO" "${GSGDBA_FILENAME}_hero" "$SGDBHEROSTYLES" "$SGDBHERODIMS" "$SGDBHEROTYPES" "$SGDBHERONSFW" "$SGDBHEROHUMOR" "$SGDBHEROEPILEPSY" "$GSGDBA_HASFILE" "$GSGDBA_APPLYARTWORK"
	# Logo doesn't have dimensions, so it's left intentionally blank
	downloadArtFromSteamGridDB "$GSGDBA_APPID" "$SGDBSEARCHENDPOINT_LOGO" "${GSGDBA_FILENAME}_logo" "$SGDBLOGOSTYLES" "" "$SGDBLOGOTYPES" "$SGDBLOGONSFW" "$SGDBLOGOHUMOR" "$SGDBLOGOEPILEPSY" "$GSGDBA_HASFILE" "$GSGDBA_APPLYARTWORK"
	downloadArtFromSteamGridDB "$GSGDBA_APPID" "$SGDBSEARCHENDPOINT_BOXART" "${GSGDBA_FILENAME}p" "$SGDBBOXARTSTYLES" "$SGDBBOXARTDIMS" "$SGDBBOXARTTYPES" "$SGDBBOXARTNSFW" "$SGDBBOXARTHUMOR" "$SGDBBOXARTEPILEPSY" "$GSGDBA_HASFILE" "$GSGDBA_APPLYARTWORK"
	downloadArtFromSteamGridDB "$GSGDBA_APPID" "$SGDBSEARCHENDPOINT_BOXART" "${GSGDBA_FILENAME}" "$SGDBTENFOOTSTYLES" "$SGDBTENFOOTDIMS" "$SGDBTENFOOTTYPES" "$SGDBTENFOOTNSFW" "$SGDBTENFOOTHUMOR" "$SGDBTENFOOTEPILEPSY" "$GSGDBA_HASFILE" "$GSGDBA_APPLYARTWORK"
}

## Fetch artwork from SteamGridDB
# Regular artwork
# The entered search name is prioritised over actual game EXE name, only one will be used and we will always prefer custom name
# Ex: user names Non-Steam Game "The Elder Scrolls IV: Oblivion" but they enter a custom search name because they want artwork for "The Elder Scrolls IV: Oblivion Game of the Year Edition"
# In case art is not found for the custom name, users should enter either the Steam AppID or the SteamGridDB Game ID to use as a fallback (Steam AppID will always be preferred because it will always be exact)
#
# Therefore, the order of priority for artwork searching is:
# 1. Name search (only ONE of the below will be used)
#     a. If the user enters a custom search name with --steamgriddb-game-name, search on that
#     b. Otherwise, use the Non-Steam Game name
# 2. Fallback to ID search if no SteamGridDB ID is found on the name search
#    a. If the user enters a Steam AppID with --steamgriddb-steam-appid, search on that
#    b. Otherwise, fall back to searching on an entered SteamGridDB Game ID
# In short, search on ONE of the names, and if a Game ID is not found on either of these, fall back to searching on ONE of the passed IDs
# If no IDs are found after all of this, we can't get artwork. We will not fall back to EXE name if no ID is found on custom name, and we will not fall back to SteamGridDB Game ID if no art is found for Steam AppID
# If no values are provided we will simply search on Non-Steam Game name
NOSTSEARCHNAME=""  # Name to search for SteamGridDB Game ID on (either custom name or app name)
NOSTSEARCHID=""  # ID to search for the SteamGridDB artwork on (either Steam AppID or SteamGridDB Game ID)
NOSTSEARCHFLAG="--nonsteam"  # Whether to search using a Steam AppID or SteamGridDB Game ID (will be set to --steam if we get an AppID)

# Only add NOSTAPPNAME as fallback if we don't have an ID to search on, because commandlineGetSteamGridDBArtwork will prefer name over ID, so if we have to fall back to Non-Steam Name (i.e. no entered custom name) then only do so if we don't have an ID given
if [[ -n "$NOSTAPPNAME" ]] ; then
	NOSTSEARCHNAME="$NOSTAPPNAME"
	NOSTSEARCHNAME="${NOSTSEARCHNAME// /_}"
fi

# Store the ID we searched with, so getSteamGridDBNonSteamIcon doesn't have to hit the endpoint again and we save an API call
if [[ "$DOWNLOAD_STEAM_GRID" == "1" ]] ; then
	commandlineGetSteamGridDBArtwork --search-name="$NOSTSEARCHNAME" --filename-appid="$NOSTAIDGRID" "$NOSTSEARCHFLAG" --apply --replace-existing
fi
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

if [[ "$DOWNLOAD_STEAM_GRID" == "1" ]] ; then
	setGameArt "$NOSTAIDGRID" --hero="$NOSTGHERO" --logo="$NOSTGLOGO" --boxart="$NOSTGBOXART" --tenfoot="$NOSTGTENFOOT" "$SGACOPYMETHOD"
fi
