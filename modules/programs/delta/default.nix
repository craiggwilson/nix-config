{
  config.substrate.modules.programs.delta = {
    tags = [ "programming" ];

    perUser =
      { pkgs, config, ... }:
      {
        packages = [ pkgs.delta ];

        # Mirrors home-manager's programs.delta enableGitIntegration.
        hdwlinux.programs.git.configFragments = [
          {
            delta = {
              navigate = true;
              light = false;
              side-by-side = true;
              line-numbers = true;
            };
            interactive.diffFilter = "${pkgs.delta}/bin/delta --color-only";
            pager = {
              blame = "${pkgs.delta}/bin/delta";
              diff = "${pkgs.delta}/bin/delta";
              log = "${pkgs.delta}/bin/delta";
              show = "${pkgs.delta}/bin/delta";
            };
          }
        ];
      };
  };
}
