#!/bin/bash
set -e
cd $(dirname $0)
mold=`pwd`/../../mold
echo -n "Testing $(basename -s .sh $0) ... "
t=$(pwd)/../../out/test/elf/$(basename -s .sh $0)
mkdir -p $t

[ $(uname -m) = x86_64 ] || { echo skipped; exit; }

cat <<'EOF' | cc -o $t/a.o -c -x assembler -
  .text
  .globl main
main:
  sub $8, %rsp
  lea msg(%rip), %rdi
  xor %rax, %rax
  call printf@PLT
  xor %rax, %rax
  add $8, %rsp
  ret

  .data
msg:
  .string "Hello world\n"
EOF

clang -fuse-ld=$mold -o $t/exe $t/a.o

readelf --sections $t/exe | fgrep -q '.got'
readelf --sections $t/exe | fgrep -q '.got.plt'

$t/exe | grep -q 'Hello world'

echo OK
