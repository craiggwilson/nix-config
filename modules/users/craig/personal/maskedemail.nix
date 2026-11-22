{
  config.substrate.modules.users.craig.personal.maskedemail = {
    tags = [
      "user:craig:personal"
      "core:security:secrets"
      "profile:email-management"
    ];

    homeManager =
      { config, ... }:
      {
        hdwlinux.programs.maskedemail.tokenFile = config.secretspec.entries.MASKEDEMAIL_TOKEN.file.path;

        secretspec.entries.MASKEDEMAIL_TOKEN = {
          description = "Fastmail Masked Email API token for maskedemail-cli";
          ref = {
            vault = "Craig";
            item = "Fastmail";
            field = "maskedemail_token";
          };

          # Materialized by the user oneshot so the wrapper reads a file at
          # exec time rather than resolving the secret through 1Password.
          file = { };
        };
      };
  };
}
