#!/usr/bin/env bash
echo "Cloning dependencies"
rm -rf AnyKernel
git clone --depth=1 https://github.com/sarthakroy2002/android_prebuilts_clang_host_linux-x86_clang-6443078 clang
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 los-4.9-64
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 los-4.9-32
echo "Done"
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
TANGGAL=$(date +"%F-%S")
START=$(date +"%s")
KERNEL_DIR=$(pwd)
PATH="${PWD}/clang/bin:${PATH}:${PWD}/los-4.9-32/bin:${PATH}:${PWD}/los-4.9-64/bin:${PATH}" \
export KBUILD_COMPILER_STRING="$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"
export ARCH=arm64
export KBUILD_BUILD_HOST=ThunderStorm
export KBUILD_BUILD_USER="AnupamRoy"
source ~/.bashrc && source ~/.profile
ccache -M 100G
export LC_ALL=C && export USE_CCACHE=1
# sticker plox
function sticker() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendSticker" \
        -d sticker="CAACAgQAAxkBAAED3JFiApkFOuZg8zt0-WNrfEGwrvoRuAACAQoAAoEcoFINevKyLXEDhSME" \
        -d chat_id=$chat_id
}
# Send info plox channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>• Test Kernel •</b>%0ABuild started on <code>Server</code>%0AFor device <b>RM6785 Devices</b> (RM6785)%0Abranch <code>$(git rev-parse --abbrev-ref HEAD)</code>(master)%0AUnder commit <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0AUsing compiler: <code>${KBUILD_COMPILER_STRING}</code>%0AStarted on <code>$(date)</code>%0A<b>Build Status:</b>#Beta"
}
# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>RM6785 (RM6785)</b>%0Abranch <code>$(git rev-parse --abbrev-ref HEAD)</code>(master) | <b>$(${GCC}gcc --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')</b>"
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
	-d sticker="CAACAgIAAxkBAAED3JViAplqY4fom_JEexpe31DcwVZ4ogAC1BAAAiHvsEs7bOVKQsl_OiME" \
        -d text="Build throw an error(s)"
    exit 1
}
# Compile plox
function compile() {

[ -d "out" ] && rm -rf out || mkdir -p out
make O=out ARCH=arm64 RMX2151_defconfig
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
		      CC="clang" \
                      CLANG_TRIPLE=aarch64-linux-gnu- \
                      CROSS_COMPILE="${PWD}/los-4.9-64/bin/aarch64-linux-android-" \
                      CROSS_COMPILE_ARM32="${PWD}/los-4.9-32/bin/arm-linux-androideabi-" \
                      CONFIG_NO_ERROR_ON_MISMATCH=y

    if ! [ -a "$IMAGE" ]; then
        finerr
        exit 1
    fi
    git clone --depth=1 https://github.com/anupamroy777/AnyKernel33.git AnyKernel
    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
}
# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 ThunderStorm-Test-KERNEL-RMX2151-${TANGGAL}.zip *
    curl -sL https://git.io/file-transfer | sh
    ./transfer wet Test-KERNEL-RMX2151-ThunderStorm.zip
    cd ..
}
sendinfo
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push

