{
  config.substrate.modules.programs.fastfetch = {
    tags = [ "core:tools:system" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.fastfetch ];
    };
  };
}
