#!/usr/bin/sh

bazel test $@ --experimental_enable_bzlmod --incompatible_enable_cc_toolchain_resolution //tests:all 
