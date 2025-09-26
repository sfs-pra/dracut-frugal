#!/bin/sh
#250926 sfs
# Mount squashed images from a image_dir like https://www.porteus.org/component/content/article/26-tutorials/general-info-tutorials/117-cheatcodes-what-they-are-and-how-to-use-them.html
# based on porteus-inirtd & https://github.com/josephvoss/dracut-lazsquash
#
# Inputs:
# dev_name: device to mount
# sfs: squashfs file extention (default: pfs)
# image_dir: directory containing .$sfs files
# overlay_size: size of overlayfs/aufs upperdir (tmpfs) to make
# root=asfs: use aufs instead of overlayfs (root=osfs)
#
# https://www.porteus.org/component/content/article/26-tutorials/general-info-tutorials/117-cheatcodes-what-they-are-and-how-to-use-them.html
# load=module[1];module[n]
# noload=

squashfs=/run/archroot/live/memory/images
images=/run/archroot/root_ro
overlay=/run/archroot/live/memory/changes

## Util functions
check_last_return() {
  if [ "$?" != "0" ]; then
    die "$@"
  fi
}

[ "$root" == "asfs" ] && use_aufs=true

param() { grep -E -qo " $1( |\$)" /proc/cmdline; }
param quiet && quiet="y"
msg2() { 
    [ "${quiet}" != "y" ] && echo "[1m""$@""[0m"
    echo "$@" >>/log-ls2
    if [ "${debug}" = "y" ] || [ "${step}" = "y" ] ;then
	[ "${quiet}" = "y" ] && echo "[1m""$@""[0m"
        echo -e "[1;33m"":: Debugging shell started. Ctrl+D: continue booting. Ctrl+Alt+Del: reboot""[0m" 
        sh 2>/dev/null 
    fi
}

## Mount partition
# Check for device
### Detect fs type
fstype=$(blkid -o value -s TYPE "$dev_name")
### Load needed fs type
[ -e "/sys/fs/$fstype" ] || modprobe "$fstype"
mkdir -p $images
mount -n -t "$fstype" -o ro "$dev_name" $images
check_last_return "Unable to mount device $dev_name! Exiting."

## Mount all .$sfs files from the directory
mkdir -p $squashfs

# Check if the directory exists
if ! [ -d "$images/$image_dir" ]; then
  die "Directory $image_dir not found on $dev_name! Exiting."
fi

# Find all .$sfs files in the directory and sort them
[ "$sfs" ] || sfs=pfs ; xzm="$sfs"

LOAD=`echo   "${load}" | sed 's/;/|/g'`; [ $LOAD ] || LOAD=._null
NOLOAD=`echo "${noload}" | sed 's/;/|/g'`; [ $NOLOAD ] || NOLOAD=._null
RAMMOD=`echo "${rammod}" | sed 's/;/|/g'`

aufs_root="$images/"
PTH="$aufs_root$image_dir"
find "$PTH"/base/ "$PTH"/modules/ -type f -regex .*'\.'$xzm''  | grep -E -v "$NOLOAD" |sort >/tmp/modules
msg2 ":: find "$PTH"/base/ "$PTH"/modules/ -type f -regex .*'\.'$xzm''"
msg2 ":: Search *.$xzm (noload=$NOLOAD) in $PTH base modules >>/tmp/modules ..."
find "$PTH"/optional/ -type f -regex .*'\.'$xzm'' 2>/dev/null | grep -E "$LOAD"  |sort >>/tmp/modules
msg2 ":: Search *.$xzm (load=$LOAD) in $PTH optional >>/tmp/modules ..."
    if [ "$extramod" ]; then
	EXTRAMOD1=`echo "$extramod" | sed 's/;/ /g'`
	for folder in $EXTRAMOD1; do
	    msg2 ":: search extramod : ${aufs_root}/${folder} ..."
	    if [ -d "${aufs_root}/$folder" ] ;then
		find "${aufs_root}/${folder}"/ -type f -regex .*'\.'$xzm'' 2>/dev/null | grep -E -v "$NOLOAD" |sort >>/tmp/modules
	    else
		err " not found extramod dir : ${aufs_root}/${folder} ... skip"
	    fi
	done
    fi

grep -Ev ''$sort2'/089-|/09[0-9]-' /tmp/modules >/tmp/modules1
grep -E  ''$sort2'/089-|/09[0-9]-' /tmp/modules | while read i; do
    i1=${i##*/}
    i2=${i%/*}
    echo "$i1$i2"
done | sort -n | while read i; do
    i1=${i#*/}
    i2=${i%%/*}
    echo "/$i1/$i2"
done >/tmp/modules2
#089 и 09х в верхний слой aufs
cat /tmp/modules1 /tmp/modules2 >/tmp/modules

#pfs_files=$(ls "$images/$image_dir"/*.$sfs 2>/dev/null | sort -r)
pfs_files=$(tac /tmp/modules)
if [ -z "$pfs_files" ]; then
  die "No .$sfs files found in $image_dir! Exiting."
fi

# Mount each .pfs file
image_mounts=()
for pfs_file in $pfs_files; do
  pfs_basename=$(basename "$pfs_file")
  mkdir -p "$squashfs/$pfs_basename"
  mount -n -t squashfs -o ro "$pfs_file" "$squashfs/$pfs_basename"
  check_last_return "Unable to mount squashed image $pfs_basename! Exiting."
  image_mounts+=( "$squashfs/$pfs_basename=ro" )
done

## Mount overlay or aufs
mkdir -p $overlay
mount_options=""
if ! [ -z "$overlay_size" ]; then
  mount_options+="-o size=$overlay_size"
fi
mount -n -t tmpfs $mount_options none $overlay/
check_last_return "Unable to mount ramdisk! Exiting."
mkdir $overlay/upper
mkdir $overlay/work

if [ "$use_aufs" = true ]; then
  # Mount using aufs
  echo "Mounting using aufs" > /dev/kmsg
#  aufs_dirs0="$overlay/upper"
  aufs_dirs0="$overlay"
    a2="="
    #init aufs:
  mount -t aufs -o nowarn_perm,br${a2}"$aufs_dirs0" none "$NEWROOT"
  for mount in "${image_mounts[@]}"; do
    mount -t aufs -o remount,append${a2}"${mount}"=rr+wh none "$NEWROOT"
  done
  check_last_return "Unable to mount aufs! Exiting."
else
  # Mount using overlayfs
  echo "Mounting using overlayfs" > /dev/kmsg
  IFS=: lower_dirs=$(echo "${image_mounts[@]}" | sed 's/=ro//g' | tr ' ' ':')
#  IFS=: lower_dirs=$(echo "${image_mounts[@]}" |sort -r | sed 's/=ro//g' | tr ' ' ':')
  IFS=$OIFS
  LIBMOUNT_FORCE_MOUNT2=always mount -n -t overlay \
    -o lowerdir="$lower_dirs",upperdir=$overlay/upper,workdir=$overlay/work \
    overlay "$NEWROOT"
  check_last_return "Unable to mount overlayfs! Exiting."
fi

## Bind mount squash, overlay, and image directories
mkdir -p "$NEWROOT$squashfs"
mkdir -p "$NEWROOT$overlay"
mkdir -p "$NEWROOT$images/"
mount --bind $squashfs "$NEWROOT$squashfs"
mount --bind $overlay/upper "$NEWROOT$overlay"
mount --bind $images "$NEWROOT$images"
