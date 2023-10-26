{ options, config, pkgs, lib, host ? "", format ? "", inputs ? { }, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.stylix;
in
{
  options.hdwlinux.features.stylix = with types; {
    enable = mkBoolOpt false "Whether or not to enable stylix.";
  };

  config = mkIf cfg.enable {
    # This is needed to skin the things unrelated to a user. Technically, we could probably only use the home-manager module,
    # but something isn't exactly working, so we'll bootstrap with an image.
    stylix.image = ./bubbles.jpg;
    stylix.polarity = "dark";
  };
}
