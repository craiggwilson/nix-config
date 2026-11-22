{
  config.substrate.modules.users.craig.work.models = {
    tags = [
      "user:craig:work"
      "profile:ai"
    ];

    homeManager =
      { lib, ... }:
      let
        # Work host routes aliases through Grove (the AI Gateway upstream;
        # providers auto-provisioned by the grove-gateway OpenCode plugin) and
        # directly to fireworks.ai for open-source models. ai-gateway-* model
        # keys come from the plugin's catalog (models.jsonc upstream). No
        # deepseek: it is being retired for us. Fireworks "latest" routers
        # track the current generation (GLM 5.3, Kimi K3.1 Pro).
        mk = provider: model: { inherit provider model; };
        fw = model: mk "fireworks-ai" "accounts/fireworks/models/${model}";
        router = model: mk "fireworks-ai" "accounts/fireworks/routers/${model}";
      in
      {
        hdwlinux.ai.clients.models = {
          aliases = lib.mkDefault {
            analysis = {
              models = [
                (fw "kimi-k3p1-pro")
                (mk "ai-gateway-misc" "fw-kimi-k3")
                (mk "ai-gateway-anthropic" "claude-opus-5-5")
                (mk "ai-gateway-openai" "gpt-6.1-sol")
              ];
            };
            balanced = {
              models = [
                (router "glm-latest")
                (mk "ai-gateway-anthropic" "claude-sonnet-5-5")
              ];
            };
            code-review = {
              models = [
                (router "glm-latest")
                (mk "ai-gateway-misc" "fw-glm-5.3")
                (mk "ai-gateway-openai" "gpt-6.1-sol")
                (fw "kimi-k3p1-pro")
              ];
            };
            coding = {
              models = [
                (fw "kimi-k3p1-pro")
                (mk "ai-gateway-misc" "fw-kimi-k3")
                (mk "ai-gateway-openai" "gpt-6.1-sol")
                (mk "ai-gateway-openai" "gpt-5.3-codex")
              ];
            };
            fast = {
              models = [
                (router "glm-flash-latest")
                (mk "ai-gateway-openai" "gpt-6-luna")
                (mk "ai-gateway-openai" "gpt-5.4-mini")
                (mk "ai-gateway-anthropic" "claude-haiku-4-5")
              ];
            };
            orchestration = {
              models = [
                (mk "ai-gateway-anthropic" "claude-opus-5-5")
                (mk "ai-gateway-openai" "gpt-6.1-sol")
                (fw "qwen3p8-max")
              ];
            };
            research = {
              models = [
                (mk "ai-gateway-openai" "gpt-6-luna")
                (mk "ai-gateway-openai" "gpt-6.1-sol")
                (mk "ai-gateway-misc" "fw-glm-5.3")
                (router "glm-latest")
              ];
            };
            writing = {
              models = [
                (mk "ai-gateway-openai" "gpt-6-luna")
                (mk "ai-gateway-openai" "gpt-5.5")
                (fw "kimi-k3p1-pro")
              ];
            };
          };

          providers = {
            # The grove-gateway OpenCode plugin auto-provisions these providers,
            # their auth, and their model catalog, so the registry only records
            # their ids for alias resolution. The ids are upstream's canonical
            # `ai-gateway-*` names; the plugin rewrites old `grove-*` ids in
            # memory with a warning per reference.
            ai-gateway-anthropic = {
              builtin = true;
              displayName = "Grove Anthropic";
            };
            ai-gateway-misc = {
              builtin = true;
              displayName = "Grove Misc";
            };
            ai-gateway-openai = {
              builtin = true;
              displayName = "Grove OpenAI";
            };
            fireworks-ai = {
              builtin = true;
              displayName = "Fireworks AI";
            };
          };
        };
      };
  };
}
