#!/bin/sh
set -e

#--------------------------------------------------------------------------------------------------
# Settings
#--------------------------------------------------------------------------------------------------

external="$PWD/../3rdparty"

#--------------------------------------------------------------------------------------------------

MinGW_versionA="7.3.0"
MinGW_versionB="73"

libtorrent_versionA="1.2.2"
libtorrent_versionB="1_2_2"

Boost_versionA="1.71.0"
Boost_versionB="1_71_0"
Boost_versionC="1_71"

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
    external="$PWD/../3rdparty/android64"
else
    os="default"
fi

MinGW="$external/MinGW/$MinGW_versionA"

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
# MinGW
#--------------------------------------------------------------------------------------------------

if [ $os = "windows" ]; then

    cp -r "$MinGW" MinGW
fi

#--------------------------------------------------------------------------------------------------
# Boost
#--------------------------------------------------------------------------------------------------

test -d boost && rm -rf boost

unzip -q boost.zip

mv boost_$Boost_versionB boost

#--------------------------------------------------------------------------------------------------
# libtorrent
#--------------------------------------------------------------------------------------------------

test -d libtorrent && rm -rf libtorrent

tar -xf libtorrent.tar.gz

mv libtorrent-rasterbar-$libtorrent_versionA libtorrent

#--------------------------------------------------------------------------------------------------
# Boost configuration
#--------------------------------------------------------------------------------------------------

if [ $1 = "android" ]; then

#    if [ $1 = "androidv7" ]; then

#        export COMPILER="$NDK"/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi29-clang++

#    elif [ $1 = "androidv8" ]; then

#        export COMPILER="$NDK"/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android29-clang++

#    elif [ $1 = "android32" ]; then

#        export COMPILER="$NDK"/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android29-clang++

#    elif [ $1 = "android64" ]; then

#        export COMPILER="$NDK"/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android29-clang++
#    fi

    cp android/user-config.jam boost/tools/build/src
fi

#--------------------------------------------------------------------------------------------------
# Build
#--------------------------------------------------------------------------------------------------

if [ $os = "windows" ]; then

    PATH=$PWD/MinGW/bin:$PWD/boost/tools/build/src/engine:$PWD/boost:$PATH
else
    PATH=$PWD/boost/tools/build/src/engine:$PWD/boost:$PATH
fi

export BOOST_BUILD_PATH=$PWD/boost/tools/build/src

export BOOST_ROOT=$PWD/boost

cd boost/tools/build/src/engine

sh build.sh gcc

cd ../../../../../libtorrent

if [ $os = "windows" ]; then

    b2 -j4 toolset=gcc cxxflags=-std=c++11 variant=release link=shared openssl-version=pre1.1

    cd ..

    sh deploy.sh $1

elif [ $1 = "android" ]; then

    export COMPILER="$NDK"/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi29-clang++

    b2 clang-arm -j4 cxxflags="-std=c++11 -fPIC -DANDROID" variant=release link=static \
                                                                           openssl-version=pre1.1

    cd ..

    sh deploy.sh androidv7

    rm -rf boost/bin.v2
    rm -rf libtorrent/bin

    cd libtorrent

    export COMPILER="$NDK"/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android29-clang++

    b2 clang-arm -j4 cxxflags="-std=c++11 -fPIC -DANDROID" variant=release link=static \
                                                                           openssl-version=pre1.1

    cd ..

    sh deploy androidv8
else
    b2 -j4 cxxflags=-std=c++11 variant=release link=shared openssl-version=pre1.1

    cd ..

    sh deploy.sh $1
fi
