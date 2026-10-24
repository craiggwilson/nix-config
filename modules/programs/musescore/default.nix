{
  config.substrate.modules.programs.musescore = {
    tags = [
      "desktop"
      "profile:personal"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          (pkgs.musescore.overrideAttrs (old: {
            # Qt 6.12 generates invalid MuseScore QML cache C++ because
            # muse::extensions::Type collides with Qt's Type.
            cmakeFlags = old.cmakeFlags ++ [ "-DQT_QML_NO_CACHEGEN=ON" ];
          }))
          pkgs.muse-sounds-manager
        ];
      };
  };
}
