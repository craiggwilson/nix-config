_: {
  compose.services.yuvomi = {
    command = [
      "node"
      "server/index.js"
    ];
    container_name = "yuvomi";
    environment = {
      BACKUP_DIR = "/backups";
      DB_PATH = "/data/yuvomi.db";
      DB_ENCRYPTION_KEY_FILE = "/run/secrets/db_encryption_key";
      DMS_ALLOW_PRIVATE_NETWORK = "true";
      MODULES_DIR = "/app/modules";
      NODE_ENV = "production";
      SESSION_SECRET_FILE = "/run/secrets/session_secret";
      SESSION_SECURE = "true";
    };
    healthcheck = {
      test = [
        "CMD"
        "node"
        "-e"
        "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode === 200 ? 0 : 1))"
      ];
      interval = "30s";
      retries = 3;
      start_period = "10s";
      timeout = "10s";
    };
    env_file = [ "/volume3/docker/yuvomi/secrets/yuvomi.env" ];
    extra_hosts = [ "auth.wilsonfamilyhq.com:192.168.100.50" ];
    image = "ghcr.io/ulsklyc/yuvomi:latest";
    entrypoint = [
      "/bin/sh"
      "/run/yuvomi-entrypoint.sh"
    ];
    ports = [ "3000:3000" ];
    restart = "unless-stopped";
    volumes = [
      "/volume3/docker/yuvomi/data:/data"
      "/volume3/docker/yuvomi/backups:/backups"
      "/volume3/docker/yuvomi/modules:/app/modules"
      "/volume3/docker/yuvomi/documents:/documents"
      "/volume3/docker/yuvomi/secrets/session_secret:/run/secrets/session_secret:ro"
      "/volume3/docker/yuvomi/secrets/db_encryption_key:/run/secrets/db_encryption_key:ro"
      "/volume3/docker/yuvomi/yuvomi-entrypoint.sh:/run/yuvomi-entrypoint.sh:ro"
    ];
  };

  files."yuvomi-entrypoint.sh" = builtins.readFile ./yuvomi/files/entrypoint.sh;

  directories = [
    "data"
    "backups"
    "modules"
    "documents"
    "secrets"
  ];

  secrets = {
    "secrets/db_encryption_key" = "YUVOMI_DB_ENCRYPTION_KEY";
    "secrets/session_secret" = "YUVOMI_SESSION_SECRET";
    "secrets/yuvomi.env" = "YUVOMI_ENV";
  };
}
