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
   [ $1 != "win32" -a $1 != "win64" -a $1 != "macOS" -a $1 != "linux" -a $1 != "androidv7" -a \
                                                                         $1 != "androidv8" -a \
                                                                         $1 != "android32" -a \
                                                                         $1 != "android64" ]; then

    echo \
    "Usage: build <win32 | win64 | macOS | linux | androidv7 | androidv8 | android32 | android64>"

    exit 1
fi

#--------------------------------------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------------------------------------

external="$external/$1"

if [ $1 = "win32" -o $1 = "win64" ]; then

    os="windows"

elif [ $1 = "androidv7" -o $1 = "androidv8" -o $1 = "android32" -o $1 = "android64" ]; then

    os="android"

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

if [ $1 = "linux" ] || [ $os = "android" ]; then

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

if [ $os = "android" ]; then

    if [ $1 = "androidv7" ]; then

        export COMPILER="$NDK"/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi29-clang++

    elif [ $1 = "androidv8" ]; then

        export COMPILER="$NDK"/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android29-clang++

    elif [ $1 = "android32" ]; then

        export COMPILER="$NDK"/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android29-clang++

    elif [ $1 = "android64" ]; then

        export COMPILER="$NDK"/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android29-clang++
    fi

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

elif [ $os = "android" ]; then

    b2 clang-arm -j4 cxxflags="-std=c++11 -fPIC -DANDROID" variant=release link=static \
                                                                           openssl-version=pre1.1
else
    b2 -j4 cxxflags=-std=c++11 variant=release link=shared openssl-version=pre1.1
fi

cd ..

#--------------------------------------------------------------------------------------------------
# Deploy
#--------------------------------------------------------------------------------------------------

echo "DEPLOYING"

path="deploy/Boost/$Boost_versionA"

mkdir -p $path

cp -r boost/boost $path/Boost

if [ $1 = "win32" ]; then

    cp boost/bin.v2/libs/system/build/gcc-$MinGW_versionA/release/threading-multi/visibility-hidden/libboost_system-mgw$MinGW_versionB-mt-x32-$Boost_versionC.dll.a \
    "$path"/libboost_system.a

    cp boost/bin.v2/libs/system/build/gcc-$MinGW_versionA/release/threading-multi/visibility-hidden/libboost_system-mgw$MinGW_versionB-mt-x32-$Boost_versionC.dll \
    "$path"/libboost_system.dll

elif [ $1 = "win64" ]; then

    cp boost/bin.v2/libs/system/build/gcc-$MinGW_versionA/release/threading-multi/visibility-hidden/libboost_system-mgw$MinGW_versionB-mt-x64-$Boost_versionC.dll.a \
    "$path"/libboost_system.a

    cp boost/bin.v2/libs/system/build/gcc-$MinGW_versionA/release/threading-multi/visibility-hidden/libboost_system-mgw$MinGW_versionB-mt-x64-$Boost_versionC.dll \
    "$path"/libboost_system.dll

elif [ $1 = "macOS" ]; then

    cp boost/bin.v2/libs/system/build/darwin-$darwin_version/release/threading-multi/visibility-hidden/libboost_system.dylib \
    "$path"/libboost_system.dylib

elif [ $1 = "linux" ]; then

    cp boost/bin.v2/libs/system/build/gcc-$gcc_version/release/threading-multi/visibility-hidden/libboost_system.so.$Boost_versionA \
    "$path"/libboost_system.so

elif [ $os = "android" ]; then

    cp boost/bin.v2/libs/system/build/clang-linux-arm/release/link-static/visibility-hidden/libboost_system.a \
    "$path"/libboost_system-$1.a
fi

#--------------------------------------------------------------------------------------------------

path="deploy/libtorrent/$libtorrent_versionA"

mkdir -p $path

cp -r libtorrent/include/libtorrent $path

if [ $os = "windows" ]; then

    cp libtorrent/bin/gcc-$MinGW_versionA/release/threading-multi/libtorrent.dll.a \
    "$path"/libtorrent.a

    cp libtorrent/bin/gcc-$MinGW_versionA/release/threading-multi/libtorrent.dll "$path"

elif [ $1 = "macOS" ]; then

    cp libtorrent/bin/darwin-$darwin_version/release/threading-multi/libtorrent.dylib.$libtorrent_versionA \
    "$path"/libtorrent.dylib

elif [ $1 = "linux" ]; then

    cp libtorrent/bin/gcc-$gcc_version/release/threading-multi/libtorrent.so.$libtorrent_versionA \
    "$path"/libtorrent.so

elif [ $os = "android" ]; then

    cp libtorrent/bin/clang-linux-arm/release/link-static/threading-multi/libtorrent.a \
    "$path"/libtorrent-$1.a
fi
