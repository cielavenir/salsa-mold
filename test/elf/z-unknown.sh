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

"$mold" -z no-such-opt 2>&1 | grep -q 'unknown command line option: -z no-such-opt'
"$mold" -zno-such-opt 2>&1 | grep -q 'unknown command line option: -zno-such-opt'

echo OK
