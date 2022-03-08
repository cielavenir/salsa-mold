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

(! "$mold" -zfoo) 2>&1 | grep -q 'unknown command line option: -zfoo'
(! "$mold" -z foo) 2>&1 | grep -q 'unknown command line option: -z foo'
(! "$mold" -abcdefg) 2>&1 | grep -q 'unknown command line option: -abcdefg'
(! "$mold" --abcdefg) 2>&1 | grep -q 'unknown command line option: --abcdefg'

echo OK
