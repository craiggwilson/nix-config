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
      };
  };
}
