_: {
  compose.services = {
    db = {
      container_name = "keycloak-db";
      env_file = [ "/volume3/docker/keycloak/secrets/keycloak.env" ];
      environment = {
        POSTGRES_DB = "keycloak";
        POSTGRES_USER = "keycloak";
      };
      image = "docker.io/library/postgres:18";
      restart = "unless-stopped";
      volumes = [
        "/volume3/docker/keycloak/pgdata:/var/lib/postgresql"
      ];
    };

    keycloak = {
      container_name = "keycloak";
      depends_on = [ "db" ];
      env_file = [ "/volume3/docker/keycloak/secrets/keycloak.env" ];
      environment = {
        KC_BOOTSTRAP_ADMIN_USERNAME = "admin";
        KC_DB = "postgres";
        KC_DB_URL = "jdbc:postgresql://db:5432/keycloak";
        KC_DB_USERNAME = "keycloak";
      };
      image = "quay.io/keycloak/keycloak:26.8.1";
      ports = [ "8080:8080" ];
      restart = "unless-stopped";
      command = [
        "start"
        "--http-enabled=true"
        "--hostname=https://auth.wilsonfamilyhq.com"
        "--hostname-admin=https://auth.wilsonfamilyhq.com"
        "--proxy-headers=xforwarded"
      ];
    };
  };

  directories = [
    "pgdata"
    "secrets"
  ];

  secrets = {
    "secrets/keycloak.env" = "KEYCLOAK_ENV";
  };
}
