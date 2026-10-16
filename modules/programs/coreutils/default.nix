{
  config.substrate.modules.programs.coreutils = {
    provides = [ "core:utils" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.coreutils ];
    };
  };
}
