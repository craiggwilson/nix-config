{
  config.substrate.modules.hardware.scanning = {
    tags = [ "scanning" ];
    nixos =
      { pkgs, ... }:
      {
        hardware.sane = {
          enable = true;
          extraBackends = [ pkgs.sane-airscan ];
        };
      };
  };
}
