#!/bin/bash

## Rough outline taken from https://nixos.org/wiki/NixOS_on_ARM, 2015-09-04 or so.

export PS4="\[\033[32;1m++++\[\033[0m "
set -ex

MOUNTPOINT=/mnt/new

function install_nix() {
	# nix deps
	apt-get install -y --force-yes libbz2-dev libsqlite3-dev libcurl4-openssl-dev libdbd-sqlite3-perl libwww-curl-perl g++ sqlite3 pkg-config patch git

	# nix itself
	wget -c http://nixos.org/releases/nix/nix-1.10/nix-1.10.tar.xz
	tar -xvf nix-1.10.tar.xz
	cd nix-1.10
	./configure
	make -j 4 # Change 4 to the number of cores your system has.
	# Wait 3 minutes.
	make install

	# add users
	groupadd -r nixbld
	for n in $(seq 1 10); do useradd -c "Nix build user $n" \
	    -d /var/empty -g nixbld -G nixbld -M -N -r -s "$(which nologin)" \
		    nixbld$n; done
}

function setup_channel() {
	#nix-channel --add https://nixos.org/channels/nixos-unstable
	#nix-channel --update
	git clone https://github.com/NixOS/nixpkgs.git /nixpkgs
}

export NIXOS_CONFIG=/etc/nixos/configuration.nix
function install_installers() {
	mkdir -p /nix/store
	cp configuration.nix /etc/nixos

	nix-env -i -K \
	  -j 4 --cores 4 -f "/nixpkgs/nixos" \
	  -A config.system.build.nixos-install \
	  -A config.system.build.nixos-option \
	  -A config.system.build.nixos-generate-config 
}

function install_nixos() {
	[ -L $HOME/.nix-profile ] || ln -s /nix/var/nix/profiles/default/ $HOME/.nix-profile
	export NIX_LINK="$HOME/.nix-profile"
	export PATH=$NIX_LINK/bin:$NIX_LINK/sbin:$PATH
	mkdir -p ${MOUNTPOINT}/nixpkgs
	mount --bind /nixpkgs ${MOUNTPOINT}/nixpkgs

	mkdir -p `dirname ${MOUNTPOINT}/$NIXOS_CONFIG`
	cp configuration.nix ${MOUNTPOINT}/$NIXOS_CONFIG
	# This is necessary for some reason.
	# From https://botbot.me/freenode/nixos/2015-05-07/?page=9
	echo 0 > /proc/sys/vm/mmap_min_addr
	nixos-install --root ${MOUNTPOINT} \
	  -j 4 --cores 4
	mkdir ${MOUNTPOINT}/root/.nixpkgs
	cp config.nix ${MOUNTPOINT}/root/.nixpkgs/config.nix
}


install_nix
setup_channel
export NIX_PATH="/"
install_installers
install_nixos
