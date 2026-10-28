{
  substrate.packages.debussy =
    { lib, pkgs, ... }:
    let
      python = pkgs.python3;
      pythonPkgs = python.pkgs;

      music21 = pythonPkgs.buildPythonPackage rec {
        pname = "music21";
        version = "10.5.1";

        src = pkgs.fetchurl {
          url = "https://files.pythonhosted.org/packages/15/12/dee0eef7c82a63e83eea94bdcde97c66ab55213d89cee1347d2d11601faa/music21-10.5.1-py3-none-any.whl";
          hash = "sha256-3DMJSYxMlc69+NTyDIaN62tjvOHZKcrU9Rp8zJgph7E=";
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
        url = "https://raw.githubusercontent.com/steinbergmedia/bravura/bravura-1.392/redist/otf/Bravura.otf";
        hash = "sha256-3KLZDIhDenAbHC5x+lTnb5+kHX3u6TXXTchx6mbs/dI=";
      };

      verovio = pythonPkgs.buildPythonPackage rec {
        pname = "verovio";
        version = "6.3.0";

        src = pkgs.fetchurl {
          url = "https://files.pythonhosted.org/packages/a7/23/25d6a382968815baf686099d519064c3444aaad7297b6e6c507c5608f225/verovio-6.3.0-cp310-abi3-manylinux2014_x86_64.manylinux_2_17_x86_64.whl";
          hash = "sha256-CJanCKWxMMxbqzoWjXBDWtiz5UaSCI5+Xigf7xHAsF0=";
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
