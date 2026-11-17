{
  config.substrate.modules.ai.clients.skills.openspec = {
    tags = [ "profile:ai" ];

    # Generated once with `openspec init --tools opencode`; regenerate on upgrades.
    homeManager =
      { lib, ... }:
      {
        hdwlinux.ai.clients.skills = lib.mapAttrs (name: _: ./skill + "/${name}") (
          builtins.readDir ./skill
        );
      };
  };
}
