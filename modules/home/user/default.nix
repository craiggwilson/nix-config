{ lib, pkgs, inputs, config, flake, options, ... }:
with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.user;

  updatesToPkgs = updates:
    let
      nodeToPkg = name: value:
        if builtins.isString value then {
          root = pkgs.writeShellScriptBin "${name}" value;
          packages = [ ];
        } else toPkgs name value;

      toPkgs = name: node:
        let
          group = builtins.map (key: nodeToPkg "${name}-${key}" node."${key}") (builtins.attrNames node);
          roots = builtins.map (g: g.root) group;
          root = pkgs.writeShellScriptBin name "${concatStringsSep "\n" (builtins.map (r: "${lib.getExe r}") roots)}";
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
  options.hdwlinux.user = with types; {
    name = mkStrOpt config.snowfallorg.user.name "The name to use for the user account.";
    fullName = mkOption { type = str; description = "The full name of the user."; };
    email = mkOption { type = str; description = "The email of the user."; };
    publicKey = mkOption { type = str; description = "The public key for the user."; };
    homeDirectory = mkOpt (nullOr str) "/home/${cfg.name}" "The user's home directory.";

    updates = mkOpt (attrsOf anything) { } "Update scripts";
  };

  config = {
    home = {
      username = mkDefault cfg.name;
      homeDirectory = mkDefault cfg.home;

      file.".ssh/id_rsa.pub".text = cfg.publicKey;

      sessionPath = [
        "$HOME/.local/bin"
      ];

      packages = updatesToPkgs cfg.updates;
    };
  };
}
