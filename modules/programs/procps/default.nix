{
  config.substrate.modules.programs.procps = {
    tags = [ "core:tools:system" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.procps ];
    };
  };
}
