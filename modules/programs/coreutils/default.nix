{
  config.substrate.modules.programs.coreutils = {
    provides = [ "programs:coreutils" "core:utils" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.coreutils ];
    };
  };
}
