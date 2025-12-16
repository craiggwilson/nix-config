{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.user;
in
{
  options.hdwlinux.user = {
    name = lib.mkOption {
      description = "The name to use for the user account.";
      type = lib.types.str;
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
  };

  config = {
    home = {
      username = lib.mkDefault cfg.name;
      homeDirectory = lib.mkDefault cfg.homeDirectory;
      file.".ssh/id_rsa.pub".text = cfg.publicKey;
      sessionPath = [ "$HOME/.local/bin" ];
    };
  };
}
