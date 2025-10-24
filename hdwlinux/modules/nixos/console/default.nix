{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.conosle;
in
{

  options.hdwlinux.conosle = {
    enable = lib.hdwlinux.mkEnableOption "console" true;
  };

  config = lib.mkIf cfg.enable {
    console.colors = [
      "1e1e2e"
      "f38ba8"
      "a6e3a1"
      "f9e2af"
      "89b4fa"
      "f5c2e7"
      "94e2d5"
      "cdd6f4"

      "585b70"
      "f38ba8"
      "a6e3a1"
      "f9e2af"
      "89b4fa"
      "f5c2e7"
      "94e2d5"
      "b4befe"
    ];
  };
}
