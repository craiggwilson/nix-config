{
  config.substrate.modules.ai.clients.skills.agent-development = {
    tags = [
      "ai:clients"
    ];

    homeManager =
      { pkgs, ... }:
      {
        hdwlinux.ai.clients.skills.agent-development = toString (pkgs.runCommand "agent-development-skill" { } ''
          mkdir -p $out
          cp -r ${./skill}/* $out/
        '');
      };
  };
}
