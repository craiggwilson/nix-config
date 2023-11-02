{ lib, inputs, pkgs, stdenv, ...}:

stdenv.mkDerivation rec {
    pname = "structurizr-cli";
    version = "1.34.0";

    src = pkgs.fetchurl {
      url = "https://github.com/structurizr/cli/releases/download/v${version}/${pname}-${version}.zip";
      hash = "sha256-SEy8zu024WXtKydMlHoyO8nl6o8kCADbWsPuQW8p5BQ=";
    };

    dontUnpack = true;

    nativeBuildInputs = with pkgs; [ 
      makeWrapper 
      unzip 
    ];

    installPhase = ''
      mkdir -p $out/bin

      unzip $src -d $out      
      
      makeWrapper ${pkgs.jre}/bin/java $out/bin/${pname} \
          --add-flags "-cp \"$out/lib/*\"" \
          --add-flags "com.structurizr.cli.StructurizrCliApplication" \
          --add-flags "$@"
    '';

    meta = {
      mainProgram = pname;
      description = "Structurizr builds upon “diagrams as code”, allowing you to create multiple software architecture diagrams, in a variety of rendering tools, from a single model.";
      homepage = "https://structurizr.com/";
    };
}