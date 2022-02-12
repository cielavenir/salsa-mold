#!/bin/bash
export LANG=
set -e
CC="${CC:-cc}"
CXX="${CXX:-c++}"
testname=$(basename -s .sh "$0")
echo -n "Testing $testname ... "
cd "$(dirname "$0")"/../..
mold="$(pwd)/mold"
t=out/test/elf/$testname
mkdir -p $t

cat <<EOF | $CC -o $t/a.o -c -xc -fno-PIE -
extern const char readonly[100];
extern char readwrite[100];

int main() {
  return readonly[0] + readwrite[0];
}
EOF

cat <<EOF | $CC -fPIC -shared -o $t/b.so -xc -
const char readonly[100] = "abc";
char readwrite[100] = "abc";
EOF

$CC -B. $t/a.o $t/b.so -o $t/exe
readelf -a $t/exe > $t/log

grep -Pqz '(?s)\[(\d+)\] .dynbss.rel.ro .* \1 readonly' $t/log
grep -Pqz '(?s)\[(\d+)\] .dynbss .* \1 readwrite' $t/log

echo OK
