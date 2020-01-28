PATH=$PWD/boost/tools/build/src/engine:$PWD/boost:$PATH

export BOOST_BUILD_PATH=$PWD/boost/tools/build/src

export BOOST_ROOT=$PWD/boost

cd boost/tools/build/src/engine

sh build.sh gcc

cd ../../../../../libtorrent

b2 $1 -j4 cxxflags=-std=c++11 variant=release link=shared openssl-version=pre1.1
