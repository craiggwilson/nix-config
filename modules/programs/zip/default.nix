{
  config.substrate.modules.programs.zip = {
    provides = [ "programs:zip" "core:utils" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [
        pkgs.zip
        pkgs.unzip
      ];
    };
  };
}
