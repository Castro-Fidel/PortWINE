#!/bin/bash
# GPL-3.0 license
# based on https://github.com/sonic2kk/steamtinkerlaunch/blob/master/steamtinkerlaunch

PROGNAME="PortProton"
# PERSONAL_NAME="$(grep PersonaName "$HOME/.local/share/Steam/config/loginusers.vdf" | awk -F'"' '{print $4}')"

if [[ ! -f "$SCPATH" ]] ; then 
	echo '0073686f727463757473000808' | xxd -r -p > "$SCPATH"
fi

NOSTAPPNAME="$name_desktop"
NOSTEXEPATH="\"${STEAM_SCRIPTS}/${name_desktop}.sh\""
NOSTSTDIR="\"${STEAM_SCRIPTS}\""
# icon
NOSTICONPATH="${PORT_WINE_PATH}/data/img/${name_desktop}.png"
# IsHidden
NOSTHIDE=0
# AllowDesktopConfig
NOSTADC=0
# AllowOverlay
NOSTAO=0
# openvr
NOSTVR=0
NOSTSTLLO=0
# LaunchOptions
NOSTLAOP=

if [ -n "${NOSTEXEPATH}" ]; then
	if [ -z "${NOSTAPPNAME}" ]; then
		NOSTAPPNAME="${QEP##*/}"
	fi

	NOSTAIDRHX="$(printf "%03x%03x%02x\n" $((RANDOM%4096)) $((RANDOM%4096)) $((RANDOM%256)))"
	#NOSTAID="$(hex2dec "$NOSTAIDRHX")"
	NOSTAIDHX="\x$(awk '{$1=$1}1' FPAT='.{2}' OFS="\\\x" <<< "$NOSTAIDRHX")"

	if [ -f "$SCPATH" ]; then
		#writelog "INFO" "${FUNCNAME[0]} - The file '$SCPATH' already exists, creating a backup, then removing the 2 closing backslashes at the end"
		cp "$SCPATH" "${SCPATH//.vdf}_${PROGNAME}_backup.vdf" 2>/dev/null
		truncate -s-2 "$SCPATH"
		OLDSET="$(grep -aPo '\x00[0-9]\x00\x02appid' "$SCPATH" | tail -n1 | tr -dc '0-9')"
		NEWSET=$((OLDSET + 1))
		#writelog "INFO" "${FUNCNAME[0]} - Last set in file has ID '$OLDSET', so continuing with '$OLDSET'"
	else
		#writelog "INFO" "${FUNCNAME[0]} - Creating new $SCPATH"
		printf '\x00%s\x00' "shortcuts" > "$SCPATH"
		NEWSET=0
	fi

	#writelog "INFO" "${FUNCNAME[0]} - Adding new set '$NEWSET'"

	{
	printf '\x00%s\x00' "$NEWSET"
	printf '\x02%s\x00%b' "appid" "$NOSTAIDHX"
	printf '\x01%s\x00%s\x00' "appname" "$NOSTAPPNAME"
	printf '\x01%s\x00%s\x00' "Exe" "$NOSTEXEPATH"
	printf '\x01%s\x00%s\x00' "StartDir" "$NOSTSTDIR"

	if [ -n "$NOSTICONPATH" ]; then
		printf '\x01%s\x00%s\x00' "icon" "$NOSTICONPATH"
	else
		printf '\x01%s\x00\x00' "icon"
	fi

	printf '\x01%s\x00\x00' "ShortcutPath"

	if [ -n "$NOSTLAOP" ]; then
		printf '\x01%s\x00%s\x00' "LaunchOptions" "$NOSTLAOP"
	else
		printf '\x01%s\x00\x00' "LaunchOptions"
	fi
	
	if [ "$NOSTHIDE" -eq 1 ]; then
		printf '\x02%s\x00\x01\x00\x00\x00' "IsHidden"
	else
		printf '\x02%s\x00\x00\x00\x00\x00' "IsHidden"
	fi

	if [ "$NOSTADC" -eq 1 ]; then
		printf '\x02%s\x00\x01\x00\x00\x00' "AllowDesktopConfig"
	else
		printf '\x02%s\x00\x00\x00\x00\x00' "AllowDesktopConfig"
	fi

	if [ "$NOSTAO" -eq 1 ]; then
		printf '\x02%s\x00\x01\x00\x00\x00' "AllowOverlay"
	else
		printf '\x02%s\x00\x00\x00\x00\x00' "AllowOverlay"
	fi

	if [ "$NOSTVR" -eq 1 ]; then
		printf '\x02%s\x00\x01\x00\x00\x00' "openvr"
	else
		printf '\x02%s\x00\x00\x00\x00\x00' "openvr"
	fi

	printf '\x02%s\x00\x00\x00\x00\x00' "Devkit"
	printf '\x01%s\x00\x00' "DevkitGameID"
	printf '\x02%s\x00\x00\x00\x00\x00' "LastPlayTime"
	printf '\x00%s\x00' "tags"
	printf '\x08'
	printf '\x08'

	#file end:
	printf '\x08'
	printf '\x08'
	} >> "$SCPATH"
	
	# echo '00013000504f727450726f746f6e0008080808' | xxd -r -p >> "$SCPATH"
fi
