_: {
  buildOnDeploy = true;

  compose = {
    services = {
      db = {
        container_name = "hindsight-db";
        env_file = [ "/volume3/docker/hindsight/secrets/db.env" ];
        environment = {
          POSTGRES_DB = "hindsight";
          POSTGRES_USER = "hindsight";
        };
        healthcheck = {
          interval = "5s";
          retries = 10;
          test = [
            "CMD-SHELL"
            "pg_isready -U hindsight -d hindsight"
          ];
          timeout = "5s";
        };
        image = "docker.io/pgvector/pgvector:pg18";
        restart = "unless-stopped";
        volumes = [
          "/volume3/docker/hindsight/pgdata:/var/lib/postgresql"
        ];
      };

      hindsight = {
        build = {
          context = ".";
          dockerfile = "Dockerfile";
        };
        container_name = "hindsight";
        depends_on = {
          db = {
            condition = "service_healthy";
          };
        };
        env_file = [ "/volume3/docker/hindsight/secrets/hindsight.env" ];
        environment = {
          HINDSIGHT_API_LLM_BASE_URL = "http://synology.raeford.wilsonfamilyhq.com:4001/v1";
          HINDSIGHT_API_LLM_DEFAULT_HEADERS = builtins.toJSON {
            "x-opencode-session" = "hindsight-wilsonfamilyhq";
          };
          HINDSIGHT_API_LLM_MODEL = "copilot/gpt-6-luna";
          HINDSIGHT_API_LLM_PROVIDER = "openai";
          HINDSIGHT_API_LLM_TEMPERATURE = "1";
          HINDSIGHT_API_MCP_ENABLED = "true";
          HINDSIGHT_API_TENANT_EXTENSION = "hindsight_ext_static_keys_tenant:StaticKeysTenantExtension";
          HINDSIGHT_API_TENANT_SCHEMA_PREFIX = "user";
          HINDSIGHT_API_WORKER_ID = "hindsight";
        };
        image = "hindsight-static-keys:1.2.0";
        ports = [
          "8888:8888"
          "9999:9999"
        ];
        restart = "unless-stopped";
        shm_size = "1gb";
        stop_grace_period = "75s";
      };
    };
  };

  directories = [
    "pgdata"
    "secrets"
  ];

  files = {
    "Dockerfile" = builtins.readFile ../hindsight-static-keys/Dockerfile;
    "hindsight_ext_static_keys_tenant/__init__.py" =
      builtins.readFile ../hindsight-static-keys/hindsight_ext_static_keys_tenant/__init__.py;
    "hindsight_ext_static_keys_tenant/extension.py" =
      builtins.readFile ../hindsight-static-keys/hindsight_ext_static_keys_tenant/extension.py;
  };

  secrets = {
    "secrets/db.env" = "HINDSIGHT_DB_ENV";
    "secrets/hindsight.env" = "HINDSIGHT_ENV";
  };
}
