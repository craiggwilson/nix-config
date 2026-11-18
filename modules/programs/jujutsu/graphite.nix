{
  config.substrate.modules.programs.jujutsu.graphite = {
    tags = [
      "user:craig"
      "profile:work"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.jj-gt ];
        programs.jujutsu.settings.aliases.gt = [
          "util"
          "exec"
          "--"
          "${pkgs.hdwlinux.jj-gt}/bin/jj-gt"
        ];
      };
  };
}
