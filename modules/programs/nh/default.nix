{
  config.substrate.modules.programs.nh = {
    provides = [ "core:nix" ];

    nixos = { config, ... }: {
      programs.nh = {
        enable = true;
        flake = config.hdwlinux.flake;
      };
    };
  };
}
