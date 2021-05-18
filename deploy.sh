#!/bin/sh
set -e

#--------------------------------------------------------------------------------------------------
# Settings
#--------------------------------------------------------------------------------------------------

libtorrent_versionA="1.2.13"
libtorrent_versionB="10.0.0"

Boost_versionA="1.71.0"
Boost_versionB="1_71"

#--------------------------------------------------------------------------------------------------
# Windows

MinGW_versionA="7.3.0"
MinGW_versionB="73"

MSVC_versionA="14.2"
MSVC_versionB="142"

#--------------------------------------------------------------------------------------------------
# macOS

clang_version="12.0.0"

#--------------------------------------------------------------------------------------------------
# linux

# NOTE: Version 7 on Ubuntu 18.04 and 9 on 20.04.
gcc_version="*"

#--------------------------------------------------------------------------------------------------
# Syntax
#--------------------------------------------------------------------------------------------------

if [ $# != 1 ] \
   || \
   [ $1 != "win32" -a $1 != "win64" -a $1 != "win32-msvc" -a $1 != "win64-msvc" -a \
     $1 != "macOS" -a $1 != "linux" -a $1 != "androidv7"  -a $1 != "androidv8"  -a \
     $1 != "android32" -a $1 != "android64" ]; then

    echo "Usage: deploy <win32 | win64 | win32-msvc | win64-msvc | macOS | linux |"
    echo "               androidv7 | androidv8 | android32 | android64>"

    exit 1
fi

#--------------------------------------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------------------------------------

if [ $1 = "win32" -o $1 = "win64" -o $1 = "win32-msvc" -o $1 = "win64-msvc" ]; then

    os="windows"

    if [ $1 = "win32" -o $1 = "win64" ]; then

        compiler="mingw"
    else
        compiler="msvc"
    fi

    if [ $1 = "win32" -o $1 = "win32-msvc" ]; then

        target="32"
    else
        target="64"
    fi

elif [ $1 = "androidv7" -o $1 = "androidv8" -o $1 = "android32" -o $1 = "android64" ]; then

    os="android"

    compiler="default"

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

    compiler="default"
fi

#--------------------------------------------------------------------------------------------------
# Deploy
#--------------------------------------------------------------------------------------------------

echo "DEPLOYING"

path="deploy/Boost/$Boost_versionA"

if [ $os = "android" ]; then

    mkdir -p $path/$abi
else
    mkdir -p $path
fi

cp -r boost/boost $path/Boost

if [ $compiler = "mingw" ]; then

    cp boost/bin.v2/libs/system/build/gcc-$MinGW_versionA/release/cxxstd-14-iso/threading-multi/visibility-hidden/libboost_system-mgw$MinGW_versionB-mt-x$target-$Boost_versionB.dll.a \
    $path/libboost_system.a

    cp boost/bin.v2/libs/system/build/gcc-$MinGW_versionA/release/cxxstd-14-iso/threading-multi/visibility-hidden/libboost_system-mgw$MinGW_versionB-mt-x$target-$Boost_versionB.dll \
    $path/libboost_system.dll

elif [ $1 = "win32-msvc" ]; then

    cp boost/bin.v2/libs/system/build/msvc-$MSVC_versionA/release/cxxstd-14-iso/threading-multi/boost_system-vc$MSVC_versionB-mt-x$target-$Boost_versionB.lib \
    $path/boost_system.lib

    cp boost/bin.v2/libs/system/build/msvc-$MSVC_versionA/release/cxxstd-14-iso/threading-multi/boost_system-vc$MSVC_versionB-mt-x$target-$Boost_versionB.dll \
    $path/boost_system.dll

elif [ $1 = "win64-msvc" ]; then

    cp boost/bin.v2/libs/system/build/msvc-$MSVC_versionA/release/address-model-$target/cxxstd-14-iso/threading-multi/boost_system-vc$MSVC_versionB-mt-x$target-$Boost_versionB.lib \
    $path/boost_system.lib

    cp boost/bin.v2/libs/system/build/msvc-$MSVC_versionA/release/address-model-$target/cxxstd-14-iso/threading-multi/boost_system-vc$MSVC_versionB-mt-x$target-$Boost_versionB.dll \
    $path/boost_system.dll

elif [ $1 = "macOS" ]; then

    cp boost/bin.v2/libs/system/build/darwin-$clang_version/release/cxxstd-14-iso/threading-multi/visibility-hidden/libboost_system.dylib \
    $path/libboost_system.dylib

elif [ $1 = "linux" ]; then

    cp boost/bin.v2/libs/system/build/gcc-$gcc_version/release/cxxstd-14-iso/threading-multi/visibility-hidden/libboost_system.so.$Boost_versionA \
    $path/libboost_system.so

elif [ $os = "android" ]; then

    cp boost/bin.v2/libs/system/build/clang-linux-arm/release/cxxstd-14-iso/link-static/threading-multi/visibility-hidden/libboost_system.a \
    $path/$abi
fi

#--------------------------------------------------------------------------------------------------

path="deploy/libtorrent/$libtorrent_versionA"

if [ $os = "android" ]; then

    mkdir -p $path/$abi
else
    mkdir -p $path
fi

cp -r libtorrent/include/libtorrent $path

if [ $compiler = "mingw" ]; then

    cp libtorrent/bin/gcc-$MinGW_versionA/release/cxxstd-14-iso/threading-multi/libtorrent.dll.a \
    $path/libtorrent.a

    cp libtorrent/bin/gcc-$MinGW_versionA/release/cxxstd-14-iso/threading-multi/libtorrent-rasterbar.dll \
    $path

elif [ $compiler = "msvc" ]; then

    cp libtorrent/bin/msvc-$MSVC_versionA/release/address-model-$target/cxxstd-14-iso/threading-multi/torrent.lib \
    $path

    cp libtorrent/bin/msvc-$MSVC_versionA/release/address-model-$target/cxxstd-14-iso/threading-multi/torrent-rasterbar.dll \
    $path

elif [ $1 = "macOS" ]; then

    cp libtorrent/bin/darwin-$clang_version/release/cxxstd-14-iso/threading-multi/libtorrent-rasterbar.dylib.$libtorrent_versionB \
    $path/libtorrent-rasterbar.dylib

elif [ $1 = "linux" ]; then

    cp libtorrent/bin/gcc-$gcc_version/release/cxxstd-14-iso/threading-multi/libtorrent-rasterbar.so.$libtorrent_versionB \
    $path/libtorrent-rasterbar.so

elif [ $os = "android" ]; then

    cp libtorrent/bin/clang-linux-arm/release/cxxstd-14-iso/link-static/threading-multi/libtorrent-rasterbar.a \
    $path/$abi
fi
