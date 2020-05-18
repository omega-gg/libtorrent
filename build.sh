#!/bin/sh
set -e

#--------------------------------------------------------------------------------------------------
# Settings
#--------------------------------------------------------------------------------------------------

external="$PWD/../3rdparty"

#--------------------------------------------------------------------------------------------------

MinGW_version="7.3.0"

libtorrent_versionA="1.2.6"
libtorrent_versionB="1_2_6"

Boost_versionA="1.73.0"
Boost_versionB="1_73_0"

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

    b2 clang-arm -j4 cxxflags="-std=c++11 -fPIC -DANDROID" variant=release link=static \
                                                                           openssl-version=pre1.1

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
   [ $1 != "win32" -a $1 != "win64" -a $1 != "macOS" -a $1 != "linux" -a $1 != "android" ]; then

    echo \
    "Usage: build <win32 | win64 | macOS | linux | android>"

    exit 1
fi

#--------------------------------------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------------------------------------

external="$external/$1"

if [ $1 = "win32" -o $1 = "win64" ]; then

    os="windows"

elif [ $1 = "android" ]; then

    os="default"

    # FIXME
    external="$PWD/../3rdparty/android"
else
    os="default"
fi

MinGW="$external/MinGW/$MinGW_version"

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

if [ $1 = "linux" ] || [ $1 = "android" ]; then

    sudo apt-get -y install build-essential curl unzip

    echo ""
fi

#--------------------------------------------------------------------------------------------------
# Download
#--------------------------------------------------------------------------------------------------

echo "DOWNLOADING boost"
echo $boost

curl -L -o boost.zip $boost

echo ""
echo "DOWNLOADING libtorrent"
echo $libtorrent

curl -L -o libtorrent.tar.gz $libtorrent

#--------------------------------------------------------------------------------------------------
# Boost
#--------------------------------------------------------------------------------------------------

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

test -d libtorrent && rm -rf libtorrent

tar -xf libtorrent.tar.gz

rm libtorrent.tar.gz

mv libtorrent-rasterbar-$libtorrent_versionA libtorrent

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

    if [ $os = "windows" ]; then

        b2 -j4 toolset=gcc cxxflags=-std=c++11 variant=release link=shared openssl-version=pre1.1
    else
        # NOTE: Sometimes, it seems b2 returns an error code.
        set +e

        b2 -j4 cxxflags=-std=c++11 variant=release link=shared openssl-version=pre1.1

        set -e
    fi

    cd ..

    sh deploy.sh $1
fi
