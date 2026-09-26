{
  config.substrate.modules.programs.lsd = {
    tags = [ "programming" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.lsd ];

        # lsd reads the standard XDG location; no wrapping needed.
        files.".config/lsd/config.yaml".text = ''
          icons:
            when: auto
        '';

        # home-manager's programs.lsd contributed these through shell
        # integration; the registry keeps them alive in zsh and bash.
        hdwlinux.shell.aliases = {
          la = "${pkgs.lsd}/bin/lsd -A";
          ll = "${pkgs.lsd}/bin/lsd -l";
          lla = "${pkgs.lsd}/bin/lsd -lA";
          llt = "${pkgs.lsd}/bin/lsd -l --tree";
          ls = "${pkgs.lsd}/bin/lsd";
          lt = "${pkgs.lsd}/bin/lsd --tree";
        };
      };
  };
}
