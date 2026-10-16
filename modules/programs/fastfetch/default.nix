{
  config.substrate.modules.programs.fastfetch = {
    provides = [ "core:utils" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.fastfetch ];
    };
  };
}
