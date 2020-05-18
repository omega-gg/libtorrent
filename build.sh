#!/bin/sh
set -e

#--------------------------------------------------------------------------------------------------
# Settings
#--------------------------------------------------------------------------------------------------

external="$PWD/../3rdparty"

#--------------------------------------------------------------------------------------------------

libtorrent_versionA="1.2.6"
libtorrent_versionB="1_2_6"

Boost_versionA="1.71.0"
Boost_versionB="1_71_0"

#--------------------------------------------------------------------------------------------------
# Windows

MinGW_versionA="7.3.0"
MinGW_versionB="730"

#--------------------------------------------------------------------------------------------------
# macOS

darwin_version="4.2.1"

#--------------------------------------------------------------------------------------------------
# linux

gcc_version="7"

#--------------------------------------------------------------------------------------------------
# Android

NDK_version="21"

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

    b2 clang-arm -j4 cxxflags="-std=c++11 -fPIC -DANDROID" variant=release link=static \
                                                                           openssl-version=pre1.1

    set -e

    cd ..

    sh deploy.sh $1

    # NOTE: We remove this folder to force a new architecture check.
    rm -rf boost/libs/config/checks/architecture/bin
    rm -rf boost/bin.v2

    rm -rf libtorrent/bin
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

            MinGW_url="http://ftp1.nluug.nl/languages/qt/online/qtsdkrepository/windows_x86/desktop/tools_mingw/qt.tools.win32_mingw730/7.3.0-1-201903151311i686-7.3.0-release-posix-dwarf-rt_v5-rev0.7z"
        else
            target="64"

            MinGW_url="http://ftp1.nluug.nl/languages/qt/online/qtsdkrepository/windows_x86/desktop/tools_mingw/qt.tools.win64_mingw730/7.3.0-1x86_64-7.3.0-release-posix-seh-rt_v5-rev0.7z"
        fi
    fi

elif [ $1 = "android" ]; then

    os="default"

    compiler="default"
else
    compiler="default"

    os="default"
fi

NDK="$external/NDK/$NDK_version"

#--------------------------------------------------------------------------------------------------

boost="https://dl.bintray.com/boostorg/release/$Boost_versionA/source/boost_$Boost_versionB.zip"

libtorrent="https://github.com/arvidn/libtorrent/releases/download/libtorrent-$libtorrent_versionB/libtorrent-rasterbar-$libtorrent_versionA.tar.gz"

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

echo ""
echo "DOWNLOADING libtorrent"
echo $libtorrent

curl -L -o libtorrent.tar.gz $libtorrent

echo ""

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

        path="$MinGW"/Tools/mingw"$MinGW_versionB"_32
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

if [ $1 = "android" ]; then

    cp android/user-config.jam boost/tools/build/src
fi

#--------------------------------------------------------------------------------------------------
# libtorrent
#--------------------------------------------------------------------------------------------------

echo "EXTRACTING libtorrent"

test -d libtorrent && rm -rf libtorrent

tar -xf libtorrent.tar.gz

rm libtorrent.tar.gz

mv libtorrent-rasterbar-$libtorrent_versionA libtorrent

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

    export COMPILER="$NDK"/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi29-clang++

    buildAndroid androidv7

    export COMPILER="$NDK"/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android29-clang++

    buildAndroid androidv8

    export COMPILER="$NDK"/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android29-clang++

    buildAndroid android32

    export COMPILER="$NDK"/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android29-clang++

    buildAndroid android64
else
    cd boost/tools/build/src/engine

    sh build.sh gcc

    cd ../../../../../libtorrent

    if [ $compiler = "mingw" ]; then

        b2 -j4 toolset=gcc cxxflags=-std=c++11 variant=release link=shared openssl-version=pre1.1

    elif [ $compiler = "msvc" ]; then

        b2 -j4 toolset=msvc address-model=$target variant=release link=shared openssl-version=pre1.1

    elif [ $1 = "linux" ]; then
        # FIXME libtorrent 1.2.6 Linux: It seems b2 returns an error code, even when it succeeds.
        set +e

        b2 -j4 cxxflags=-std=c++11 variant=release link=shared openssl-version=pre1.1

        set -e
    else
        b2 -j4 cxxflags=-std=c++11 variant=release link=shared openssl-version=pre1.1 warnings-as-errors=off
    fi

    cd ..

    sh deploy.sh $1
fi
