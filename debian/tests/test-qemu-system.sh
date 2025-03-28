#!/bin/sh
set -e

architectures=i386
if [ -x /usr/bin/qemu-system-x86_64 ]; then
  architectures="$architectures x86_64"
fi

for ARCH in $architectures; do
    echo -n "Checking for pc in ${ARCH}..."
    qemu-system-${ARCH} -M help | grep -qs "pc\s\+Standard PC"
    echo "done."
done

