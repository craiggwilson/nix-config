{
  config.substrate.modules.ai.clients.models.grove = {
    tags = [
      "user:craig"
      "profile:work"
      "profile:ai"
    ];

    homeManager.hdwlinux.ai.clients.models.providers = {
      # The grove-gateway OpenCode plugin (see programs.opencode.grove-gateway)
      # auto-provisions these providers, their auth, and their model catalog,
      # so the registry only records their ids for alias resolution. The ids
      # are upstream's canonical `ai-gateway-*` names — the service was renamed
      # from Grove to AI Gateway upstream (AII-803), and the plugin rewrites
      # old `grove-*` ids in memory with a warning per reference, so aliases
      # use the real runtime ids even though everyone calls it Grove.
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
    };
  };
}
