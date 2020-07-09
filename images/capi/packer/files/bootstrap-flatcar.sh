#!/bin/bash
set -e

[[ "$BUILD_NAME" != *"flatcar"* ]] && exit 0

BINDIR="/opt/bin"
BUILDER_ENV="/opt/bin/builder-env"

mkdir -p $BINDIR

cd $BINDIR

if [[ -e $BINDIR/.bootstrapped ]]; then
  exit 0
fi

PYPY_VERSION=7.0.0

wget -O - https://bitbucket.org/squeaky/portable-pypy/downloads/pypy-$PYPY_VERSION-linux_x86_64-portable.tar.bz2 | tar -xjf -
mv -n pypy-$PYPY_VERSION-linux_x86_64-portable pypy2
ln -s ./pypy2/bin/pypy python2
ln -s ./pypy2/bin/pypy python

wget -O - https://bitbucket.org/squeaky/portable-pypy/downloads/pypy3.5-$PYPY_VERSION-linux_x86_64-portable.tar.bz2 | tar -xjf -
mv -n pypy3.5-$PYPY_VERSION-linux_x86_64-portable pypy3
ln -s ./pypy3/bin/pypy3 python3

$BINDIR/python --version

${BINDIR}/pypy2/bin/virtualenv-pypy ${BUILDER_ENV}
chown -R core ${BUILDER_ENV}

ln -s builder-env/bin/pip ${BINDIR}/pip

touch $BINDIR/.bootstrapped
