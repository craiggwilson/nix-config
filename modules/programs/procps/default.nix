{
  config.substrate.modules.programs.procps = {
    provides = [ "core:utils" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.procps ];
    };
  };
}
