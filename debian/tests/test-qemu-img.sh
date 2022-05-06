#!/bin/sh

set -e

cd "$AUTOPKGTEST_TMP"

doit() {
 echo "$1:"
  shift
  echo "$1"
  if [ -n "$2" ]; then
    out=$($1)
    eval "case \"\$out\" in ( $2 ) echo \"\$out\";; (*) echo \"unexpected output:\"; echo \" want $2\"; echo \"  got \$out\"; return 1;; esac"
  else
    $1
  fi
  echo ok.
}

doit "Testing if qemu-img creates images" \
	"qemu-img create q.raw 12G"

doit "Testing for correct image size" \
	"ls -l q.raw" '*\ 12884901888\ *'

doit "Testing if file is sparse" \
	'ls -s q.raw' '[04]\ *'

doit "Testing if conversion to a qcow2 image works" \
	"qemu-img convert -f raw -O qcow2 q.raw q.qcow2"

doit "Checking if image is qcow2" \
	'file q.qcow2' '*QEMU\ QCOW2\ Image\ *\ 12884901888\ *'

rm -f q.raw q.qcow2
