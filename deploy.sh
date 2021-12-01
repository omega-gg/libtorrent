#!/bin/sh
set -e

#--------------------------------------------------------------------------------------------------
# Settings
#--------------------------------------------------------------------------------------------------

libtorrent_versionA="2.0.5"
libtorrent_versionB="2.0"

Boost_versionA="1.71.0"
Boost_versionB="1_71"

#--------------------------------------------------------------------------------------------------
# Windows

MinGW_version="81"

MSVC_version="142"

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

    cp libtorrent/build/lib/libboost_system-mgw$MinGW_version-mt-x$target-$Boost_versionB.dll.a \
    $path/libboost_system.a

    cp libtorrent/build/lib/libboost_system-mgw$MinGW_version-mt-x$target-$Boost_versionB.dll \
    $path/libboost_system.dll

elif [ $1 = "win32-msvc" ]; then

    cp libtorrent/build/lib/boost_system-vc$MSVC_version-mt-x$target-$Boost_versionB.lib \
    $path/boost_system.lib

    cp libtorrent/build/lib/boost_system-vc$MSVC_version-mt-x$target-$Boost_versionB.dll \
    $path/boost_system.dll

elif [ $1 = "win64-msvc" ]; then

    cp libtorrent/build/lib/boost_system-vc$MSVC_version-mt-x$target-$Boost_versionB.lib \
    $path/boost_system.lib

    cp libtorrent/build/lib/boost_system-vc$MSVC_version-mt-x$target-$Boost_versionB.dll \
    $path/boost_system.dll

elif [ $1 = "macOS" ]; then

    cp libtorrent/build/lib/libboost_system.dylib $path/libboost_system.dylib

elif [ $1 = "linux" ]; then

    cp libtorrent/build/lib/libboost_system.so.$Boost_versionA $path/libboost_system.so

elif [ $os = "android" ]; then

    cp libtorrent/build/lib/libboost_system.a $path/$abi
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

    cp libtorrent/build/lib/libtorrent.dll.a $path/libtorrent.a

    cp libtorrent/build/lib/libtorrent-rasterbar.dll $path

elif [ $compiler = "msvc" ]; then

    cp libtorrent/build/lib/torrent.lib $path

    cp libtorrent/build/lib/torrent-rasterbar.dll $path

elif [ $1 = "macOS" ]; then

    cp libtorrent/build/lib/libtorrent-rasterbar.dylib.$libtorrent_versionB \
    $path/libtorrent-rasterbar.dylib

elif [ $1 = "linux" ]; then

    cp libtorrent/build/lib/libtorrent-rasterbar.so.$libtorrent_versionB \
    $path/libtorrent-rasterbar.so

elif [ $os = "android" ]; then

    # NOTE: This library is required when building against libtorrent-rasterbar.
    cp libtorrent/build/lib/libtry_signal.a $path/$abi

    cp libtorrent/build/lib/libtorrent-rasterbar.a $path/$abi
fi
