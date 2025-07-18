{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.prisma-access-browser;

  fhsEnv = pkgs.buildFHSEnv {
    name = "prisma-access-browser-bash";
    targetPkgs = pkgs: [
      pkgs.hdwlinux.prisma-access-browser-unwrapped
    ];
    includeClosures = true;
    privateTmp = true;
  };

  prisma-access-browser = pkgs.writeScriptBin "prisma-access-browser" ''
    #! ${pkgs.bash}/bin/sh

    "${fhsEnv}/bin/prisma-access-browser-bash" -c "PrismaAccessBrowser $*"
  '';

in
{
  options.hdwlinux.programs.prisma-access-browser = {
    enable = config.lib.hdwlinux.mkEnableOption "prisma-access-browser" false;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      prisma-access-browser
    ];
  };
}
