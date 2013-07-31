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

    empty=1
    copied=0

    ls -ht | while read fitname; do
        empty=0

        if [ -f "$hgpath/garmin/${fitname}" ]; then
            echo "Already copied ${fitname}"
            break
        fi

        cp "$fitname" "$hgpath/garmin/" || die "Couldn't copy activity"

        echo "Copying ${fitname}"
        copied=$((copied+1))

        date="${fitname/.fit/}"
        pushd "$hgpath" >/dev/null || die "Couldn't find run directory?!"

        echo "Converting ${fitname} to ${date}.gpx"
        gpsbabel -i garmin_fit -f "garmin/${date}.fit" -o gpx -F "gpx/${date}.gpx" \
            || die "gpsbabel failed"

        popd >/dev/null
    done

    if [ "x$empty" = "x1" ]; then
        die "No activity file(s) present?!"
    fi

    if [ "x$copied" = "x0" ]; then
        echo "No new activity files found."
    else
        echo "Successfully imported the last ${copied} .fit files!"
    fi
}

main
