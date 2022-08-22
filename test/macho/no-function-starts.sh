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
t=out/test/macho/$MACHINE/$testname
mkdir -p $t

cat <<EOF | $CC -o $t/a.o -c -xc -
int main() {}
EOF

clang --ld-path=./ld64 -o $t/exe1 $t/a.o
otool -l $t/exe1 | grep -q LC_FUNCTION_STARTS

clang --ld-path=./ld64 -o $t/exe2 $t/a.o -Wl,-no_function_starts
otool -l $t/exe2 > $t/log
! grep -q LC_FUNCTION_STARTS $t/log || false

echo OK
