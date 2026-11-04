{
  config.substrate.modules.locations.raeford.secrets = {
    tags = [
      "location:raeford"
      "user:craig"
      "profile:personal"
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

  config.substrate.modules.locations.raeford.secrets-craig-personal = {
    tags = [
      "location:raeford"
      "user:craig"
      "profile:personal"
    ];

    homeManager = {
      secretspec.entries = {
        PAPERLESS_POSTGRES_PASSWORD = {
          description = "PostgreSQL password for the Paperless-ngx Synology stack.";
          ref = {
            field = "postgres_password";
            item = "Paperless";
            vault = "Craig";
          };
        };

        PAPERLESS_SECRET_KEY = {
          description = "Django secret key for the Paperless-ngx Synology stack.";
          ref = {
            field = "secret_key";
            item = "Paperless";
            vault = "Craig";
          };
        };

        YUVOMI_DB_ENCRYPTION_KEY = {
          description = "Database encryption key for the Yuvomi Synology stack.";
          ref = {
            field = "db_encryption_key";
            item = "Yuvomi";
            vault = "Craig";
          };
        };

        YUVOMI_SESSION_SECRET = {
          description = "Session secret for the Yuvomi Synology stack.";
          ref = {
            field = "session_secret";
            item = "Yuvomi";
            vault = "Craig";
          };
        };
      };
    };
  };
}
