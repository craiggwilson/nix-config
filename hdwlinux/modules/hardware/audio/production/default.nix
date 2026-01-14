{
  config.substrate.modules.hardware.audio.production = {
    tags = [ "audio:production" ];
    nixos = {
      musnix = {
        enable = true;
        rtcqs.enable = true;
      };
    };
  };
}
