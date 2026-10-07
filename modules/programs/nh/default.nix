{
  config.substrate.modules.programs.nh = {

    nixos = { config, ... }: {
      programs.nh = {
        enable = true;
        flake = config.hdwlinux.flake;
      };
    };
  };
}
