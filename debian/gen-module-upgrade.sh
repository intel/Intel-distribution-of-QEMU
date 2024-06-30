#! /bin/sh
pkg=$1 pkgversion="$2" moddir="$3"

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
#
# Ideally the remove of the saved modules should be done when
# last qemu-system-* process with this version is terminated,
# but we can't do this.  So old modules keep accumulating in
# /run/qemu/ until reboot, even if not needed already.
#
# Currently we handle purging of the modules, removing the
# whole saved LAST-versioned subdir.  Probably we should
# remove all saved subdirs in this case.
#
# Additional complication is that /run is mounted noexec
# so it's impossible to run .so files from there, and
# a (bind-re-)mount is needed.
#
# When this script is run, files for the package in question
# has already been installed into debian/package/.

savetopdir=/run/qemu
savedir=$savetopdir/$(echo -n "$pkgversion" |
                      tr --complement '[:alnum:]+-.~' '_')
tagname=.savemoddir
tx=$savedir/$tagname

marker="### added by qemu/$0:"
# add_maintscript_fragment package {preinst|postinst|prerm|postrm} < contents
add_maintscript_fragment() {
  maintscript=debian/$1.$2.debhelper
  if ! grep -sq "^$marker$" $maintscript; then
    { echo "$marker"; cat; echo "### end added section"; } >> $maintscript
  fi
}


modules=$(echo debian/$pkg/$moddir/*.so | sed "s|debian/[^ ]*/||g")

add_maintscript_fragment $pkg prerm <<EOF
case \$1 in
(upgrade|deconfigure)
  # only save if qemu-system-* or kvm process running
  # can also check version of the running processes
  if ps -e -o comm | grep -E -q '^(qemu-system-|kvm$)'; then
    echo "$pkg: qemu process(es) running, saving block modules in $savedir..."
    mkdir -p -m 0755 $savedir
    ( cd $moddir/; cp -p -n -t $savedir/ $modules )
    > $tx; chmod 0744 $tx
    if [ ! -x $tx ]; then # mounted noexec?
       mountpoint -q $savedir || mount --bind $savedir $savedir
       mount -o remount,exec $savedir
    fi
  fi
  ;;
esac
EOF

add_maintscript_fragment $pkg postrm <<EOF
case \$1 in
(remove)
  # remove modules for all versions not just one
  for dirf in ${savedir%%_*}_*/$tagname; do
    [ -f "\$dirf" ] || continue
    dir="\${dirf%/*}"
    ( cd "\$dir"; rm -f $modules )
    if [ ! "\$(ls -- "\$dir/")" ]; then
      rm -f "\$dirf"
      umount "\$dir" 2>/dev/null || :
      rmdir "\$dir" 2>/dev/null || :
    fi
  done
  ;;
esac
EOF
