{
  config.substrate.modules.ai.clients.mcp-servers.plannotator-inbox = {
    tags = [
      "profile:ai"
    ];

    homeManager =
      { lib, pkgs, ... }:
      {
        # Plannotator's own stdio server (`plannotator inbox mcp`): the
        # Inbox where agents leave questions, summaries and reviews for the
        # person — send_message and friends, per `plannotator inbox --help`.
        # OpenCode is excluded from this entry in the opencode module and
        # uses the @plannotator/opencode plugin instead, whose replies
        # arrive back inside the session.
        hdwlinux.ai.clients.mcpServers.plannotator-inbox.stdio = {
          command = lib.getExe pkgs.hdwlinux.plannotator;
          args = [
            "inbox"
            "mcp"
          ];
        };
      };
  };
}
