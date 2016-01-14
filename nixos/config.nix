{
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
    build-cores = 4;
    build-max-jobs = 4;
}
