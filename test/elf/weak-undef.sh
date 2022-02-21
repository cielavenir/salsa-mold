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

cat <<EOF | $CC -c -o $t/a.o -fPIC -xc -
#include <stdio.h>
__attribute__((weak)) int foo();
int main() {
  printf("%d\n", foo ? foo() : -1);
}
EOF

cat <<EOF | $CC -c -o $t/b.o -fno-PIC -xc -
#include <stdio.h>
__attribute__((weak)) int foo();
int main() {
  printf("%d\n", foo ? foo() : -1);
}
EOF

cat <<EOF | $CC -fcommon -xc -c -o $t/c.o -
int foo() { return 2; }
EOF

$CC -B. -o $t/exe1 $t/a.o -pie
$CC -B. -o $t/exe2 $t/b.o -no-pie
$CC -B. -o $t/exe3 $t/a.o $t/c.o -pie
$CC -B. -o $t/exe4 $t/b.o $t/c.o -no-pie

$t/exe1 | grep -q '^-1$'
$t/exe2 | grep -q '^-1$'
$t/exe3 | grep -q '^2$'
$t/exe4 | grep -q '^2$'

echo OK
