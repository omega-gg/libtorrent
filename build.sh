#!/bin/sh
set -e

#--------------------------------------------------------------------------------------------------
# Settings
#--------------------------------------------------------------------------------------------------

external="../3rdparty"

#--------------------------------------------------------------------------------------------------

MinGW_versionA="7.3.0"
MinGW_versionB="73"

libtorrent_versionA="1.2.2"
libtorrent_versionB="1_2_2"

Boost_versionA="1.71.0"
Boost_versionB="1_71_0"
Boost_versionC="1_71"

#--------------------------------------------------------------------------------------------------
# linux

gcc_version="7"

#--------------------------------------------------------------------------------------------------
# macOS

darwin_version="4.2.1"

#--------------------------------------------------------------------------------------------------
# Syntax
#--------------------------------------------------------------------------------------------------

if [ $# != 1 ] || [ $1 != "win32" -a $1 != "win64" -a $1 != "linux" -a $1 != "macOS" ]; then

    echo "Usage: build <win32 | win64 | linux | macOS>"

    exit 1
fi

#--------------------------------------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------------------------------------

if [ $1 = "win32" -o $1 = "win64" ]; then

    windows=true
else
    windows=false
fi

MinGW="$external/$1/MinGW/$MinGW_versionA"

#--------------------------------------------------------------------------------------------------

thirdparty="http://omega.gg/get/Sky/3rdparty/$1"

boost="https://dl.bintray.com/boostorg/release/$Boost_versionA/source/boost_$Boost_versionB.zip"

libtorrent="https://github.com/arvidn/libtorrent/releases/download/libtorrent-$libtorrent_versionB/libtorrent-rasterbar-$libtorrent_versionA.tar.gz"

#--------------------------------------------------------------------------------------------------
# Download
#--------------------------------------------------------------------------------------------------

echo ""
echo "DOWNLOAD boost"
echo $boost
curl -L -o boost.zip $boost

echo ""
echo "DOWNLOAD libtorrent"
echo $libtorrent
curl -L -o libtorrent.tar.gz $libtorrent

if [ $windows = true ]; then

    echo ""
    echo "DOWNLOAD 3rdparty"
    echo $thirdparty
    curl -L -o ../3rdparty.zip --retry 3 $thirdparty
fi

#--------------------------------------------------------------------------------------------------
# 3rdparty
#--------------------------------------------------------------------------------------------------

if [ $windows = true ]; then

    cd ..

    unzip -q 3rdparty.zip

    cd -
fi

#--------------------------------------------------------------------------------------------------
# MinGW
#--------------------------------------------------------------------------------------------------

if [ $windows = true ]; then

    cp -r $MinGW MinGW
fi

#--------------------------------------------------------------------------------------------------
# Boost
#--------------------------------------------------------------------------------------------------

unzip -q boost.zip

mv boost_$Boost_versionB boost

#--------------------------------------------------------------------------------------------------
# libtorrent
#--------------------------------------------------------------------------------------------------

tar -xf libtorrent.tar.gz

mv libtorrent-rasterbar-$libtorrent_versionA libtorrent

#--------------------------------------------------------------------------------------------------
# Build
#--------------------------------------------------------------------------------------------------

if [ $windows = true ]; then

    cmd < windows/build.bat
else
    sh unix/build.sh
fi

#--------------------------------------------------------------------------------------------------
# Deploy
#--------------------------------------------------------------------------------------------------

path="deploy/Boost/$Boost_versionA"

mkdir -p "$path"

cp -r boost/boost "$path"/Boost

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

elif [ $1 = "linux" ]; then

    cp boost/bin.v2/libs/system/build/gcc-$gcc_version/release/threading-multi/visibility-hidden/libboost_system.so.$Boost_versionA \
    "$path"/libboost_system.so

elif [ $1 = "macOS" ]; then

    cp boost/bin.v2/libs/system/build/darwin-$darwin_version/release/threading-multi/visibility-hidden/libboost_system.dylib \
    "$path"/libboost_system.dylib
fi

#--------------------------------------------------------------------------------------------------

path="deploy/libtorrent/$libtorrent_versionA"

mkdir -p "$path"

cp -r libtorrent/include/libtorrent "$path"

if [ $windows = true ]; then

    cp libtorrent/bin/gcc-$MinGW_versionA/release/threading-multi/libtorrent.dll.a \
    "$path"/libtorrent.a

    cp libtorrent/bin/gcc-$MinGW_versionA/release/threading-multi/libtorrent.dll "$path"

elif [ $1 = "linux" ]; then

    cp libtorrent/bin/gcc-$gcc_version/release/threading-multi/libtorrent.so.$libtorrent_versionA \
    "$path"/libtorrent.so

elif [ $1 = "macOS" ]; then

    cp libtorrent/bin/darwin-$darwin_version/release/threading-multi/libtorrent.dylib.$libtorrent_versionA \
    "$path"/libtorrent.dylib
fi
