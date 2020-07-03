#!/usr/bin/env bash
echo "Cloning dependencies"
git clone --depth=1 https://github.com/stormbreaker-project/android_kernel_xiaomi_phoenix.git -b ten-rebase kernel
cd kernel
bash build.sh
