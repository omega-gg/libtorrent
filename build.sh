#!/bin/sh
set -e

#--------------------------------------------------------------------------------------------------
# Settings
#--------------------------------------------------------------------------------------------------

external="$PWD/../3rdparty"

#--------------------------------------------------------------------------------------------------

libtorrent_hash="e9bbf16bdd899f42aef0f0c2b1f214de2c15ac92" # 2.0.6

Boost_versionA="1.78.0"
Boost_versionB="1_78_0"

#--------------------------------------------------------------------------------------------------
# Windows

MinGW_versionA="11.2.0"
MinGW_versionB="1120"
MinGW_versionC="810"

#--------------------------------------------------------------------------------------------------
# macOS

darwin_version="4.2.1"

#--------------------------------------------------------------------------------------------------
# Android

# NOTE android: SDK 24 seems to be the best bet for the maximum compatibilty. If we build against
#               SDK 29 or 30 we get a 'cannot locate fread_unlocked' at runtime on Android 7.0.
SDK_version="31"

NDK_version="23"

#--------------------------------------------------------------------------------------------------
# Functions
#--------------------------------------------------------------------------------------------------

buildAndroid()
{
    cd boost/tools/build/src/engine

    sh build.sh gcc

    cd ../../../../../libtorrent

    # FIXME libtorrent 1.2.6 Linux: It seems b2 returns an error code, even when it succeeds.
    set +e

    b2 clang-arm -j4 cxxflags="-fPIC -DANDROID" cxxstd=17 variant=release link=static \
                     threading=multi crypto=built-in target-os=android \
                     install --prefix="$PWD/build"

    set -e

    cd ..

    sh deploy.sh $1

    # NOTE: We remove this folder to force a new architecture check.
    rm -rf boost/libs/config/checks/architecture/bin
    rm -rf boost/bin.v2

    rm -rf libtorrent/bin
    rm -rf libtorrent/deps/try_signal/bin

    rm -rf libtorrent/build
}

#--------------------------------------------------------------------------------------------------
# Syntax
#--------------------------------------------------------------------------------------------------

if [ $# != 1 ] \
   || \
   [ $1 != "win32" -a $1 != "win64" -a $1 != "win32-msvc" -a $1 != "win64-msvc" -a \
     $1 != "macOS" -a $1 != "linux" -a $1 != "android" ]; then

    echo "Usage: build <win32 | win64 | win32-msvc | win64-msvc | macOS | linux | android>"

    exit 1
fi

#--------------------------------------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------------------------------------

external="$external/$1"

if [ $1 = "win32" -o $1 = "win64" -o $1 = "win32-msvc" -o $1 = "win64-msvc" ]; then

    os="windows"

    if [ $1 = "win32" -o $1 = "win64" ]; then

        compiler="mingw"

        MinGW="$external/MinGW/$MinGW_versionA"
    else
        compiler="msvc"

        MinGW="$PWD/MinGW/$MinGW_versionA"

        if [ $1 = "win32-msvc" ]; then

            target="32"

            MinGW_url="http://ftp1.nluug.nl/languages/qt/online/qtsdkrepository/windows_x86/desktop/tools_mingw/qt.tools.win32_mingw810/8.1.0-1-202004170606i686-8.1.0-release-posix-dwarf-rt_v6-rev0.7z"
        else
            target="64"

            MinGW_url="http://ftp1.nluug.nl/languages/qt/online/qtsdkrepository/windows_x86/desktop/tools_mingw90/qt.tools.win64_mingw900/9.0.0-1-202203221220mingw-w64-x86_64-11.2.0-release-posix-seh-rt_v9-rev3.7z"
        fi
    fi
else
    os="default"

    compiler="default"
fi

NDK="$external/NDK/$NDK_version"

#--------------------------------------------------------------------------------------------------

boost="https://boostorg.jfrog.io/artifactory/main/release/$Boost_versionA/source/boost_$Boost_versionB.zip"

#--------------------------------------------------------------------------------------------------
# Clean
#--------------------------------------------------------------------------------------------------

echo "CLEANING"

rm -rf deploy
mkdir  deploy
touch  deploy/.gitignore

#--------------------------------------------------------------------------------------------------
# Install
#--------------------------------------------------------------------------------------------------

if [ $compiler = "msvc" ]; then

    if [ ! -d "/c/Program Files/7-Zip" ]; then

        echo "Warning: You need 7zip installed in C:/Program Files/7-Zip"
    else
        PATH="/c/Program Files/7-Zip:$PATH"
    fi

elif [ $1 = "linux" ] || [ $1 = "android" ]; then

    sudo apt-get -y install build-essential curl unzip

    echo ""
fi

#--------------------------------------------------------------------------------------------------
# Download
#--------------------------------------------------------------------------------------------------

if [ $compiler = "msvc" ]; then

    echo "DOWNLOADING MinGW"
    echo $MinGW_url

    curl -L -o MinGW.7z $MinGW_url

    echo ""
fi

echo "DOWNLOADING Boost"
echo $boost

curl -L -o boost.zip $boost

#--------------------------------------------------------------------------------------------------
# MinGW
#--------------------------------------------------------------------------------------------------

if [ $compiler = "msvc" ]; then

    echo "EXTRACTING MinGW"

    test -d "$MinGW" && rm -rf "$MinGW"

    mkdir -p "$MinGW"

    7z x MinGW.7z -o"$MinGW" > /dev/null

    rm MinGW.7z

    if [ $1 = "win32-msvc" ]; then

        path="$MinGW"/Tools/mingw"$MinGW_versionC"_32
    else
        path="$MinGW"/Tools/mingw"$MinGW_versionB"_64
    fi

    mv "$path"/* "$MinGW"

    rm -rf "$MinGW/Tools"
fi

#--------------------------------------------------------------------------------------------------
# Boost
#--------------------------------------------------------------------------------------------------

echo "EXTRACTING Boost"

test -d boost && rm -rf boost

unzip -q boost.zip

rm boost.zip

mv boost_$Boost_versionB boost

if [ $1 = "macOS" ]; then

    cp macOS/darwin.jam boost/tools/build/src/tools

elif [ $1 = "android" ]; then

    cp android/user-config.jam boost/tools/build/src
fi

#--------------------------------------------------------------------------------------------------
# libtorrent
#--------------------------------------------------------------------------------------------------

echo "CLONING libtorrent"

test -d libtorrent && rm -rf libtorrent

# NOTE: We want to clone sub modules too.
git clone --recursive "https://github.com/arvidn/libtorrent"

cd libtorrent

git checkout $libtorrent_hash

cd ..

echo ""

#--------------------------------------------------------------------------------------------------
# Build
#--------------------------------------------------------------------------------------------------

if [ $os = "windows" ]; then

    PATH=$MinGW/bin:$PWD/boost/tools/build/src/engine:$PWD/boost:$PATH
else
    PATH=$PWD/boost/tools/build/src/engine:$PWD/boost:$PATH
fi

export BOOST_BUILD_PATH=$PWD/boost/tools/build/src

export BOOST_ROOT=$PWD/boost

if [ $1 = "android" ]; then

    export COMPILER="$NDK"/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi$SDK_version-clang++

    buildAndroid androidv7

    export COMPILER="$NDK"/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android$SDK_version-clang++

    buildAndroid androidv8

    export COMPILER="$NDK"/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android$SDK_version-clang++

    buildAndroid android32

    export COMPILER="$NDK"/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android$SDK_version-clang++

    buildAndroid android64
else
    cd boost/tools/build/src/engine

    sh build.sh gcc

    cd ../../../../../libtorrent

    if [ $compiler = "mingw" ]; then

        set +e

        # FIXME libtorrent 2.0.4: For some reason we need to call this twice for the build to work.
        # FIXME libtorrent 2.0.6: We avoid narrowing when using MinGW 11.2.0.
        b2 -j4 toolset=gcc cxxflags="-Wno-narrowing" cxxstd=17 variant=release link=shared \
               threading=multi crypto=built-in install --prefix="$PWD/build"

        set -e

        b2 -j4 toolset=gcc cxxflags="-Wno-narrowing" cxxstd=17 variant=release link=shared \
               threading=multi crypto=built-in install --prefix="$PWD/build"

    elif [ $compiler = "msvc" ]; then

        set +e

        # FIXME libtorrent 2.0.4: For some reason we need to call this twice for the build to work.
        b2 -j4 toolset=msvc address-model=$target cxxstd=17 variant=release link=shared \
               threading=multi crypto=built-in install --prefix="$PWD/build"

        set -e

        b2 -j4 toolset=msvc address-model=$target cxxstd=17 variant=release link=shared \
               threading=multi crypto=built-in install --prefix="$PWD/build"

    elif [ $1 = "macOS" ]; then

        b2 -j4 toolset=darwin cxxstd=17 variant=release link=shared threading=multi \
               crypto=built-in install --prefix="$PWD/build"

    elif [ $1 = "linux" ]; then
        # FIXME libtorrent 1.2.6 Linux: It seems b2 returns an error code, even when it succeeds.
        set +e

        b2 -j4 cxxstd=17 variant=release link=shared threading=multi crypto=built-in \
               install --prefix="$PWD/build"

        set -e
    fi

    cd ..

    sh deploy.sh $1
fi
