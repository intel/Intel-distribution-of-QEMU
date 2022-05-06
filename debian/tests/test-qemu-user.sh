#!/bin/sh

set -e

ARCH=$(dpkg-architecture -q DEB_HOST_GNU_CPU)

echo -n "Checking if qemu-${ARCH} can run executables..."
qemu-${ARCH} /bin/ls -1 debian/changelog | grep -qs ^debian/changelog
echo "done."
