#!/usr/bin/zsh

function die(){
    fmt="$1"
    shift

    printf "${fmt}\n" "$@"
    exit 1
}

function main(){
    gapath=/run/media/conrad/GARMIN/Garmin/Activities
    hgpath="$HOME/docs/run"

    cd "$gapath" || die "Couldn't find activities directory: %s" "$gapath"

    fitname="`ls -htr | tail -n1`"
    if ! ( echo "$fitname" | grep -q ".fit" ) ; then
        die "No activity file present?!"
    fi

    if [ -f "$hgpath/garmin/${fitname}" ]; then
        die "Already copied latest activity"
    fi

    cp "$fitname" "$hgpath/garmin/" || die "Couldn't copy activity"

    date="${fitname/.fit/}"
    cd "$hgpath" || die "Couldn't find run directory?!"

    gpsbabel -i garmin_fit -f "garmin/${date}.fit" -o gpx -F "gpx/${date}.gpx" \
        || die "gpsbabel failed"
}

main
