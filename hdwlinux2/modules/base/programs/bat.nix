{ config, ... }:
{
  flake.modules.homeManager.base = {
    programs.bat = {
      enable = true;
      config = {
        theme = "base16";
      };
    };
  };
}
