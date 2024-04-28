#!/bin/bash
# Based on https://gist.github.com/tobywf/aeeeee63053aaaa841b4032963406684

set -xeuo pipefail
IFS=$'\n\t'

PREFIX="${1:-/usr/local/dvisvgm}"
TEX="$(kpsewhich -var-value SELFAUTOLOC)"

echo "$PREFIX, $TEX"

brew install automake freetype ghostscript potrace pkgconfig

# download the sources
mkdir -p "$PREFIX/source/texk"
cd "$PREFIX/source/"

# see https://www.tug.org/texlive/svn/
rsync -av --exclude=.svn tug.org::tldevsrc/Build/source/build-aux .
rsync -av --exclude=.svn tug.org::tldevsrc/Build/source/texk/kpathsea texk/

git clone https://github.com/mgieseki/dvisvgm.git || (cd dvisvgm && git pull)

# compile kpathsea
cd texk/kpathsea

# patch SELFAUTOLOC
perl -0777 -i.bak \
    -pe 's|(kpathsea_selfdir \(kpathsea kpse, const_string argv0\)\n\{)|$1\n  return xstrdup("'"$TEX"'");\n|g' \
    progname.c
./configure --prefix="$PREFIX/"

make
make install

# compile dvisvgm
cd ../../dvisvgm

export LANG=C LC_CTYPE=C
export CPPFLAGS="-I$PREFIX/include/" LDFLAGS="-L$PREFIX/lib/" 

# ./autogen.sh
# begin autogen.sh from https://stackoverflow.com/a/8817650/200764 
case `uname` in Darwin*) glibtoolize --copy ;;
  *) libtoolize --copy ;; esac

autoheader
aclocal -I m4 --install
autoconf -vfi --warnings=all|| echo "Warning: autoconf has some error, safely ignoring IIUC"

automake --foreign --add-missing --force-missing --copy
# end autogen.sh

# patch ./configure
sed -i '' 's/^.*AX_CHECK_GNU_MAKE.*,AC_MSG_ERROR.*$/echo "not using GNU make that is needed for coverage"/' ./configure

./configure --enable-bundled-libs --enable-code-coverage=no --prefix="$PREFIX/"
make
make check
make install