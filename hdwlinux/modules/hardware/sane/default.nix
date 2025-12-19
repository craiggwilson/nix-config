{
  config.substrate.modules.hardware.sane = {
    tags = [ "scanning" ];
    nixos = { pkgs, ... }: {
      hardware.sane = {
        enable = true;
        extraBackends = [ pkgs.sane-airscan ];
      };
    };
  };
}

