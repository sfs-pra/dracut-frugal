#!/bin/sh

check() {
  # We have no deps
  return 0
}

depends() {
  # We have no deps
  # Scratch that. Img-lib would be nice to get tar
  echo base img-lib
  return 0
}

installkernel() {
  instmods loop squashfs overlay
}

install() {
  # Rsync is needed to build overlay from squash
  # blkid is needed to build mount dev
  inst_multiple blkid
  inst_multiple basename
  inst_multiple find
  inst_multiple grep
  inst_multiple sort
  inst_multiple tac
  inst_hook cmdline 90 "$moddir/parse-frugal.sh"
  inst_hook mount 90 "$moddir/mount-frugal.sh"
}
