{ lib, ... }:
{
  config.substrate.modules.hardware.laptop = {
    provides = [ "hardware:laptop" ];
    nixos = {
      powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
    };
  };
}
