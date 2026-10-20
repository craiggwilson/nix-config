{
  config.substrate.modules.ai.clients.models.providers.fireworks-ai = {
    tags = [
      "users:craig:work"
      "ai:clients"
    ];

    homeManager = _: {
      hdwlinux.ai.clients.models.providers.fireworks-ai = {
        displayName = "Fireworks AI";

        # Models are auto-listed by OpenCode v2 (models.dev); this provider
        # entry exists to wire the API key through secretspec.
        secret = "FIREWORKS_API_KEY";
      };

      # FIXME(craig): confirm the 1Password item/field for the Fireworks key —
      # until this ref resolves, the ai_clients_opencode launcher scope fails
      # and OpenCode will not start.
      secretspec.entries.FIREWORKS_API_KEY = {
        description = "Fireworks AI API key for the fireworks-ai model provider";
        ref = {
          field = "api-key";
          item = "Fireworks";
          vault = "Work";
        };
      };
    };
  };
}
