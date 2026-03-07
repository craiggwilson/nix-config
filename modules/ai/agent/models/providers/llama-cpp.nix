{
  config.substrate.modules.ai.agent.models.providers.llama-cpp = {
    tags = [
      "ai:llm"
      "ai:agent"
    ];

    homeManager =
      { config, lib, ... }:
      let
        llmModels = config.hdwlinux.ai.llm.models;
        modelNames = builtins.attrNames llmModels;
        aliasNames = config.hdwlinux.ai.agent.models.aliasNames;

        aliases = lib.filterAttrs (_: v: v != null) (
          lib.genAttrs aliasNames (
            alias:
            let
              matchingModel = lib.findFirst (
                name: builtins.elem alias (llmModels.${name}.categories or [ ])
              ) null modelNames;
            in
            if matchingModel != null then
              {
                provider = "llama.cpp";
                model = matchingModel;
              }
            else
              null
          )
        );
      in
      {
        hdwlinux.ai.agent.models.providers."llama.cpp" = {
          displayName = "LLaMA C++ (local)";
          models = lib.mapAttrs (
            name: model:
            let
              oc = model.settings.opencode or { };
            in
            {
              displayName = name;
              limits = {
                context = oc.limit.context or 32000;
                output = oc.limit.output or 8192;
              };
            }
          ) llmModels;
        };

        hdwlinux.ai.agent.models.aliases = lib.mkOptionDefault aliases;
      };
  };
}
