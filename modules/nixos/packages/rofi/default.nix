{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.rofi;
in
{
  options.hdwlinux.packages.rofi = with types; {
    enable = mkBoolOpt false "Whether or not to enable rofi.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland-unwrapped;
      theme = "theme";
    };

    hdwlinux.home.configFile."rofi/themes/theme.rasi".text = ''
      * {
          font:   "IBM Plex Mono 12";

          background-color:   transparent;
          text-color:         #${config.hdwlinux.theme.color4};
          accent-color:       #${config.hdwlinux.theme.color8};

          margin:     0px;
          padding:    0px;

          spacing:    0px;
      }

      window {
          background-color:   #${config.hdwlinux.theme.color0};
          border-color:       @accent-color;

          location:   center;
          width:      480px;
          border:     1px;
      }

      inputbar {
          padding:    8px 12px;
          spacing:    12px;
          children:   [ prompt, entry ];
      }

      prompt, entry, element-text, element-icon {
          vertical-align: 0.5;
      }

      prompt {
          text-color: @accent-color;
      }

      listview {
          lines:      8;
          columns:    1;

          fixed-height:   false;
      }

      element {
          padding:    8px;
          spacing:    8px;
      }

      element normal urgent {
          text-color: #${config.hdwlinux.theme.color13};
      }

      element normal active {
          text-color: @accent-color;
      }

      element selected {
          text-color: #${config.hdwlinux.theme.color0};
      }

      element selected normal {
          background-color:   @accent-color;
      }

      element selected urgent {
          background-color:   #${config.hdwlinux.theme.color13};
      }

      element selected active {
          background-color:   #${config.hdwlinux.theme.color8};
      }

      element-icon {
          size:   0.75em;
      }

      element-text {
          text-color: inherit;
      }
    '';
  };
}
