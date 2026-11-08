_: {
  compose = {
    services.hindsight = {
      container_name = "hindsight";
      environment = {
        # shortcut: keep LLM off until agentgateway can refresh a Keycloak token for Hindsight.
        HINDSIGHT_API_LLM_PROVIDER = "none";
        HINDSIGHT_API_MCP_ENABLED = "true";
        HINDSIGHT_API_TENANT_EXTENSION = "hindsight_api.extensions.builtin.tenant:ApiKeyTenantExtension";
        HINDSIGHT_API_WORKER_ID = "hindsight";
      };
      env_file = [ "/volume3/docker/hindsight/secrets/hindsight.env" ];
      image = "ghcr.io/vectorize-io/hindsight:1.2.0";
      ports = [
        "8888:8888"
        "9999:9999"
      ];
      restart = "unless-stopped";
      shm_size = "1gb";
      stop_grace_period = "75s";
      # shortcut: use pg0 for the trial; switch to external PostgreSQL before relying on the data.
      volumes = [ "hindsight-data:/home/hindsight/.pg0" ];
    };

    volumes.hindsight-data = { };
  };

  directories = [ "secrets" ];

  secrets."secrets/hindsight.env" = "HINDSIGHT_ENV";
}
