{ lib, pkgs, inputs, config, options, ... }: 
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
    };
  };
}
