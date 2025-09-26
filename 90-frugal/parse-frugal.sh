#!/bin/sh
#250924 sfs
[ -z "$root" ] && root=$(getarg root=)
dev_name=$(getarg dev=)
image_dir=$(getarg dir=)
overlay_size=$(getarg overlay_size=)
if [ "`echo $root |grep -E '[ao]sfs' `" ] ;then
 if  ! [ -z "dev_name" ] && \
  ! [ -z "image_dir" ]; then

  ## Wait for device and don't reload systemd
  wait_for_dev $dev_name

  rootok=1
 fi
fi
