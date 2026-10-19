{
  config.substrate.modules.desktop.actions = {
    generic =
      { lib, ... }:
      let
        actionType = lib.types.submodule {
          options = {
            binding = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Optional compositor-neutral key binding.";
            };
            command = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Command and arguments to run for this action.";
            };
            description = lib.mkOption {
              type = lib.types.str;
              description = "Description of the action.";
            };
          };
        };
      in
      {
        options.hdwlinux.desktop.actions = lib.mkOption {
          type = lib.types.attrsOf actionType;
          default = { };
          description = "Semantic desktop actions and their optional key bindings.";
        };
      };

    homeManager =
      { config, lib, ... }:
      let
        apps = config.hdwlinux.desktop.apps;
        appAction = name: description: binding: {
          inherit binding description;
          command = [ "app-${name}" ];
        };
      in
      {
        hdwlinux.desktop.actions = lib.mkMerge [
          (lib.optionalAttrs (apps.terminal != null) {
            launchTerminal = appAction "terminal" "Launch terminal" "Mod+T";
          })
          (lib.optionalAttrs (apps.webBrowser != null) {
            launchWebBrowser = appAction "webBrowser" "Launch web browser" "Mod+B";
          })
          (lib.optionalAttrs (apps.fileManager != null) {
            launchFileManager = appAction "fileManager" "Launch file manager" "Mod+E";
          })
          (lib.optionalAttrs (apps.passwordManager-toggle != null) {
            togglePasswordManager = appAction "passwordManager-toggle" "Toggle password manager" "Mod+L";
          })
          (lib.optionalAttrs (apps.passwordManager-lock != null) {
            lockPasswordManager = appAction "passwordManager-lock" "Lock password manager" "Mod+Shift+L";
          })
        ];
      };
  };
}
