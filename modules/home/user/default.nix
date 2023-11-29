{ lib, pkgs, inputs, config, flake, options, ... }: 
with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.user;
in
{
  options.hdwlinux.user = with types; {
    name = mkStrOpt config.snowfallorg.user.name "The name to use for the user account.";
    fullName = mkOption { type = str; description = "The full name of the user."; };
    email = mkOption { type = str; description = "The email of the user."; };
    publicKey = mkOption { type = str; description = "The public key for the user."; };
    homeDirectory = mkOpt (nullOr str) "/home/${cfg.name}" "The user's home directory.";
  };

  config = {
    home = {
      username = mkDefault cfg.name;
      homeDirectory = mkDefault cfg.home;

      file.".ssh/id_rsa.pub".text = cfg.publicKey;
      file.".ssh/authorized_keys".text = cfg.publicKey;

      sessionVariables = {
        NIX_CONFIG_FLAKE=flake;
      };

      shellAliases = {
        "start" = "xdg-open";
        "nix-config" = "git -C ${flake}";
        "nix-config-switch" = "nix-config add -A . && sudo nixos-rebuild switch --flake ${flake}?submodules=1";
      };
    };
  };
}
