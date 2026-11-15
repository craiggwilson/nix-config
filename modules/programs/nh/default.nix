{
  config.substrate.modules.programs.nh = {
    tags = [ "core:tools:nix" ];

    nixos = { config, ... }: {
      programs.nh = {
        enable = true;
        flake = config.hdwlinux.flake;
      };
    };
  };
}
