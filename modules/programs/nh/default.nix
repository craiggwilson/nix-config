{
  config.substrate.modules.programs.nh = {
    tags = [ "profile:programming" ];

    nixos = { config, ... }: {
      programs.nh = {
        enable = true;
        flake = config.hdwlinux.flake;
      };
    };
  };
}
