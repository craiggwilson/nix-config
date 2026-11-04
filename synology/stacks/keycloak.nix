_: {
  compose.services = {
    db = {
      container_name = "keycloak-db";
      environment = {
        POSTGRES_DB = "keycloak";
        POSTGRES_USER = "keycloak";
        POSTGRES_PASSWORD_FILE = "/run/secrets/db_password";
      };
      image = "docker.io/library/postgres:18";
      restart = "unless-stopped";
      volumes = [
        "/volume3/docker/keycloak/pgdata:/var/lib/postgresql"
        "/volume3/docker/keycloak/secrets/db_password:/run/secrets/db_password:ro"
      ];
    };

    keycloak = {
      container_name = "keycloak";
      depends_on = [ "db" ];
      entrypoint = [
        "/bin/sh"
        "-c"
      ];
      environment = {
        KC_BOOTSTRAP_ADMIN_USERNAME = "admin";
        KC_DB = "postgres";
        KC_DB_URL = "jdbc:postgresql://db:5432/keycloak";
        KC_DB_USERNAME = "keycloak";
      };
      image = "quay.io/keycloak/keycloak:26.8.1";
      ports = [ "8080:8080" ];
      restart = "unless-stopped";
      volumes = [
        "/volume3/docker/keycloak/secrets/admin_password:/run/secrets/admin_password:ro"
        "/volume3/docker/keycloak/secrets/db_password:/run/secrets/db_password:ro"
      ];
      command = [
        "export KC_DB_PASSWORD=\"$(cat /run/secrets/db_password)\" KC_BOOTSTRAP_ADMIN_PASSWORD=\"$(cat /run/secrets/admin_password)\"; exec /opt/keycloak/bin/kc.sh start --http-enabled=true --hostname=https://auth.wilsonfamilyhq.com --hostname-admin=https://auth.wilsonfamilyhq.com --proxy-headers=xforwarded"
      ];
    };
  };

  directories = [
    "pgdata"
    "secrets"
  ];

  secrets = {
    "secrets/admin_password" = "KEYCLOAK_ADMIN_PASSWORD";
    "secrets/db_password" = "KEYCLOAK_DB_PASSWORD";
  };
}
