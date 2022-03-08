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

cat <<EOF | $CC -fcommon -xc -c -o $t/a.o -
#include <stdio.h>

int bar;

int main() {
  printf("%d\n", bar);
}
EOF

cat <<EOF | $CC -fcommon -xc -c -o $t/b.o -
int foo;
EOF

rm -f $t/c.a
ar rcs $t/c.a $t/b.o

cat <<EOF | $CC -fcommon -xc -c -o $t/d.o -
int foo;
int bar = 5;
int get_foo() { return foo; }
EOF

rm -f $t/e.a
ar rcs $t/e.a $t/d.o

$CC -B. -o $t/exe $t/a.o $t/c.a $t/e.a
$t/exe | grep -q 5

echo OK
