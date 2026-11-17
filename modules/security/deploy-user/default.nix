{ lib, ... }:
let
  deploySshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL4ZoVIjS1Wu2tOWOifjz+o1DlIjqJdT18JTZru1YCdC deploy@hdwlinux";
in
{
  config.substrate.modules.security.deployUser = {
    tags = [ "core:base" ];

    nixos =
      { config, pkgs, ... }:
      {
        options.hdwlinux.security.deployUser.sshPublicKey = lib.mkOption {
          type = lib.types.str;
          default = deploySshPublicKey;
          description = "SSH public key allowed to log in as the deploy user.";
        };

        config = {
          users.users.deploy = {
            isSystemUser = true;
            group = "deploy";
            description = "Deployment automation user";
            home = "/var/lib/deploy";
            createHome = true;
            shell = pkgs.bash;
            openssh.authorizedKeys.keys = [ config.hdwlinux.security.deployUser.sshPublicKey ];
          };

          users.groups.deploy = { };

          # The deploy user exists solely to run automated deployments. It is
          # authenticated by a dedicated SSH key and confined to this role, so
          # passwordless sudo is acceptable here even though the interactive
          # user still requires a password.
          security.sudo-rs.extraRules = [
            {
              users = [ "deploy" ];
              commands = [
                {
                  command = "ALL";
                  options = [ "NOPASSWD" ];
                }
              ];
            }
          ];
        };
      };

    homeManager = _: {
      programs.ssh.settings = {
        "Match Host blackflame,unsouled,wintersteel User deploy" = {
          IdentityFile = "~/.ssh/deploy_ed25519";
          IdentitiesOnly = "yes";
        };
      };
    };
  };
}
