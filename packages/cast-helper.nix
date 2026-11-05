{
  substrate.packages.cast-helper =
    { lib, pkgs, ... }:
    pkgs.buildGoModule {
      pname = "cast-helper";
      version = "0.1.0-unstable-2026-10-24";

      src = pkgs.fetchFromGitHub {
        owner = "Conava";
        repo = "dux-cast";
        rev = "4d3869e7faf0501ab82742ee608dfd6eb7a39ef8";
        hash = "sha256-hF7a2kQmkTm2YxS7LFvul8V5iS8FZ/fGlgLTypcEOz4=";
      };

      vendorHash = "sha256-JdnJBwV2DHo/1EZ5v6bxC1JK/5PUIZeRmjroMnZrQoQ=";

      patches = [ ./cast-helper-airplay-audio.patch ];

      nativeBuildInputs = [ pkgs.makeWrapper ];

      buildPhase = ''
        runHook preBuild
        CGO_ENABLED=0 go build -o cast-helper .
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        install -Dm755 cast-helper $out/bin/cast-helper
        runHook postInstall
      '';

      postInstall = ''
        wrapProgram $out/bin/cast-helper \
          --prefix LD_LIBRARY_PATH : ${
            lib.makeLibraryPath [
              pkgs.gst_all_1.gstreamer.out
              pkgs.gst_all_1.gst-plugins-base
              pkgs.gst_all_1.gst-plugins-good
              pkgs.gst_all_1.gst-plugins-bad
              pkgs.gst_all_1.gst-libav
              pkgs.pipewire
            ]
          } \
          --set GST_PLUGIN_SYSTEM_PATH_1_0 ${
            lib.makeSearchPath "lib/gstreamer-1.0" [
              pkgs.gst_all_1.gstreamer.out
              pkgs.gst_all_1.gst-plugins-base
              pkgs.gst_all_1.gst-plugins-good
              pkgs.gst_all_1.gst-plugins-bad
              pkgs.gst_all_1.gst-libav
              pkgs.pipewire
            ]
          }
      '';

      meta = {
        description = "Standalone Cast helper for Dux Shell and other applications";
        homepage = "https://github.com/Conava/dux-cast";
        license = pkgs.lib.licenses.mit;
        mainProgram = "cast-helper";
        platforms = pkgs.lib.platforms.linux;
      };
    };
}
