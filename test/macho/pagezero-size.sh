#!/bin/bash
set -e
cd $(dirname $0)
mold=`pwd`/../../ld64.mold
echo -n "Testing $(basename -s .sh $0) ... "
t=$(pwd)/../../out/test/macho/$(basename -s .sh $0)
mkdir -p $t

[ "`uname -p`" = arm ] && { echo skipped; exit; }

cat <<EOF | cc -o $t/a.o -c -xc -
#include <stdio.h>
int main() {
  printf("Hello world\n");
}
EOF

clang -fuse-ld=$mold -o $t/exe $t/a.o

otool -l $t/exe | grep -A5 'segname __PAGEZERO' | \
  grep -q 'vmsize 0x0000000100000000'

clang -fuse-ld=$mold -o $t/exe $t/a.o -Wl,-pagezero_size,0x10000
$t/exe | grep -q 'Hello world'

otool -l $t/exe | grep -A5 'segname __PAGEZERO' | \
  grep -q 'vmsize 0x0000000000010000'

echo OK
