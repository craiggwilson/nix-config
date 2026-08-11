{ lib, pkgs, ... }:
let
  python = pkgs.python3;
  pythonPkgs = python.pkgs;

  music21 = pythonPkgs.buildPythonPackage rec {
    pname = "music21";
    version = "10.5.0";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/81/4c/4f307e5ab6fbf59233813e58e07128a599c810dd974673449e132ce1432d/music21-10.5.0-py3-none-any.whl";
      hash = "sha256-mSTv9fv1hJDmfL87eKWLpTBA53woGTDTVK8yp0fpRgY=";
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
    version = "6.2.1";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/a1/23/0470c944d4dfb79bb86b8b5e606cb182583c3d04d053d4e5e3ff82bc2ed7/verovio-6.2.1-cp314-cp314-manylinux2014_x86_64.manylinux_2_17_x86_64.whl";
      hash = "sha256-b4U8XpS4mvVD9pjz3MxA/po/NmwNzCTPQQBeiUcUKFs=";
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
}
