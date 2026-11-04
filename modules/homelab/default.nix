{
  config.substrate.modules.homelab = {
    tags = [
      "profile:homelab"
    ];

    homeManager =
      { config, ... }:
      {
        secretspec = {
          providers.onepassword_homelab = {
            credentials.service_account_token = "file:${config.xdg.configHome}/secretspec/homelab";
            uri = "onepassword://";
          };

          entries = {
            HOMELAB_SERVICE_ACCOUNT_TOKEN = {
              description = "SecretSpec service account token scoped to the Homelab 1Password vault.";
              file.path = "${config.xdg.configHome}/secretspec/homelab/${config.home.username}/_provider/service_account_token";
              providers = [ "onepassword" ];
              ref = {
                field = "homelab_service_account_token";
                item = "1password";
                vault = "Craig";
              };
            };

            AGENTGATEWAY_OPENCODE_GO_API_KEY = {
              description = "OpenCode Go API key for the agentgateway Synology stack.";
              providers = [ "onepassword_homelab" ];
              ref = {
                vault = "Homelab";
                item = "agentgateway";
                field = "opencode_api_key";
              };
            };

            AGENTGATEWAY_OIDC_COOKIE_SECRET = {
              description = "Agentgateway OIDC session cookie encryption key.";
              providers = [ "onepassword_homelab" ];
              ref = {
                vault = "Homelab";
                item = "agentgateway";
                field = "oidc_cookie_secret";
              };
            };

            AGENTGATEWAY_OIDC_ENV = {
              composed = ''
                OIDC_COOKIE_SECRET=''${AGENTGATEWAY_OIDC_COOKIE_SECRET}
                UI_CLIENT_SECRET=''${KEYCLOAK_AGENTGATEWAY_UI_CLIENT_SECRET}
              '';
              description = "Agentgateway OIDC environment file.";
              file.path = "${config.xdg.configHome}/secretspec/agentgateway-oidc.env";
            };

            KEYCLOAK_AGENTGATEWAY_UI_CLIENT_SECRET = {
              description = "Keycloak client secret for the agentgateway administrator UI.";
              providers = [ "onepassword_homelab" ];
              ref = {
                vault = "Homelab";
                item = "keycloak";
                field = "agentgateway_ui_client_secret";
              };
            };

            KEYCLOAK_ADMIN_PASSWORD = {
              description = "Keycloak bootstrap administrator password for the Synology stack.";
              providers = [ "onepassword_homelab" ];
              ref = {
                vault = "Homelab";
                item = "keycloak";
                field = "admin_password";
              };
            };

            KEYCLOAK_DB_PASSWORD = {
              description = "Keycloak PostgreSQL password for the Synology stack.";
              providers = [ "onepassword_homelab" ];
              ref = {
                vault = "Homelab";
                item = "keycloak";
                field = "db_password";
              };
            };

            PAPERLESS_POSTGRES_PASSWORD = {
              description = "PostgreSQL password for the Paperless-ngx Synology stack.";
              providers = [ "onepassword_homelab" ];
              ref = {
                vault = "Homelab";
                item = "paperless";
                field = "postgres_password";
              };
            };

            PAPERLESS_SECRET_KEY = {
              description = "Django secret key for the Paperless-ngx Synology stack.";
              providers = [ "onepassword_homelab" ];
              ref = {
                vault = "Homelab";
                item = "paperless";
                field = "secret_key";
              };
            };

            YUVOMI_DB_ENCRYPTION_KEY = {
              description = "Database encryption key for the Yuvomi Synology stack.";
              providers = [ "onepassword_homelab" ];
              ref = {
                vault = "Homelab";
                item = "yuvomi";
                field = "db_encryption_key";
              };
            };

            YUVOMI_SESSION_SECRET = {
              description = "Session secret for the Yuvomi Synology stack.";
              providers = [ "onepassword_homelab" ];
              ref = {
                vault = "Homelab";
                item = "yuvomi";
                field = "session_secret";
              };
            };
          };
        };
      };
  };
}
