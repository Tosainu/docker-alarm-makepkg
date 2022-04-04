FROM --platform=$BUILDPLATFORM alpine:3.15.3 AS base
ARG BUILDPLATFORM
ARG TARGETPLATFORM
RUN \
  apk add --no-cache curl gnupg libarchive-tools && \
  case "$TARGETPLATFORM" in \
  linux/arm64) \
    PLATFORM=aarch64 ;; \
  linux/arm/v7) \
    PLATFORM=armv7 ;; \
  *) \
    exit 1 ;; \
  esac && \
  curl -LO http://os.archlinuxarm.org/os/ArchLinuxARM-$PLATFORM-latest.tar.gz && \
  curl -LO http://os.archlinuxarm.org/os/ArchLinuxARM-$PLATFORM-latest.tar.gz.sig && \
  gpg --recv-keys 68B3537F39A313B3E574D06777193F152BDBE6A6 && \
  gpg --verify ArchLinuxARM-$PLATFORM-latest.tar.gz.sig && \
  mkdir /rootfs && \
  bsdtar -xpf ArchLinuxARM-$PLATFORM-latest.tar.gz -C /rootfs && \
  rm ArchLinuxARM-$PLATFORM-latest.tar.gz ArchLinuxARM-$PLATFORM-latest.tar.gz.sig

FROM scratch AS pacstrap
COPY --from=base /rootfs/ /
RUN \
  pacman-key --init && \
  pacman-key --populate archlinuxarm && \
  pacman -Sy arch-install-scripts --needed --noconfirm && \
  mkdir -p /rootfs && \
  mkdir -m 0755 -p /rootfs/var/{cache/pacman/pkg,lib/pacman,log} && \
  mkdir -m 0755 -p /rootfs/{dev,run,etc/pacman.d} && \
  mkdir -m 1777 -p /rootfs/tmp && \
  mkdir -m 0555 -p /rootfs/{sys,proc} && \
  mkdir -p /rootfs/alpm-hooks/usr/share/libalpm/hooks && \
  bash -c "find /usr/share/libalpm/hooks -exec ln -sf /dev/null /rootfs/alpm-hooks{} \;" && \
  pacman -r /rootfs -Sy --noconfirm --noscriptlet \
    --hookdir /rootfs/alpm-hooks/usr/share/libalpm/hooks/ base base-devel && \
  sed -i 's/^#\(en_US\.UTF-8\)/\1/' /rootfs/etc/locale.gen && \
  ln -s /usr/lib/os-release /rootfs/etc/os-release && \
  echo 'alarm ALL=(ALL) NOPASSWD: ALL' >> /rootfs/etc/sudoers && \
  rm -rf /rootfs/alpm-hooks /rootfs/var/lib/pacman/sync/*

FROM scratch
COPY --from=pacstrap /rootfs/ /
RUN \
  ldconfig && \
  update-ca-trust && \
  locale-gen && \
  (ls usr/lib/sysusers.d/*.conf | /usr/share/libalpm/scripts/systemd-hook sysusers) && \
  useradd -m -U alarm
ENV LANG=en_US.UTF-8
USER alarm
CMD ["/usr/bin/bash"]
