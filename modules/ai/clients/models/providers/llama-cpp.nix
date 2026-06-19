{
  config.substrate.modules.ai.clients.models.providers.llama-cpp = {
    tags = [
      "ai:llm"
      "ai:clients"
    ];

    homeManager =
      { config, lib, ... }:
      let
        llmModels = config.hdwlinux.ai.llm.models;
        modelNames = builtins.attrNames llmModels;
        aliasNames = config.hdwlinux.ai.clients.models.aliasNames;

        aliases = lib.filterAttrs (_: v: v != null) (
          lib.genAttrs aliasNames (
            alias:
            let
              matchingModel = lib.foldl' (
                best: name:
                if builtins.elem alias (llmModels.${name}.categories or [ ]) then
                  let
                    candidatePriority = llmModels.${name}.priority or 0;
                    bestPriority = if best == null then -1 else llmModels.${best}.priority or 0;
                  in
                  if best == null || candidatePriority > bestPriority then name else best
                else
                  best
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
        hdwlinux.ai.clients.models.providers."llama.cpp" = {
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

        hdwlinux.ai.clients.models.aliases = lib.mkOptionDefault aliases;
      };
  };
}
