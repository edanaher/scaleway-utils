{ pkgs, config, ... }:

let
  scaleway-scripts = (import ./scaleway-scripts (with pkgs; { inherit stdenv bash curl; } ));
in
{
  boot = {
    initrd.kernelModules = [];
    kernelParams = [];
    kernelModules = [];
    kernelPackages = pkgs.linuxPackages;
    loader = {
      grub.enable = false;
      generationsDir = {
        enable = true;
        copyKernels = true;
      };
    };
  };
  sound.enable = false;
  fonts.fontconfig.enable = false;
  services = {
    nixosManual.enable = false;
    openssh.enable = true;
  };
  fileSystems = [
    { mountPoint = "/";
      device = "/dev/nbd0";
      options = "relatime";
      }
    ];
  nixpkgs.config = {
    platform = {
      name = "scaleway-c1";
      kernelMajor = "2.6";
      kernelHeadersBaseConfig = "defconfig";
      kernelBaseConfig = "defconfig";
      kernelArch = "arm";
      kernelAutoModules = false;
      kernelExtraConfig =
        ''
        '';
      kernelTarget = "zImage";
      uboot = null;
      gcc = {
        arch = "armv7-a";
        fpu = "vfpv3";
        float = "hard";
      };
    };
  };

  environment.systemPackages = [
    scaleway-scripts
    pkgs.screen
    pkgs.vim
  ];

  # TODO(edanaher): There's probably a better way to pass in scaleway-scripts.
  # But currying works!
  imports = [ (import ./scaleway-scripts/services.nix scaleway-scripts) ];

  # Avoid pulling in all of X.
  environment.noXlibs = true;

  # Build faster!
  nix.buildCores = 4;
  nix.maxJobs = 4;
  #swapDevices = [ { device = "/dev/mmcblk0p2"; } ];
}
