{
  config.substrate.modules.ai.clients.skills.debussy = {
    tags = [
      "ai:clients"
      "users:craig:personal"
    ];

    homeManager =
      { pkgs, ... }:
      let
        python = pkgs.python3;
        pythonPkgs = python.pkgs;

        music21 = pythonPkgs.buildPythonPackage rec {
          pname = "music21";
          version = "10.3.0";

          src = pkgs.fetchurl {
            url = "https://files.pythonhosted.org/packages/fa/32/3790478438b1fdd0b9b5154e2ac6f91dce105743a26bf0bd20c04b1922ec/music21-10.3.0-py3-none-any.whl";
            hash = "sha256-97EhABQlN++WofPqVnylnfm1oMcyO5iOmwXFbFJUfuE=";
          };

          format = "wheel";

          propagatedBuildInputs = with pythonPkgs; [
            chardet
            joblib
            jsonpickle
            matplotlib
            more-itertools
            numpy
            requests
            webcolors
          ];

          doCheck = false;
        };

        verovio = pythonPkgs.buildPythonPackage rec {
          pname = "verovio";
          version = "6.2.1";

          src = pkgs.fetchurl {
            url = "https://files.pythonhosted.org/packages/e3/72/2fb4b56a1430d81d4f136ad8b40e78c42ec7d4dd109ffd61035bd3cb2dc7/verovio-6.2.1-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.whl";
            hash = "sha256-ALmrVR3oWfphrGfWpfTz2Xp/k4kZdkTZSTtenAt7aas=";
          };

          format = "wheel";

          doCheck = false;
        };

        debussy = pythonPkgs.buildPythonApplication {
          pname = "debussy";
          version = "0.2.0";

          src = pkgs.fetchFromGitHub {
            owner = "VjiaoBlack";
            repo = "claude-debussy";
            rev = "241e1d88a44f97d544e1b6c07cd0eb6b3b2aa7de";
            hash = "sha256-IrRNejNTkwPU3DCYa50IEinh71R/DmUHFgEvgsScUAI=";
          };

          format = "pyproject";

          nativeBuildInputs = with pythonPkgs; [ setuptools wheel ];

          propagatedBuildInputs = with pythonPkgs; [
            cairosvg
            pypdf
            music21
            verovio
          ];

          doCheck = false;
        };
      in
      {
        home.packages = [ pkgs.lilypond ];

        hdwlinux.ai.clients.skills.debussy = toString (pkgs.runCommand "debussy-skill" { } ''
          mkdir -p $out/bin
          cp -r ${./skill}/* $out/

          cat > $out/bin/debussy <<WRAPPER
          #!${pkgs.bash}/bin/bash
          exec ${debussy}/bin/debussy "$@"
          WRAPPER
          chmod +x $out/bin/debussy

          ${pkgs.gnused}/bin/sed -i "s|\$DEBUSSY|$out/bin/debussy|g" $out/SKILL.md
        '');
      };
  };
}
