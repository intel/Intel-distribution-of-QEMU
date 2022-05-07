#!/bin/sh

set -e

# dpkg-architecture wants gcc and prints a warning if not found
dpkg-architecture -q DEB_HOST_GNU_CPU 2>&1

# redirect it to /dev/null for actual run
ARCH=$(dpkg-architecture -q DEB_HOST_GNU_CPU 2>/dev/null)
echo DEB_HOST_GNU_CPU=$ARCH uname-m=$(uname -m) arch=$(arch) dpkg-print-architecture: $(dpkg --print-architecture)

case $ARCH in
  amd64) ARCH=x86_64 ;;
  i[456]86) ARCH=i386 ;;
esac

if [ -x /usr/bin/qemu-$ARCH ]; then
echo "Checking if qemu-$ARCH can run executables:"
qemu-$ARCH /bin/ls -1 debian/changelog | grep ^debian/changelog
echo "done."
else
echo Warning: qemu-$ARCH not found, not testing qemu-user
fi
