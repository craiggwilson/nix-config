{
  config.substrate.modules.programs.bat = {
    tags = [ "programming" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.bat ];

        # bat reads the standard XDG location; no wrapping needed.
        files.".config/bat/config".text = ''
          theme = "base16"
        '';
      };
  };
}
