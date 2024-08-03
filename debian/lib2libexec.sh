#! /bin/sh
# Compatibility wrapper for moving stuff from /usr/lib/ to /usr/libexec/.
# Remove for trixie+1.

n="/usr/libexec/qemu/${0##*/}"
echo "W: $0 is deprecated, use $n instead" >&2
sleep 10
exec "$n" "$@"
