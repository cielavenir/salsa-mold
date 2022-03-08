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

cat <<EOF | $CC -o $t/a.o -c -x assembler -
.globl main
main:
EOF

$CC -B. -o $t/exe $t/a.o

$CC -B. -o $t/exe $t/a.o -Wl,-z,cet-report=warning >& $t/log
grep -q 'a.o: -cet-report=warning: missing GNU_PROPERTY_X86_FEATURE_1_IBT' $t/log
grep -q 'a.o: -cet-report=warning: missing GNU_PROPERTY_X86_FEATURE_1_SHSTK' $t/log

! $CC -B. -o $t/exe $t/a.o -Wl,-z,cet-report=error >& $t/log
grep -q 'a.o: -cet-report=error: missing GNU_PROPERTY_X86_FEATURE_1_IBT' $t/log
grep -q 'a.o: -cet-report=error: missing GNU_PROPERTY_X86_FEATURE_1_SHSTK' $t/log

echo OK
