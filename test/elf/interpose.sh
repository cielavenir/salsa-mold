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

cat <<EOF | $CC -c -fPIC -o $t/a.o -xc -
#include <stdio.h>

void foo() {
  printf("Hello world\n");
}
EOF

$CC -B. -shared -o $t/b.so $t/a.o -Wl,-z,interpose
readelf --dynamic $t/b.so | grep -q 'Flags:.*INTERPOSE'

echo OK
