{
  config.substrate.modules.programs.calibre = {
    tags = [ "gui" "users:craig:personal" ];

    homeManager =
      { pkgs, ... }:
      let
        fanficfareSrc = pkgs.fetchFromGitHub {
          owner = "JimmXinu";
          repo = "FanFicFare";
          rev = "86832ac463d00ac6f1dfc10c94c47c0127c2a67c";
          hash = "sha256-UJx8cpVR+yev6xWecAMCPCn9LtExiY4wtom0QHluBhI=";
        };

        fanficfarePlugin = pkgs.runCommand "fanficfare-plugin" {
          nativeBuildInputs = [ pkgs.python3 pkgs.python3Packages.six pkgs.unzip ];
        } ''
          cp -r ${fanficfareSrc}/* .
          python makeplugin.py
          mkdir -p $out
          unzip FanFicFare.zip -d $out
        '';
      in
      {
        programs.calibre = {
          enable = true;
          plugins = [ "${fanficfarePlugin}" ];
        };
      };
  };
}
