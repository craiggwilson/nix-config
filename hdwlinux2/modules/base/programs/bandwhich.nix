{ config, ... }:
{
  flake.modules.nixos.base = {
    programs.bandwhich = {
      enable = true;
    };
  };
}
