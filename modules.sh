#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later

# setup paths
KERNEL_DIR=$PWD
ZIP_DIR=$KERNEL_DIR/AnyKernel3
OUTDIR="$PWD/out/"
SRCDIR="$PWD/"
MODULEDIR="$PWD/AnyKernel3/modules/vendor/lib/modules/"
PRIMA="$PWD/AnyKernel3/modules/vendor/lib/modules/wlan.ko"
PRONTO="$PWD/AnyKernel3/modules/vendor/lib/modules/pronto/pronto_wlan.ko"
STRIP="$PWD/gcc/bin/$(echo "$(find "$PWD/gcc/bin" -type f -name "aarch64-*-gcc")" | awk -F '/' '{print $NF}' |\
			sed -e 's/gcc/strip/')"

cd $ZIP_DIR

for MOD in $(find "${OUTDIR}" -name '*.ko') ; do
	"${STRIP}" --strip-unneeded --strip-debug "${MOD}" &> /dev/null
	"${SRCDIR}"/scripts/sign-file sha512 \
			"${OUTDIR}/signing_key.priv" \
			"${OUTDIR}/signing_key.x509" \
			"${MOD}"
	find "${OUTDIR}" -name '*.ko' -exec cp {} "${MODULEDIR}" \;
	case ${MOD} in
		*/*.ko)
			cp -ar "${MOD}" "${PRIMA}"
			cp -ar "${MOD}" "${PRONTO}"
			cp -ar "${MOD}" "${MODULEDIR}"
	esac
done
