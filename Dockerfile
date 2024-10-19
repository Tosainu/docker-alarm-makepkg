# syntax=docker/dockerfile:1-labs

FROM --platform=$BUILDPLATFORM archlinux:latest@sha256:36e14d971d587c5cc7e2c832bd8789b27cabfd75e0be8e4f79bc162468c5043b AS pacstrap
ARG BUILDPLATFORM
ARG TARGETPLATFORM
ARG ARCHLINUXARM_PACKAGE_GPG=68B3537F39A313B3E574D06777193F152BDBE6A6
RUN --mount=type=tmpfs,target=/tmp \
  pacman-key --init && \
  pacman-key --populate archlinux && \
  pacman -Syy --noconfirm archlinux-keyring && \
  pacman -Su --noconfirm arch-install-scripts && \
  pacman-key --recv-keys "$ARCHLINUXARM_PACKAGE_GPG" && \
  pacman-key --finger "$ARCHLINUXARM_PACKAGE_GPG" && \
  pacman-key --lsign-key "$ARCHLINUXARM_PACKAGE_GPG" && \
  echo 'Server = https://ca.us.mirror.archlinuxarm.org/$arch/$repo' > /etc/pacman.d/mirrorlist_arm && \
  sed 's!\(/etc/pacman.d/mirrorlist\)!\1_arm! ; /NoExtract\s*=.*\betc\/pacman.conf\b.*/d' /etc/pacman.conf > /etc/pacman_arm.conf && \
  case "$TARGETPLATFORM" in \
  linux/arm64) \
    sed 's/\(Architecture\s*=\).\+$/\1 aarch64/' -i /etc/pacman_arm.conf ;; \
  linux/arm/v7) \
    sed 's/\(Architecture\s*=\).\+$/\1 armv7h/' -i /etc/pacman_arm.conf ;; \
  *) \
    exit 1 ;; \
  esac && \
  pacman -Syydd --noconfirm --config /etc/pacman_arm.conf --dbpath "$(mktemp -d)" archlinuxarm-keyring && \
  pacman-key --populate archlinuxarm
RUN --security=insecure \
  mkdir -p /rootfs && \
  mount --bind /rootfs /rootfs && \
  pacstrap -C /etc/pacman_arm.conf -G -M /rootfs base base-devel archlinux-keyring archlinuxarm-keyring git openssh && \
  echo '[options]' >> /rootfs/etc/pacman.conf && \
  grep '^NoExtract' /etc/pacman.conf >> /rootfs/etc/pacman.conf && \
  sed -i 's/^#\(en_US\.UTF-8\)/\1/' /rootfs/etc/locale.gen && \
  echo 'alarm ALL=(ALL) NOPASSWD: ALL' >> /rootfs/etc/sudoers && \
  rm -rf /rootfs/var/lib/pacman/sync/* /rootfs/var/cache/pacman/pkg/* && \
  arch-chroot /rootfs /usr/bin/locale-gen && \
  arch-chroot /rootfs /usr/bin/useradd -m -U alarm


FROM scratch
COPY --from=pacstrap /rootfs/ /
ENV LANG=en_US.UTF-8
USER alarm
CMD ["/usr/bin/bash"]
