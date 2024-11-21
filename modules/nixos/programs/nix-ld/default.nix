{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.programs.nh;
in
{
  options.hdwlinux.programs.nh = {
    enable = lib.hdwlinux.mkBoolOpt config.hdwlinux.nix.enable "Whether to enable nh.";
  };

  config = lib.mkIf cfg.enable {
    programs.nix-ld = {
      enable = true;
    };
  };
}
