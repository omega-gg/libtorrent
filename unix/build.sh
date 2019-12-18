PATH=$(pwd)/boost/tools/build/src/engine:$(pwd)/boost:$PATH

export BOOST_BUILD_PATH=$(pwd)/boost/tools/build/src

export BOOST_ROOT=$(pwd)/boost

cd boost/tools/build/src/engine

sh build.sh gcc

cd ../../../../../libtorrent

b2 -j4 cxxflags=-std=c++11 variant=release link=shared openssl-version=pre1.1
