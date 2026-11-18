{
  substrate.packages.jj-gt =
    { lib, pkgs, ... }:
    pkgs.stdenv.mkDerivation {
      pname = "jj-gt";
      version = "0.1.0";

      src = ./jj-gt;
      dontUnpack = true;
      doCheck = true;
      nativeBuildInputs = [
        pkgs.jujutsu
        pkgs.python3
      ];

      checkPhase = ''
        runHook preCheck
        python3 $src/test_jj_gt.py
        runHook postCheck
      '';

      installPhase = ''
        runHook preInstall
        install -Dm755 $src/jj-gt.py $out/bin/jj-gt
        substituteInPlace $out/bin/jj-gt \
          --replace-fail '@PYTHON@' '${pkgs.python3}/bin/python3' \
          --replace-fail '@JUJUTSU@' '${lib.getExe pkgs.jujutsu}' \
          --replace-fail '@GRAPHITE@' '${pkgs.graphite-cli}/bin/gt'
        ln -s jj-gt $out/bin/gt
        runHook postInstall
      '';

      meta = {
        description = "Guarded Jujutsu-native bridge to Graphite";
        mainProgram = "jj-gt";
      };
    };
}
