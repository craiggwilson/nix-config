{
  config.substrate.modules.boot.v4l2loopback = {
    tags = [ "v4l2loopback" ];
    nixos = { config, ... }: {
      boot = {
        kernelModules = [ "v4l2loopback" ];
        extraModulePackages = [
          # The install step runs Kbuild's depmod, leaving a modules.alias/modules.dep
          # database in $out that collides with the kernel's own copies when
          # aggregateModules merges both into system.modulesTree. DEPMOD=true skips it;
          # aggregateModules regenerates the merged database anyway.
          # Upstream fix: nixpkgs PR #575861 (issue #576406). Drop once the lock has it.
          (config.boot.kernelPackages.v4l2loopback.overrideAttrs (_: {
            preBuild = "";
            installFlags = [
              "DEPMOD=true"
              "INSTALL_MOD_PATH=${placeholder "out"}"
            ];
          })).out
        ];
        extraModprobeConfig = ''
          options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
        '';
      };
    };
  };
}
