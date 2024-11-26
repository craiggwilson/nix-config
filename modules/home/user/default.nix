{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.hdwlinux.user;

  updatesToPkgs =
    updates:
    let
      nodeToPkg =
        name: value:
        if builtins.isString value then
          {
            root = pkgs.writeShellScriptBin "${name}" value;
            packages = [ ];
          }
        else
          toPkgs name value;

      toPkgs =
        name: node:
        let
          group = builtins.map (key: nodeToPkg "${name}-${key}" node."${key}") (builtins.attrNames node);
          roots = builtins.map (g: g.root) group;
          root = pkgs.writeShellScriptBin name "${lib.strings.concatStringsSep "\n" (
            builtins.map (r: "${lib.getExe r}") roots
          )}";
          packages = builtins.concatMap (g: [ g.root ] ++ g.packages) group;
        in
        {
          root = root;
          packages = packages;
        };
      result = toPkgs "update" updates;
    in
    [ result.root ] ++ result.packages;

in
{
  options.hdwlinux.user = {
    name = lib.mkOption {
      description = "The name to use for the user account.";
      type = lib.types.str;
      default = config.snowfallorg.user.name;
    };
    fullName = lib.mkOption {
      type = lib.types.str;
      description = "The full name of the user.";
    };
    email = lib.mkOption {
      type = lib.types.str;
      description = "The email of the user.";
    };
    publicKey = lib.mkOption {
      type = lib.types.str;
      description = "The public key for the user.";
    };
    homeDirectory = lib.mkOption {
      description = "The user's home directory.";
      type = lib.types.nullOr lib.types.str;
      default = "/home/${cfg.name}";
    };

    updates = lib.mkOption {
      description = "Update scripts";
      type = lib.types.attrsOf lib.types.anything;
      default = { };
    };
  };

  config = {
    home = {
      username = lib.mkDefault cfg.name;
      homeDirectory = lib.mkDefault cfg.home;

      file.".ssh/id_rsa.pub".text = cfg.publicKey;

      sessionPath = [ "$HOME/.local/bin" ];

      packages = updatesToPkgs cfg.updates;
    };
  };
}
