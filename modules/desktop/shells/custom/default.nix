{
  config.substrate.modules.desktop.shells.custom = {
    tags = [ "desktop:shells:custom" ];

    # Custom shell: waybar, mako, hyprpaper, hypridle/hyprlock, syshud,
    # wlsunset, vicinae, and hyprpolkitagent, composed from the submodules
    # under this directory.

    nixos = {
      hdwlinux.desktop.shells.custom.prettyName = "Custom";
    };
  };
}
