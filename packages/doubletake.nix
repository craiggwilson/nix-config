{
  substrate.packages.doubletake =
    { pkgs, ... }:
    pkgs.buildGoModule {
      pname = "doubletake";
      version = "0.5.0";

      src = pkgs.fetchFromGitHub {
        owner = "omarroth";
        repo = "doubletake";
        rev = "e18f85d07f74a3b9d49f448762d28f3b7feb3938";
        hash = "sha256-rsxZ/UL4Pv32+timlohcue0GZcZOrAIrUkR1FX6CyTI=";
      };

      nativeBuildInputs = [ pkgs.gnumake ];
      vendorHash = "sha256-cgvY9MVGe8I3g3Ni2sGucTY6YCyPJ2YnoxxUaYfl1E4=";

      patches = [ ./doubletake-backpressure.patch ];

      buildPhase = "make";

      installPhase = ''
        install -Dm755 bin/doubletake $out/bin/doubletake
        install -Dm755 bin/doubletake-ctl $out/bin/doubletake-ctl
      '';

      meta = {
        description = "AirPlay screen mirroring sender for Linux";
        homepage = "https://github.com/omarroth/doubletake";
        license = pkgs.lib.licenses.lgpl3Only;
        mainProgram = "doubletake";
        platforms = pkgs.lib.platforms.linux;
      };
    };
}
