{
  config.substrate.modules.programs.nh = {

    nixos =
      {
        pkgs,
        config,
        lib,
        ...
      }:
      {
        config = lib.mkIf (config.hdwlinux.flake != null) {
          programs.nh = {
            enable = true;
            flake = config.hdwlinux.flake;
          };
        };
      };
  };
}
