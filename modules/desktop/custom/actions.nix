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
          showInHotkeyOverlay = true;
        };
        showClipboard = {
          binding = "Mod+V";
          command = [
            "clipboardctl"
            "show-menu"
          ];
          description = "Show clipboard menu";
          showInHotkeyOverlay = true;
        };
        showPowerMenu = {
          binding = "Mod+X";
          command = [
            "vicinae"
            "vicinae://launch/power?toggle=true"
          ];
          description = "Show power menu";
          showInHotkeyOverlay = true;
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
          binding = "Alt+Tab";
          command = [
            "vicinae"
            "vicinae://launch/windows?toggle=true"
          ];
          description = "Show window switcher";
          showInHotkeyOverlay = true;
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
