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

cat <<EOF | $CC -shared -o $t/a.so -xc -
int foo = 1;
EOF

cat <<EOF | $CC -shared -o $t/b.so -xc -
int bar = 1;
EOF

cat <<EOF | $CC -c -o $t/c.o -xc -
int main() {}
EOF

$CC -B. -o $t/exe $t/c.o -Wl,-as-needed \
  -Wl,-push-state -Wl,-no-as-needed $t/a.so -Wl,-pop-state $t/b.so

readelf --dynamic $t/exe > $t/log
fgrep -q a.so $t/log
! fgrep -q b.so $t/log || false

echo OK
