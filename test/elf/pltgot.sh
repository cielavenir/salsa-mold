#!/bin/bash
set -e
cd $(dirname $0)
mold=`pwd`/../../mold
echo -n "Testing $(basename -s .sh $0) ... "
t=$(pwd)/../../out/test/elf/$(basename -s .sh $0)
mkdir -p $t

[ $(uname -m) = x86_64 ] || { echo skipped; exit; }

cat <<EOF | cc -fPIC -shared -o $t/a.so -x assembler -
.globl ext1, ext2
ext1:
  nop
ext2:
  nop
EOF

cat <<EOF | cc -c -o $t/b.o -x assembler -
.globl _start
_start:
  call ext1@PLT
  call ext2@PLT
  mov ext2@GOTPCREL(%rip), %rax
  ret
EOF

$mold --pie -o $t/exe $t/b.o $t/a.so

objdump -d -j .plt.got $t/exe > $t/log

grep -Pq '1020:\s+ff 25 da 0f 00 00\s+jmp.*# 2000 <ext2>' $t/log

echo OK
