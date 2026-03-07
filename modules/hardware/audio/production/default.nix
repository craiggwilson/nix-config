{
  config.substrate.modules.hardware.audio.production = {
    tags = [ "audio:production" ];
    nixos =
      { inputs, ... }:
      {
        imports = [ inputs.musnix.nixosModules.musnix ];

        musnix = {
          enable = true;
          rtcqs.enable = true;
        };
      };
  };
}
