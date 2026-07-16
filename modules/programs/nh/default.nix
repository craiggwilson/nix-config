{
  config.substrate.modules.programs.nh = {

    nixos = { pkgs, config, ... }: {
      programs.nh = {
        enable = true;
        flake = config.hdwlinux.flake;
      };
    };
  };
}
