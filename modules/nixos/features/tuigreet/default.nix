{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.tuigreet;
in
{
  options.hdwlinux.features.tuigreet = with types; {
    enable = mkBoolOpt false "Whether or not to enable tuigreet.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      greetd.tuigreet
    ];

    services.greetd.settings.default_session.command = "${pkgs.greetd.tuigreet}/bin/tuigreet --remember --remember-user-session --time --cmd Hyprland";
  };
}
