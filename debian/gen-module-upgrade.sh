#! /bin/sh
pkgversion="$1" libdir="$2"

# qemu-system-* can be told to add a new device at runtime,
# including block devices for which a driver is implemented
# in a loadable module.  In case qemu is upgraded, running
# qemus will not be able to load modules anymore (since the
# new modules are from the different build).  Qemu has
# mechanism to load modules from alternative directory,
# it is hardcoded in util/module.c as /run/qemu/$version/.
# We can save old modules on upgrade if qemu processes are
# running, - it does not take much space but ensures qemu
# is not left without maybe-needed modules.  See LP#1847361.
# This is a rare situation.
# Additional complication is that /run is mounted noexec
# so it's impossible to run .so files from there, and
# a (bind-re-)mount is needed.

savetopdir=/run/qemu
savedir=$savetopdir/$(echo -n "$pkgversion" |
                      tr --complement '[:alnum:]+-.~' '_')

marker="### added by qemu/$0:"
# add_maintscript_fragment package {preinst|postinst|prerm|postrm} < contents
add_maintscript_fragment() {
  maintscript=debian/$1.$2.debhelper
  if ! grep -sq "^$marker$" $maintscript; then
    { echo "$marker"; cat; echo "### end added section"; } >> $maintscript
  fi
}


add_maintscript_fragment qemu-block-extra prerm <<EOF
case \$1 in
(upgrade|deconfigure)
  # only save if qemu-system-* or kvm process running
  if ps -e -o comm | grep -E -q '^(qemu-system-|kvm$)'; then
    echo "qemu-block-extra: qemu process(es) running, saving block modules in $savedir..."
    mkdir -p -m 0755 $savedir
    cp -p $libdir/qemu/block-*.so $savedir/
    chmod 0744 $savedir/block-curl.so # a common module
    if [ ! -x $savedir/block-curl.so ]; then # mounted noexec?
       mountpoint -q $savedir || mount --bind $savedir $savedir
       mount -o remount,exec $savedir
    fi
  fi
  ;;
esac
EOF

add_maintscript_fragment qemu-block-extra postrm <<EOF
case \$1 in
(remove)
  if [ -d $savedir ]; then
    rm -f $savedir/block-*.so
    umount $savedir 2>/dev/null || :
    rmdir $savedir 2>/dev/null || :
  fi
  ;;
esac
EOF

add_maintscript_fragment qemu-block-extra postinst <<'EOF'
if [ "$1" = configure -a -x /usr/bin/deb-systemd-helper ] &&
   dpkg --compare-versions -- "$2" lt-nl 1:8.2.1+ds-2~
then
  deb-systemd-helper purge 'run-qemu.mount' >/dev/null || :
fi
EOF
