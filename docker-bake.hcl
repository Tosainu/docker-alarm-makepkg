group "default" {
  targets = ["archlinux"]
}

mirrorlists_arm = <<-EOT
Server = https://ca.us.mirror.archlinuxarm.org/$arch/$repo
Server = http://mirror.archlinuxarm.org/$arch/$repo
EOT

mirrorlists_x86_64 = <<-EOT
Server = https://fastly.mirror.pkgbuild.com/$repo/os/$arch
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = https://ftpmirror.infania.net/mirror/archlinux/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
EOT

repos_arm = <<-EOT
[core]
${mirrorlists_arm}
[extra]
${mirrorlists_arm}
EOT

repos_x86_64 = <<-EOT
[core]
${mirrorlists_x86_64}
[extra]
${mirrorlists_x86_64}
EOT

target "archlinux" {
  dockerfile = "Dockerfile"
  target = "archlinux"
  name = "archlinux-${item.pacman_arch}"
  platforms = [item.platform]
  args = {
    PACMAN_ARCH = item.pacman_arch
    PACMAN_CONF_EXTRA = item.pacman_conf_extra
    PACMAN_KEYRING = item.pacman_keyring
    PACMAN_PACKAGES = item.pacman_packages
  }
  matrix = {
    item = [
      {
        pacman_arch = "aarch64"
        pacman_conf_extra = repos_arm
        pacman_keyring = "archlinuxarm-keyring"
        pacman_packages = "base archlinuxarm-keyring"
        platform = "linux/arm64"
      },
      {
        pacman_arch = "armv7h"
        pacman_conf_extra = repos_arm
        pacman_keyring = "archlinuxarm-keyring"
        pacman_packages = "base archlinuxarm-keyring"
        platform = "linux/arm/v7"
      },
      {
        pacman_arch = "x86_64"
        pacman_conf_extra = repos_x86_64
        pacman_keyring = "archlinux-keyring"
        pacman_packages = "base"
        platform = "linux/amd64"
      },
    ]
  }
}
