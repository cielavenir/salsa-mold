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

cat <<EOF | $CXX -c -o $t/a.o -xc++ -
int one() { return 1; }

struct Foo {
  int three() { static int x = 3; return x++; }
};

int a() {
  Foo x;
  return x.three();
}
EOF

cat <<EOF | $CXX -c -o $t/b.o -xc++ -
int two() { return 2; }

struct Foo {
  int three() { static int x = 3; return x++; }
};

int b() {
  Foo x;
  return x.three();
}
EOF

"$mold" --relocatable -o $t/c.o $t/a.o $t/b.o

[ -f $t/c.o ]
! [ -x t/c.o ] || false

cat <<EOF | $CXX -c -o $t/d.o -xc++ -
#include <iostream>

int one();
int two();

struct Foo {
  int three();
};

int main() {
  Foo x;
  std::cout << one() << " " << two() << " " << x.three() << "\n";
}
EOF

$CXX -B. -o $t/exe $t/c.o $t/d.o
$t/exe | grep -q '^1 2 3$'

echo OK
