{
  config.substrate.modules.hardware.audio.production = {
    provides = [
      "hardware:audio:production"
      "audio:production"
    ];
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
