{
  config.substrate.modules.ai.agent.skills.codebase-search = {
    tags = [
      "ai:agent"
    ];

    homeManager =
      { pkgs, ... }:
      {
        hdwlinux.ai.agent.skills.codebase-search = pkgs.runCommand "codebase-search-skill" { } ''
          mkdir -p $out
          cp -r ${./skill}/* $out/
        '';
      };
  };
}
