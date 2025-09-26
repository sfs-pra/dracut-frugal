# dracut-frugal
Mount a local device containing multiple squashfs images (like in https://www.porteus.org). Mount a selected images as the rootfs (with overlayfs or aufs) with a writable ramdisk in overlay.

Boot parameters (also known as cheatcodes) are used to affect the booting process of system.  You can use these parameters to disable desired kinds of hardware detection, start  from a specific location, load additional modules, etc.

## dev_name=
device to mount: dev_name=/dev/sr0
## sfs=
squashfs file extention (default: pfs)
## image_dir=
directory containing .$sfs files
## overlay_size=
size of overlayfs/aufs upperdir (tmpfs) to make
## root=
use aufs (root=asfs) instead of overlayfs (root=osfs)

## https://www.porteus.org/component/content/article/26-tutorials/general-info-tutorials/117-cheatcodes-what-they-are-and-how-to-use-them.html
### load=
module[1];module[n]
### noload=
