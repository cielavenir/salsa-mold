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

cat <<EOF | $CC -c -o $t/a.o -ffunction-sections -fdata-sections -xc -
#include <stdio.h>

int bar() {
  return 5;
}

int foo1(int x) {
  return bar() + x;
}

int foo2(int x) {
  return bar() + x;
}

int foo3() {
  bar();
  return 5;
}

int main() {
  printf("%d %d\n", (long)foo1 == (long)foo2, (long)foo1 == (long)foo3);
  return 0;
}
EOF

$CC -B. -o $t/exe $t/a.o -Wl,-icf=all
$t/exe | grep -q '1 0'

echo OK
