{
  config.substrate.modules.users.craig.work.grove-gateway = {
    tags = [
      "user:craig:work"
      "profile:ai"
    ];

    homeManager =
      {
        pkgs,
        ...
      }:
      {
        programs.opencode.settings.plugins = [
          {
            # MongoDB's internal Grove gateway plugin (upstream renamed the
            # service "AI Gateway"): provisions the ai-gateway-* providers,
            # injects the saved `ai-gateway` credential, and contributes its
            # model catalog to the picker. Connect once with /connect ->
            # AI Gateway (the picker entry; or set AI_GATEWAY_API_KEY) — old
            # Grove keys are rejected by the new gateway.
            package = "${pkgs.hdwlinux.opencode-grove-gateway}";
          }
        ];

        # The plugin's own config file. `__v = 1` is the current schema, so
        # the plugin reads this and never rewrites it. allowProviders limits
        # OpenCode's enabled_providers to the gateway's providers plus this
        # list — anything not named stays off, which is what keeps
        # amazon-bedrock out (it activates whenever the service inherits
        # AWS_* from a direnv shell). Set to "*" to disable the filter.
        xdg.configFile."opencode/grove.jsonc".text = builtins.toJSON {
          "__v" = 1;
          enabled = true;
          providers = {
            anthropic = true;
            misc = true;
            openai = true;
          };
          allowProviders = [
            "agentgateway"
            "fireworks-ai"
            "github-copilot"
            "opencode"
          ];
        };
      };
  };
}
