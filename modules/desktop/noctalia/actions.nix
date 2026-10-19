{
  config.substrate.modules.desktop.noctalia.actions = {
    tags = [ "desktop:noctalia" ];
    homeManager = {
      hdwlinux.desktop.actions = {
        showApplicationLauncher = {
          binding = "Mod+Space";
          command = [
            "noctalia"
            "msg"
            "panel-toggle"
            "launcher"
          ];
          description = "Show application launcher";
          showInHotkeyOverlay = true;
        };
        showClipboard = {
          binding = "Mod+V";
          command = [
            "noctalia"
            "msg"
            "panel-toggle"
            "clipboard"
          ];
          description = "Show clipboard menu";
          showInHotkeyOverlay = true;
        };
        showControlCenter = {
          binding = "Mod+S";
          command = [
            "noctalia"
            "msg"
            "panel-toggle"
            "control-center"
          ];
          description = "Show control center";
          showInHotkeyOverlay = true;
        };
        showPowerMenu = {
          binding = "Mod+X";
          command = [
            "noctalia"
            "msg"
            "panel-toggle"
            "session"
          ];
          description = "Show power menu";
          showInHotkeyOverlay = true;
        };
        showScreenRecordMenu = {
          binding = "Mod+Print";
          command = [
            "noctalia"
            "msg"
            "plugin"
            "noctalia/screen_recorder:service"
            "all"
            "toggle"
          ];
          description = "Toggle screen recording";
        };
        showShellSettings = {
          binding = "Mod+Comma";
          command = [
            "noctalia"
            "msg"
            "settings-toggle"
          ];
          description = "Show shell settings";
          showInHotkeyOverlay = true;
        };
        showWindowSwitcher = {
          binding = "Alt+Tab";
          command = [
            "noctalia"
            "msg"
            "window-switcher"
          ];
          description = "Show window switcher";
          showInHotkeyOverlay = true;
        };
        toggleAudioMute = {
          binding = "XF86AudioMute";
          command = [
            "noctalia"
            "msg"
            "volume-mute"
          ];
          description = "Toggle audio mute";
        };
        volumeLower = {
          binding = "XF86AudioLowerVolume";
          command = [
            "noctalia"
            "msg"
            "volume-down"
          ];
          description = "Lower volume";
        };
        volumeRaise = {
          binding = "XF86AudioRaiseVolume";
          command = [
            "noctalia"
            "msg"
            "volume-up"
          ];
          description = "Raise volume";
        };
        brightnessLower = {
          binding = "XF86MonBrightnessDown";
          command = [
            "noctalia"
            "msg"
            "brightness-down"
          ];
          description = "Lower brightness";
        };
        brightnessRaise = {
          binding = "XF86MonBrightnessUp";
          command = [
            "noctalia"
            "msg"
            "brightness-up"
          ];
          description = "Raise brightness";
        };
      };
    };
  };
}
