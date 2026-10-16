{
  config.substrate.modules.programs.zip = {
    provides = [ "core:utils" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [
        pkgs.zip
        pkgs.unzip
      ];
    };
  };
}
