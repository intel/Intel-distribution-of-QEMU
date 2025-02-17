#!/usr/bin/make -rRf
SHELL = /bin/sh -e

VENDOR := $(shell dpkg-vendor --derives-from Ubuntu && \
            echo ubuntu || echo debian)
include /usr/share/dpkg/pkg-info.mk

# since some files and/or lists differ from version to version,
# ensure we have the expected qemu version, or else scream loudly
checked-version := 9.2.1+ds
# version of last vdso change for d/control Depends field:
vdso-version := 1:9.2.0~rc3+ds-1~

vdso-files := \
 linux-user/aarch64/vdso-be.so \
 linux-user/aarch64/vdso-le.so \
 linux-user/arm/vdso-be32.so \
 linux-user/arm/vdso-be8.so \
 linux-user/arm/vdso-le.so \
 linux-user/hppa/vdso.so \
 linux-user/i386/vdso.so \
 linux-user/loongarch64/vdso.so \
 linux-user/ppc/vdso-32.so \
 linux-user/ppc/vdso-64.so \
 linux-user/ppc/vdso-64le.so \
 linux-user/riscv/vdso-32.so \
 linux-user/riscv/vdso-64.so \
 linux-user/s390x/vdso.so \
 linux-user/x86_64/vdso.so \
#

user-targets := \
 aarch64 \
 aarch64_be \
 alpha \
 arm \
 armeb \
 hexagon \
 hppa \
 i386 \
 loongarch64 \
 m68k \
 microblaze \
 microblazeel \
 mips \
 mips64 \
 mips64el \
 mipsel \
 mipsn32 \
 mipsn32el \
 or1k \
 ppc \
 ppc64 \
 ppc64le \
 riscv32 \
 riscv64 \
 s390x \
 sh4 \
 sh4eb \
 sparc \
 sparc32plus \
 sparc64 \
 x86_64 \
 xtensa \
 xtensaeb \
#

# qemu-system (softmmu) targets, in multiple packages
# For each package:
#  system-archlist-$pkg - list qemu architectues which should go to this pkg
#  system-kvmcpus-$pkg  - list of ${DEB_HOST_ARCH_CPU}s where we create
#                         kvm link for this package
# For each of ${system-archlist-*}, optional:
#  system-alias-$qcpu   - aliases for this qemu architecture
# For each of ${system-kvmcpus-*}, mandatory:
#  system-kvmlink-$dcpu - where to point kvm link for this ${DEB_HOST_ARCH_CPU}

system-packages := arm mips ppc riscv s390x sparc x86 misc

system-archlist-arm := aarch64 arm
system-alias-aarch64 := arm64
system-alias-arm := armel armhf
system-kvmcpus-arm := arm64 arm
system-kvmlink-arm64 := aarch64
system-kvmlink-arm := arm

system-archlist-mips := mips mipsel mips64 mips64el

system-archlist-ppc := ppc ppc64
system-alias-ppc := powerpc
system-alias-ppc64 := ppc64le ppc64el
system-kvmcpus-ppc := ppc64 ppc64el powerpc
system-kvmlink-ppc64 := ppc64
system-kvmlink-ppc64el := ppc64
system-kvmlink-powerpc := ppc

system-archlist-riscv := riscv32 riscv64

system-archlist-s390x := s390x
system-kvmcpus-s390x := s390x
system-kvmlink-s390x := s390x

system-archlist-sparc := sparc sparc64

system-archlist-x86 := i386 x86_64
system-alias-x86_64 := amd64
system-kvmcpus-x86 := amd64 i386
system-kvmlink-amd64 := x86_64
system-kvmlink-i386 := x86_64

system-archlist-misc := alpha avr hppa m68k loongarch64 \
                microblaze microblazeel or1k rx sh4 sh4eb \
                tricore xtensa xtensaeb
system-alias-loongarch64 := loong64

ifneq (${checked-version},${DEB_VERSION_UPSTREAM})
$(warning Debian packaging is set up for version ${checked-version} while actual version is ${DEB_VERSION_UPSTREAM})

actual-vdso-files := $(sort $(shell \
 for f in linux-user/*/Makefile.vdso ; do \
   sed -n "s|^\\\$$(SUBDIR)/\(.*\):.*|$${f%/*}/\1|p" $$f; \
 done))
ifneq ($(sort ${vdso-files}),${actual-vdso-files})
$(warning vdso-files list changed: \
 added: $(filter-out ${vdso-files},${actual-vdso-files}), \
 removed: $(filter-out ${actual-vdso-files},${vdso-files}))
endif
vdso-version-upstream := $(word 2,$(subst :, ,$(subst -, ,${vdso-version})))
vdso-tag := v$(subst ~rc,-rc,${vdso-version-upstream:+ds=})
actual-vdso-tag := v$(subst ~rc,-rc,${DEB_VERSION_UPSTREAM:+ds=})
vdso-changed-files != set -x; \
  git diff --name-only ${vdso-tag}..${actual-vdso-tag} -- 'linux-user/*/vdso*.so'
ifneq (0,${.SHELLSTATUS})
$(warning unable to run git to find list of changed vdso files)
endif
ifneq (,${vdso-changed-files})
$(warning changes in vdso files found since ${vdso-version}, update vdso-version)
endif

actual-user-targets := $(sort $(shell \
  ls -1 configs/targets/*-linux-user.mak \
   | sed 's|.*/\(.*\)-linux-user\.mak$$|\1|'))
ifneq ($(sort ${user-targets}),${actual-user-targets})
$(warning user-targets list differs from actual, \
  added: $(filter-out ${user-targets},${actual-user-targets}), \
  removed: $(filter-out ${actual-user-targets},${user-targets}))
$(warning Check debian/binfmt-install too!)
endif

$(error verify everything is set up correctly)
endif

# Host architectures we produce packages for.
# when changing this list, check d/control-in too, if any changes
# needs to be done for build deps and --enable options.
system-arch-linux-64 = \
	amd64 arm64 loong64 mips64 mips64el ppc64 ppc64el riscv64 s390x sparc64
system-arch-linux = $(sort ${system-arch-linux-64} \
	arm armel armhf i386 mips mipsel powerpc powerpcspe sparc)
system-arch = ${system-arch-linux}
user-arch = ${system-arch-linux}
utils-arch = $(sort ${system-arch} alpha hppa m68k sh4 x32)
# subset of system-arch
spice-arch = amd64 i386 arm64 armel armhf loong64 mips64el mipsel ppc64el riscv64

substvars = system-arch-linux-64 system-arch-linux system-arch spice-arch user-arch utils-arch \
	vdso-version

debian/control: debian/control-in debian/control.mk
	sed -e '1i\# autogenerated file from debian/control-in' \
	    -e 's/^:${VENDOR}://' -e '/^:[a-z]*:/D' \
		$(foreach v,${substvars},-e 's/:$v:/${$v}/') \
		$< > $@.tmp
	mv -f $@.tmp $@
