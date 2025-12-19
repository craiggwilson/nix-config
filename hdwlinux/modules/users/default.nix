{ lib, ... }:
let
  userOption = lib.types.submodule (
    { config, ... }:
    {
      options = {
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
          type = lib.types.str;
          default = "/home/${config.name}";
        };
      };
    }
  );
in
{
  config.substrate.modules.users = {
    homeManager =
      { config, lib, ... }:
      {
        options.hdwlinux.user = lib.mkOption {
          description = "User information for home-manager configuration.";
          type = userOption;
        };

        config = {
          home = {
            username = lib.mkDefault config.hdwlinux.user.name;
            homeDirectory = lib.mkDefault config.hdwlinux.user.homeDirectory;
            file.".ssh/id_rsa.pub".text = config.hdwlinux.user.publicKey;
            sessionPath = [ "$HOME/.local/bin" ];
          };
        };
      };
  };
}
