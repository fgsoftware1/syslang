#!/bin/bash
cd /home/baby/syslang

# Compile syslang source
./build/syslang tests/test.sl output.s

# Compile harness (single module)
rm -rf /tmp/c3c_test && mkdir -p /tmp/c3c_test
c3c compile-only tests/harness.c3 -o /tmp/c3c_test/harness.o --single-module=yes

# Link and run
gcc -o /tmp/c3c_test/test /tmp/c3c_test/harness.o output.s -ldl -lm
/tmp/c3c_test/test
echo "Exit code: $?"
