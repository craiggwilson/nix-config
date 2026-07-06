{
  config.substrate.modules.programs.calibre = {
    tags = [ "gui" "users:craig:personal" ];

    homeManager =
      { pkgs, ... }:
      let
        fanficfareSrc = pkgs.fetchFromGitHub {
          owner = "JimmXinu";
          repo = "FanFicFare";
          rev = "5ffc5b90074d3faa2e299465c1f544bbf0fad66b";
          hash = "sha256-LPrZtFmyq9IzDTAP/FgZCEiZNDbAgxeP5NUFi/0W0Fg=";
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
