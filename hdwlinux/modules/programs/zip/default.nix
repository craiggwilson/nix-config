{
  config.substrate.modules.programs.zip = {
    nixos = { pkgs, ... }: {
      environment.systemPackages = [
        pkgs.zip
        pkgs.unzip
      ];
    };
  };
}

