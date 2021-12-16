#!/bin/bash
set -e
cd $(dirname $0)
mold=`pwd`/../../mold
echo -n "Testing $(basename -s .sh $0) ..."
t=$(pwd)/../../out/test/elf/$(basename -s .sh $0)
mkdir -p $t

which dwarfdump >& /dev/null || { echo skipped; exit; }

cat <<EOF | g++ -c -o $t/a.o -g -gz=zlib-gnu -xc++ -
int main() {
  return 0;
}
EOF

cat <<EOF | g++ -c -o $t/b.o -g -gz=zlib -xc++ -
int foo() {
  return 0;
}
EOF

clang -fuse-ld=$mold -o $t/exe $t/a.o $t/b.o
dwarfdump $t/exe > /dev/null
readelf --sections $t/exe | fgrep -q .debug_info

echo ' OK'
