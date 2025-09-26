pkgname=dracut-frugal
pkgver=r11.5bf5c1e
pkgrel=1
pkgdesc="Mount a squashfs image as the rootfs with a writable ramdisk in overlay."
arch=('any')
url="https://github.com/sfs-pra/dracut-frugal"
license=('GPL3')
source=("git+$url")
depends=("sh" "dracut")
sha256sums=('SKIP')

pkgver() {
    cd "$pkgname"
    printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

package() {
  cd "${pkgname}"
  install -Dm 644 90frugal/module-setup.sh    "${pkgdir}"/usr/lib/dracut/modules.d/90frugal/module-setup.sh
  install -Dm 644 90frugal/mount-frugal.sh "${pkgdir}"/usr/lib/dracut/modules.d/90frugal/mount-frugal.sh
  install -Dm 644 90frugal/parse-frugal.sh "${pkgdir}"/usr/lib/dracut/modules.d/90frugal/parse-frugal.sh
  install -Dm 644 README.md "${pkgdir}"/usr/share/doc/dracut-frugal/README.md
  install -Dm 644 build_initrd.sh "${pkgdir}"/usr/share/doc/dracut-frugal/build_initrd.sh
}

