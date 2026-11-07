{
  substrate.packages.debussy =
    { lib, pkgs, ... }:
    let
      python = pkgs.python3;
      pythonPkgs = python.pkgs;

      music21 = pythonPkgs.buildPythonPackage rec {
        pname = "music21";
        version = "10.5.2";

        src = pkgs.fetchurl {
          url = "https://files.pythonhosted.org/packages/be/a3/4948b2326e5957d54e3a754ee66d23d44126996986bb31eb47e22d06df9b/music21-10.5.2-py3-none-any.whl";
          hash = "sha256-26hpbq+rcJokS28YxkOZ7czPTpbd0eDk3n7/CikcLew=";
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

      bravura = pkgs.fetchurl {
        name = "Bravura.otf";
        url = "https://raw.githubusercontent.com/steinbergmedia/bravura/bravura-1.482/redist/otf/Bravura.otf";
        hash = "sha256-zfD4k+4f22S39nE9ce4Nz8NJwKwBQpqORRsBqeefXzs=";
      };

      verovio = pythonPkgs.buildPythonPackage rec {
        pname = "verovio";
        version = "6.4.1";

        src = pkgs.fetchurl {
          url = "https://files.pythonhosted.org/packages/03/22/c98513dfe1d31681080ea742d8a9a8e7dc83e68d9528b35913298687824e/verovio-6.4.1-cp310-abi3-manylinux2014_x86_64.manylinux_2_17_x86_64.whl";
          hash = "sha256-wZMR7CixE+F5tUd5K2CLkBUJu9BlYV2FvziyrTEUbhI=";
        };

        format = "wheel";

        nativeBuildInputs = [ pkgs.autoPatchelfHook ];

        buildInputs = [ pkgs.stdenv.cc.cc.lib ];

        postInstall = ''
          mkdir -p $out/lib/${python.libPrefix}/site-packages/verovio/data
          cp ${bravura} $out/lib/${python.libPrefix}/site-packages/verovio/data/Bravura.otf
        '';

        doCheck = false;
      };
    in
    pythonPkgs.buildPythonApplication {
      pname = "debussy";
      version = "0.2.0";

      src = pkgs.fetchFromGitHub {
        owner = "craiggwilson";
        repo = "claude-debussy";
        rev = "02cc22c3389ade8b68d0a1b084be860011831e48";
        hash = "sha256-/Lr/w0YXRSI/SK7YtFlMXb0Rhddp5KuKTNJwlUJiD2k=";
      };

      format = "pyproject";

      nativeBuildInputs = with pythonPkgs; [
        setuptools
        wheel
      ];

      # setDefaultResourcePath is global C++ state that doesn't
      # propagate to threads.  HTTP handler threads (ThreadingMixIn) create
      # toolkit instances that get the wrong resource path.  Fix by setting
      # the global resource path in each thread before creating the toolkit.
      postPatch = ''
        sed -i \
          '/^    import verovio/a\    verovio.setDefaultResourcePath(verovio.__path__[0] + "/data")' \
          src/debussy/preview.py
      '';

      propagatedBuildInputs = with pythonPkgs; [
        cairosvg
        pypdf
        music21
        verovio
      ];

      doCheck = false;

      meta = {
        description = "MusicXML CLI harness powered by music21";
        homepage = "https://github.com/craiggwilson/claude-debussy";
        license = lib.licenses.mit;
        mainProgram = "debussy";
        platforms = lib.platforms.linux;
      };
    };
}
