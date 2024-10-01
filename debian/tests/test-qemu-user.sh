#!/bin/sh

set -e

host=$(dpkg --print-architecture)

# list of release architectures
architectures="amd64 arm64 armel armhf i386 mips64el ppc64el riscv64 s390x"

for arch in $architectures; do
  [ $arch = $host ] ||
    dpkg --add-architecture $arch
done

apt-get update

skipped= failed= mismatch= ok=

for arch in $architectures; do

    if ! apt-get install --no-install-recommends -q -y busybox:$arch 2>&1; then
      echo "Skipping test for $arch because of busybox:$arch installation problem"
      skipped="$skipped $arch"
      continue
    fi

    f=/usr/bin/qemu-$arch
    bb=/bin/busybox

    echo "=== Checking if $f can run executables:"
    echo "glob with sh: $f $bb ash -c \"$f $bb ls -dCFl debian/*[t]*\":"
    ls="$($f $bb ash -c "$f $bb ls -dCFl debian/*[t]*")" || failed="$failed $arch"
    echo "$ls"
    case "$ls" in
      (*debian/control*) echo "=== ok."; ok="$ok $arch";;
      (*) echo "Expected output not found" >&2;;
    esac

done

[ -z "$skipped" ] || echo skipped: $skipped
[ -z "$failed" ] || echo failed: $failed
if [ -n "$ok" ]; then
  echo succeeded: $ok
else
  exit 77
fi
