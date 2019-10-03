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
# Syntax
#--------------------------------------------------------------------------------------------------

if [ $# != 1 ] || [ $1 != "win32" -a $1 != "win64" ]; then

    echo "Usage: configure <win32 | win64>"

    exit 1
fi

#--------------------------------------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------------------------------------

MinGW="$external/$1/MinGW/$MinGW_versionA"

#--------------------------------------------------------------------------------------------------

thirdparty="http://omega.gg/get/Sky/3rdparty/$1"

boost="https://dl.bintray.com/boostorg/release/$Boost_versionA/source/boost_$Boost_versionB.zip"

libtorrent="https://github.com/arvidn/libtorrent/releases/download/libtorrent-$libtorrent_versionB/libtorrent-rasterbar-$libtorrent_versionA.tar.gz"

#--------------------------------------------------------------------------------------------------
# Download
#--------------------------------------------------------------------------------------------------

echo ""
echo "DOWNLOADING 3rdparty"
echo $thirdparty
curl -L -o ../3rdparty.zip $thirdparty

echo ""
echo "DOWNLOADING boost"
echo $boost
curl -L -o boost.zip $boost

echo ""
echo "DOWNLOADING libtorrent"
echo $libtorrent
curl -L -o libtorrent.tar.gz $libtorrent

#--------------------------------------------------------------------------------------------------
# 3rdparty
#--------------------------------------------------------------------------------------------------

cd ..

unzip 3rdparty.zip

cd -

#--------------------------------------------------------------------------------------------------
# MinGW
#--------------------------------------------------------------------------------------------------

cp -r $MinGW MinGW

#--------------------------------------------------------------------------------------------------
# Boost
#--------------------------------------------------------------------------------------------------

unzip boost.zip

mv boost_$Boost_versionB boost

#--------------------------------------------------------------------------------------------------
# libtorrent
#--------------------------------------------------------------------------------------------------

tar -xf libtorrent.tar.gz

mv libtorrent-rasterbar-$libtorrent_versionA libtorrent

#--------------------------------------------------------------------------------------------------
# Build
#--------------------------------------------------------------------------------------------------

cmd < build.bat

#--------------------------------------------------------------------------------------------------
# Deploy
#--------------------------------------------------------------------------------------------------

path="deploy/Boost/$Boost_versionA"

mkdir -p "$path"

cp -r boost/boost "$path"/Boost

if [ $1 = "win32" ]; then

    cp boost/bin.v2/libs/system/build/gcc-$MinGW_versionA/release/threading-multi/visibility-hidden/libboost_system-mgw$MinGW_versionB-mt-x86-$Boost_versionC.dll.a \
    "$path"/libboost_system.a

    cp boost/bin.v2/libs/system/build/gcc-$MinGW_versionA/release/threading-multi/visibility-hidden/libboost_system-mgw$MinGW_versionB-mt-x86-$Boost_versionC.dll \
    "$path"/libboost_system.dll
else
    cp boost/bin.v2/libs/system/build/gcc-$MinGW_versionA/release/threading-multi/visibility-hidden/libboost_system-mgw$MinGW_versionB-mt-x64-$Boost_versionC.dll.a \
    "$path"/libboost_system.a

    cp boost/bin.v2/libs/system/build/gcc-$MinGW_versionA/release/threading-multi/visibility-hidden/libboost_system-mgw$MinGW_versionB-mt-x64-$Boost_versionC.dll \
    "$path"/libboost_system.dll
fi

#--------------------------------------------------------------------------------------------------

path="deploy/libtorrent/$libtorrent_versionA"

mkdir -p "$path"

cp -r libtorrent/include/libtorrent "$path"

cp libtorrent/bin/gcc-$MinGW_versionA/release/threading-multi/libtorrent.dll.a "$path"/libtorrent.a
cp libtorrent/bin/gcc-$MinGW_versionA/release/threading-multi/libtorrent.dll   "$path"
