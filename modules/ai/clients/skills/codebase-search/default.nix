{
  config.substrate.modules.ai.clients.skills.codebase-search = {
    tags = [
      "ai:clients"
    ];

    homeManager =
      { pkgs, ... }:
      {
        hdwlinux.ai.clients.skills.codebase-search = pkgs.runCommand "codebase-search-skill" { } ''
          mkdir -p $out
          cp -r ${./skill}/* $out/
        '';
      };
  };
}
