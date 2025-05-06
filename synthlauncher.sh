#!/bin/bash
export SF_DIR=/home/$(whoami)/sf
if [ $# -eq 0 ]; then
    echo "Usage: $0 <MIDI file>"
    echo "Example: $0 song.mid"
    exit 1
fi
export SF=$SF_DIR/gm.sf2
echo "    ________      _     _______             __  __     "
echo "   / ____/ /_  __(_)___/ / ___/__  ______  / /_/ /_    "
echo "  / /_  / / / / / / __  /\__ \/ / / / __ \/ __/ __ \   "
echo " / __/ / / /_/ / / /_/ /___/ / /_/ / / / / /_/ / / /    "
echo "/_/   /_/\__,_/_/\__,_//____/\__, /_/ /_/\__/_/ /_/     "
echo "                            /____/                     "
echo "Select a SoundFont:"
if [ -d $SF_DIR ]; then
    i=1
    for sf in $SF_DIR/*.sf2; do
        echo "[$i] $(basename $sf)"
        let i++
    done
    read -p "fluidsynth~>" n
    i=1
    for sf in $SF_DIR/*.sf2; do
        if [ $i -eq $n ]; then
            export SF=$sf
            break
        fi
        let i++
    done
fi
echo "currently playing: $1"
echo "using SoundFont $sf"
fluidsynth -q -d $sf "$1" # > /dev/null 2>&1
# Uncomment this above to mute fluidsynth output
