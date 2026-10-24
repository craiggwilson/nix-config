{
  config.substrate.modules.hardware.scanning = {
    tags = [ "capability:scanning" ];
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
