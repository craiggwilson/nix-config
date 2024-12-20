{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.hdwlinux.programs.spotify;
in
{
  options.hdwlinux.programs.spotify = {
    enable = config.lib.hdwlinux.mkEnableOption "spotify" [
      "audio"
      "gui"
    ];
  };

  config = lib.mkIf cfg.enable {
    programs.spicetify =
      let
        spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
      in
      {
        enable = true;
        theme = spicePkgs.themes.catppuccin;
        colorScheme = "mocha";

        enabledExtensions = with spicePkgs.extensions; [
          adblock
          shuffle # shuffle+ (special characters are sanitized out of extension names)
        ];
      };
  };
}
