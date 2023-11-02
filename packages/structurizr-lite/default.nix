{ lib, inputs, pkgs, stdenv, ...}:

stdenv.mkDerivation rec {
    pname = "structurizr-lite";
    version = "v3207";

    src = pkgs.fetchurl {
      url = "https://github.com/structurizr/lite/releases/download/${version}/${pname}.war";
      hash = "sha256-J7vztvHj/UoR/E2RP3eiyeYmDnX7SAQZKG4FHnLNjro=";
    };

    dontUnpack = true;

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      mkdir -p $out/bin
      
      makeWrapper ${pkgs.jre}/bin/java $out/bin/${pname} \
          --suffix PATH : ${lib.makeBinPath [ pkgs.graphviz ]} \
          --add-flags "-Djdk.util.jar.enableMultiRelease=false" \
          --add-flags "-jar $src" \
          --add-flags "$@"
    '';

    meta = {
      mainProgram = pname;
      description = "Structurizr builds upon “diagrams as code”, allowing you to create multiple software architecture diagrams, in a variety of rendering tools, from a single model.";
      homepage = "https://structurizr.com/";
    };
}