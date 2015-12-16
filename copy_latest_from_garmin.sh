#!/usr/bin/zsh

mntpath=/mnt/GARMIN
gapath="${mntpath}/GARMIN/ACTIVITY"
hgpath="$HOME/docs/run"
devpath="/dev/disk/by-id/usb-Garmin_FR230_Flash-0:0"
mounted=0

function cleanup(){
    cd /
    if [ $mounted -eq 1 ]; then
        sudo umount "$mntpath"
    fi
}

function die(){
    fmt="$1"
    shift

    printf "${fmt}\n" "$@"

    cleanup

    exit 1
}

function main(){
    if [ "x`id -u`" != "x0" ]; then
        echo "Mounting '$devpath' on '$mntpath'"
    fi

    sudo mount "$devpath" "$mntpath" || die "Couldn't mount %s" "$devpath"
    mounted=1

    cd "$gapath" || die "Couldn't find activities directory: %s" "$gapath"

    empty=1
    copied=0

    ls -ht | while read fitname; do
        empty=0

        date="$(date --reference "$fitname" +"%Y-%m-%d-%H-%M-%S")"

        if [ -f "$hgpath/garmin/${date}.fit" ]; then
            echo "Already copied ${fitname} (${date}.fit)"
            break
        fi

        echo "Copying ${fitname}"
        cp "$fitname" "$hgpath/garmin/" || die "Couldn't copy activity"
        copied=$((copied+1))

        echo "Renaming to '${date}.fit'"
        mv "$hgpath/garmin/$fitname" "$hgpath/garmin/${date}.fit"

        pushd "$hgpath" >/dev/null || die "Couldn't find run directory?!"

        echo "Converting ${date}.fit to ${date}.gpx"
        gpsbabel -i garmin_fit -f "garmin/${date}.fit" \
            -o 'gpx,garminextensions=1' -F "gpx/${date}.gpx" \
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

    cleanup
}

main
