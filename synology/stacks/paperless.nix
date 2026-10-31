_: {
  compose.services = {
    broker = {
      image = "docker.io/valkey/valkey:9-alpine";
      restart = "unless-stopped";
      volumes = [ "/volume3/docker/paperless/redisdata:/data" ];
    };

    db = {
      environment = {
        POSTGRES_DB = "paperless";
        POSTGRES_USER = "paperless";
        POSTGRES_PASSWORD_FILE = "/run/secrets/postgres_password";
      };
      image = "docker.io/library/postgres:18";
      restart = "unless-stopped";
      volumes = [
        "/volume3/docker/paperless/pgdata:/var/lib/postgresql"
        "/volume3/docker/paperless/secrets/postgres_password:/run/secrets/postgres_password:ro"
      ];
    };

    gotenberg = {
      command = [
        "gotenberg"
        "--chromium-disable-javascript=true"
        "--chromium-allow-list=file:///tmp/.*"
      ];
      image = "docker.io/gotenberg/gotenberg:8.24";
      restart = "unless-stopped";
    };

    paperless = {
      depends_on = [
        "db"
        "broker"
        "gotenberg"
        "tika"
      ];
      environment = {
        PAPERLESS_DBENGINE = "postgresql";
        PAPERLESS_DBHOST = "db";
        PAPERLESS_DBPASS_FILE = "/run/secrets/postgres_password";
        PAPERLESS_REDIS = "redis://broker:6379";
        PAPERLESS_SECRET_KEY_FILE = "/run/secrets/secret_key";
        PAPERLESS_OCR_LANGUAGE = "eng";
        PAPERLESS_TIME_ZONE = "America/New_York";
        PAPERLESS_URL = "https://paperless.raeford.wilsonfamilyhq.com";
        PAPERLESS_TIKA_ENDPOINT = "http://tika:9998";
        PAPERLESS_TIKA_ENABLED = "1";
      };
      image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
      ports = [ "8010:8000" ];
      restart = "unless-stopped";
      volumes = [
        "/volume3/docker/paperless/data:/usr/src/paperless/data"
        "/volume3/docker/paperless/media:/usr/src/paperless/media"
        "/volume3/docker/paperless/export:/usr/src/paperless/export"
        "/volume3/docker/paperless/consume:/usr/src/paperless/consume"
        "/volume3/docker/paperless/secrets/postgres_password:/run/secrets/postgres_password:ro"
        "/volume3/docker/paperless/secrets/secret_key:/run/secrets/secret_key:ro"
      ];
    };

    tika = {
      image = "docker.io/apache/tika:latest";
      restart = "unless-stopped";
    };
  };

  directories = [
    "data"
    "media"
    "export"
    "consume"
    "pgdata"
    "redisdata"
    "secrets"
  ];

  secrets = {
    "secrets/postgres_password" = "PAPERLESS_POSTGRES_PASSWORD";
    "secrets/secret_key" = "PAPERLESS_SECRET_KEY";
  };
}
