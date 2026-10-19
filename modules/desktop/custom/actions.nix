{
  config.substrate.modules.desktop.custom.actions = {
    tags = [ "desktop:custom" ];
    homeManager = {
      hdwlinux.desktop.actions = {
        showApplicationLauncher = {
          binding = "Mod+Space";
          command = [
            "vicinae"
            "vicinae://toggle"
          ];
          description = "Show application launcher";
        };
        showClipboard = {
          binding = "Mod+V";
          command = [
            "clipboardctl"
            "show-menu"
          ];
          description = "Show clipboard menu";
        };
        showPowerMenu = {
          binding = "Mod+X";
          command = [
            "vicinae"
            "vicinae://launch/power?toggle=true"
          ];
          description = "Show power menu";
        };
        showScreenRecordMenu = {
          binding = "Mod+Print";
          command = [
            "screenctl"
            "record"
            "show-menu"
          ];
          description = "Show screen recording menu";
        };
        showWindowSwitcher = {
          binding = "Mod+Tab";
          command = [
            "vicinae"
            "vicinae://launch/windows?toggle=true"
          ];
          description = "Show window switcher";
        };
        toggleAudioMute = {
          binding = "XF86AudioMute";
          command = [
            "audioctl"
            "output"
            "mute"
            "toggle"
          ];
          description = "Toggle audio mute";
        };
        volumeLower = {
          binding = "XF86AudioLowerVolume";
          command = [
            "audioctl"
            "output"
            "volume"
            "lower"
          ];
          description = "Lower volume";
        };
        volumeRaise = {
          binding = "XF86AudioRaiseVolume";
          command = [
            "audioctl"
            "output"
            "volume"
            "raise"
          ];
          description = "Raise volume";
        };
        brightnessLower = {
          binding = "XF86MonBrightnessDown";
          command = [
            "screenctl"
            "backlight"
            "lower"
          ];
          description = "Lower brightness";
        };
        brightnessRaise = {
          binding = "XF86MonBrightnessUp";
          command = [
            "screenctl"
            "backlight"
            "raise"
          ];
          description = "Raise brightness";
        };
      };
    };
  };
}
