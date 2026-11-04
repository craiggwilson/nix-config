{
  # NixOS-side CIFS creds: craig mounts //synology/home on raeford hosts
  # regardless of personal/work profile, so no profile tag here.
  config.substrate.modules.locations.raeford.secrets = {
    tags = [
      "location:raeford"
      "user:craig"
    ];

    nixos = {
      secretspec.entries = {
        SYNOLOGY_CIFS_PASSWORD = {
          description = "Password for the Synology SMB account.";
          ref = {
            vault = "Craig";
            item = "Synology - Craig";
            field = "password";
          };
        };
        synologyCifsCredentials = {
          description = "Credentials file for Synology SMB mounts.";
          composed = ''
            username=craiggwilson
            password=''${SYNOLOGY_CIFS_PASSWORD}'';
          file = { };
        };
      };
    };
  };

}
