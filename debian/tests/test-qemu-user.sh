#!/bin/sh

set -e

# dpkg-architecture wants gcc and prints a warning if not found
dpkg-architecture -q DEB_HOST_GNU_CPU 2>&1

# redirect it to /dev/null for actual run
ARCH=$(dpkg-architecture -q DEB_HOST_GNU_CPU 2>/dev/null)
echo DEB_HOST_GNU_CPU=$ARCH uname-m=$(uname -m) arch=$(arch)

echo -n "Checking if qemu-${ARCH} can run executables..."
qemu-${ARCH} /bin/ls -1 debian/changelog | grep -qs ^debian/changelog
echo "done."
