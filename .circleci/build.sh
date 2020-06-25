#!/usr/bin/env bash
# Copyright (C) 2020 Saalim Quadri (iamsaalim)
# SPDX-License-Identifier: GPL-3.0-or-later

cd $HOME
echo -e "machine github.com\n  login $GITHUB_TOKEN" > ~/.netrc
echo "Cloning dependencies"
git clone --depth=1 https://github.com/iamsaalim/kernel_asus_X01A -b stock kernel
cd kernel
git clone --depth=1 https://github.com/stormbreaker-project/stormbreaker-clang clang
git clone --depth=1 https://github.com/stormbreaker-project/aarch64-linux-android-4.9 gcc
git clone --depth=1 https://github.com/stormbreaker-project/arm-linux-androideabi-4.9 gcc32
echo "Done"
export kernelzip="$HOME/AnyKernel3"
git clone --depth=1 https://github.com/stormbreaker-project/AnyKernel3 -b X01A $kernelzip
export IMAGE="$HOME/kernel/out/arch/arm64/boot/Image.gz-dtb"
GCC="$HOME/kernel/gcc/bin/aarch64-linux-android-"
TANGGAL=$(date +"%F-%S")
START=$(date +"%s")
export CONFIG_PATH=$PWD/arch/arm64/configs/X01A_defconfig
PATH="${PWD}/clang/bin:${PWD}/gcc/bin:${PWD}/gcc32/bin:${PATH}"
export ARCH=arm64
export KBUILD_BUILD_HOST=hetzner
export KBUILD_BUILD_USER="saalim"

# Send info to channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>• Kernel •</b>%0ABuild started on <code>Circle CI/CD</code>%0AFor device <b>Zenfone Max M2</b> (X01A)%0Abranch <code>$(git rev-parse --abbrev-ref HEAD)</code>(master)%0AUnder commit <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0AUsing compiler: <code>$(${GCC}gcc --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')</code>%0AStarted on <code>$(date)</code>%0A<b>Build Status:</b> #Test"
}

# Push kernel to channel
function push() {
    cd $kernelzip
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>Zenfone Max M2 (X01A)</b> | <b>$(${GCC}gcc --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')</b>"
}

# spam Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s)"
    exit 1
}

# Compile
function compile() {
    make O=out ARCH=arm64 X01A_defconfig
    make -j$(nproc --all) O=out \
                             ARCH=arm64 \
			     CROSS_COMPILE=aarch64-linux-android- \
			     CROSS_COMPILE_ARM32=arm-linux-androideabi-
}

# Zipping
function zip() {
    cd $kernelzip
    cp $IMAGE $kernelzip/
    make normal
    cd ..
}

# Create modules
function module() {

# setup paths
KERNEL_DIR="$HOME/kernel"
OUTDIR="$KERNEL_DIR/out/"
SRCDIR="$KERNEL_DIR"
MODULEDIR="$kernelzip/modules/vendor/lib/modules/"
PRIMA="$kernelzip/modules/vendor/lib/modules/wlan.ko"
STRIP="$KERNEL_DIR/gcc/bin/$(echo "$(find "$KERNEL_DIR/gcc/bin" -type f -name "aarch64-*-gcc")" | awk -F '/' '{print $NF}' |\
			sed -e 's/gcc/strip/')"

cd $kernelzip

for MOD in $(find "${OUTDIR}" -name '*.ko') ; do
	"${STRIP}" --strip-unneeded --strip-debug "${MOD}" &> /dev/null
	find "${OUTDIR}" -name '*.ko' -exec cp {} "${MODULEDIR}" \;
	case ${MOD} in
		*/wlan.ko)
			cp -ar "${MOD}" "${PRIMA}"
			cp -ar "${MOD}" "${MODULEDIR}"
	esac
done

cd ..
}

# Generate dtbo
function dtbo() {

KERNEL_DIR="$HOME/kernel"
    cd $KERNEL_DIR
    git clone https://android.googlesource.com/platform/system/libufdt "$KERNEL_DIR"/scripts/ufdt/libufdt
    python scripts/ufdt/libufdt/utils/src/mkdtboimg.py create $kernelzip/dtbo.img --page_size=4096 out/arch/arm64/boot/dts/qcom/*.dtbo
}

sendinfo
compile
module
zip
END=$(date +"%s")
DIFF=$(($END - $START))
push
