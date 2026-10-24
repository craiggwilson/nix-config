{ lib, ... }:
{
  config.substrate.modules.hardware.laptop = {
    tags = [ "role:laptop" ];

    nixos = {
      powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
    };
  };
}
