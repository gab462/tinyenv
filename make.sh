#!/bin/sh

set -xe

ROOT=$PWD

mkdir src build usr
cd build

git clone https://git.musl-libc.org/git/musl $ROOT/src/musl --depth 1
$ROOT/src/musl/configure --prefix=$ROOT/usr
make -j4
make install

git clone https://repo.or.cz/tinycc.git ../src/tinycc --depth 1
$ROOT/src/tinycc/configure --tcc-switches='-static' --prefix=$ROOT/usr --config-musl --sysroot=$ROOT --crtprefix=$ROOT/usr/lib
make -j4
make install

ln -s $ROOT/usr/lib/ $ROOT/usr/lib64

TCC="$ROOT/usr/bin/tcc"

$ROOT/src/tinycc/configure --cc=$TCC --tcc-switches='-static' --prefix=$ROOT/usr --config-musl --sysroot=$ROOT --crtprefix=$ROOT/usr/lib
make -j4
make install

git clone https://github.com/lua/lua.git $ROOT/src/lua --depth 1
sed -i 's/ -Wl,-E//' $ROOT/src/lua/makefile
make -C $ROOT/src/lua CC=$TCC
cp $ROOT/src/lua/lua $ROOT/usr/bin
cp $ROOT/src/lua/liblua.a $ROOT/usr/lib
cp $ROOT/src/lua/lua.h $ROOT/usr/include
cp $ROOT/src/lua/luaconf.h $ROOT/usr/include
cp $ROOT/src/lua/lualib.h $ROOT/usr/include
cp $ROOT/src/lua/lauxlib.h $ROOT/usr/include

git clone https://github.com/edubart/nelua-lang.git $ROOT/src/nelua
sed -i 's/ -Wl,-E//' $ROOT/src/nelua/Makefile
make -C $ROOT/src/nelua CC=$TCC
make -C $ROOT/src/nelua install PREFIX=$ROOT/usr

git clone https://github.com/mauke/unibilium.git $ROOT/src/unibilium --depth 1
$TCC -D TERMINFO_DIRS='"/etc/terminfo:/usr/share/terminfo"' -c $ROOT/src/unibilium/*.c
$TCC -ar libunibilium.a unibilium.o uninames.o uniutil.o
cp libunibilium.a $ROOT/usr/lib
cp $ROOT/src/unibilium/unibilium.h $ROOT/usr/include

curl -LO http://www.leonerd.org.uk/code/libtermkey/libtermkey-0.22.tar.gz
tar xf libtermkey-0.22.tar.gz -C $ROOT/src/
$TCC -DHAVE_UNIBILIUM -c $ROOT/src/libtermkey-0.22/termkey.c $ROOT/src/libtermkey-0.22/driver-csi.c $ROOT/src/libtermkey-0.22/driver-ti.c
$TCC -ar libtermkey.a termkey.o driver-csi.o driver-ti.o
cp libtermkey.a $ROOT/usr/lib
cp $ROOT/src/libtermkey-0.22/termkey.h $ROOT/usr/include

git clone https://github.com/martanne/vis.git $ROOT/src/vis --depth 1
sed -i '1i#include <stdio.h>' $ROOT/src/vis/ui-terminal.c
make -C $ROOT/src/vis DESTDIR=$ROOT/usr/ CC=$TCC CONFIG_CURSES=0 CONFIG_LUA=0 LDFLAGS_VIS='-ltermkey -lunibilium'
make -C $ROOT/src/vis install DESTDIR=$ROOT/usr/
