{
  config.substrate.modules.programs.nh = {
    provides = [ "programs:nh" "core:nix" ];

    nixos = { config, ... }: {
      programs.nh = {
        enable = true;
        flake = config.hdwlinux.flake;
      };
    };
  };
}
