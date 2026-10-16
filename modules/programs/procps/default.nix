{
  config.substrate.modules.programs.procps = {
    provides = [ "programs:procps" "core:utils" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.procps ];
    };
  };
}
