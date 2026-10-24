{
  config.substrate.modules.programs.zip = {
    tags = [ "core:tools:system" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [
        pkgs.zip
        pkgs.unzip
      ];
    };
  };
}
