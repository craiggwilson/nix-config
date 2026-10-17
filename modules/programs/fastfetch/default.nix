{
  config.substrate.modules.programs.fastfetch = {
    provides = [
      "programs:fastfetch"
      "core:utils"
    ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.fastfetch ];
    };
  };
}
