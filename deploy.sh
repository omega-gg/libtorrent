#!/bin/sh
set -e

#--------------------------------------------------------------------------------------------------
# Settings
#--------------------------------------------------------------------------------------------------

MinGW_versionA="7.3.0"
MinGW_versionB="73"

libtorrent_version="1.2.2"

Boost_versionA="1.73.0"
Boost_versionB="1_73"

#--------------------------------------------------------------------------------------------------
# macOS

darwin_version="4.2.1"

#--------------------------------------------------------------------------------------------------
# linux

gcc_version="7"

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
    "Usage: deploy <win32 | win64 | macOS | linux | androidv7 | androidv8 | android32 | android64>"

    exit 1
fi

#--------------------------------------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------------------------------------

if [ $1 = "win32" -o $1 = "win64" ]; then

    os="windows"

elif [ $1 = "androidv7" -o $1 = "androidv8" -o $1 = "android32" -o $1 = "android64" ]; then

    os="android"

    if [ $1 = "androidv7" ]; then

        abi="armeabi-v7a"

    elif [ $1 = "androidv8" ]; then

        abi="arm64-v8a"

    elif [ $1 = "android32" ]; then

        abi="x86"

    elif [ $1 = "android64" ]; then

        abi="x86_64"
    fi
else
    os="default"
fi

#--------------------------------------------------------------------------------------------------
# Deploy
#--------------------------------------------------------------------------------------------------

echo "DEPLOYING"

path="deploy/Boost/$Boost_versionA"

mkdir -p $path

cp -r boost/boost $path/Boost

if [ $1 = "win32" ]; then

    cp boost/bin.v2/libs/system/build/gcc-$MinGW_versionA/release/threading-multi/visibility-hidden/libboost_system-mgw$MinGW_versionB-mt-x32-$Boost_versionB.dll.a \
    "$path"/libboost_system.a

    cp boost/bin.v2/libs/system/build/gcc-$MinGW_versionA/release/threading-multi/visibility-hidden/libboost_system-mgw$MinGW_versionB-mt-x32-$Boost_versionB.dll \
    "$path"/libboost_system.dll

elif [ $1 = "win64" ]; then

    cp boost/bin.v2/libs/system/build/gcc-$MinGW_versionA/release/threading-multi/visibility-hidden/libboost_system-mgw$MinGW_versionB-mt-x64-$Boost_versionB.dll.a \
    "$path"/libboost_system.a

    cp boost/bin.v2/libs/system/build/gcc-$MinGW_versionA/release/threading-multi/visibility-hidden/libboost_system-mgw$MinGW_versionB-mt-x64-$Boost_versionB.dll \
    "$path"/libboost_system.dll

elif [ $1 = "macOS" ]; then

    cp boost/bin.v2/libs/system/build/darwin-$darwin_version/release/threading-multi/visibility-hidden/libboost_system.dylib \
    "$path"/libboost_system.dylib

elif [ $1 = "linux" ]; then

    cp boost/bin.v2/libs/system/build/gcc-$gcc_version/release/threading-multi/visibility-hidden/libboost_system.so.$Boost_versionA \
    "$path"/libboost_system.so

elif [ $1 = "android" ]; then

    cp boost/bin.v2/libs/system/build/clang-linux-arm/release/link-static/visibility-hidden/libboost_system.a \
    "$path"/libboost_system_$abi.a
fi

#--------------------------------------------------------------------------------------------------

path="deploy/libtorrent/$libtorrent_version"

mkdir -p $path

cp -r libtorrent/include/libtorrent $path

if [ $os = "windows" ]; then

    cp libtorrent/bin/gcc-$MinGW_versionA/release/threading-multi/libtorrent.dll.a \
    "$path"/libtorrent.a

    cp libtorrent/bin/gcc-$MinGW_versionA/release/threading-multi/libtorrent.dll "$path"

elif [ $1 = "macOS" ]; then

    cp libtorrent/bin/darwin-$darwin_version/release/threading-multi/libtorrent.dylib.$libtorrent_version \
    "$path"/libtorrent.dylib

elif [ $1 = "linux" ]; then

    cp libtorrent/bin/gcc-$gcc_version/release/threading-multi/libtorrent.so.$libtorrent_version \
    "$path"/libtorrent.so

elif [ $1 = "android" ]; then

    cp libtorrent/bin/clang-linux-arm/release/link-static/threading-multi/libtorrent.a \
    "$path"/libtorrent_$abi.a
fi
