{ lib, ... }:
{
  config.substrate.modules.hardware.laptop = {
    provides = [ "hardware:laptop" ];
    tags = [ "laptop" ];

    nixos = {
      powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
    };
  };
}
