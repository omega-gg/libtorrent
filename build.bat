set PATH=%cd%\MinGW\bin;%cd%\boost\tools\build\src\engine\;%cd%\boost;%PATH%

set BOOST_BUILD_PATH=%cd%\boost\tools\build\src

set BOOST_ROOT=%cd%\boost

cd boost\tools\build\src\engine

call build.bat gcc

cd ..\..\..\..\..\libtorrent

b2.exe -j4 toolset=gcc cxxflags=-std=c++11 variant=release link=shared openssl-version=pre1.1
