#!/bin/sh
kernel="`uname -r`"
  dracut --no-hostonly \
  --modules "bash frugal  kernel-modules kernel-modules-extra" \
  ./initrd-frugal-$kernel.zst $kernel
