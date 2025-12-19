{
  config,
  lib,
  ...
}:

{
  options.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }:
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
              type = lib.types.nullOr lib.types.str;
              description = "The public key for the user.";
              default = null;
            };
            homeDirectory = lib.mkOption {
              description = "The user's home directory.";
              type = lib.types.str;
              default = "/home/${name}";
            };

            type = lib.mkOption {
              description = "The type of user.";
              type = lib.types.enum [
                "standard"
                "admin"
              ];
              default = "standard";
            };

            modules = lib.mkOption {
              type = lib.types.attrsOf (lib.types.listOf lib.types.module);
              default = [ ];
            };
          };
        }
      )
    );
    default = { };
    description = "User specific configurations.";
  };

  config.users = lib.mapAttrs (username: usercfg: {
    ${username}.modules.nixos = [
      {
        users.users.${username} = {
          isNormalUser = true;

          name = username;
          home = usercfg.homeDirectory;
          group = "users";
          initialPassword = "password";

          openssh.authorizedKeys.keys = lib.mkIf (usercfg.publicKey != null) [
            usercfg.publicKey
          ];

          extraGroups = lib.mkIf (usercfg.type == "admin") [
            "wheel"
          ];
        };
      }
    ];
  }) config.users;
}
