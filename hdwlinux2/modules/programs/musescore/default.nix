{
  config.substrate.modules.programs.musescore = {
    tags = [
      "gui"
      "users:craig:personal"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.musescore
          pkgs.muse-sounds-manager
        ];
      };
  };
}

