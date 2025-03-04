#!/usr/bin/env bash

. "./data_from_portwine/scripts/add_in_steam.sh"

SCPATH="/home/mint/.steam/steam/userdata/360843101/config/shortcuts.vdf"
rm -f "${SCPATH}"

NOSTAIDVDFHEX='3939714855'
NOSTAPPNAME='Need for Speed The Run'
NOSTEXEPATH='/home/mint/PortProton/steam_scripts/Need For Speed The Run.sh'
NOSTSTDIR='/home/mint/PortProton/steam_scripts'
NOSTICONPATH='/home/mint/PortProton/data/img/Need_for_Speed(TM)_The_Run.png'
NOSTARGS=''

addEntry

listNonSteamGames
