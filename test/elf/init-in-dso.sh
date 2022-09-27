#!/bin/bash
export LC_ALL=C
set -e
CC="${TEST_CC:-cc}"
CXX="${TEST_CXX:-c++}"
GCC="${TEST_GCC:-gcc}"
GXX="${TEST_GXX:-g++}"
OBJDUMP="${OBJDUMP:-objdump}"
MACHINE="${MACHINE:-$(uname -m)}"
testname=$(basename "$0" .sh)
echo -n "Testing $testname ... "
t=out/test/elf/$MACHINE/$testname
mkdir -p $t

cat <<EOF | $CC -shared -o $t/a.so -xc -
void foo() {}
EOF

cat <<EOF | $CC -o $t/b.o -c -xc -
void foo();
int main() {}
EOF

$CC -B. -o $t/exe $t/a.so $t/b.o -Wl,-init,foo
readelf --dynamic $t/exe > $t/log
! grep -Fq '(INIT)' $t/log || false

echo OK
