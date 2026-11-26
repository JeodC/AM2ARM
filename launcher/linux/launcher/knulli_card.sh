# Included in the Ports shortcut so the first shell can open the runtime image.
if [ -r /boot/boot/knulli.board ] &&
   [ "$(cat /boot/boot/knulli.board)" = trimui-brick ] &&
   [ "$(stat -f -c %T "$card" 2>/dev/null)" = fuseblk ] &&
   [ "$(blkid -s TYPE -o value "$(findmnt -n -o SOURCE -T "$card")" 2>/dev/null)" = exfat ]; then
    package=$card/am2arm-launcher
    if [ ! -r "$package/knulli-runtime.squashfs" ]; then
        echo 'The Brick runtime image is missing. Extract the complete launcher ZIP again.' >&2
        exit 1
    fi
    view=$(mktemp -d /tmp/am2arm-runtime.XXXXXX)
    app=$view/am2arm-launcher/AM2ARM
    cleanup() {
        for point in "$app/patcher/input" "$app/patcher/patch-bundle" "$app/logs" "$view"; do
            if grep -Fq " $point " /proc/mounts; then umount "$point" || return 1; fi
        done
        rmdir "$view"
    }
    trap cleanup EXIT
    trap 'exit 129' HUP
    trap 'exit 130' INT
    trap 'exit 143' TERM
    mount -t squashfs -o loop,ro "$package/knulli-runtime.squashfs" "$view"
    mkdir -p "$package/AM2ARM/logs" "$package/AM2ARM/patcher/input"
    for dir in logs patcher/patch-bundle patcher/input; do
        mount -o bind "$package/AM2ARM/$dir" "$app/$dir"
    done
    /bin/sh "$view/am2arm-launcher/launch.sh" "$@"
    exit $?
fi
