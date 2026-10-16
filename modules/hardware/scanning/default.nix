{
  config.substrate.modules.hardware.scanning = {
    provides = [ "hardware:scanning" ];
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
