#!/bin/bash
export LANG=
set -e
CC="${CC:-cc}"
CXX="${CXX:-c++}"
testname=$(basename "$0" .sh)
echo -n "Testing $testname ... "
cd "$(dirname "$0")"/../..
mold="$(pwd)/mold"
t=out/test/elf/$testname
mkdir -p $t

ldd "$mold"-wrapper.so | grep -q libasan && { echo skipped; exit; }

rm -rf $t
mkdir -p $t/bin $t/lib/mold
cp "$mold" $t/bin
cp "$mold"-wrapper.so $t/bin

$t/bin/mold -run bash -c 'echo $LD_PRELOAD' | grep -q '/bin/mold-wrapper.so'

echo OK
