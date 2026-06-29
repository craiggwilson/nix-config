{
  config.substrate.modules.programs.calibre = {
    tags = [ "gui" "users:craig:personal" ];

    homeManager =
      { pkgs, ... }:
      let
        fanficfareSrc = pkgs.fetchFromGitHub {
          owner = "JimmXinu";
          repo = "FanFicFare";
          rev = "7021f866543a968452e287362e25147ab4703f72";
          hash = "sha256-eHDRHFiZcxwYx/AxXWYhXsspJW416t6mM0mdLJKDcVg=";
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
