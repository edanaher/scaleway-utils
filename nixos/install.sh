#!/bin/bash

## Rough outline taken from https://nixos.org/wiki/NixOS_on_ARM, 2015-09-04 or so.

export PS4="\[\033[32;1m++++\[\033[0m "
set -ex

MOUNTPOINT=/mnt/new
CHANNEL=nixos-15.09

function install_nix() {
  getent passwd nixbld10 > /dev/null && which nix-env && return
  # nix deps
  apt-get update
  apt-get install -y --force-yes libbz2-dev libsqlite3-dev libcurl4-openssl-dev libdbd-sqlite3-perl libwww-curl-perl g++ sqlite3 pkg-config patch git

  # nix itself
  wget -c http://nixos.org/releases/nix/nix-1.10/nix-1.10.tar.xz
  tar -xvf nix-1.10.tar.xz
  (
    cd nix-1.10
    ./configure
    make -j 4 # Change 4 to the number of cores your system has.
    # Wait 3 minutes.
    make install
  )

  # add users
  getent group nixbld > /dev/null || groupadd -r nixbld
  for n in $(seq 1 10); do
      getent passwd nixbld$n && continue
      useradd -c "Nix build user $n" \
      -d /var/empty -g nixbld -G nixbld -M -N -r -s "$(which nologin)" \
        nixbld$n
   done
}

function setup_store() {
  mkdir -p /nix
  mkdir -p ${MOUNTPOINT}/nix
  mount | grep /nix || mount -obind ${MOUNTPOINT}/nix /nix
}

function setup_channel() {
  mkdir -p /nix/store
  mkdir -p /mnt/new/nix/store
  mount --bind /mnt/new/nix/store /nix/store
  nix-channel --remove nixos
  nix-channel --add https://nixos.org/channels/${CHANNEL}
  nix-channel --update
#[ -d /nixpkgs ] || git clone https://github.com/NixOS/nixpkgs.git /nixpkgs
}

export NIXOS_CONFIG=/etc/nixos/configuration.nix
function install_installers() {
  mkdir -p /etc/nixos
  cp configuration.nix /etc/nixos

  nix-env -i -K --no-build-output \
    -j 4 --cores 4 -f /root/.nix-defexpr/channels/${CHANNEL}/nixpkgs/nixos \
    -A config.system.build.nixos-install \
    -A config.system.build.nixos-option \
    -A config.system.build.nixos-generate-config 
}

function install_nixos() {
  [ -L $HOME/.nix-profile ] || ln -s /nix/var/nix/profiles/default/ $HOME/.nix-profile
  export NIX_LINK="$HOME/.nix-profile"
  export PATH=$NIX_LINK/bin:$NIX_LINK/sbin:$PATH

  mkdir -p `dirname ${MOUNTPOINT}/$NIXOS_CONFIG`
  cp configuration.nix ${MOUNTPOINT}/$NIXOS_CONFIG
  # This is necessary for some reason.
  # From https://botbot.me/freenode/nixos/2015-05-07/?page=9
  # echo 0 > /proc/sys/vm/mmap_min_addr
  export NIX_PATH=/root/.nix-defexpr/channels/nixos-15.09
  nixos-install --root ${MOUNTPOINT} \
    -j 4 --cores 4
  mkdir ${MOUNTPOINT}/root/.nixpkgs
  cp config.nix ${MOUNTPOINT}/root/.nixpkgs/config.nix
}

function fixup() {
  mkdir /mnt/new/sbin
  ln -s /boot/default/init /mnt/new/sbin/init
}

install_nix
setup_store
setup_channel
install_installers
install_nixos
fixup
